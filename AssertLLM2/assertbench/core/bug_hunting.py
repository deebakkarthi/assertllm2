from __future__ import annotations

import difflib
import hashlib
import re
import shutil
from pathlib import Path

from assertbench.core.io import read_json, write_json

_MUTATION_LINE_RE = re.compile(r"@ line (\d+)")
_DEFAULT_K_BUGS = 5


def bug_hunting_enabled(cfg: dict) -> bool:
    return bool(cfg.get("bug_hunting", {}).get("enabled", False))


def resolve_bug_hunting_prompt_rtl_source(cfg: dict) -> str:
    bug_cfg = cfg.get("bug_hunting", {})
    source = str(bug_cfg.get("prompt_rtl_source", "buggy")).strip().lower()
    if source not in {"buggy", "golden"}:
        raise ValueError(
            "Invalid bug_hunting.prompt_rtl_source='{}'; supported values are ['buggy', 'golden']".format(
                source
            )
        )
    return source


def apply_bug_hunting_golden_output_dir_segment(cfg: dict) -> None:
    if not bug_hunting_enabled(cfg):
        return
    if resolve_bug_hunting_prompt_rtl_source(cfg) != "golden":
        return
    out = cfg.get("output_dir")
    if not out or not str(out).strip():
        return
    p = Path(str(out).rstrip("/"))
    if p.name == "_golden":
        return
    cfg["output_dir"] = str(p / "_golden")


def _infer_source_mutations_dir(cfg: dict, bug_cfg: dict) -> Path:
    candidates = []

    direct = bug_cfg.get("source_mutations_dir")
    if direct:
        candidates.append(Path(str(direct)).expanduser())

    mut_cfg = cfg.get("mutation", {})
    mut_direct = mut_cfg.get("source_mutations_dir")
    if mut_direct:
        candidates.append(Path(str(mut_direct)).expanduser())

    dataset_root = mut_cfg.get("dataset_root") or cfg.get("benchmark", {}).get("dataset_root")
    if dataset_root:
        candidates.append(Path(str(dataset_root)).expanduser() / "mutations")

    spec_files = [str(p) for p in (cfg.get("spec_file") or []) if str(p).strip()]
    if spec_files:
        candidates.append(Path(spec_files[0]).expanduser().resolve().parent / "mutations")

    rtl_files = [str(p) for p in (cfg.get("rtl", {}).get("filelist", []) or []) if str(p).strip()]
    if rtl_files:
        candidates.append(Path(rtl_files[0]).expanduser().resolve().parent / "mutations")

    seen: set[Path] = set()
    resolved: list[Path] = []
    for c in candidates:
        r = c.resolve()
        if r in seen:
            continue
        seen.add(r)
        resolved.append(r)

    for c in resolved:
        if c.is_dir() and (c / "mutants_index.json").is_file():
            return c

    for c in resolved:
        if c.is_dir():
            return c

    raise ValueError(
        "bug_hunting could not resolve source mutations directory. "
        "Set bug_hunting.source_mutations_dir explicitly or keep a '<design>/mutations' folder. "
        f"Checked: {[str(p) for p in resolved]}"
    )


def ensure_bug_hunting_assets(cfg: dict, run_outdir: Path | None = None) -> dict | None:
    if not bug_hunting_enabled(cfg):
        return None

    bug_cfg = cfg.get("bug_hunting", {})
    top_module = str(cfg.get("rtl", {}).get("top_module", "top")).strip() or "top"
    rtl_files = [str(p) for p in cfg.get("rtl", {}).get("filelist", []) if str(p).strip()]
    if not rtl_files:
        raise ValueError("bug_hunting.enabled=true requires rtl.filelist in config")

    source_dir = _infer_source_mutations_dir(cfg=cfg, bug_cfg=bug_cfg)
    source_index = source_dir / "mutants_index.json"
    if not source_index.is_file():
        raise FileNotFoundError(f"Missing source mutants_index.json: {source_index}")

    source_payload = read_json(source_index)
    source_mutants = source_payload.get("mutants", [])
    if not isinstance(source_mutants, list):
        raise ValueError(f"Invalid mutants list in {source_index}")
    success_mutants = [
        m for m in source_mutants if str(m.get("status", "success")).strip().lower() == "success"
    ]
    if not success_mutants:
        raise ValueError(f"No successful mutants found in {source_index}")

    default_root = Path(cfg["output_dir"]).expanduser().resolve().parent / "bug_hunting_artifacts"
    local_root = bug_cfg.get("local_artifact_root")
    artifact_root = Path(str(local_root)).expanduser().resolve() if local_root else default_root
    design_root = artifact_root / top_module
    merged_rtl_dir = design_root / "merged_buggy_rtl"
    single_bug_mutants_dir = design_root / "single_bug_mutants"
    manifest_path = design_root / "bug_hunting_manifest.json"

    source_mutants_root = source_dir / "mutants"
    if not source_mutants_root.is_dir():
        raise FileNotFoundError(f"Missing source mutants directory: {source_mutants_root}")

    rtl_name_to_src, golden_lines_by_name = _prepare_base_rtl_maps(rtl_files)
    mutation_summary_map = _load_mutation_summary_map(source_dir)
    merge_base_lines_by_name = _build_merge_base_lines(
        rtl_name_to_src=rtl_name_to_src,
        golden_lines_by_name=golden_lines_by_name,
        source_mutants=success_mutants,
        source_mutants_root=source_mutants_root,
        mutation_summary_map=mutation_summary_map,
    )

    explicit_ids = [
        str(x).strip() for x in (bug_cfg.get("selected_mutant_ids") or []) if str(x).strip()
    ]
    if explicit_ids:
        by_id = {str(m.get("mutant_id", "")).strip(): m for m in success_mutants}
        missing = [mid for mid in explicit_ids if mid not in by_id]
        if missing:
            raise ValueError(
                "selected_mutant_ids includes unknown/non-success IDs: " + ", ".join(missing)
            )
        selected_payloads = _validate_explicit_selection_no_overlap(
            selected=[by_id[mid] for mid in explicit_ids],
            source_mutants_root=source_mutants_root,
            rtl_name_to_src=rtl_name_to_src,
            merge_base_lines_by_name=merge_base_lines_by_name,
            mutation_summary_map=mutation_summary_map,
        )
        selection_policy = "explicit_mutant_ids_non_overlapping_prechecked"
    else:
        k_default = int(bug_cfg.get("default_k_bugs", _DEFAULT_K_BUGS))
        k_bugs = int(bug_cfg.get("k_bugs", k_default))
        if k_bugs <= 0:
            raise ValueError(
                "bug_hunting requires positive bug count. "
                f"Set bug_hunting.k_bugs > 0 (default is {_DEFAULT_K_BUGS})."
            )
        selected_payloads = _select_non_overlapping_mutants(
            candidates=success_mutants,
            k_bugs=k_bugs,
            source_mutants_root=source_mutants_root,
            rtl_name_to_src=rtl_name_to_src,
            merge_base_lines_by_name=merge_base_lines_by_name,
            mutation_summary_map=mutation_summary_map,
        )
        selection_policy = "first_k_non_overlapping_successful_mutants_prechecked"

    selected = [p["mutant"] for p in selected_payloads]
    _rebuild_single_bug_mutants(
        selected=selected,
        rtl_files=rtl_files,
        source_dir=source_dir,
        out_dir=single_bug_mutants_dir,
    )
    merged_manifest = _build_merged_buggy_rtl(
        selected_payloads=selected_payloads,
        rtl_files=rtl_files,
        merge_base_lines_by_name=merge_base_lines_by_name,
        merged_rtl_dir=merged_rtl_dir,
    )

    manifest = {
        "enabled": True,
        "top_module": top_module,
        "source_mutations_dir": str(source_dir),
        "artifact_root": str(design_root),
        "merged_rtl_dir": str(merged_rtl_dir),
        "merged_rtl_filelist": [str(merged_rtl_dir / Path(rtl).name) for rtl in rtl_files],
        "single_bug_mutants_dir": str(single_bug_mutants_dir),
        "selected_mutants": [
            {
                "mutant_id": str(m.get("mutant_id", "")).strip(),
                "target_signal_id": m.get("target_signal_id"),
                "target_signal": m.get("target_signal"),
                "target_module": m.get("target_module"),
                "operator": m.get("operator"),
                "mutation_log": m.get("mutation_log"),
                "target_rtl_file": m.get("target_rtl_file"),
            }
            for m in selected
        ],
        "merged_operations": merged_manifest["operations"],
        "inserted_mutations": merged_manifest["inserted_mutations"],
        "selection_size": len(selected),
        "selection_policy": selection_policy,
    }

    write_json(manifest_path, manifest)
    if run_outdir is not None:
        write_json(run_outdir / "bug_hunting_manifest.json", manifest)

    return manifest


def prepare_bug_hunting_eval_inputs(cfg: dict, outdir: Path) -> dict | None:
    manifest = ensure_bug_hunting_assets(cfg=cfg, run_outdir=outdir)
    if manifest is None:
        return None

    selected = manifest.get("selected_mutants", [])
    if not selected:
        raise ValueError("bug_hunting selected_mutants is empty")

    source_mutants_dir = Path(manifest["single_bug_mutants_dir"])
    run_mutants_dir = outdir / "mutants"
    if run_mutants_dir.exists():
        shutil.rmtree(run_mutants_dir)
    run_mutants_dir.mkdir(parents=True, exist_ok=True)

    rtl_files = [str(p) for p in cfg.get("rtl", {}).get("filelist", []) if str(p).strip()]
    if not rtl_files:
        raise ValueError("Missing rtl.filelist while preparing bug-hunting evaluation inputs")
    rtl_names = [Path(p).name for p in rtl_files]

    mutants = []
    logs = []
    for item in selected:
        mutant_id = str(item.get("mutant_id", "")).strip()
        if not mutant_id:
            raise ValueError("Found selected mutant without mutant_id in bug_hunting manifest")
        src_dir = source_mutants_dir / mutant_id
        if not src_dir.is_dir():
            raise FileNotFoundError(f"Missing copied single-bug mutant folder: {src_dir}")

        dst_dir = run_mutants_dir / mutant_id
        shutil.copytree(src_dir, dst_dir, dirs_exist_ok=True)

        all_rtl_files = []
        for name in rtl_names:
            p = dst_dir / name
            if not p.is_file():
                raise FileNotFoundError(
                    f"Mutant {mutant_id} missing RTL file '{name}' in {dst_dir}"
                )
            all_rtl_files.append(str(p))

        target_file = item.get("target_rtl_file")
        target_name = Path(str(target_file)).name if target_file else (rtl_names[0] if rtl_names else "")
        rtl_path = str(dst_dir / target_name) if target_name else all_rtl_files[0]
        if target_name and not Path(rtl_path).is_file():
            rtl_path = all_rtl_files[0]

        mutation_log = str(item.get("mutation_log", "")).strip()
        logs.append(f"{mutant_id}: {mutation_log}".strip())

        mutants.append(
            {
                "mutant_id": mutant_id,
                "operator": item.get("operator"),
                "target_signal": item.get("target_signal"),
                "target_signal_id": item.get("target_signal_id"),
                "target_module": item.get("target_module"),
                "target_kind": "logic",
                "target_rtl_file": str(item.get("target_rtl_file", "")),
                "location": _extract_mutation_location(mutation_log),
                "mutation_log": mutation_log,
                "rtl_path": rtl_path,
                "all_rtl_files": all_rtl_files,
                "status": "success",
            }
        )

    payload = {
        "target_source": "bug_hunting_prepared",
        "budget": len(mutants),
        "successful_mutations": len(mutants),
        "failed_mutations": 0,
        "mutants": mutants,
        "mutation_logs": logs,
        "bug_hunting": {
            "enabled": True,
            "selection_size": len(mutants),
            "artifact_root": manifest.get("artifact_root"),
            "merged_rtl_filelist": manifest.get("merged_rtl_filelist", []),
        },
    }
    write_json(outdir / "mutants_index.json", payload)
    write_json(
        outdir / "bug_hunting_selected_mutants.json",
        {
            "selected_mutants": selected,
            "copied_to": str(run_mutants_dir),
        },
    )
    return payload


def get_bug_hunting_prompt_rtl_files(cfg: dict, run_outdir: Path | None = None) -> list[str] | None:
    if not bug_hunting_enabled(cfg):
        return None

    prompt_rtl_source = resolve_bug_hunting_prompt_rtl_source(cfg)
    if prompt_rtl_source == "golden":
        files = [str(p) for p in cfg.get("rtl", {}).get("filelist", []) if str(p).strip()]
        if not files:
            raise ValueError(
                "bug_hunting.prompt_rtl_source='golden' requires rtl.filelist in config"
            )
        return files

    manifest = ensure_bug_hunting_assets(cfg=cfg, run_outdir=run_outdir)
    if manifest is None:
        return None
    files = manifest.get("merged_rtl_filelist", [])
    return [str(p) for p in files if str(p).strip()]


def _prepare_base_rtl_maps(rtl_files: list[str]) -> tuple[dict[str, str], dict[str, list[str]]]:
    rtl_name_to_src: dict[str, str] = {}
    base_lines_by_name: dict[str, list[str]] = {}
    for rtl in rtl_files:
        path = Path(rtl).expanduser().resolve()
        if not path.is_file():
            raise FileNotFoundError(f"RTL file does not exist: {path}")
        name = path.name
        if name in rtl_name_to_src and rtl_name_to_src[name] != str(path):
            raise ValueError(
                f"RTL basename collision detected: '{name}'. "
                "Use unique file basenames for bug_hunting merge."
            )
        rtl_name_to_src[name] = str(path)
        base_lines_by_name[name] = path.read_text(
            encoding="utf-8", errors="ignore"
        ).splitlines(keepends=True)
    return rtl_name_to_src, base_lines_by_name


def _load_mutation_summary_map(source_dir: Path) -> dict[str, dict]:
    summary_path = source_dir / "mutation_summary.json"
    if not summary_path.is_file():
        return {}
    payload = read_json(summary_path)
    rows = payload.get("mutants", [])
    if not isinstance(rows, list):
        return {}

    out: dict[str, dict] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        mid = str(row.get("mutant_id", "")).strip()
        if not mid:
            continue
        files = row.get("applied_to_source_files")
        if not isinstance(files, list):
            files = []
        out[mid] = {
            "applied_to_source_files": [str(x).strip() for x in files if str(x).strip()],
            "log": str(row.get("log", "")).strip(),
        }
    return out


def _extract_log_line(log: str) -> int | None:
    matches = _MUTATION_LINE_RE.findall(log)
    if not matches:
        return None
    for s in matches:
        try:
            v = int(s)
            if v > 0:
                return v
        except Exception:
            continue
    return None


def _resolve_target_file_name(
    mutant: dict,
    mutation_summary_map: dict[str, dict],
    rtl_name_to_src: dict[str, str],
) -> str:
    mid = str(mutant.get("mutant_id", "")).strip()
    summary_item = mutation_summary_map.get(mid, {}) if mutation_summary_map else {}
    for rel in summary_item.get("applied_to_source_files", []) or []:
        name = Path(str(rel)).name
        if name in rtl_name_to_src:
            return name

    target = mutant.get("target_rtl_file")
    if target:
        name = Path(str(target)).name
        if name in rtl_name_to_src:
            return name
        if name:
            return name

    raise ValueError(f"Cannot resolve target RTL file for mutant {mid}")


def _build_line_hunks(base_lines: list[str], mutant_lines: list[str]) -> list[dict]:
    matcher = difflib.SequenceMatcher(a=base_lines, b=mutant_lines, autojunk=False)
    hunks = []
    for tag, a0, a1, b0, b1 in matcher.get_opcodes():
        if tag == "equal":
            continue
        hunks.append(
            {
                "tag": tag,
                "base_start": int(a0),
                "base_end": int(a1),
                "new_lines": mutant_lines[b0:b1],
                "old_lines": base_lines[a0:a1],
            }
        )
    return hunks


def _hunk_covers_target_line(h: dict, target_line: int) -> bool:
    idx = target_line - 1
    start = int(h["base_start"])
    end = int(h["base_end"])
    if start < end:
        return start <= idx < end
    return abs(start - idx) <= 1


def _select_relevant_hunks(hunks: list[dict], target_line: int | None) -> list[dict]:
    if not hunks:
        return []
    if target_line is None:
        return hunks
    matched = [h for h in hunks if _hunk_covers_target_line(h, target_line)]
    if matched:
        return matched
    idx = target_line - 1
    return [
        min(
            hunks,
            key=lambda h: min(abs(int(h["base_start"]) - idx), abs(int(h["base_end"]) - idx)),
        )
    ]


def _normalize_for_match(text: str) -> str:
    return re.sub(r"\s+", "", text or "")


def _extract_mutation_cues(mutation_log: str) -> dict:
    log = str(mutation_log or "")
    cues = {"before": None, "after": None, "swap_tokens": None}

    match = re.search(r"@ line\s+\d+\s*:\s*(.*?)\s*==>\s*(.*)$", log)
    if match:
        before_raw = match.group(1).strip()
        after_raw = match.group(2).strip()
        if before_raw and "..." not in before_raw:
            cues["before"] = _normalize_for_match(before_raw)
        if after_raw and "..." not in after_raw:
            cues["after"] = _normalize_for_match(after_raw)

    swap = re.search(r"CSW\(([^<>()\s]+)<->([^<>()\s]+)\)", log)
    if swap:
        cues["swap_tokens"] = (swap.group(1).strip(), swap.group(2).strip())
    return cues


def _select_hunks_for_mutation(
    hunks: list[dict],
    target_line: int | None,
    mutation_log: str,
) -> list[dict]:
    if not hunks:
        return []

    cues = _extract_mutation_cues(mutation_log)
    if cues.get("after"):
        needle = str(cues["after"])
        matched = [
            h for h in hunks if needle in _normalize_for_match("".join(h.get("new_lines", [])))
        ]
        if matched:
            return matched
    if cues.get("before"):
        needle = str(cues["before"])
        matched = [
            h for h in hunks if needle in _normalize_for_match("".join(h.get("old_lines", [])))
        ]
        if matched:
            return matched
    if cues.get("swap_tokens"):
        a, b = cues["swap_tokens"]
        matched = [
            h for h in hunks if a in "".join(h.get("new_lines", [])) and b in "".join(h.get("new_lines", []))
        ]
        if matched:
            return matched

    return _select_relevant_hunks(hunks=hunks, target_line=target_line)


def _read_mutant_rtl_lines(
    source_mutants_root: Path,
    mutant_id: str,
    rtl_name: str,
) -> list[str]:
    mutant_path = source_mutants_root / mutant_id / rtl_name
    if not mutant_path.is_file():
        raise FileNotFoundError(f"Mutant RTL file not found: {mutant_path}")
    return mutant_path.read_text(encoding="utf-8", errors="ignore").splitlines(keepends=True)


def _build_merge_base_lines(
    rtl_name_to_src: dict[str, str],
    golden_lines_by_name: dict[str, list[str]],
    source_mutants: list[dict],
    source_mutants_root: Path,
    mutation_summary_map: dict[str, dict],
) -> dict[str, list[str]]:
    merge_base_lines_by_name: dict[str, list[str]] = {}
    for rtl_name in rtl_name_to_src:
        chosen_lines: list[str] | None = None
        chosen_mid: str | None = None

        for mutant in source_mutants:
            mid = str(mutant.get("mutant_id", "")).strip()
            if not mid:
                continue
            target_file = _resolve_target_file_name(
                mutant=mutant,
                mutation_summary_map=mutation_summary_map,
                rtl_name_to_src=rtl_name_to_src,
            )
            if target_file == rtl_name:
                continue
            lines = _read_mutant_rtl_lines(source_mutants_root, mid, rtl_name)
            if chosen_lines is None:
                chosen_lines = lines
                chosen_mid = mid
            elif lines != chosen_lines:
                raise ValueError(
                    "Non-target mutant file content mismatch while building merge base: "
                    f"{rtl_name} differs between mutants {chosen_mid} and {mid}"
                )

        merge_base_lines_by_name[rtl_name] = (
            chosen_lines if chosen_lines is not None else list(golden_lines_by_name[rtl_name])
        )
    return merge_base_lines_by_name


def _build_mutant_payload(
    mutant: dict,
    source_mutants_root: Path,
    rtl_name_to_src: dict[str, str],
    merge_base_lines_by_name: dict[str, list[str]],
    mutation_summary_map: dict[str, dict],
) -> dict:
    mid = str(mutant.get("mutant_id", "")).strip()
    if not mid:
        raise ValueError("Found mutant without mutant_id")

    if not (source_mutants_root / mid).is_dir():
        raise FileNotFoundError(f"Missing source mutant folder: {source_mutants_root / mid}")

    target_file = _resolve_target_file_name(mutant, mutation_summary_map, rtl_name_to_src)
    if target_file not in merge_base_lines_by_name:
        raise FileNotFoundError(f"Target RTL file '{target_file}' not in configured rtl.filelist")

    mutation_log = str(mutant.get("mutation_log", "")).strip()
    summary_log = str((mutation_summary_map.get(mid, {}) or {}).get("log", "")).strip()
    target_line = _extract_log_line(mutation_log) or _extract_log_line(summary_log)
    mutant_lines = _read_mutant_rtl_lines(source_mutants_root, mid, target_file)
    target_digest = hashlib.sha1("".join(mutant_lines).encode("utf-8", errors="ignore")).hexdigest()

    return {
        "mutant": mutant,
        "mutant_id": mid,
        "target_file": target_file,
        "target_line": target_line,
        "mutant_lines": mutant_lines,
        "target_digest": target_digest,
        "footprint": (target_file, int(target_line) if target_line is not None else -1),
    }


def _span_overlaps(a: tuple[int, int], b: tuple[int, int]) -> bool:
    a0, a1 = int(a[0]), int(a[1])
    b0, b1 = int(b[0]), int(b[1])
    if a0 == a1 and b0 == b1:
        return a0 == b0
    if a0 == a1:
        return b0 <= a0 < b1
    if b0 == b1:
        return a0 <= b0 < a1
    return max(a0, b0) < min(a1, b1)


def _payloads_conflict(a: dict, b: dict) -> bool:
    if a["target_file"] != b["target_file"]:
        return False
    if str(a.get("target_digest", "")) == str(b.get("target_digest", "")):
        return True
    return a["footprint"] == b["footprint"]


def _file_group_merge_overlap_conflict(rows: list[dict]) -> tuple[str, str, str] | None:
    if len(rows) <= 1:
        return None

    rtl_name = str(rows[0].get("target_file", ""))
    anchor = rows[0]
    anchor_lines = list(anchor["mutant_lines"])
    used_spans: list[tuple[int, int]] = []
    if anchor.get("target_line") is not None:
        idx = max(0, int(anchor["target_line"]) - 1)
        used_spans.append((idx, idx + 1))

    extras = sorted(
        rows[1:],
        key=lambda p: (int(p["target_line"]) if p.get("target_line") is not None else -1),
        reverse=True,
    )
    for p in extras:
        diff_hunks = _build_line_hunks(base_lines=anchor_lines, mutant_lines=list(p["mutant_lines"]))
        selected_hunks = _select_hunks_for_mutation(
            hunks=diff_hunks,
            target_line=p.get("target_line"),
            mutation_log=str(p["mutant"].get("mutation_log", "")),
        )
        if not selected_hunks:
            return (anchor["mutant_id"], p["mutant_id"], rtl_name)
        spans = [(int(h["base_start"]), int(h["base_end"])) for h in selected_hunks]
        if any(any(_span_overlaps(sp, used) for used in used_spans) for sp in spans):
            return (anchor["mutant_id"], p["mutant_id"], rtl_name)
        used_spans.extend(spans)
    return None


def _selection_merge_overlap_conflict(payloads: list[dict]) -> tuple[str, str, str] | None:
    grouped: dict[str, list[dict]] = {}
    for p in payloads:
        grouped.setdefault(p["target_file"], []).append(p)
    for rows in grouped.values():
        conflict = _file_group_merge_overlap_conflict(rows)
        if conflict is not None:
            return conflict
    return None


def _validate_explicit_selection_no_overlap(
    selected: list[dict],
    source_mutants_root: Path,
    rtl_name_to_src: dict[str, str],
    merge_base_lines_by_name: dict[str, list[str]],
    mutation_summary_map: dict[str, dict],
) -> list[dict]:
    payloads = [
        _build_mutant_payload(
            mutant=m,
            source_mutants_root=source_mutants_root,
            rtl_name_to_src=rtl_name_to_src,
            merge_base_lines_by_name=merge_base_lines_by_name,
            mutation_summary_map=mutation_summary_map,
        )
        for m in selected
    ]
    for i in range(len(payloads)):
        for j in range(i + 1, len(payloads)):
            if _payloads_conflict(payloads[i], payloads[j]):
                raise ValueError(
                    "Explicit selected_mutant_ids overlap before insertion: "
                    f"{payloads[i]['mutant_id']} and {payloads[j]['mutant_id']} "
                    f"in {payloads[i]['target_file']}"
                )
    merge_conflict = _selection_merge_overlap_conflict(payloads)
    if merge_conflict is not None:
        a_id, b_id, rtl_name = merge_conflict
        raise ValueError(
            "Explicit selected_mutant_ids overlap before insertion in same file: "
            f"{a_id} and {b_id} in {rtl_name}"
        )
    return payloads


def _select_non_overlapping_mutants(
    candidates: list[dict],
    k_bugs: int,
    source_mutants_root: Path,
    rtl_name_to_src: dict[str, str],
    merge_base_lines_by_name: dict[str, list[str]],
    mutation_summary_map: dict[str, dict],
) -> list[dict]:
    payloads = [
        _build_mutant_payload(
            mutant=m,
            source_mutants_root=source_mutants_root,
            rtl_name_to_src=rtl_name_to_src,
            merge_base_lines_by_name=merge_base_lines_by_name,
            mutation_summary_map=mutation_summary_map,
        )
        for m in candidates
    ]

    uniq = []
    seen_keys = set()
    for p in payloads:
        key = (
            p["target_file"],
            str(p.get("target_digest", "")),
            int(p["target_line"]) if p.get("target_line") is not None else None,
        )
        if key in seen_keys:
            continue
        seen_keys.add(key)
        uniq.append(p)
    payloads = uniq

    if len(payloads) < k_bugs:
        raise ValueError(
            f"Requested {k_bugs} bugs but only {len(payloads)} unique prechecked mutants are available"
        )

    chosen: list[dict] = []

    def dfs(idx: int) -> bool:
        need = k_bugs - len(chosen)
        remain = len(payloads) - idx
        if need == 0:
            return True
        if remain < need:
            return False

        cand = payloads[idx]
        if not any(_payloads_conflict(cand, c) for c in chosen):
            probe = chosen + [cand]
            if _selection_merge_overlap_conflict(probe) is None:
                chosen.append(cand)
                if dfs(idx + 1):
                    return True
                chosen.pop()
        return dfs(idx + 1)

    if not dfs(0):
        max_possible = _max_non_overlapping_count(payloads)
        raise ValueError(
            f"Requested {k_bugs} bugs but only {max_possible} non-overlapping successful mutants are available"
        )
    return chosen


def _max_non_overlapping_count(payloads: list[dict]) -> int:
    best = 0
    chosen: list[dict] = []

    def dfs(idx: int):
        nonlocal best
        if len(chosen) + (len(payloads) - idx) <= best:
            return
        if idx >= len(payloads):
            best = max(best, len(chosen))
            return
        cand = payloads[idx]
        if not any(_payloads_conflict(cand, c) for c in chosen):
            probe = chosen + [cand]
            if _selection_merge_overlap_conflict(probe) is None:
                chosen.append(cand)
                dfs(idx + 1)
                chosen.pop()
        dfs(idx + 1)

    dfs(0)
    return best


def _rebuild_single_bug_mutants(
    selected: list[dict],
    rtl_files: list[str],
    source_dir: Path,
    out_dir: Path,
) -> None:
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    source_mutants_dir = source_dir / "mutants"
    if not source_mutants_dir.is_dir():
        raise FileNotFoundError(f"Missing source mutants directory: {source_mutants_dir}")

    rtl_names = [Path(p).name for p in rtl_files]
    for mutant in selected:
        mutant_id = str(mutant.get("mutant_id", "")).strip()
        if not mutant_id:
            raise ValueError("Found selected mutant without mutant_id")
        src = source_mutants_dir / mutant_id
        if not src.is_dir():
            raise FileNotFoundError(f"Missing source mutant folder: {src}")
        dst = out_dir / mutant_id
        shutil.copytree(src, dst, dirs_exist_ok=True)
        for name in rtl_names:
            expected = dst / name
            if not expected.is_file():
                raise FileNotFoundError(
                    f"Mutant {mutant_id} is missing required RTL file '{name}' in {dst}"
                )


def _find_subsequence_positions(lines: list[str], pattern: list[str]) -> list[int]:
    if not pattern:
        return list(range(len(lines) + 1))
    n = len(pattern)
    return [i for i in range(0, len(lines) - n + 1) if lines[i : i + n] == pattern]


def _apply_hunk_by_content(cur_lines: list[str], hunk: dict) -> tuple[list[str], int, int]:
    old_lines = list(hunk.get("old_lines", []))
    new_lines = list(hunk.get("new_lines", []))
    anchor = int(hunk.get("base_start", 0))
    if old_lines:
        hits = _find_subsequence_positions(cur_lines, old_lines)
        if not hits:
            raise ValueError(
                "Failed to apply mutation hunk by content: "
                f"base_range=[{int(hunk.get('base_start', 0))}, {int(hunk.get('base_end', 0))})"
            )
        start = min(hits, key=lambda x: abs(x - anchor))
        end = start + len(old_lines)
        return cur_lines[:start] + new_lines + cur_lines[end:], start, end
    start = max(0, min(anchor, len(cur_lines)))
    return cur_lines[:start] + new_lines + cur_lines[start:], start, start


def _build_merged_buggy_rtl(
    selected_payloads: list[dict],
    rtl_files: list[str],
    merge_base_lines_by_name: dict[str, list[str]],
    merged_rtl_dir: Path,
) -> dict:
    if merged_rtl_dir.exists():
        shutil.rmtree(merged_rtl_dir)
    merged_rtl_dir.mkdir(parents=True, exist_ok=True)

    rtl_name_to_src, _ = _prepare_base_rtl_maps(rtl_files)
    file_groups: dict[str, list[dict]] = {name: [] for name in rtl_name_to_src}
    for p in selected_payloads:
        file_groups[p["target_file"]].append(p)

    merged_lines_by_file = {name: list(merge_base_lines_by_name[name]) for name in rtl_name_to_src}
    operations = []
    inserted_mutations = []

    for rtl_name, rows in file_groups.items():
        if not rows:
            continue

        anchor = rows[0]
        anchor_lines = list(anchor["mutant_lines"])
        cur = list(anchor_lines)
        operations.append(
            {
                "mutant_id": anchor["mutant_id"],
                "target_rtl_file": rtl_name,
                "target_line": anchor.get("target_line"),
                "mutation_log": str(anchor["mutant"].get("mutation_log", "")).strip(),
                "applied_hunks": [
                    {"mode": "anchor_full_file", "new_line_count": len(anchor_lines)}
                ],
            }
        )
        inserted_mutations.append(
            {
                "mutant_id": anchor["mutant_id"],
                "mutation_log": str(anchor["mutant"].get("mutation_log", "")).strip(),
                "changed_rtl_files": [rtl_name],
                "target_line": anchor.get("target_line"),
            }
        )

        used_spans: list[tuple[int, int]] = []
        if anchor.get("target_line") is not None:
            idx = max(0, int(anchor["target_line"]) - 1)
            used_spans.append((idx, idx + 1))

        extras = sorted(
            rows[1:],
            key=lambda p: (int(p["target_line"]) if p.get("target_line") is not None else -1),
            reverse=True,
        )
        for p in extras:
            diff_hunks = _build_line_hunks(base_lines=anchor_lines, mutant_lines=list(p["mutant_lines"]))
            selected_hunks = _select_hunks_for_mutation(
                hunks=diff_hunks,
                target_line=p.get("target_line"),
                mutation_log=str(p["mutant"].get("mutation_log", "")),
            )
            if not selected_hunks:
                raise ValueError(f"Mutant {p['mutant_id']} has no relevant delta hunks for {rtl_name}")
            spans = [(int(h["base_start"]), int(h["base_end"])) for h in selected_hunks]
            for sp in spans:
                if any(_span_overlaps(sp, used) for used in used_spans):
                    raise ValueError(
                        "Selected mutants overlap before insertion in same file: "
                        f"{anchor['mutant_id']} + {p['mutant_id']} on {rtl_name}"
                    )

            applied_hunks = []
            for h in sorted(
                selected_hunks,
                key=lambda h: (int(h["base_start"]), int(h["base_end"])),
                reverse=True,
            ):
                cur, matched_start, matched_end = _apply_hunk_by_content(cur, h)
                applied_hunks.append(
                    {
                        "base_start": int(h["base_start"]),
                        "base_end": int(h["base_end"]),
                        "matched_start": int(matched_start),
                        "matched_end": int(matched_end),
                        "new_line_count": len(h["new_lines"]),
                    }
                )
            operations.append(
                {
                    "mutant_id": p["mutant_id"],
                    "target_rtl_file": rtl_name,
                    "target_line": p.get("target_line"),
                    "mutation_log": str(p["mutant"].get("mutation_log", "")).strip(),
                    "applied_hunks": applied_hunks,
                }
            )
            inserted_mutations.append(
                {
                    "mutant_id": p["mutant_id"],
                    "mutation_log": str(p["mutant"].get("mutation_log", "")).strip(),
                    "changed_rtl_files": [rtl_name],
                    "target_line": p.get("target_line"),
                }
            )
            used_spans.extend(spans)
        merged_lines_by_file[rtl_name] = cur

    for rtl_name in rtl_name_to_src:
        (merged_rtl_dir / rtl_name).write_text(
            "".join(merged_lines_by_file[rtl_name]), encoding="utf-8"
        )
    return {"operations": operations, "inserted_mutations": inserted_mutations}


def _extract_mutation_location(log: str) -> str:
    match = re.search(r"(\w+) @ line (\d+)", log)
    if match:
        return f"{match.group(1)}:L{match.group(2)}"
    match = re.search(r"^(\w+) ->", log)
    if match:
        return match.group(1)
    return "unknown"
