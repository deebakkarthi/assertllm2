import contextlib
import copy
import importlib.util
import json
import os
import re
import random
import shutil
import sys
from collections import defaultdict
from pathlib import Path

from assertbench.core.bug_hunting import bug_hunting_enabled, prepare_bug_hunting_eval_inputs
from assertbench.core.context import RunContext
from assertbench.core.io import read_json, write_json
from assertbench.core.rtl_metadata import extract_structural_metadata
from assertbench.schemas.contracts import stamp
from run_jasper import _generate_mutant_tcl, _parse_fpv_report, _resolve_bbox_modules, _run_jaspergold

MUTATION_CACHE_SCHEMA = "assertbench_mutations_v1"

_CLOCK_RESET_HINT_RE = re.compile(
    r"(^|_)(clk|clock|rst|reset|areset|nreset|rst_n|reset_n)($|_)",
    re.IGNORECASE,
)


def _looks_like_clock_or_reset(name: str) -> bool:
    return bool(_CLOCK_RESET_HINT_RE.search(name or ""))


_SYNTHESIS_TRANSLATE_RE = re.compile(
    r"^\s*//\s*(?:synthesis|synopsys)\s+translate_(off|on)\b.*$",
    re.IGNORECASE,
)


def _normalize_rtl_anchor(line: str) -> str:
    return re.sub(r"\s+", " ", line.strip())


def _first_nonblank_line(lines: list[str], start: int, stop: int | None = None) -> tuple[int, str] | None:
    end = len(lines) if stop is None else min(stop, len(lines))
    for idx in range(max(start, 0), end):
        text = lines[idx].strip()
        if text:
            return idx, text
    return None


def _find_generated_anchor(
    generated_lines: list[str], anchor: str, start: int = 0
) -> int | None:
    normalized_anchor = _normalize_rtl_anchor(anchor)
    if not normalized_anchor:
        return None

    identifier_match = re.search(r"\b[A-Za-z_][A-Za-z0-9_$]*\b", normalized_anchor)
    identifier = identifier_match.group(0) if identifier_match else ""

    for idx in range(max(start, 0), len(generated_lines)):
        normalized_line = _normalize_rtl_anchor(generated_lines[idx])
        if not normalized_line:
            continue
        if normalized_anchor in normalized_line or (
            len(normalized_line) >= 4 and normalized_line in normalized_anchor
        ):
            return idx
        if identifier and re.search(rf"\b{re.escape(identifier)}\b", normalized_line):
            return idx
    return None


def _restore_synthesis_translate_directives(original_text: str, generated_text: str) -> str:
    """
    PyVerilog codegen drops comments, including synthesis translate_off/on guards.
    Re-add those guards around the corresponding generated code so simulation-only
    vendor cells stay invisible to Jasper elaboration.
    """
    if "translate_off" not in original_text.lower():
        return generated_text

    original_lines = original_text.splitlines()
    generated_lines = [
        line for line in generated_text.splitlines() if not _SYNTHESIS_TRANSLATE_RE.match(line)
    ]
    if not original_lines or not generated_lines:
        return generated_text

    pairs: list[tuple[int, int]] = []
    pending_off: int | None = None
    for idx, line in enumerate(original_lines):
        match = _SYNTHESIS_TRANSLATE_RE.match(line)
        if not match:
            continue
        directive = match.group(1).lower()
        if directive == "off":
            pending_off = idx
        elif directive == "on" and pending_off is not None:
            pairs.append((pending_off, idx))
            pending_off = None

    insertions: list[tuple[int, str]] = []
    search_from = 0
    for off_idx, on_idx in pairs:
        start_anchor = _first_nonblank_line(original_lines, off_idx + 1, on_idx)
        if start_anchor is None:
            continue
        gen_start = _find_generated_anchor(generated_lines, start_anchor[1], search_from)
        if gen_start is None:
            continue

        end_anchor = _first_nonblank_line(original_lines, on_idx + 1)
        if end_anchor is not None:
            gen_end = _find_generated_anchor(generated_lines, end_anchor[1], gen_start + 1)
        else:
            gen_end = len(generated_lines)
        if gen_end is None:
            gen_end = len(generated_lines)

        insertions.append((gen_start, original_lines[off_idx].strip()))
        insertions.append((gen_end, original_lines[on_idx].strip()))
        search_from = max(gen_end, gen_start + 1)

    if not insertions:
        return generated_text

    for idx, text in sorted(insertions, key=lambda item: item[0], reverse=True):
        generated_lines.insert(idx, text)

    trailing_newline = "\n" if generated_text.endswith("\n") else ""
    return "\n".join(generated_lines) + trailing_newline


def _repair_mutant_translate_directives(mutant_dir: Path, original_rtl_files: list[str]) -> None:
    for rtl_file in original_rtl_files:
        original_path = Path(rtl_file).expanduser()
        mutant_path = mutant_dir / original_path.name
        if not original_path.is_file() or not mutant_path.is_file():
            continue
        try:
            original_text = original_path.read_text(encoding="utf-8")
            mutant_text = mutant_path.read_text(encoding="utf-8")
        except OSError:
            continue
        repaired = _restore_synthesis_translate_directives(original_text, mutant_text)
        if repaired != mutant_text:
            mutant_path.write_text(repaired, encoding="utf-8")


def _normalize_submodule_whitelist(value) -> list[str]:
    if isinstance(value, str):
        items = [x.strip() for x in value.split(",") if x.strip()]
    elif isinstance(value, (list, tuple, set)):
        items = [str(x).strip() for x in value if str(x).strip()]
    else:
        items = []

    seen = set()
    out = []
    for m in items:
        if m in seen:
            continue
        seen.add(m)
        out.append(m)
    return out


def _resolve_dataset_root(ctx: RunContext) -> Path | None:
    cfg = ctx.cfg
    for section in ("benchmark", "mutation"):
        dr = cfg.get(section, {}).get("dataset_root")
        if dr:
            p = Path(str(dr)).expanduser().resolve()
            if p.is_dir():
                return p
    spec_files = cfg.get("spec_file") or []
    if spec_files:
        p = Path(str(spec_files[0])).expanduser().resolve().parent
        if p.is_dir():
            return p
    return None


def _mutations_cache_paths(ctx: RunContext) -> tuple[Path | None, Path | None]:
    root = _resolve_dataset_root(ctx)
    if root is None:
        return None, None
    return root / "mutations", root


def _rewrite_path_prefix(obj: dict, old_root: Path, new_root: Path) -> dict:
    old_s = str(old_root.resolve())
    new_s = str(new_root.resolve())
    data = copy.deepcopy(obj)

    def fix(s: str) -> str:
        if isinstance(s, str) and s.startswith(old_s):
            return new_s + s[len(old_s) :]
        return s

    for m in data.get("mutants", []):
        for key in ("rtl_path", "target_rtl_file"):
            if key in m and isinstance(m[key], str):
                m[key] = fix(m[key])
        if "all_rtl_files" in m and isinstance(m["all_rtl_files"], list):
            m["all_rtl_files"] = [fix(x) if isinstance(x, str) else x for x in m["all_rtl_files"]]
    return data


def _hydrate_cached_mutants_index(raw: dict, ctx: RunContext, dst_mut: Path) -> dict:
    data = copy.deepcopy(raw)
    original_rtl_files = [str(p) for p in ctx.cfg.get("rtl", {}).get("filelist", [])]

    for mutant in data.get("mutants", []):
        mutant_id = mutant.get("mutant_id")
        if not mutant_id:
            continue
        mutant.setdefault("status", "success")

        mutant_dir = dst_mut / mutant_id
        if mutant_dir.is_dir():
            _repair_mutant_translate_directives(mutant_dir, original_rtl_files)

        if "all_rtl_files" not in mutant and mutant_dir.is_dir():
            all_rtl_files = []
            for rtl_file in original_rtl_files:
                candidate = mutant_dir / Path(rtl_file).name
                all_rtl_files.append(str(candidate if candidate.is_file() else Path(rtl_file)))
            mutant["all_rtl_files"] = all_rtl_files

    data["cache_schema"] = MUTATION_CACHE_SCHEMA
    return data


def _rel_path_under_root(path: Path, root: Path | None) -> str:
    rp = path.resolve()
    if root is None:
        return str(rp)
    try:
        return str(rp.relative_to(root.resolve()))
    except ValueError:
        return str(rp)


def _list_applied_source_files(
    mutant_dir: Path, rtl_files: list[str], dataset_root: Path | None
) -> list[str]:
    changed: list[str] = []
    for rtl in rtl_files:
        src = Path(rtl).expanduser()
        if not src.is_file():
            continue
        copy_p = mutant_dir / src.name
        if not copy_p.is_file():
            continue
        try:
            if copy_p.read_bytes() != src.read_bytes():
                changed.append(_rel_path_under_root(src, dataset_root))
        except OSError:
            continue
    return sorted(set(changed))


def _build_mutation_summary(
    mutants: list[dict],
    rtl_files: list[str],
    dataset_root: Path | None,
    outdir: Path,
) -> dict:
    entries = []
    for m in mutants:
        if m.get("status") != "success":
            continue
        mid = m.get("mutant_id", "")
        log = f"{mid}: {m.get('mutation_log', '')}".strip()
        mdir = outdir / "mutants" / mid
        applied = _list_applied_source_files(mdir, rtl_files, dataset_root)
        entries.append(
            {
                "mutant_id": mid,
                "log": log,
                "applied_to_source_files": applied,
            }
        )
    return {
        "cache_schema": MUTATION_CACHE_SCHEMA,
        "dataset_root": str(dataset_root.resolve()) if dataset_root else None,
        "mutants": entries,
    }


def _persist_mutation_cache(
    ctx: RunContext,
    mutations_dir: Path,
    dataset_root: Path | None,
    rtl_files: list[str],
) -> None:
    outdir = ctx.outdir
    index_path = outdir / "mutants_index.json"
    if not index_path.is_file():
        return
    try:
        data = read_json(index_path)
    except (json.JSONDecodeError, OSError):
        return
    mutants = data.get("mutants", [])
    if not mutants:
        return
    data["cache_schema"] = MUTATION_CACHE_SCHEMA
    write_json(index_path, data)

    mutations_dir.mkdir(parents=True, exist_ok=True)
    src_mut = outdir / "mutants"
    dst_mut = mutations_dir / "mutants"
    if src_mut.is_dir():
        shutil.copytree(src_mut, dst_mut, dirs_exist_ok=True)

    cached_index = _rewrite_path_prefix(data, outdir, mutations_dir)
    write_json(mutations_dir / "mutants_index.json", cached_index)

    cache_summary = _build_mutation_summary(mutants, rtl_files, dataset_root, mutations_dir)
    write_json(mutations_dir / "mutation_summary.json", cache_summary)

    targets = outdir / "spec_mutation_targets.json"
    if targets.is_file():
        shutil.copy2(targets, mutations_dir / "spec_mutation_targets.json")


def _try_load_mutation_cache(ctx: RunContext, mutations_dir: Path, budget: int) -> bool:
    """
    If cache has enough mutants, copy into ctx.outdir and return True.
    """
    index_path = mutations_dir / "mutants_index.json"
    summary_path = mutations_dir / "mutation_summary.json"
    cache_source = index_path if index_path.is_file() else summary_path
    if not cache_source.is_file():
        return False
    try:
        raw = read_json(cache_source)
    except (json.JSONDecodeError, OSError):
        return False
    mutants = raw.get("mutants", [])
    if budget <= 0 or len(mutants) < budget:
        return False

    src_mut = mutations_dir / "mutants"
    dst_mut = ctx.outdir / "mutants"
    if not src_mut.is_dir():
        return False

    ctx.outdir.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src_mut, dst_mut, dirs_exist_ok=True)

    hydrated = _rewrite_path_prefix(raw, mutations_dir, ctx.outdir)
    hydrated = _hydrate_cached_mutants_index(hydrated, ctx, dst_mut)
    write_json(ctx.outdir / "mutants_index.json", hydrated)

    targets = mutations_dir / "spec_mutation_targets.json"
    if targets.is_file():
        shutil.copy2(targets, ctx.outdir / "spec_mutation_targets.json")

    print(
        f"[*] Mutation cache hit: loaded {len(mutants)} mutant(s) from {mutations_dir} "
        f"via {cache_source.name} "
        f"(skipped generation; budget={budget}).",
        flush=True,
    )
    return True


def _load_mutation_modules():
    mutation_dir = Path(__file__).resolve().parents[2].parent / "mutation"
    if not mutation_dir.is_dir():
        raise ModuleNotFoundError(f"Mutation directory not found: {mutation_dir}")
    if str(mutation_dir) not in sys.path:
        sys.path.insert(0, str(mutation_dir))

    operators_path = mutation_dir / "Operators.py"
    if not operators_path.is_file():
        raise ModuleNotFoundError(f"Mutation operators file not found: {operators_path}")
    if "MutationOperators" not in sys.modules:
        spec = importlib.util.spec_from_file_location("MutationOperators", operators_path)
        if spec is None or spec.loader is None:
            raise ImportError(f"Failed to load mutation operators from {operators_path}")
        operators_module = importlib.util.module_from_spec(spec)
        sys.modules["MutationOperators"] = operators_module
        spec.loader.exec_module(operators_module)
    else:
        operators_module = sys.modules["MutationOperators"]

    main_path = mutation_dir / "main.py"
    if not main_path.is_file():
        raise ModuleNotFoundError(f"Mutation main file not found: {main_path}")
    module_name = "_assertllm_mutation_main"
    if module_name not in sys.modules:
        spec = importlib.util.spec_from_file_location(module_name, main_path)
        if spec is None or spec.loader is None:
            raise ImportError(f"Failed to load mutation main from {main_path}")
        main_module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = main_module
        spec.loader.exec_module(main_module)
    else:
        main_module = sys.modules[module_name]

    return main_module, operators_module


def _ensure_assertions_meta(ctx: RunContext) -> None:
    meta_path = ctx.outdir / "assertions_meta.json"
    if meta_path.exists():
        return

    top_module = ctx.cfg.get("rtl", {}).get("top_module", "top")
    structural = extract_structural_metadata(
        ctx.cfg["rtl"]["filelist"], top_module
    )
    top_signals = [s for s in structural.get("signals", []) if s.get("module") == top_module]
    signal_dict = {s["name"]: s.get("signal_id", f"{top_module}.{s['name']}") for s in top_signals}

    assertions_file = ctx.outdir / "assertions.sv"
    if not assertions_file.exists():
        raise FileNotFoundError(f"Missing assertions.sv at {assertions_file}")

    assertions = []
    current_signal = None
    idx = 0
    lines = assertions_file.read_text(encoding="utf-8", errors="ignore").splitlines()

    in_assertion = False
    current_block = []

    for line in lines:
        m = re.match(r"\s*//\s*Assertions for Signal:\s*(\S+)", line)
        if m:
            current_signal = m.group(1)
            continue

        lc = line.strip()
        if not in_assertion:
            if re.search(r"\b(assert|assume|cover)\b", lc) and not lc.startswith("//"):
                in_assertion = True
                current_block = [line]
                if ";" in lc:
                    in_assertion = False
        else:
            current_block.append(line)
            if ";" in lc:
                in_assertion = False

        if not in_assertion and current_block:
            idx += 1
            sig = current_signal or f"assert_{idx}"
            sig_leaf = sig.split(".")[-1]
            sig_id = signal_dict.get(sig_leaf, f"{top_module}.{sig_leaf}")
            assertions.append(
                {
                    "signal_name": sig,
                    "signal_id": sig_id,
                    "code": "\n".join(current_block),
                }
            )
            current_block = []

    write_json(
        meta_path,
        {
            "assertions": assertions,
            "total_signals": len(assertions),
            "assertions_generated": len(assertions),
            "generation_method": "plugin_submission",
        },
    )


def _extract_mutation_location(log: str) -> str:
    match = re.search(r"(\w+) @ line (\d+)", log)
    if match:
        return f"{match.group(1)}:L{match.group(2)}"
    match = re.search(r"^(\w+) ->", log)
    if match:
        return match.group(1)
    return "unknown"


def _extract_mutation_line(log: str) -> int | None:
    match = re.search(r"@ line (\d+)", log)
    if not match:
        return None
    try:
        return int(match.group(1))
    except Exception:
        return None


def _load_spec_targets(ctx: RunContext, structural: dict) -> dict:
    targets_path = ctx.outdir / "spec_mutation_targets.json"
    if targets_path.exists():
        return read_json(targets_path)

    spec_parts = []
    for p in ctx.cfg.get("spec_file", []):
        path = Path(p)
        if path.exists():
            spec_parts.append(path.read_text(encoding="utf-8", errors="ignore"))
    spec_text = "\n\n---\n\n".join(spec_parts)

    from assertbench.core.rtl_wrapper_schema import extract_rtl_module_signal_targets
    from assertbench.core.spec_targets import extract_spec_module_signal_targets

    mut_cfg = ctx.cfg.get("mutation", {})
    include_top_with_submodules = bool(mut_cfg.get("include_top_with_submodules", True))
    no_submodule_fallback = str(mut_cfg.get("no_submodule_fallback", "top_only"))
    target_source = str(mut_cfg.get("target_source", "rtl_hierarchy"))
    top_module = ctx.cfg.get("rtl", {}).get("top_module", "top")
    rtl_files = ctx.cfg.get("rtl", {}).get("filelist", [])

    if target_source == "spec_submodule_signals":
        targets = extract_spec_module_signal_targets(
            spec_text=spec_text,
            structural=structural,
            top_module=top_module,
            include_top_with_submodules=include_top_with_submodules,
            no_submodule_fallback=no_submodule_fallback,
        )
    else:
        targets = extract_rtl_module_signal_targets(
            structural=structural,
            rtl_files=rtl_files,
            top_module=top_module,
        )
    targets["config"] = {
        "include_top_with_submodules": include_top_with_submodules,
        "no_submodule_fallback": no_submodule_fallback,
        "target_source": target_source,
    }
    write_json(targets_path, targets)
    return targets


def _build_module_to_file_map(structural: dict, rtl_files: list[str]) -> dict[str, str]:
    by_file = defaultdict(set)
    for m in structural.get("modules", []):
        mod = m.get("module")
        file = m.get("file")
        if mod and file:
            by_file[file].add(mod)

    module_to_file = {}
    for rtl in rtl_files:
        for mod in sorted(by_file.get(rtl, [])):
            module_to_file.setdefault(mod, rtl)

    for m in structural.get("modules", []):
        mod = m.get("module")
        file = m.get("file")
        if mod and file:
            module_to_file.setdefault(mod, file)

    return module_to_file


def _allocate_budget_by_weight(weights: dict[str, int], budget: int) -> dict[str, int]:
    modules = [m for m, w in weights.items() if w > 0]
    if budget <= 0 or not modules:
        return {m: 0 for m in weights}

    alloc = {m: 0 for m in modules}

    if budget >= len(modules):
        for m in modules:
            alloc[m] = 1
        remaining = budget - len(modules)
    else:
        remaining = budget

    if remaining > 0:
        total_weight = sum(weights[m] for m in modules)
        if total_weight <= 0:
            for idx in range(remaining):
                alloc[modules[idx % len(modules)]] += 1
        else:
            fractional = []
            for m in modules:
                share = remaining * (weights[m] / total_weight)
                base = int(share)
                alloc[m] += base
                fractional.append((share - base, m))

            leftover = remaining - sum(
                int(remaining * (weights[m] / total_weight)) for m in modules
            )
            for _, m in sorted(fractional, reverse=True)[:leftover]:
                alloc[m] += 1

    out = {m: 0 for m in weights}
    out.update(alloc)
    return out


def _select_plain_prompt_targets(ctx: RunContext, structural: dict) -> dict:
    top_module = ctx.cfg.get("rtl", {}).get("top_module", "top")
    mut_cfg = ctx.cfg.get("mutation", {})
    scope_policy = str(mut_cfg.get("scope_policy", "top_and_direct_submodules"))

    target_source = str(mut_cfg.get("target_source", "rtl_hierarchy"))
    if target_source == "assertions":
        return {"mode": "legacy_assertions", "target_source": target_source}

    spec_targets = _load_spec_targets(ctx, structural)
    module_to_file = _build_module_to_file_map(
        structural, ctx.cfg.get("rtl", {}).get("filelist", [])
    )
    top_rtl_file = module_to_file.get(top_module, "")

    wrapper_schema_path = ctx.outdir / "wrapper_schema.json"
    wrapper_schema_present = wrapper_schema_path.exists()

    if not wrapper_schema_present:
        print(
            "[!] wrapper_schema.json not found; falling back to "
            "spec_mutation_targets pool (legacy behavior).",
            flush=True,
        )
        return _select_plain_prompt_targets_legacy(
            ctx, structural, spec_targets, module_to_file, top_rtl_file,
        )

    wrapper_schema = read_json(wrapper_schema_path)
    entries = wrapper_schema.get("entries", [])

    _NON_MUTATABLE_REASONS = {"clock_signal", "reset_signal"}

    max_connectivity_per_module = int(mut_cfg.get("max_connectivity_per_module", 3))
    whitelist_requested = _normalize_submodule_whitelist(
        mut_cfg.get("submodule_whitelist", [])
    )
    structural_modules = {
        sig.get("module")
        for sig in structural.get("signals", [])
        if sig.get("module")
    }
    whitelist_candidates = [
        m for m in whitelist_requested if m != top_module and m in structural_modules
    ]
    whitelist_unmatched = sorted(
        m for m in whitelist_requested if m not in structural_modules
    )

    selected = []
    selected_keys: set[tuple] = set()
    dropped = []
    skipped_closure_only_top = []
    skipped_clock_reset = []
    seen_pairs: set[tuple[str, str]] = set()
    wrapper_modules: set[str] = set()
    wrapper_direct_modules: set[str] = set()
    connectivity_count_by_module: dict[str, int] = defaultdict(int)

    for entry in entries:
        module = entry.get("module_type")
        signal = entry.get("rtl_signal")
        if not module or not signal:
            continue

        if entry.get("is_helper") or entry.get("mutation_eligible") is False:
            dropped.append(
                {
                    "module": module,
                    "signal": signal,
                    "reason": "wrapper_entry_not_mutation_eligible",
                }
            )
            continue

        depth = len(entry.get("instance_path", []) or [])
        wrapper_modules.add(module)
        if depth == 1:
            wrapper_direct_modules.add(module)

        pair = (module, signal)
        if pair in seen_pairs:
            continue
        seen_pairs.add(pair)

        source_reasons = set(entry.get("source_reasons", []))
        source_kind = entry.get("source_kind", "")

        if source_reasons and source_reasons <= _NON_MUTATABLE_REASONS:
            skipped_clock_reset.append(
                {"module": module, "signal": signal, "reasons": sorted(source_reasons)}
            )
            continue

        rtl_file = module_to_file.get(module)
        if not rtl_file:
            dropped.append({"module": module, "signal": signal, "reason": "module_not_mapped_to_rtl_file"})
            continue

        if source_kind == "top":
            is_explicit_top_target = (
                "spec_target" in source_reasons
                or "golden_semantic_target" in source_reasons
            )
            if not is_explicit_top_target:
                skipped_closure_only_top.append(
                    {"module": module, "signal": signal, "reasons": sorted(source_reasons)}
                )
                continue

            logic_key = (module, signal, "logic", rtl_file)
            if logic_key not in selected_keys:
                selected.append(
                    {
                        "module": module,
                        "signal": signal,
                        "signal_id": f"{module}.{signal}",
                        "rtl_file": rtl_file,
                        "source": "wrapper_schema_top_explicit_target",
                        "target_kind": "logic",
                        "scope_depths": [0],
                    }
                )
                selected_keys.add(logic_key)

        else:
            logic_key = (module, signal, "logic", rtl_file)
            if logic_key not in selected_keys:
                selected.append(
                    {
                        "module": module,
                        "signal": signal,
                        "signal_id": f"{module}.{signal}",
                        "rtl_file": rtl_file,
                        "source": "wrapper_schema_submodule",
                        "target_kind": "logic",
                        "scope_depths": [depth],
                    }
                )
                selected_keys.add(logic_key)

            if top_rtl_file and connectivity_count_by_module[module] < max_connectivity_per_module:
                conn_key = (module, signal, "connectivity", top_rtl_file)
                if conn_key not in selected_keys:
                    selected.append(
                        {
                            "module": module,
                            "signal": signal,
                            "signal_id": f"{module}.{signal}",
                            "rtl_file": top_rtl_file,
                            "source": "wrapper_schema_connectivity",
                            "target_kind": "connectivity",
                            "scope_depths": [1],
                        }
                    )
                    selected_keys.add(conn_key)
                    connectivity_count_by_module[module] += 1

    whitelist_applied: list[str] = []
    for module in whitelist_candidates:
        rtl_file = module_to_file.get(module)
        if not rtl_file:
            dropped.append(
                {
                    "module": module,
                    "reason": "whitelist_module_not_mapped_to_rtl_file",
                }
            )
            continue

        port_signals = sorted(
            {
                sig.get("name")
                for sig in structural.get("signals", [])
                if sig.get("module") == module
                and str(sig.get("direction", "")).lower() in {"input", "output", "inout"}
                and sig.get("name")
            }
        )
        if not port_signals:
            dropped.append(
                {
                    "module": module,
                    "reason": "whitelist_module_has_no_port_targets",
                }
            )
            continue

        added_any = False
        for signal in port_signals:
            if _looks_like_clock_or_reset(signal):
                continue
            logic_key = (module, signal, "logic", rtl_file)
            if logic_key in selected_keys:
                continue
            selected.append(
                {
                    "module": module,
                    "signal": signal,
                    "signal_id": f"{module}.{signal}",
                    "rtl_file": rtl_file,
                    "source": "explicit_submodule_whitelist",
                    "target_kind": "logic",
                    "scope_depths": [1],
                }
            )
            selected_keys.add(logic_key)
            added_any = True

        if added_any:
            whitelist_applied.append(module)
            wrapper_modules.add(module)

    whitelist_applied_set = set(whitelist_applied)
    selected_submodules = sorted(m for m in wrapper_modules if m != top_module)
    if scope_policy == "top_and_direct_submodules":
        selected_submodules = [
            m
            for m in selected_submodules
            if m in wrapper_direct_modules or m in whitelist_applied_set
        ]

    return {
        "mode": target_source,
        "target_source": target_source,
        "scope_policy": scope_policy,
        "pool_source": "wrapper_schema",
        "has_explicit_submodules": bool(selected_submodules),
        "selected_submodules": selected_submodules,
        "include_top_with_submodules": bool(
            mut_cfg.get("include_top_with_submodules", True)
        ),
        "fallback_applied": spec_targets.get("fallback_applied", "none"),
        "has_submodules": bool(selected_submodules),
        "targets": selected,
        "dropped": dropped,
        "skipped_closure_only_top": skipped_closure_only_top,
        "skipped_clock_reset": skipped_clock_reset,
        "spec_targets": spec_targets,
        "wrapper_schema": {
            "present": True,
            "entries": len(entries),
            "modules": sorted(wrapper_modules),
            "direct_modules": sorted(wrapper_direct_modules),
        },
        "submodule_whitelist": {
            "requested_modules": whitelist_requested,
            "applied_modules": sorted(whitelist_applied_set),
            "unmatched_modules": whitelist_unmatched,
        },
    }


def _select_plain_prompt_targets_legacy(
    ctx: RunContext,
    structural: dict,
    spec_targets: dict,
    module_to_file: dict,
    top_rtl_file: str,
) -> dict:
    """Fallback when wrapper_schema.json is absent -- preserves original behavior."""
    top_module = ctx.cfg.get("rtl", {}).get("top_module", "top")
    mut_cfg = ctx.cfg.get("mutation", {})
    scope_policy = str(mut_cfg.get("scope_policy", "top_and_direct_submodules"))

    module_to_signals = defaultdict(set)
    for s in structural.get("signals", []):
        mod = s.get("module")
        name = s.get("name")
        if mod and name:
            module_to_signals[mod].add(name)

    whitelist_requested = _normalize_submodule_whitelist(
        mut_cfg.get("submodule_whitelist", [])
    )
    structural_modules = {
        sig.get("module")
        for sig in structural.get("signals", [])
        if sig.get("module")
    }
    whitelist_candidates = [
        m for m in whitelist_requested if m != top_module and m in structural_modules
    ]
    whitelist_unmatched = sorted(
        m for m in whitelist_requested if m not in structural_modules
    )

    selected = []
    selected_keys: set[tuple] = set()
    dropped = []

    for item in spec_targets.get("module_targets", []):
        module = item.get("module")
        if not module:
            continue

        rtl_file = module_to_file.get(module)
        if not rtl_file:
            dropped.append({"module": module, "reason": "module_not_mapped_to_rtl_file"})
            continue

        valid_names = module_to_signals.get(module, set())
        for sig in sorted(set(item.get("signals", []))):
            if sig not in valid_names:
                dropped.append(
                    {
                        "module": module,
                        "signal": sig,
                        "reason": "signal_not_found_in_module",
                    }
                )
                continue

            if scope_policy == "top_and_direct_submodules":
                allowed_depths = {0 if module == top_module else 1}
            else:
                allowed_depths = {0 if module == top_module else 1}

            logic_key = (module, sig, "logic", rtl_file)
            if logic_key not in selected_keys:
                selected.append(
                    {
                        "module": module,
                        "signal": sig,
                        "signal_id": f"{module}.{sig}",
                        "rtl_file": rtl_file,
                        "source": item.get("source", "spec"),
                        "target_kind": "logic",
                        "scope_depths": sorted(allowed_depths),
                    }
                )
                selected_keys.add(logic_key)

            if module != top_module and 1 in allowed_depths and top_rtl_file:
                conn_key = (module, sig, "connectivity", top_rtl_file)
                if conn_key not in selected_keys:
                    selected.append(
                        {
                            "module": module,
                            "signal": sig,
                            "signal_id": f"{module}.{sig}",
                            "rtl_file": top_rtl_file,
                            "source": "top_direct_instance_connectivity",
                            "target_kind": "connectivity",
                            "scope_depths": [1],
                        }
                    )
                    selected_keys.add(conn_key)

    whitelist_applied: list[str] = []
    for module in whitelist_candidates:
        rtl_file = module_to_file.get(module)
        if not rtl_file:
            dropped.append(
                {
                    "module": module,
                    "reason": "whitelist_module_not_mapped_to_rtl_file",
                }
            )
            continue

        port_signals = sorted(
            {
                sig.get("name")
                for sig in structural.get("signals", [])
                if sig.get("module") == module
                and str(sig.get("direction", "")).lower() in {"input", "output", "inout"}
                and sig.get("name")
            }
        )
        if not port_signals:
            dropped.append(
                {
                    "module": module,
                    "reason": "whitelist_module_has_no_port_targets",
                }
            )
            continue

        added_any = False
        for sig in port_signals:
            if _looks_like_clock_or_reset(sig):
                continue
            logic_key = (module, sig, "logic", rtl_file)
            if logic_key in selected_keys:
                continue
            selected.append(
                {
                    "module": module,
                    "signal": sig,
                    "signal_id": f"{module}.{sig}",
                    "rtl_file": rtl_file,
                    "source": "explicit_submodule_whitelist",
                    "target_kind": "logic",
                    "scope_depths": [1],
                }
            )
            selected_keys.add(logic_key)
            added_any = True

        if added_any:
            whitelist_applied.append(module)

    whitelist_applied_set = set(whitelist_applied)
    selected_submodules = sorted(
        set(m for m in spec_targets.get("selected_submodules", []) if m != top_module)
        | whitelist_applied_set
    )

    return {
        "mode": str(mut_cfg.get("target_source", "rtl_hierarchy")),
        "target_source": str(mut_cfg.get("target_source", "rtl_hierarchy")),
        "scope_policy": scope_policy,
        "pool_source": "spec_mutation_targets_legacy",
        "has_explicit_submodules": spec_targets.get("has_explicit_submodules", False),
        "selected_submodules": selected_submodules,
        "include_top_with_submodules": bool(
            mut_cfg.get("include_top_with_submodules", True)
        ),
        "fallback_applied": spec_targets.get("fallback_applied", "none"),
        "has_submodules": bool(selected_submodules),
        "targets": selected,
        "dropped": dropped,
        "skipped_closure_only_top": [],
        "skipped_clock_reset": [],
        "spec_targets": spec_targets,
        "wrapper_schema": {
            "present": False,
            "entries": 0,
            "modules": [],
            "direct_modules": [],
        },
        "submodule_whitelist": {
            "requested_modules": whitelist_requested,
            "applied_modules": sorted(whitelist_applied_set),
            "unmatched_modules": whitelist_unmatched,
        },
    }


def _generate_plain_prompt_mutants(ctx: RunContext) -> dict:
    mut_cfg = ctx.cfg.get("mutation", {})
    mut_cfg_ts = str(mut_cfg.get("target_source", "rtl_hierarchy"))

    random.seed(int(ctx.cfg.get("seed", 42)))

    try:
        mutation_main, mutation_ops = _load_mutation_modules()
        apply_mutations = mutation_main.apply_mutations
        collect_node_ids_by_type_in_module = mutation_main.collect_node_ids_by_type_in_module
        resolve_requested_operators = mutation_main.resolve_requested_operators
        sanitize_mutated_rtl_text = mutation_main.sanitize_mutated_rtl_text
        select_applicable_ops = mutation_main.select_applicable_ops
        from pyverilog.ast_code_generator.codegen import ASTCodeGenerator
        from pyverilog.vparser.parser import parse as parse_rtl
    except Exception as exc:
        return {"mutants": 0, "failed": 0, "error": f"mutation_import_failed: {exc}"}

    top_module = ctx.cfg.get("rtl", {}).get("top_module", "top")
    structural = extract_structural_metadata(
        ctx.cfg["rtl"]["filelist"], top_module
    )

    selection = _select_plain_prompt_targets(ctx, structural)

    if selection.get("mode") == "legacy_assertions":
        return {
            "mutants": 0,
            "failed": 0,
            "error": "mutation.target_source='assertions' requires the removed assertion-target flow",
        }

    base_target_entries = selection.get("targets", [])
    n_candidates = len(base_target_entries)
    resolved_mode = selection.get("mode") or selection.get("target_source") or mut_cfg_ts
    print(
        f"[*] Mutation target selection: {n_candidates} candidate(s), "
        f"resolved_mode={resolved_mode!r}, "
        f"mutation.target_source={mut_cfg_ts!r}",
        flush=True,
    )

    if not base_target_entries:
        write_json(
            ctx.outdir / "mutants_index.json",
            {
                "target_source": mut_cfg_ts,
                "target_signals": [],
                "operators_used": [],
                "budget": int(mut_cfg.get("budget", 0)),
                "successful_mutations": 0,
                "failed_mutations": 0,
                "mutants": [],
                "mutation_logs": [],
                "selection": selection,
                "generation_phases": [],
                "unique_space_exhausted": False,
                "budget_gap_reason": "no_target_entries",
                "exhausted_targets_count": 0,
            },
        )
        return {"mutants": 0, "failed": 0, "signals_covered": 0, "total_attempted": 0}

    budget = int(mut_cfg.get("budget", 0))
    operators = resolve_requested_operators(mut_cfg.get("operators", ["all"]))
    enable_structural_fallback = bool(mut_cfg.get("enable_structural_fallback", False))
    signal_pool_policy = str(mut_cfg.get("signal_pool_policy", "ports_then_internal")).strip().lower()
    if signal_pool_policy not in {"ports_only", "ports_then_internal"}:
        signal_pool_policy = "ports_then_internal"

    incdir = ctx.cfg.get("rtl", {}).get("incdir", [])
    rtl_files = ctx.cfg.get("rtl", {}).get("filelist", [])
    module_to_file = _build_module_to_file_map(structural, rtl_files)

    mutation_dir = ctx.outdir / "mutants"
    mutation_dir.mkdir(exist_ok=True)

    codegen = ASTCodeGenerator()
    parse_cache: dict[str, object | None] = {}
    baseline_mixed_cache: dict[str, set[str]] = {}

    phase_reports: list[dict] = []

    mutants = []
    mutation_logs = []
    used_fingerprints = set()
    used_code_fingerprints = {}  # (op, before, after, file) -> True
    used_op_line_keys: set[tuple[str, str, int]] = set()
    op_usage_counts: dict[str, int] = defaultdict(int)
    successful_mutations = 0
    failed_mutations = 0
    rejected_mixed_assignments = 0
    rejected_parse_after_sanitize = 0
    rejected_code_duplicate = 0
    rejected_fingerprint_duplicate = 0
    rejected_same_line_same_op = 0
    rejected_no_mutation_log = 0
    covered_signals = set()
    total_attempts = 0
    mutant_idx = 0

    max_target_no_progress = int(mut_cfg.get("max_target_no_progress", 60))
    target_no_progress_counts: dict[tuple, int] = defaultdict(int)
    exhausted_target_keys: set[tuple] = set()
    exhausted_target_meta: dict[tuple, dict] = {}

    clock_reset_hint_re = re.compile(
        r"(^|_)(clk|clock|rst|reset|areset|nreset|rst_n|reset_n)($|_)",
        re.IGNORECASE,
    )

    def _is_clock_or_reset_name(name: str) -> bool:
        return bool(clock_reset_hint_re.search(name or ""))

    def _target_key(target: dict) -> tuple:
        return (
            target.get("module"),
            target.get("signal"),
            target.get("target_kind", "logic"),
            str(target.get("rtl_file", "")),
        )

    def _target_module_scope(target: dict) -> str | None:
        module_scope = target.get("module")
        if module_scope == "__untargeted__":
            return None
        return module_scope

    def _bump_target_no_progress(target: dict, reason: str) -> None:
        key = _target_key(target)
        target_no_progress_counts[key] += 1
        if target_no_progress_counts[key] >= max_target_no_progress and key not in exhausted_target_keys:
            exhausted_target_keys.add(key)
            exhausted_target_meta[key] = {
                "module": target.get("module"),
                "signal": target.get("signal"),
                "target_kind": target.get("target_kind", "logic"),
                "rtl_file": str(target.get("rtl_file", "")),
                "fail_count": target_no_progress_counts[key],
                "reason": reason,
            }

    def _reset_target_progress(target: dict) -> None:
        key = _target_key(target)
        target_no_progress_counts[key] = 0

    def _ensure_parse_cache(rtl_file: str):
        if rtl_file not in parse_cache:
            try:
                ast_probe, _ = parse_rtl([str(rtl_file)], preprocess_include=incdir)
                parse_cache[rtl_file] = ast_probe
            except Exception:
                parse_cache[rtl_file] = None
        return parse_cache.get(rtl_file)

    def _baseline_mixed_signals_for_file(rtl_file: str) -> set[str]:
        if rtl_file in baseline_mixed_cache:
            return baseline_mixed_cache[rtl_file]

        ast_base = _ensure_parse_cache(rtl_file)
        if ast_base is None:
            baseline_mixed_cache[rtl_file] = set()
            return baseline_mixed_cache[rtl_file]

        try:
            base_code_raw = codegen.visit(ast_base)
            _, base_sanitize_meta = sanitize_mutated_rtl_text(base_code_raw)
            baseline_mixed = set(base_sanitize_meta.get("mixed_assignment_signals") or [])
        except Exception:
            baseline_mixed = set()

        baseline_mixed_cache[rtl_file] = baseline_mixed
        return baseline_mixed

    def _probe_operator_executable(ast_probe, entry: dict, op: str) -> bool:
        for _ in range(2):
            try:
                ast_try = copy.deepcopy(ast_probe)
                mutation_try = mutation_ops.MutationOperators(None, None, None)
                mutation_try._root = ast_try
                logs_try = apply_mutations(
                    ast_try,
                    mutation_try,
                    [op],
                    10,
                    entry.get("signal"),
                    _target_module_scope(entry),
                )
                if not logs_try:
                    continue
                mutated_code_raw_try = codegen.visit(ast_try)
                _, sanitize_meta_try = sanitize_mutated_rtl_text(mutated_code_raw_try)
                mixed_now = set(sanitize_meta_try.get("mixed_assignment_signals") or [])
                baseline_mixed = _baseline_mixed_signals_for_file(str(entry.get("rtl_file", "")))
                if mixed_now - baseline_mixed:
                    continue
                return True
            except Exception:
                continue
        return False

    def _prepare_live_entries(entries: list[dict], phase_name: str) -> list[dict]:
        precheck_stats = {
            "parse_failed": 0,
            "no_applicable": 0,
            "no_executable": 0,
        }
        live_entries: list[dict] = []

        for entry in entries:
            rtl_file = str(entry.get("rtl_file", ""))
            ast_probe = _ensure_parse_cache(rtl_file)
            if ast_probe is None:
                precheck_stats["parse_failed"] += 1
                continue

            target_kind = entry.get("target_kind", "logic")
            type2ids = collect_node_ids_by_type_in_module(
                ast_probe,
                _target_module_scope(entry),
                entry.get("signal"),
            )

            if target_kind == "connectivity":
                requested_ops = [op for op in operators if op == "CSW"]
                applicable, op_profile = select_applicable_ops(
                    type2ids,
                    requested_ops,
                    enable_structural_fallback=False,
                )
            else:
                applicable, op_profile = select_applicable_ops(
                    type2ids,
                    operators,
                    enable_structural_fallback=enable_structural_fallback,
                )

            if not applicable:
                precheck_stats["no_applicable"] += 1
                continue

            executable_ops = [
                op for op in applicable if _probe_operator_executable(ast_probe, entry, op)
            ]
            if not executable_ops:
                precheck_stats["no_executable"] += 1
                continue

            e = dict(entry)
            e["applicable_ops"] = executable_ops
            e["op_profile"] = op_profile
            live_entries.append(e)

        phase_reports.append(
            {
                "phase": phase_name,
                "candidate_count": len(entries),
                "live_count": len(live_entries),
                "precheck": precheck_stats,
                "run": {
                    "attempts": 0,
                    "successes": 0,
                    "failures": 0,
                    "stop_reason": "not_started",
                    "active_targets": len(live_entries),
                },
            }
        )
        return live_entries

    def _get_phase_report(phase_name: str) -> dict:
        for report in phase_reports:
            if report.get("phase") == phase_name:
                return report
        rec = {
            "phase": phase_name,
            "candidate_count": 0,
            "live_count": 0,
            "precheck": {"parse_failed": 0, "no_applicable": 0, "no_executable": 0},
            "run": {
                "attempts": 0,
                "successes": 0,
                "failures": 0,
                "stop_reason": "not_started",
                "active_targets": 0,
            },
        }
        phase_reports.append(rec)
        return rec

    def _sort_targets_for_op_diversity(targets_list: list[dict]) -> list[dict]:
        if not op_usage_counts:
            return targets_list
        min_usage = min(op_usage_counts.values()) if op_usage_counts else 0

        def score(t: dict) -> int:
            ops = t.get("applicable_ops", [])
            return min(op_usage_counts.get(o, 0) for o in ops) if ops else min_usage

        return sorted(targets_list, key=score)

    def _try_generate_mutant(target: dict, mutant_idx_val: int):
        nonlocal failed_mutations, rejected_mixed_assignments
        nonlocal rejected_parse_after_sanitize, rejected_code_duplicate
        nonlocal rejected_fingerprint_duplicate, rejected_same_line_same_op, rejected_no_mutation_log
        nonlocal successful_mutations

        key = _target_key(target)
        if key in exhausted_target_keys:
            return None, "target_exhausted"

        mutant_id = f"M_{mutant_idx_val:04d}"
        mutant_dir_i = mutation_dir / mutant_id
        mutant_dir_i.mkdir(exist_ok=True)

        for rtl in rtl_files:
            shutil.copy(rtl, mutant_dir_i / Path(rtl).name)

        target_file_original = Path(target["rtl_file"])
        mutant_target_rtl = mutant_dir_i / target_file_original.name

        try:
            original_target_text = mutant_target_rtl.read_text(encoding="utf-8")
            ast, _ = parse_rtl([str(mutant_target_rtl)], preprocess_include=incdir)
            mutation = mutation_ops.MutationOperators(None, None, None)
            mutation._root = ast

            logs = apply_mutations(
                ast,
                mutation,
                target.get("applicable_ops", operators),
                50,
                target.get("signal"),
                _target_module_scope(target),
            )

            if not logs:
                rejected_no_mutation_log += 1
                failed_mutations += 1
                _bump_target_no_progress(target, "no_mutation_log")
                shutil.rmtree(mutant_dir_i, ignore_errors=True)
                return None, "no_mutation_log"

            mutation_log = logs[0]
            match_op = re.search(r"applied\.\s+(\w+)", mutation_log)
            applied_op = match_op.group(1) if match_op else "?"
            location = _extract_mutation_location(mutation_log)
            location_line = _extract_mutation_line(mutation_log)
            line_op_key = None
            if location_line is not None:
                line_op_key = (applied_op, str(target_file_original), int(location_line))
                if line_op_key in used_op_line_keys:
                    rejected_same_line_same_op += 1
                    failed_mutations += 1
                    _bump_target_no_progress(target, "same_line_same_op")
                    shutil.rmtree(mutant_dir_i, ignore_errors=True)
                    return None, "same_line_same_op"

            before_text = mutation_log.split("==>")[0].strip() if "==>" in mutation_log else mutation_log
            after_text = mutation_log.split("==>")[1].strip() if "==>" in mutation_log else ""
            # Uniqueness should be code-delta-based (before/after), not only location-based.
            # Otherwise valid variants at the same location are over-rejected.
            fingerprint = (
                target.get("module"),
                target.get("signal"),
                target.get("target_kind", "logic"),
                applied_op,
                before_text,
                after_text,
                target_file_original.name,
            )
            if fingerprint in used_fingerprints:
                rejected_fingerprint_duplicate += 1
                failed_mutations += 1
                _bump_target_no_progress(target, "fingerprint_duplicate")
                shutil.rmtree(mutant_dir_i, ignore_errors=True)
                return None, "fingerprint_duplicate"
            code_fp = (applied_op, before_text, after_text, target_file_original.name)
            if code_fp in used_code_fingerprints:
                rejected_code_duplicate += 1
                failed_mutations += 1
                _bump_target_no_progress(target, "code_duplicate")
                shutil.rmtree(mutant_dir_i, ignore_errors=True)
                return None, "code_duplicate"

            mutated_code_raw = codegen.visit(ast)
            mutated_code, sanitize_meta = sanitize_mutated_rtl_text(mutated_code_raw)
            mutated_code = _restore_synthesis_translate_directives(
                original_target_text, mutated_code
            )

            mixed_signals = set(sanitize_meta.get("mixed_assignment_signals") or [])
            baseline_mixed = _baseline_mixed_signals_for_file(str(target_file_original))
            new_mixed_signals = sorted(mixed_signals - baseline_mixed)
            if new_mixed_signals:
                rejected_mixed_assignments += 1
                failed_mutations += 1
                _bump_target_no_progress(target, "mixed_assignment")
                shutil.rmtree(mutant_dir_i, ignore_errors=True)
                return None, "mixed_assignment"

            mutant_target_rtl.write_text(mutated_code, encoding="utf-8")
            try:
                _devnull = open(os.devnull, "w")
                try:
                    with contextlib.redirect_stderr(_devnull):
                        parse_rtl([str(mutant_target_rtl)], preprocess_include=incdir)
                finally:
                    _devnull.close()
            except Exception:
                rejected_parse_after_sanitize += 1
                failed_mutations += 1
                _bump_target_no_progress(target, "parse_after_sanitize")
                shutil.rmtree(mutant_dir_i, ignore_errors=True)
                return None, "parse_after_sanitize"

            used_fingerprints.add(fingerprint)
            used_code_fingerprints[code_fp] = True
            if line_op_key is not None:
                used_op_line_keys.add(line_op_key)
            successful_mutations += 1
            op_usage_counts[applied_op] += 1
            covered_signals.add(target.get("signal_id"))
            _reset_target_progress(target)

            record = {
                "mutant_id": mutant_id,
                "operator": applied_op,
                "operator_profile": target.get("op_profile", "unknown"),
                "target_signal": target.get("signal"),
                "target_signal_id": target.get("signal_id"),
                "target_module": target.get("module"),
                "target_kind": target.get("target_kind", "logic"),
                "target_rtl_file": str(target_file_original),
                "location": location,
                "mutation_log": mutation_log,
                "sanitizer": {
                    "changed": bool(sanitize_meta.get("changed", False)),
                    "restored_decl_initializers": int(
                        sanitize_meta.get("restored_decl_initializers", 0)
                    ),
                },
                "rtl_path": str(mutant_target_rtl),
                "all_rtl_files": [
                    str(mutant_dir_i / Path(f).name) for f in rtl_files
                ],
                "status": "success",
            }
            mutants.append(record)
            mutation_logs.append(f"{mutant_id}: {mutation_log}")
            return record, None
        except Exception:
            failed_mutations += 1
            _bump_target_no_progress(target, "exception")
            shutil.rmtree(mutant_dir_i, ignore_errors=True)
            return None, "exception"

    def _run_generation_phase(live_entries: list[dict], phase_name: str) -> None:
        nonlocal mutant_idx, total_attempts

        rec = _get_phase_report(phase_name)
        rec["run"]["active_targets"] = len(live_entries)

        if not live_entries:
            rec["run"]["stop_reason"] = "no_live_targets"
            return

        remaining = max(0, budget - mutant_idx)
        if remaining <= 0:
            rec["run"]["stop_reason"] = "budget_reached"
            return

        max_attempts = max(remaining * 40, len(live_entries) * 20, 80)
        attempts = 0
        successes = 0
        failures = 0
        consecutive_failures = 0
        cursor = 0
        stop_reason = "budget_reached"

        while (
            mutant_idx < budget
            and attempts < max_attempts
            and consecutive_failures < 150
        ):
            active_targets = [t for t in live_entries if _target_key(t) not in exhausted_target_keys]
            if not active_targets:
                stop_reason = "all_targets_exhausted"
                break

            attempts += 1
            total_attempts += 1

            sorted_targets = _sort_targets_for_op_diversity(active_targets)
            target = sorted_targets[cursor % len(sorted_targets)]
            cursor += 1

            result, _ = _try_generate_mutant(target, mutant_idx)
            if result is not None:
                mutant_idx += 1
                successes += 1
                consecutive_failures = 0
            else:
                failures += 1
                consecutive_failures += 1

        if mutant_idx >= budget:
            stop_reason = "budget_reached"
        elif attempts >= max_attempts:
            stop_reason = "phase_attempt_limit"
        elif consecutive_failures >= 150:
            stop_reason = "consecutive_failures_limit"

        rec["run"]["attempts"] = attempts
        rec["run"]["successes"] = successes
        rec["run"]["failures"] = failures
        rec["run"]["stop_reason"] = stop_reason
        rec["run"]["active_targets"] = len([t for t in live_entries if _target_key(t) not in exhausted_target_keys])

    def _build_internal_fallback_entries(existing_entries: list[dict]) -> list[dict]:
        if signal_pool_policy != "ports_then_internal":
            return []

        selected_submodules = selection.get("selected_submodules") or []
        allowed_modules = {top_module}
        allowed_modules.update(selected_submodules)
        if not allowed_modules:
            allowed_modules.update(
                {e.get("module") for e in existing_entries if e.get("module")}
            )

        module_port_signals: dict[str, set[str]] = defaultdict(set)
        existing_keys: set[tuple] = set()
        for e in existing_entries:
            if e.get("target_kind") != "logic":
                continue
            module = e.get("module")
            signal = e.get("signal")
            if module and signal:
                module_port_signals[module].add(signal)
            existing_keys.add(_target_key(e))

        internal_entries: list[dict] = []
        seen_internal_keys: set[tuple] = set()

        for sig in structural.get("signals", []):
            module = sig.get("module")
            name = sig.get("name")
            if not module or not name:
                continue
            if module not in allowed_modules:
                continue
            if _is_clock_or_reset_name(name):
                continue

            direction = str(sig.get("direction", "")).lower()
            if direction in {"input", "output", "inout"}:
                continue
            if name in module_port_signals.get(module, set()):
                continue

            rtl_file = module_to_file.get(module)
            if not rtl_file:
                continue

            entry = {
                "module": module,
                "signal": name,
                "signal_id": sig.get("signal_id", f"{module}.{name}"),
                "rtl_file": rtl_file,
                "source": "internal_signal_fallback",
                "target_kind": "logic",
                "scope_depths": [0 if module == top_module else 1],
            }
            key = _target_key(entry)
            if key in existing_keys or key in seen_internal_keys:
                continue
            seen_internal_keys.add(key)
            internal_entries.append(entry)

        return internal_entries

    def _build_untargeted_entries() -> list[dict]:
        entries = []
        for rtl_file in rtl_files:
            entries.append(
                {
                    "module": "__untargeted__",
                    "signal": None,
                    "signal_id": f"__untargeted__.{Path(rtl_file).stem}",
                    "rtl_file": str(rtl_file),
                    "target_kind": "logic",
                    "source": "untargeted_fallback",
                    "scope_depths": [],
                }
            )
        return entries

    # Phase A: wrapper/port-driven targets.
    live_ports = _prepare_live_entries(base_target_entries, "targeted_ports")
    _run_generation_phase(live_ports, "targeted_ports")

    # Phase B: internal-signal expansion in the same module scope when budget is not met.
    internal_entries = []
    live_internal = []
    if mutant_idx < budget and signal_pool_policy == "ports_then_internal":
        internal_entries = _build_internal_fallback_entries(base_target_entries)
        live_internal = _prepare_live_entries(internal_entries, "targeted_internal_fallback")
        _run_generation_phase(live_internal, "targeted_internal_fallback")

    # Phase C: untargeted fallback on all RTL files (still unique-only).
    live_untargeted = []
    if mutant_idx < budget:
        untargeted_entries = _build_untargeted_entries()
        live_untargeted = _prepare_live_entries(untargeted_entries, "untargeted_fallback")
        _run_generation_phase(live_untargeted, "untargeted_fallback")

    all_live_for_budget = live_ports + live_internal
    live_by_module = defaultdict(list)
    for entry in all_live_for_budget:
        live_by_module[entry.get("module")].append(entry)
    live_weights = {m: len(v) for m, v in live_by_module.items() if m and v}
    module_budget = _allocate_budget_by_weight(live_weights, budget)

    exhausted_targets = sorted(
        exhausted_target_meta.values(),
        key=lambda x: (-int(x.get("fail_count", 0)), x.get("module", ""), x.get("signal", "")),
    )

    unique_space_exhausted = bool(mutant_idx < budget and exhausted_targets)
    budget_gap_reason = None
    if mutant_idx < budget:
        if unique_space_exhausted:
            budget_gap_reason = "no_more_unique_fingerprints"
        elif not any(r.get("live_count", 0) > 0 for r in phase_reports):
            budget_gap_reason = "no_live_targets"
        else:
            budget_gap_reason = "attempt_limit_or_non_unique_space"

    write_json(
        ctx.outdir / "mutants_index.json",
        {
            "target_source": mut_cfg_ts,
            "signal_pool_policy": signal_pool_policy,
            "target_signals": sorted({m.get("target_signal_id") for m in mutants if m.get("target_signal_id")}),
            "operators_used": operators,
            "budget": budget,
            "successful_mutations": successful_mutations,
            "failed_mutations": failed_mutations,
            "mutants": mutants,
            "mutation_logs": mutation_logs,
            "selection": selection,
            "module_budget": module_budget,
            "signals_covered": sorted(s for s in covered_signals if s),
            "operator_distribution": dict(op_usage_counts),
            "generation_phases": phase_reports,
            "unique_space_exhausted": unique_space_exhausted,
            "budget_gap_reason": budget_gap_reason,
            "exhausted_targets_count": len(exhausted_targets),
            "exhausted_targets": exhausted_targets[:20],
            "sanitizer_rejections": {
                "mixed_assignment": rejected_mixed_assignments,
                "parse_after_sanitize": rejected_parse_after_sanitize,
                "code_duplicate": rejected_code_duplicate,
                "fingerprint_duplicate": rejected_fingerprint_duplicate,
                "same_line_same_op": rejected_same_line_same_op,
                "no_mutation_log": rejected_no_mutation_log,
            },
        },
    )

    mutations_cache, dataset_root = _mutations_cache_paths(ctx)
    if mutations_cache is not None:
        _persist_mutation_cache(ctx, mutations_cache, dataset_root, rtl_files)

    return {
        "mutants": successful_mutations,
        "failed": failed_mutations,
        "signals_covered": len(covered_signals),
        "total_attempted": total_attempts,
    }


def _safe_ratio(num: float, den: float) -> float:
    if den <= 0:
        return 0.0
    return float(num) / float(den)


def _read_json_if_exists(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        return read_json(path)
    except Exception:
        return {}


def _derive_bug_hunting_eval(ctx: RunContext, metrics: dict, mutation_results: dict) -> dict | None:
    if not bug_hunting_enabled(ctx.cfg):
        return None

    results = mutation_results.get("results", []) if isinstance(mutation_results, dict) else []
    killed_rows = []
    survived_rows = []
    error_rows = []
    unique_killing_assertions: set[str] = set()

    for row in results:
        outcome = str(row.get("outcome", "")).strip().lower()
        if outcome == "killed":
            killed_rows.append(row)
            for item in row.get("killed_by", []) or []:
                if item:
                    unique_killing_assertions.add(str(item))
        elif outcome == "survived":
            survived_rows.append(row)
        elif outcome == "error":
            error_rows.append(row)

    tested = int(metrics.get("total_tested", len(killed_rows) + len(survived_rows)) or 0)
    killed = int(metrics.get("killed", len(killed_rows)) or 0)
    survived = int(metrics.get("survived", len(survived_rows)) or 0)
    errors = int(metrics.get("errors", len(error_rows)) or 0)

    mutants_index = _read_json_if_exists(ctx.outdir / "mutants_index.json")
    successful_mutants = [
        m
        for m in mutants_index.get("mutants", [])
        if str(m.get("status", "success")).strip().lower() == "success"
    ]
    expected_bug_count = len(successful_mutants)

    baseline_eval = _read_json_if_exists(ctx.outdir / "baseline_eval.json")
    baseline_summary = baseline_eval.get("summary", {}) if isinstance(baseline_eval, dict) else {}
    clean_cex = int(baseline_summary.get("cex", 0) or 0)
    clean_total_assertions = int(baseline_summary.get("total_assertions", 0) or 0)
    clean_cex_ratio = _safe_ratio(clean_cex, clean_total_assertions)

    detection_rate = _safe_ratio(killed, tested)
    miss_rate = _safe_ratio(survived, tested)
    error_rate = _safe_ratio(errors, max(tested + errors, 0))

    compare_cfg = ctx.cfg.get("bug_hunting", {}).get("compare_against_run_outdir")
    comparison = None
    local_misleading_signal = bool(clean_cex > 0 and miss_rate > 0)

    if compare_cfg:
        compare_dir = Path(str(compare_cfg)).expanduser().resolve()
        if not compare_dir.is_dir():
            raise FileNotFoundError(
                f"bug_hunting.compare_against_run_outdir does not exist: {compare_dir}"
            )

        ref_metrics = _read_json_if_exists(compare_dir / "metrics.json")
        ref_baseline = _read_json_if_exists(compare_dir / "baseline_eval.json")

        ref_bug_eval = ref_metrics.get("bug_hunting_eval", {}) if isinstance(ref_metrics, dict) else {}
        ref_detection_rate = ref_bug_eval.get("detection_rate")
        if ref_detection_rate is None:
            ref_detection_rate = ref_metrics.get("kill_ratio")
        ref_detection_rate = float(ref_detection_rate) if ref_detection_rate is not None else 0.0

        ref_summary = ref_baseline.get("summary", {}) if isinstance(ref_baseline, dict) else {}
        ref_clean_cex = int(ref_summary.get("cex", 0) or 0)
        ref_total_assertions = int(ref_summary.get("total_assertions", 0) or 0)
        ref_clean_cex_ratio = _safe_ratio(ref_clean_cex, ref_total_assertions)

        delta_detection_rate = detection_rate - ref_detection_rate
        delta_clean_cex_ratio = clean_cex_ratio - ref_clean_cex_ratio
        misleading_vs_reference = bool(delta_clean_cex_ratio > 0 and delta_detection_rate <= 0)

        comparison = {
            "reference_run_outdir": str(compare_dir),
            "reference_detection_rate": ref_detection_rate,
            "reference_clean_design_cex_ratio": ref_clean_cex_ratio,
            "delta_detection_rate": delta_detection_rate,
            "delta_clean_design_cex_ratio": delta_clean_cex_ratio,
            "possible_misleading_signal_vs_reference": misleading_vs_reference,
        }
    else:
        misleading_vs_reference = False

    return {
        "mode": "bug_hunting",
        "bugs_expected": expected_bug_count,
        "bugs_tested": tested,
        "bugs_detected": killed,
        "bugs_missed": survived,
        "errors": errors,
        "detection_rate": detection_rate,
        "miss_rate": miss_rate,
        "error_rate": error_rate,
        "clean_design_cex": clean_cex,
        "clean_design_total_assertions": clean_total_assertions,
        "clean_design_cex_ratio": clean_cex_ratio,
        "syntax_correctness": baseline_eval.get("Syntax_correctness"),
        "unique_killing_assertions_count": len(unique_killing_assertions),
        "unique_killing_assertions": sorted(unique_killing_assertions),
        "possible_misleading_signal_local": local_misleading_signal,
        "possible_misleading_signal": bool(local_misleading_signal or misleading_vs_reference),
        "comparison": comparison,
    }


def _run_mutation_testing(ctx: RunContext) -> dict:
    mutants_data = read_json(ctx.outdir / "mutants_index.json")
    mutants = [m for m in mutants_data.get("mutants", []) if m.get("status") == "success"]
    results_path = ctx.outdir / "mutation_results.json"

    if not mutants:
        metrics = {
            "kill_ratio": 0.0,
            "killed": 0,
            "survived": 0,
            "errors": 0,
            "total_tested": 0,
            "total_mutants": 0,
        }
        write_json(results_path, {"results": []})
        write_json(ctx.outdir / "metrics.json", metrics)
        return metrics

    mut_test_dir = ctx.outdir / "mutation_testing"
    mut_test_dir.mkdir(exist_ok=True)

    template_path = Path(__file__).resolve().parents[2] / "jp_run_template.tcl"
    if not template_path.exists():
        raise FileNotFoundError(f"Missing Jasper template: {template_path}")
    tcl_template = template_path.read_text(encoding="utf-8")

    top_module = ctx.cfg["rtl"].get("top_module", "top")
    params = ctx.cfg["rtl"].get("parameters", {})
    param_str = " ".join(f"-parameter {k} {v}" for k, v in params.items())
    assertions_file = ctx.outdir / "assertions.sv"
    bind_file = ctx.outdir / f"{top_module}_bind.sv"
    incdir = ctx.cfg["rtl"].get("incdir", [])
    original_rtl_files = ctx.cfg["rtl"]["filelist"]
    bbox_modules = _resolve_bbox_modules(ctx.cfg)

    mutation_results = []
    killed = 0
    survived = 0
    errors = 0

    for mutant in mutants:
        mutant_id = mutant["mutant_id"]
        work_dir = mut_test_dir / mutant_id
        work_dir.mkdir(exist_ok=True)

        mutant_rtl_files = mutant.get("all_rtl_files") or [
            mutant.get("rtl_path", original_rtl_files[0])
        ]
        mutant_tcl = _generate_mutant_tcl(
            template=tcl_template,
            mutant_rtl=mutant_rtl_files,
            assertions_file=str(assertions_file),
            top_module=top_module,
            clk=ctx.cfg.get("clock_reset", {}).get("clock", "clk"),
            rst=ctx.cfg.get("clock_reset", {}).get("reset", "rst"),
            param_str=param_str,
            work_dir=work_dir,
            bind_file=str(bind_file),
            incdir=incdir,
            bbox_modules=bbox_modules,
        )

        tcl_file = work_dir / "mutation_test.tcl"
        tcl_file.write_text(mutant_tcl, encoding="utf-8")

        jg_result = _run_jaspergold(tcl_file, work_dir)
        base_result = {
            "mutant_id": mutant_id,
            "operator": mutant.get("operator"),
            "target_signal": mutant.get("target_signal"),
        }
        if jg_result.get("status") == "error":
            errors += 1
            mutation_results.append(
                {
                    **base_result,
                    "outcome": "error",
                    "killed_by": [],
                    "error": jg_result.get("error"),
                }
            )
            continue

        fpv_entries = _parse_fpv_report(work_dir / "report" / "design.fpv.rpt")
        cex_assertions = [
            f"_assert_{entry['assert_num']}"
            for entry in fpv_entries
            if entry.get("status") == "cex"
        ]
        if cex_assertions:
            killed += 1
            mutation_results.append(
                {**base_result, "outcome": "killed", "killed_by": cex_assertions}
            )
        else:
            survived += 1
            mutation_results.append({**base_result, "outcome": "survived", "killed_by": []})

    total = killed + survived
    metrics = {
        "kill_ratio": killed / total if total > 0 else 0.0,
        "killed": killed,
        "survived": survived,
        "errors": errors,
        "total_tested": total,
        "total_mutants": len(mutants),
    }
    write_json(results_path, {"results": mutation_results})
    write_json(ctx.outdir / "metrics.json", metrics)
    return metrics


def evaluate_mutants(ctx: RunContext) -> dict:
    if ctx.method_id != "plain_prompt":
        raise ValueError("Only method_id='plain_prompt' is supported in AssertLLM2")

    print("[*] Mutation testing")

    if bug_hunting_enabled(ctx.cfg):
        prepared = prepare_bug_hunting_eval_inputs(cfg=ctx.cfg, outdir=ctx.outdir)
        if prepared is None:
            raise RuntimeError("bug_hunting mode was enabled but preparation returned no data")
        metrics = _run_mutation_testing(ctx)
    else:
        mut_cfg = ctx.cfg.get("mutation", {})
        target_source = str(mut_cfg.get("target_source", "rtl_hierarchy"))
        if target_source == "assertions":
            raise ValueError("mutation.target_source='assertions' requires the removed assertion-target flow")

        mutations_cache, _ = _mutations_cache_paths(ctx)
        budget = int(mut_cfg.get("budget", 0))
        force = bool(mut_cfg.get("force_regenerate", False))
        loaded = False
        if mutations_cache is not None and not force and budget > 0:
            loaded = _try_load_mutation_cache(ctx, mutations_cache, budget)
        if not loaded:
            generation = _generate_plain_prompt_mutants(ctx)
            if isinstance(generation, dict) and generation.get("error"):
                raise RuntimeError(
                    "plain_prompt mutation generation failed: "
                    f"{generation.get('error')}"
                )
        metrics = _run_mutation_testing(ctx)

    mutation_results = {}
    results_path = ctx.outdir / "mutation_results.json"
    if results_path.exists():
        mutation_results = read_json(results_path)

    metrics_out = dict(metrics) if isinstance(metrics, dict) else {}
    bug_eval = _derive_bug_hunting_eval(ctx=ctx, metrics=metrics_out, mutation_results=mutation_results)
    if bug_eval is not None:
        metrics_out["bug_hunting_eval"] = bug_eval
        write_json(ctx.outdir / "bug_hunting_eval.json", bug_eval)
        write_json(ctx.outdir / "metrics.json", metrics_out)

    payload = stamp(
        ctx,
        "mutation_eval",
        {
            "results": mutation_results.get("results", []),
            "summary": metrics_out,
        },
    )
    write_json(results_path, payload)

    killed = int(metrics_out.get("killed", 0) or 0)
    survived = int(metrics_out.get("survived", 0) or 0)
    total_tested = int(metrics_out.get("total_tested", 0) or 0)
    total_mutants = int(metrics_out.get("total_mutants", 0) or 0)
    kill_ratio = float(metrics_out.get("kill_ratio", 0.0) or 0.0)

    print("[*] Mutation Testing Complete:")
    if total_tested > 0:
        print(f"    Killed: {killed}/{total_tested} ({kill_ratio:.2%})")
        print(f"    Survived: {survived}/{total_tested}")
    else:
        print("    Killed: 0/0")
        print("    Survived: 0/0")
    print(f"    Total tested: {total_tested}")
    print(f"    Total mutants: {total_mutants}")

    return metrics_out
