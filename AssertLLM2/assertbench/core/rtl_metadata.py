import re
from pathlib import Path
from typing import Dict, List, Optional


_LOCALPARAM_DIRECT_INT = re.compile(
    r"\blocalparam\s+(?:\w+\s+)?(?P<name>\w+)\s*=\s*(?P<val>\d+)\s*;",
    re.IGNORECASE,
)
_LOCALPARAM_ALIAS = re.compile(
    r"\blocalparam\s+(?:\w+\s+)?(?P<name>\w+)\s*=\s*(?P<ref>\w+)\s*;",
    re.IGNORECASE,
)
_LOCALPARAM_ADD1 = re.compile(
    r"\blocalparam\s+(?:\w+\s+)?(?P<name>\w+)\s*=\s*(?P<ref>\w+)\s*\+\s*1\s*;",
    re.IGNORECASE,
)
_LOCALPARAM_SUB1 = re.compile(
    r"\blocalparam\s+(?:\w+\s+)?(?P<name>\w+)\s*=\s*(?P<ref>\w+)\s*-\s*1\s*;",
    re.IGNORECASE,
)
_PARAM_DIRECT_INT = re.compile(
    r"\bparameter\s+(?:\w+\s+)?(?P<name>\w+)\s*=\s*(?P<val>\d+)\s*;",
    re.IGNORECASE,
)


def detect_top_module_from_top_file(rtl_files: List[str], configured_top: str = "") -> str:
    if not rtl_files:
        return configured_top or "top"

    top_file = Path(rtl_files[0])
    stem = top_file.stem
    if not top_file.exists():
        return configured_top or stem or "top"

    text = top_file.read_text(encoding="utf-8", errors="ignore")
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.DOTALL)
    text = re.sub(r"//[^\n]*", "", text)
    module_set = set(re.findall(r"\bmodule\s+([A-Za-z_]\w*)\b", text))

    if stem in module_set:
        return stem
    if configured_top and configured_top in module_set:
        return configured_top
    return configured_top or stem or "top"


def build_param_lut(rtl_files: List[str]) -> Dict[str, int]:
    text_parts: List[str] = []
    for rtl_path in rtl_files:
        p = Path(rtl_path)
        if not p.exists():
            continue
        try:
            text_parts.append(p.read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            continue

    text = "\n".join(text_parts)
    if not text:
        return {}

    resolved: Dict[str, int] = {}
    for m in _PARAM_DIRECT_INT.finditer(text):
        resolved[m.group("name")] = int(m.group("val"))
    for m in _LOCALPARAM_DIRECT_INT.finditer(text):
        resolved[m.group("name")] = int(m.group("val"))

    for _ in range(50):
        changed = False
        for m in _LOCALPARAM_ALIAS.finditer(text):
            name, ref = m.group("name"), m.group("ref")
            if name not in resolved and ref in resolved:
                resolved[name] = resolved[ref]
                changed = True
        for m in _LOCALPARAM_ADD1.finditer(text):
            name, ref = m.group("name"), m.group("ref")
            if name not in resolved and ref in resolved:
                resolved[name] = resolved[ref] + 1
                changed = True
        for m in _LOCALPARAM_SUB1.finditer(text):
            name, ref = m.group("name"), m.group("ref")
            if name not in resolved and ref in resolved:
                resolved[name] = resolved[ref] - 1
                changed = True
        if not changed:
            break

    return resolved


def _eval_width_expression(expr_str: str, param_lut: Dict[str, int]) -> Optional[int]:
    if not expr_str or not expr_str.strip():
        return None
    s = expr_str.strip()
    for name in sorted(param_lut.keys(), key=len, reverse=True):
        s = re.sub(rf"\b{re.escape(name)}\b", str(param_lut[name]), s)
    if not re.match(r"^[\d\s+\-*/().]+$", s):
        return None
    try:
        return int(eval(s.replace("/", "//")))
    except Exception:
        return None


def extract_structural_metadata(rtl_files: List[str], top: str) -> dict:
    module_re = re.compile(r"\bmodule\s+(\w+)")
    width_re = re.compile(r"(\d+)\s*:\s*(\d+)")
    func_task_start_re = re.compile(r"\b(function|task)\b")
    func_task_end_re = re.compile(r"\b(endfunction|endtask)\b")
    decl_re = re.compile(
        r"\b(input|output|inout|wire|reg)\b"
        r"\s*(?:(?:reg|wire|signed|unsigned)\s+)*"
        r"(?:\[([^\]]+)\])?"
        r"\s+"
        r"([\w][\w,\s]*)"
        r"\s*;"
    )

    modules: List[dict] = []
    direction_priority = {"input": 3, "output": 3, "inout": 3, "reg": 2, "wire": 1}
    signal_map: Dict[tuple, dict] = {}
    param_lut = build_param_lut(rtl_files)

    def record_signal(
        mod: str,
        name: str,
        direction: str,
        width: int,
        packed_range: str | None = None,
    ) -> None:
        key = (mod, name)
        priority = direction_priority.get(direction, 0)
        pr = packed_range.strip() if packed_range and packed_range.strip() else None

        if key in signal_map:
            existing = signal_map[key]
            existing_priority = direction_priority.get(existing["direction"], 0)
            if priority > existing_priority:
                entry = {
                    "signal_id": f"{mod}.{name}",
                    "module": mod,
                    "name": name,
                    "direction": direction,
                    "width": max(width, existing["width"]),
                }
                if pr or existing.get("packed_range"):
                    entry["packed_range"] = pr or existing.get("packed_range")
                signal_map[key] = entry
            elif priority == existing_priority:
                if width > existing["width"]:
                    signal_map[key]["width"] = width
                if pr and not signal_map[key].get("packed_range"):
                    signal_map[key]["packed_range"] = pr
            return

        entry = {
            "signal_id": f"{mod}.{name}",
            "module": mod,
            "name": name,
            "direction": direction,
            "width": width,
        }
        if pr:
            entry["packed_range"] = pr
        signal_map[key] = entry

    def calc_width(width_str: str | None) -> int:
        if not width_str:
            return 1
        if ":" in width_str and param_lut:
            msb_expr, lsb_expr = [part.strip() for part in width_str.split(":", 1)]
            msb_val = _eval_width_expression(msb_expr, param_lut)
            lsb_val = _eval_width_expression(lsb_expr, param_lut)
            if msb_val is not None and lsb_val is not None:
                return abs(msb_val - lsb_val) + 1
        wm = width_re.search(width_str)
        if wm:
            if param_lut and re.search(r"[A-Za-z_]\w*", width_str):
                return 1
            hi, lo = int(wm.group(1)), int(wm.group(2))
            return abs(hi - lo) + 1
        return 1

    def normalize_line(line: str) -> str:
        line = re.sub(r"\s*=\s*[^,;)]+", "", line)
        line = re.sub(r"[,)]+\s*;?\s*$", ";", line.strip())
        if line and not line.endswith(";"):
            line += ";"
        return line

    def parse_declaration(norm_line: str, current_module: str) -> None:
        dm = decl_re.search(norm_line)
        if not dm:
            return

        direction = dm.group(1)
        width_str = dm.group(2)
        names_str = dm.group(3)
        width = calc_width(width_str)
        packed_range = width_str.strip() if width_str else None

        for name in names_str.split(","):
            name = name.strip()
            if name and re.match(r"^\w+$", name):
                record_signal(current_module, name, direction, width, packed_range)

    for rf in rtl_files:
        path = Path(rf)
        if not path.exists():
            print(f"[!] RTL file not found: {rf}")
            continue

        raw = path.read_text(encoding="utf-8", errors="ignore")
        raw = re.sub(r"/\*.*?\*/", " ", raw, flags=re.DOTALL)
        raw = re.sub(r"//[^\n]*", "", raw)

        current_module = None
        in_func_task = 0
        for line_no, line in enumerate(raw.splitlines(), start=1):
            stripped = line.strip()
            if not stripped:
                continue

            mm = module_re.search(stripped)
            if mm:
                current_module = mm.group(1)
                modules.append({"module": current_module, "file": rf, "line": line_no})
                in_func_task = 0

                paren_match = re.search(r"\((.*)\)", stripped, re.DOTALL)
                if paren_match:
                    port_body = paren_match.group(1)
                    if re.search(r"\b(input|output|inout)\b", port_body):
                        for fragment in port_body.split(","):
                            fragment = fragment.strip()
                            if fragment:
                                parse_declaration(normalize_line(fragment), current_module)
                continue

            if not current_module:
                continue

            if func_task_start_re.search(stripped):
                in_func_task += 1
            if func_task_end_re.search(stripped):
                in_func_task = max(0, in_func_task - 1)
                continue
            if in_func_task > 0:
                continue

            if stripped.startswith("endmodule"):
                current_module = None
                continue

            parse_declaration(normalize_line(stripped), current_module)

    return {
        "top_module": top,
        "modules": modules,
        "signals": sorted(signal_map.values(), key=lambda s: s["signal_id"]),
    }
