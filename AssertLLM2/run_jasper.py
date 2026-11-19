from __future__ import annotations

import json
import re
from pathlib import Path
from typing import List, Optional, Union


def _normalize_bbox_modules(raw_modules, source_desc: str) -> List[str]:
    if raw_modules is None:
        return []
    if not isinstance(raw_modules, list):
        raise TypeError(f"{source_desc} must be a list of module names")

    modules: List[str] = []
    seen = set()
    for idx, item in enumerate(raw_modules):
        if not isinstance(item, str):
            raise TypeError(f"{source_desc}[{idx}] must be a string")
        name = item.strip()
        if not name:
            raise ValueError(f"{source_desc}[{idx}] must not be empty")
        if name in seen:
            continue
        seen.add(name)
        modules.append(name)
    return modules


def _load_bbox_modules_from_file(jg_bbox_path: Path) -> List[str]:
    payload = json.loads(jg_bbox_path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise TypeError(f"{jg_bbox_path} must be a JSON object")
    if "blackbox_modules" not in payload:
        raise KeyError(f"{jg_bbox_path} missing required key: blackbox_modules")
    return _normalize_bbox_modules(payload["blackbox_modules"], f"{jg_bbox_path}:blackbox_modules")


def _resolve_bbox_modules(cfg: dict) -> List[str]:
    formal_cfg = cfg.get("formal", {})
    if isinstance(formal_cfg, dict) and formal_cfg.get("bbox_modules") is not None:
        return _normalize_bbox_modules(formal_cfg.get("bbox_modules"), "cfg.formal.bbox_modules")

    spec_files = cfg.get("spec_file") or []
    if not spec_files:
        return []

    jg_bbox_path = Path(spec_files[0]).resolve().parent / "jg_bbox.json"
    if not jg_bbox_path.is_file():
        return []
    return _load_bbox_modules_from_file(jg_bbox_path)

def _generate_mutant_tcl(template: str, mutant_rtl, assertions_file: str,
                         top_module: str, clk: Optional[Union[str, List[str]]], rst: str, param_str: str,
                         work_dir: Path, bind_file: str, incdir: list = None,
                         bbox_modules: Optional[List[str]] = None) -> str:
    def _abs_path(path) -> str:
        return str(Path(path).expanduser().resolve())

    # Build the analyze block for RTL files
    if isinstance(mutant_rtl, str):
        mutant_rtl = [mutant_rtl]

    incdir_str = ""
    if incdir:
        incdir_str = " ".join(f"-incdir {_abs_path(d)}" for d in incdir) + " \\\n  "

    analyze_lines = []
    for rtl_file in mutant_rtl:
        rtl_path = _abs_path(rtl_file)
        if rtl_file == mutant_rtl[0] and incdir_str:
            analyze_lines.append(f"analyze -sv12 \\\n  {incdir_str}{rtl_path}")
        else:
            analyze_lines.append(f"analyze -sv12 {rtl_path}")

    rtl_block = "\n\n".join(analyze_lines)

    # Build clock/reset TCL lines; omit if empty (combinational design)
    if clk:
        # Single clock (str) or multiple clocks (list) from JSON clock_reset.clock
        if isinstance(clk, str):
            clk = [clk]
        clk_line = "\n".join(
            f"clock {clk_signal} -both_edges" for clk_signal in clk
        )
    else:
        clk_line = "clock -none"

    if rst:
        r = rst.strip().lower()
        is_active_low = (
            (r.endswith("n") and not r.endswith("in"))
            or r.startswith("n")
            or r.endswith("_b")
            or r.endswith("_l")
        )
        if is_active_low:
            rst_expr = f"~{rst}"
        else:
            rst_expr = rst
        rst_line = f"reset -max_iterations 1000 {rst_expr}"
    else:
        rst_line = "reset -none"

    clk_rst_block = "\n".join(line for line in [clk_line, rst_line] if line)
    bbox_flags = ""
    if bbox_modules:
        normalized = _normalize_bbox_modules(bbox_modules, "bbox_modules")
        bbox_flags = " ".join(f"-bbox_m {name}" for name in normalized)

    replacements = {
        "{{MUTANT_RTL}}": rtl_block,
        "{{ASSERTIONS_FILE}}": _abs_path(assertions_file),
        "{{TOP_MODULE}}": top_module,
        "{{PARAMETERS}}": param_str,
        "{{BBOX_FLAGS}}": bbox_flags,
        "{{WORK_DIR}}": _abs_path(work_dir),
        "{{BINDING_FILE}}": _abs_path(bind_file),
        "{{CLK_RST_BLOCK}}": (
            "# Clock and reset configuration\n" + clk_rst_block
            if clk_rst_block
            else "# No clock/reset (combinational design)"
        ),
    }

    tcl_code = template
    for placeholder, value in replacements.items():
        tcl_code = tcl_code.replace(placeholder, value)

    return tcl_code


def _run_jaspergold(tcl_file: Path, work_dir: Path) -> dict:
    """
    Run JasperGold with the given TCL script.
    Returns dict with 'status' and 'killed_by' list.
    """
    import subprocess
    
    work_dir.mkdir(parents=True, exist_ok=True)
    log_file = work_dir / "jg.log"
    tcl_path = tcl_file.expanduser().resolve()
    cmd = ["jg", "-batch", "-tcl", str(tcl_path)]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=1200,  # 10 minutes
            cwd=work_dir
        )

        log_file.write_text(
            "\n".join(
                [
                    f"$ {' '.join(cmd)}",
                    f"cwd: {work_dir.resolve()}",
                    f"returncode: {result.returncode}",
                    "",
                    "=== stdout ===",
                    result.stdout or "",
                    "",
                    "=== stderr ===",
                    result.stderr or "",
                ]
            ),
            encoding="utf-8",
        )

        if result.returncode != 0:
            return {
                "status": "error",
                "error": f"JasperGold exited with code {result.returncode}; see {log_file}",
                "killed_by": [],
            }

        fpv_report = work_dir / "report" / "design.fpv.rpt"
        if not fpv_report.exists():
            return {
                "status": "error",
                "error": f"JasperGold did not produce {fpv_report}; see {log_file}",
                "killed_by": [],
            }
        
        # Parse results from report files
        killed_by = _parse_jg_reports(work_dir)
        
        return {
            "status": "success",
            "killed_by": killed_by
        }
    
    except subprocess.TimeoutExpired:
        return {"status": "error", "error": "JasperGold timeout", "killed_by": []}
    except Exception as e:
        return {"status": "error", "error": str(e), "killed_by": []}


def _parse_jg_reports(work_dir: Path) -> list:
    """
    Parse JasperGold report files to find which assertions failed (killed the mutant).
    
    An assertion that fails (CEX/FAIL) on a mutant = killed the mutant.
    """
    killed_by = []

    fpv_report = work_dir / "report" / "design.fpv.rpt"
    if fpv_report.exists():
        content = fpv_report.read_text(encoding="utf-8")
        for line in content.splitlines():
            match = re.search(
                r"\[\d+\]\s+\S+\._assert_(\d+)\s+"
                r"(cex|fail|ar_cex)",
                line,
                re.IGNORECASE,
            )
            if match:
                prop_name = f"_assert_{match.group(1)}"
                if prop_name not in killed_by:
                    killed_by.append(prop_name)

    return sorted(set(killed_by))


def _parse_coverage_report(report_path: Path) -> dict:
    """Parse a single JasperGold coverage report (formal/stimuli/checker_coi/checker_proof)."""
    result = {"percentage": None, "covered": 0, "total": 0, "instances": {}}
    if not report_path.exists():
        return result

    content = report_path.read_text(encoding="utf-8", errors="ignore")
    pattern = re.compile(r"\|([^|+]+?)\s*\|\s*([\d.]+)%\s*\((\d+)/(\d+)\)")

    first = True
    for match in pattern.finditer(content):
        instance = match.group(1).strip().lstrip("|-")
        pct = float(match.group(2))
        covered = int(match.group(3))
        total = int(match.group(4))

        if first:
            result["percentage"] = pct
            result["covered"] = covered
            result["total"] = total
            first = False

        result["instances"][instance] = {
            "percentage": pct,
            "covered": covered,
            "total": total,
        }

    return result


def _parse_fpv_report(report_path: Path) -> list:
    """
    Parse design.fpv.rpt and return per-assertion results.

    Each result is {'assert_num': int, 'status': str}.
    Excludes :witness and :precondition cover items.

    Supports both numbered assertions (``_assert_1``) and named assertions
    (``a_fault_prop``).      For named assertions, ``assert_num`` is assigned
    sequentially (1-based) in file order, matching the counting used by
    ``_build_assert_num_to_signal`` (``assert property``, immediate
    ``assert (...)``, and ``always_comb`` bodies).
    """
    results = []
    if not report_path.exists():
        return results

    content = report_path.read_text(encoding="utf-8", errors="ignore")

    # Match any result line: [seq]  hierarchy.name  status ...
    line_pattern = re.compile(
        r"\[(\d+)\]\s+(\S+)\s+"
        r"(proven|cex|undetermined|unprocessed|error|marked_proven|ar_cex)",
        re.IGNORECASE,
    )

    assert_counter = 0
    for match in line_pattern.finditer(content):
        full_name = match.group(2)
        raw_status = match.group(3).lower()

        # Skip witness / precondition cover entries
        if re.search(r":(witness|precondition)\d*$", full_name):
            continue

        assert_counter += 1

        # If the name follows the _assert_N convention, prefer the embedded number
        num_match = re.search(r"\._assert_(\d+)$", full_name)
        assert_num = int(num_match.group(1)) if num_match else assert_counter

        # Extract the leaf assertion name (last component after final '.')
        assert_name = full_name.rsplit(".", 1)[-1] if "." in full_name else full_name

        if raw_status in ("cex", "fail", "ar_cex"):
            status = "cex"
        elif raw_status in ("proven", "marked_proven"):
            status = "proven"
        elif raw_status == "undetermined":
            status = "undetermined"
        else:
            status = raw_status
        results.append({"assert_num": assert_num, "status": status, "assert_name": assert_name})

    return results


def _line_code_sv(s: str) -> str:
    return re.sub(r"//.*", "", s)


# Concurrent assertions (optional label), same order as removal scanner
_RE_ASSERT_PROPERTY_HEAD = re.compile(
    r"\s*(?:(?P<label>\w+)\s*:\s*)?(?P<kw>assert|assume|cover)\s+property\b"
)

# Immediate assert/assume/cover: optional label; optional #0 or final; '(' on same line
_RE_IMMEDIATE_ASSERT_HEAD = re.compile(
    r"\s*(?:(?P<label>\w+)\s*:\s*)?(?P<kw>assert|assume|cover)\s*(?:#\s*0\b|final\b)?\s*\("
)


def _find_comment_start_block(lines: list[str], idx: int) -> int:
    """First line index to include when removing an assertion (comments above it)."""
    start = idx
    while start > 0:
        prev = lines[start - 1].strip()
        if prev.startswith("//"):
            if "======" in prev or "Assertions for Signal" in prev \
                    or re.search(r"\[(?:function|width|connectivity)\]", prev):
                break
            start -= 1
        elif prev == "":
            start -= 1
        else:
            break
    while start < idx and lines[start].strip() == "":
        start += 1
    return start


def _find_paren_statement_end(lines: list[str], start_idx: int) -> int:
    end = start_idx
    paren_count = 0
    started_parens = False
    while end < len(lines):
        for char in _line_code_sv(lines[end]):
            if char == "(":
                paren_count += 1
                started_parens = True
            elif char == ")":
                paren_count -= 1
            elif char == ";" and started_parens and paren_count == 0:
                return end
        end += 1
    return min(end, len(lines) - 1)


def _find_always_comb_end(lines: list[str], start_idx: int) -> int:
    end = start_idx
    nesting = 0
    while end < len(lines):
        code = _line_code_sv(lines[end])
        nesting += len(re.findall(r"\bbegin\b", code))
        nesting -= len(re.findall(r"\bend\b", code))
        if nesting <= 0 and re.search(r"\bend\b", code):
            return end
        end += 1
    return min(end, len(lines) - 1)


def _is_always_comb_inner_assert_line(inner_lc: str) -> bool:
    if not re.search(r"\b(assert|assume|cover)\b", inner_lc):
        return False
    if re.search(r"\b(assert|assume|cover)\s+property\b", inner_lc):
        return False
    return True


def _label_from_always_comb_line(inner_lc: str) -> Optional[str]:
    m = _RE_IMMEDIATE_ASSERT_HEAD.match(inner_lc)
    if m:
        return m.group("label")
    m = _RE_ASSERT_PROPERTY_HEAD.match(inner_lc)
    return m.group("label") if m else None


def _collect_assert_blocks(lines: list[str]) -> list[tuple[int, int, Optional[str]]]:
    """
    One entry per assertion in elaboration order (matches Jasper sequential numbering).

    Each tuple is (block_start_line, block_end_line_inclusive, optional_label).
    """
    blocks: list[tuple[int, int, Optional[str]]] = []
    i = 0
    n = len(lines)

    while i < n:
        lc = _line_code_sv(lines[i])

        if re.search(r"\balways_comb\b", lc):
            comment_start = _find_comment_start_block(lines, i)

            # Case A: one-line always_comb assert(...);
            if _is_always_comb_inner_assert_line(lc):
                stmt_end = _find_paren_statement_end(lines, i)
                label = _label_from_always_comb_line(lc)
                blocks.append((comment_start, stmt_end, label))
                i = stmt_end + 1
                continue

            # Case B: always_comb begin ... end block
            if re.search(r"\bbegin\b", lc):
                block_end = _find_always_comb_end(lines, i)
                for j in range(i, block_end + 1):
                    inner_lc = _line_code_sv(lines[j])
                    if not _is_always_comb_inner_assert_line(inner_lc):
                        continue
                    label = _label_from_always_comb_line(inner_lc)
                    blocks.append((comment_start, block_end, label))
                i = block_end + 1
                continue

            # Case C: always_comb then assert on the next line (no begin/end)
            if i + 1 < n:
                next_lc = _line_code_sv(lines[i + 1])
                if _is_always_comb_inner_assert_line(next_lc):
                    stmt_end = _find_paren_statement_end(lines, i + 1)
                    label = _label_from_always_comb_line(next_lc)
                    blocks.append((comment_start, stmt_end, label))
                    i = stmt_end + 1
                    continue

            i += 1
            continue

        m_prop = _RE_ASSERT_PROPERTY_HEAD.match(lc)
        if m_prop:
            block_end = _find_paren_statement_end(lines, i)
            comment_start = _find_comment_start_block(lines, i)
            prop_start = comment_start
            check = comment_start - 1
            while check >= 0 and lines[check].strip() == "":
                check -= 1
            if check >= 0 and re.search(r"\bendproperty\b", _line_code_sv(lines[check])):
                ep = check
                while ep > 0 and not re.search(
                    r"\bproperty\s+\w+\b", _line_code_sv(lines[ep])
                ):
                    ep -= 1
                prop_start = _find_comment_start_block(lines, ep)
            label = m_prop.group("label")
            blocks.append((prop_start, block_end, label))
            i = block_end + 1
            continue

        if _RE_IMMEDIATE_ASSERT_HEAD.match(lc) and not re.search(
            r"\b(assert|assume|cover)\s+property\b", lc
        ):
            block_end = _find_paren_statement_end(lines, i)
            comment_start = _find_comment_start_block(lines, i)
            m_imm = _RE_IMMEDIATE_ASSERT_HEAD.match(lc)
            label = m_imm.group("label") if m_imm else None
            blocks.append((comment_start, block_end, label))
            i = block_end + 1
            continue

        if re.search(r"\bproperty\s+\w+\b", lc) \
                and not re.search(r"\b(assert|assume|cover)\b", lc):
            end = i
            while end < n and not re.search(
                r"\bendproperty\b", _line_code_sv(lines[end])
            ):
                end += 1
            i = end + 1
            continue

        i += 1

    return blocks


def _build_assert_num_to_signal(assertions_file: Path) -> dict:
    """
    Map sequential assertion numbers (as assigned by JasperGold) to signal names
    by scanning assertions in the same order as ``_remove_cex_from_sv``:
    ``assert property``, immediate ``assert (...)``, and asserts inside ``always_comb``.

    Signal names are determined by (in priority order):
      1. ``// Assertions for Signal: <name>`` section headers (at assertion line)
      2. The assertion label (``label: assert ...``) as a fallback

    Also returns a secondary mapping from assertion label → assert_num via
    the ``label_to_num`` attribute on the returned dict.
    """
    mapping: dict = {}
    if not assertions_file.exists():
        return mapping

    content = assertions_file.read_text(encoding="utf-8", errors="ignore")
    lines = content.split("\n")

    signal_at_line: list[Optional[str]] = []
    cur_sig: Optional[str] = None
    for line in lines:
        signal_at_line.append(cur_sig)
        sig_match = re.match(r"// Assertions for Signal:\s*(\S+)", line)
        if sig_match:
            cur_sig = sig_match.group(1)

    blocks = _collect_assert_blocks(lines)
    label_to_num: dict[str, int] = {}

    for num, (start, _end, label) in enumerate(blocks, start=1):
        section = signal_at_line[start] if start < len(signal_at_line) else None
        sig = section if section else label
        mapping[num] = sig
        if label:
            label_to_num[label] = num

    mapping["_label_to_num"] = label_to_num  # type: ignore[assignment]
    return mapping


def _count_assert_statements_in_sv(assertions_file: Path) -> int:
    if not assertions_file.exists():
        return 0
    lines = assertions_file.read_text(encoding="utf-8", errors="ignore").split("\n")
    return len(_collect_assert_blocks(lines))


def _remove_erroneous_assertions(log_content: str, assertions_file: Path) -> int:
    """Remove assertion blocks referenced by Jasper VERI error line numbers."""
    if not assertions_file.exists():
        return 0

    error_lines = {
        int(m.group(1))
        for m in re.finditer(r"assertions(?:_\w+)?\.sv\((\d+)\)", log_content)
    }
    if not error_lines:
        return 0

    lines = assertions_file.read_text(encoding="utf-8", errors="ignore").split("\n")
    blocks = _collect_assert_blocks(lines)
    remove_ranges: list[tuple[int, int]] = []

    for start, end, _label in blocks:
        block_lines = set(range(start + 1, end + 2))
        if error_lines.intersection(block_lines):
            remove_ranges.append((start, end))

    if not remove_ranges:
        return 0

    remove_ranges.sort()
    merged: list[tuple[int, int]] = []
    for start, end in remove_ranges:
        if merged and start <= merged[-1][1] + 1:
            merged[-1] = (merged[-1][0], max(merged[-1][1], end))
        else:
            merged.append((start, end))

    lines_to_remove = set()
    for start, end in merged:
        for idx in range(start, end + 1):
            if idx < len(lines) and not re.search(r"\bendmodule\b", _line_code_sv(lines[idx])):
                lines_to_remove.add(idx)

    cleaned = [line for idx, line in enumerate(lines) if idx not in lines_to_remove]
    out = "\n".join(cleaned)
    if not re.search(r"\bendmodule\b", out):
        out = out.rstrip() + "\nendmodule\n"
    assertions_file.write_text(out, encoding="utf-8")
    return len(merged)


def _remove_cex_from_sv(assertions_file: Path, cex_nums: set) -> None:
    """
    Remove CEX assertion blocks (including preceding comments) from assertions.sv.
    CEX numbers correspond to each individual assert/assume/cover statement in file order.
    Block identification:
      (1) property ... endproperty (paired with its assert/assume/cover)
      (2) assert/assume/cover property (...) ;
      (3) standalone immediate: assert/assume/cover [#0|final] (...) ;
      (4) always_comb begin ... end
    Never removes lines containing endmodule; ensures file always ends with endmodule.
    """
    if not assertions_file.exists() or not cex_nums:
        return

    content = assertions_file.read_text(encoding="utf-8", errors="ignore")
    lines = content.split("\n")

    raw_blocks = _collect_assert_blocks(lines)

    # ===================================================================
    # Pass 2: Mark lines for removal based on CEX numbers (1-based)
    # ===================================================================
    lines_to_remove = set()
    for num, (start, end, _label) in enumerate(raw_blocks, start=1):
        if num in cex_nums:
            for j in range(start, end + 1):
                if re.search(r"\bendmodule\b", _line_code_sv(lines[j])):
                    continue
                lines_to_remove.add(j)

    new_lines = [line for idx, line in enumerate(lines) if idx not in lines_to_remove]

    # ===================================================================
    # Pass 3: Collapse consecutive blank lines
    # ===================================================================
    cleaned = []
    prev_blank = False
    for line in new_lines:
        if line.strip() == "":
            if prev_blank:
                continue
            prev_blank = True
        else:
            prev_blank = False
        cleaned.append(line)

    out = "\n".join(cleaned)
    if not re.search(r"\bendmodule\b", out):
        out = out.rstrip() + "\nendmodule\n"

    assertions_file.write_text(out, encoding="utf-8")


def _update_meta_after_cex_removal(meta_file: Path, assertions_file: Path) -> None:
    """
    Re-read the updated assertions.sv and sync each signal's ``code`` field
    in assertions_meta.json to match the file on disk.
    """
    import json

    if not meta_file.exists() or not assertions_file.exists():
        return

    sv_content = assertions_file.read_text(encoding="utf-8", errors="ignore")
    signal_sections = {}
    current_signal = None
    current_lines = []

    for line in sv_content.splitlines():
        sig_match = re.match(r"// Assertions for Signal:\s*(\S+)", line)
        if sig_match:
            if current_signal and current_lines:
                signal_sections[current_signal] = "\n".join(current_lines).strip()
            current_signal = sig_match.group(1)
            current_lines = []
            continue

        header_match = re.match(r"//={5,}", line)
        if header_match:
            continue

        if current_signal is not None:
            if line.strip() == "endmodule":
                if current_lines:
                    signal_sections[current_signal] = "\n".join(current_lines).strip()
                current_signal = None
                continue
            next_sig = re.match(r"// Assertions for Signal:", line)
            if next_sig:
                if current_lines:
                    signal_sections[current_signal] = "\n".join(current_lines).strip()
                current_signal = next_sig.group(1) if hasattr(next_sig, "group") else None
                current_lines = []
                continue
            current_lines.append(line)

    if current_signal and current_lines:
        signal_sections[current_signal] = "\n".join(current_lines).strip()

    meta = json.loads(meta_file.read_text(encoding="utf-8"))
    for entry in meta.get("assertions", []):
        sig_name = entry.get("signal_name", "")
        if sig_name in signal_sections:
            entry["code"] = signal_sections[sig_name]

    meta_file.write_text(json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8")


def _parse_baseline_results(
    work_dir: Path,
    assertions: list,
    assertions_file: Path = None,
    meta_file: Path = None,
) -> tuple:
    """
    Parse JasperGold baseline evaluation results.

    Parses:
      1. design.fpv.rpt    – per-assertion FPV status (proven / cex / undetermined)
      2. Coverage reports   – formal, stimuli, checker_coi, checker_proof
      3. jg.log             – syntax errors
    Side-effects:
      * Removes CEX assertion blocks from ``assertions_file``
      * If ``meta_file`` is provided, updates it to keep code fields in sync with the .sv file

    Returns
    -------
    (fpv_results, coverage_results, cex_assert_nums)
        fpv_results      : list[dict]  – per-assertion ``{assert_num, status, signal_name, signal_id}``
        coverage_results : dict        – keys: formal, stimuli, checker_coi, checker_proof
        cex_assert_nums  : set[int]    – assertion numbers that are CEX (removed from file)
    """
    report_dir = work_dir / "report"

    # ------------------------------------------------------------------
    # 1. Coverage reports
    # ------------------------------------------------------------------
    coverage_results = {
        "formal": _parse_coverage_report(report_dir / "formal_coverage.rpt"),
        "stimuli": _parse_coverage_report(report_dir / "stimuli_coverage.rpt"),
        "checker_coi": _parse_coverage_report(report_dir / "checker_coi.rpt"),
        "checker_proof": _parse_coverage_report(report_dir / "checker_proof.rpt"),
    }

    # ------------------------------------------------------------------
    # 2. FPV report → per-assertion status
    # ------------------------------------------------------------------
    raw_fpv = _parse_fpv_report(report_dir / "design.fpv.rpt")

    cex_assert_nums = {r["assert_num"] for r in raw_fpv if r["status"] == "cex"}

    # ------------------------------------------------------------------
    # 3. Map assertion numbers → signal names / signal_ids
    # ------------------------------------------------------------------
    if assertions_file is None:
        assertions_file = work_dir.parent / "assertions.sv"

    assert_num_to_signal = _build_assert_num_to_signal(assertions_file)
    label_to_num = assert_num_to_signal.pop("_label_to_num", {})

    signal_name_to_id = {}
    for a in assertions:
        sig_name = a.get("signal_name", "")
        sig_id = a.get("signal_id", "")
        if sig_name:
            signal_name_to_id[sig_name] = sig_id

    fpv_results = []
    for r in raw_fpv:
        sig_name = assert_num_to_signal.get(r["assert_num"])
        # Fallback: use the assertion label from the FPV report to cross-reference
        if not sig_name:
            assert_name = r.get("assert_name", "")
            num_via_label = label_to_num.get(assert_name)
            if num_via_label is not None:
                sig_name = assert_num_to_signal.get(num_via_label)
            if not sig_name:
                sig_name = assert_name or "unknown"
        fpv_results.append({
            "assert_num": r["assert_num"],
            "status": r["status"],
            "signal_name": sig_name,
            "signal_id": signal_name_to_id.get(sig_name, ""),
        })

    # ------------------------------------------------------------------
    # 4. Remove CEX assertions from the .sv file and update meta JSON
    # ------------------------------------------------------------------
    if cex_assert_nums:
        _remove_cex_from_sv(assertions_file, cex_assert_nums)
        if meta_file is not None:
            _update_meta_after_cex_removal(meta_file, assertions_file)

    return fpv_results, coverage_results, cex_assert_nums
