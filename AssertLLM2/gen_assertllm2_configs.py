#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Generate design configs for AssertLLM2 designs.
Layout: <root>/<category>/<design>/ with top RTL + spec.md + include/.
"""

from __future__ import annotations

import argparse
import json
import os
import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

HDL_EXTS = [".v", ".sv", ".vhd", ".vhdl"]
VERILOG_EXTS = {".v", ".sv"}
VHDL_EXTS = {".vhd", ".vhdl"}


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""


def _strip_sv_comments(s: str) -> str:
    s = re.sub(r"/\*.*?\*/", "", s, flags=re.DOTALL)
    s = re.sub(r"//.*?$", "", s, flags=re.MULTILINE)
    return s


def _strip_vhdl_comments(s: str) -> str:
    return re.sub(r"--.*?$", "", s, flags=re.MULTILINE)


def _strip_verilog_ifdef_regions(s: str) -> str:
    """
    Drop lines inside `ifdef / `ifndef ... `endif (nested blocks supported).
    Port names and body declarations under conditional compilation are ignored
    for clock/reset heuristics when macros are undefined in plain-text parsing.
    """
    lines = s.splitlines()
    out: List[str] = []
    depth = 0
    re_ifdef = re.compile(r"^\s*`(?:ifdef|ifndef)\b", re.IGNORECASE)
    re_elsif = re.compile(r"^\s*`elsif\b", re.IGNORECASE)
    re_else = re.compile(r"^\s*`else\b", re.IGNORECASE)
    re_endif = re.compile(r"^\s*`endif\b", re.IGNORECASE)

    for line in lines:
        if depth == 0:
            if re_ifdef.search(line):
                depth = 1
                continue
            if re_elsif.search(line) or re_else.search(line) or re_endif.search(line):
                continue
            out.append(line)
        else:
            if re_endif.search(line):
                depth -= 1
                continue
            if re_ifdef.search(line):
                depth += 1
                continue
            continue

    return "\n".join(out)


def _find_design_dirs(root: Path) -> List[Path]:
    design_dirs: List[Path] = []
    category_dirs = sorted([p for p in root.iterdir() if p.is_dir()], key=lambda x: str(x))
    for category_dir in category_dirs:
        design_dirs.extend(sorted([p for p in category_dir.iterdir() if p.is_dir()], key=lambda x: str(x)))
    return design_dirs


def _list_top_level_rtl_files(design_dir: Path) -> List[Path]:
    files: List[Path] = []
    for ext in HDL_EXTS:
        files.extend([p for p in design_dir.glob(f"*{ext}") if p.is_file()])
    return sorted(files, key=lambda x: str(x))


def _require_single_top_rtl_file(design_dir: Path) -> Path:
    rtl_files = _list_top_level_rtl_files(design_dir)
    if not rtl_files:
        raise ValueError(f"no top-level RTL found in {design_dir}")
    if len(rtl_files) > 1:
        names = ", ".join(p.name for p in rtl_files)
        raise ValueError(f"multiple top-level RTL files in {design_dir}: {names}")
    return rtl_files[0]


def _require_spec_md_file(design_dir: Path) -> Path:
    spec_path = design_dir / "spec.md"
    if not spec_path.is_file():
        raise ValueError(f"missing required spec file: {spec_path}")
    return spec_path


def _slugify(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", name.strip().lower()).strip("_")
    if not slug:
        raise ValueError(f"cannot build slug from name: {name!r}")
    return slug


def _collect_include_compile_units(design_dir: Path) -> Tuple[List[str], List[str]]:
    include_dir = design_dir / "include"
    if not include_dir.is_dir():
        return [], []

    include_files: List[Path] = []
    for ext in HDL_EXTS:
        include_files.extend([p for p in include_dir.rglob(f"*{ext}") if p.is_file()])
    include_files = sorted(include_files, key=lambda x: str(x))

    # Keep include root + all subdirs so `include lookups remain robust.
    incdirs = sorted([p for p in include_dir.rglob("*") if p.is_dir()] + [include_dir], key=lambda x: str(x))

    unique_files: List[str] = []
    seen_files: Set[str] = set()
    for p in include_files:
        rp = str(p)
        if rp in seen_files:
            continue
        seen_files.add(rp)
        unique_files.append(rp)

    unique_incdirs: List[str] = []
    seen_dirs: Set[str] = set()
    for p in incdirs:
        rp = str(p)
        if rp in seen_dirs:
            continue
        seen_dirs.add(rp)
        unique_incdirs.append(rp)

    return unique_files, unique_incdirs


def _extract_verilog_module_text(
    verilog_text: str, prefer_module: Optional[str]
) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    """
    Return (module_name, ports_block_text, module_body_text).
    """
    s = _strip_sv_comments(verilog_text)

    def find_module(name: str) -> Optional[re.Match]:
        return re.search(
            rf"\bmodule\s+{re.escape(name)}\s*(?:#\s*\(.*?\)\s*)?\(\s*(.*?)\s*\)\s*;\s*(.*?)\bendmodule\b",
            s,
            flags=re.DOTALL,
        )

    if prefer_module:
        m = find_module(prefer_module)
        if m:
            return prefer_module, m.group(1), m.group(2)
        # Caller may try another name (e.g. file stem); do not pick the file's first module here.
        return None, None, None

    m = re.search(
        r"\bmodule\s+([A-Za-z_]\w*)\s*(?:#\s*\(.*?\)\s*)?\(\s*(.*?)\s*\)\s*;\s*(.*?)\bendmodule\b",
        s,
        flags=re.DOTALL,
    )
    if not m:
        return None, None, None
    return m.group(1), m.group(2), m.group(3)


def _split_ports_top_level(ports_block: str) -> List[str]:
    b = re.sub(r"\(\*.*?\*\)", "", ports_block, flags=re.DOTALL)
    b = _strip_verilog_ifdef_regions(b)
    b = re.sub(r"^\s*`.*$", "", b, flags=re.MULTILINE)
    return [p.strip() for p in b.split(",") if p.strip()]


def _parse_ansi_ports(parts: List[str]) -> List[Dict[str, str]]:
    ports: List[Dict[str, str]] = []
    dir_pat = re.compile(r"^\s*(input|output|inout)\b", flags=re.IGNORECASE)
    for p in parts:
        p = re.sub(r"=\s*.*$", "", p).strip()
        m = dir_pat.search(p)
        direction = m.group(1).lower() if m else "unknown"

        tokens = re.findall(r"[A-Za-z_]\w*", p)
        if not tokens:
            continue
        name = tokens[-1]

        if name.lower() in {
            "input",
            "output",
            "inout",
            "wire",
            "reg",
            "logic",
            "signed",
            "unsigned",
            "tri",
            "wand",
            "wor",
            "integer",
            "parameter",
            "localparam",
        }:
            continue
        ports.append({"name": name, "dir": direction})

    seen = set()
    out = []
    for p in ports:
        if p["name"] in seen:
            continue
        seen.add(p["name"])
        out.append(p)
    return out


def _detect_ansi_style(parts: List[str]) -> bool:
    for p in parts:
        if re.search(r"^\s*(input|output|inout)\b", p, flags=re.IGNORECASE):
            return True
    return False


def _parse_input_decls_from_body(module_body: str) -> Set[str]:
    inputs: Set[str] = set()
    if not module_body:
        return inputs

    body = _strip_verilog_ifdef_regions(module_body)
    for m in re.finditer(r"\binput\b\s+(.*?);", body, flags=re.DOTALL | re.IGNORECASE):
        stmt = m.group(1)
        toks = re.findall(r"[A-Za-z_]\w*", stmt)
        for t in toks:
            if t.lower() in {
                "wire",
                "reg",
                "logic",
                "signed",
                "unsigned",
                "tri",
                "wand",
                "wor",
                "integer",
            }:
                continue
            inputs.add(t)
    return inputs


def _is_clock_name(name: str) -> bool:
    nl = name.lower()
    return ("clk" in nl) or ("clock" in nl)


def _pick_reset_from_names(names: List[str]) -> Optional[str]:
    lower = [x.lower() for x in names]
    for target in ["rst_n", "reset_n", "rstn", "resetn"]:
        if target in lower:
            return names[lower.index(target)]
    for target in ["rst", "reset"]:
        if target in lower:
            return names[lower.index(target)]

    cands = [names[i] for i, pl in enumerate(lower) if ("rst" in pl or "reset" in pl)]
    if cands:

        def score(name: str) -> Tuple[int, int, str]:
            nl = name.lower()
            active_low = 0 if (
                nl.endswith("_n") or "rst_n" in nl or "reset_n" in nl or nl.endswith("n")
            ) else 1
            return (active_low, len(name), name)

        return sorted(cands, key=score)[0]

    return None


def _extract_clock_reset_from_verilog(
    top_v_path: Path,
    prefer_module: str,
    default_clk: str,
    default_rst: str,
) -> Tuple[List[Dict[str, str]], str]:
    v_text = _read_text(top_v_path)
    _, ports_block, body = _extract_verilog_module_text(v_text, prefer_module)
    if not ports_block:
        clocks = [{"signal": default_clk}] if default_clk else []
        return clocks, default_rst

    parts = _split_ports_top_level(ports_block)
    is_ansi = _detect_ansi_style(parts)
    ansi_ports = _parse_ansi_ports(parts) if is_ansi else []

    clocks: List[str] = []
    if is_ansi:
        for p in ansi_ports:
            if p["dir"] == "input" and _is_clock_name(p["name"]):
                clocks.append(p["name"])
    else:
        header_names: List[str] = []
        for item in parts:
            toks = re.findall(r"[A-Za-z_]\w*", re.sub(r"=\s*.*$", "", item).strip())
            if toks:
                header_names.append(toks[-1])
        input_set = _parse_input_decls_from_body(body or "")
        for n in header_names:
            if n in input_set and _is_clock_name(n):
                clocks.append(n)

    seen = set()
    clocks_out: List[Dict[str, str]] = []
    for c in clocks:
        if c in seen:
            continue
        seen.add(c)
        clocks_out.append({"signal": c})
    if not clocks_out and default_clk:
        clocks_out = [{"signal": default_clk}]

    reset = ""
    if is_ansi:
        input_names = [p["name"] for p in ansi_ports if p["dir"] == "input"]
        reset = _pick_reset_from_names(input_names) or ""
        if not reset:
            all_names = [p["name"] for p in ansi_ports]
            reset = _pick_reset_from_names(all_names) or ""
    else:
        header_names = []
        for item in parts:
            toks = re.findall(r"[A-Za-z_]\w*", re.sub(r"=\s*.*$", "", item).strip())
            if toks:
                header_names.append(toks[-1])
        input_set = _parse_input_decls_from_body(body or "")
        input_names = [n for n in header_names if n in input_set]
        reset = _pick_reset_from_names(input_names) or _pick_reset_from_names(header_names) or ""

    if not reset:
        reset = default_rst
    return clocks_out, reset


def _extract_vhdl_entity_name(vhdl_text: str, prefer_entity: Optional[str]) -> Optional[str]:
    s = _strip_vhdl_comments(vhdl_text)

    if prefer_entity:
        m = re.search(
            rf"\bentity\s+{re.escape(prefer_entity)}\s+is\b",
            s,
            flags=re.IGNORECASE,
        )
        if m:
            return prefer_entity

    m = re.search(r"\bentity\s+([A-Za-z_]\w*)\s+is\b", s, flags=re.IGNORECASE)
    return m.group(1) if m else None


def _extract_vhdl_ports(vhdl_text: str, entity_name: str) -> List[Dict[str, str]]:
    s = _strip_vhdl_comments(vhdl_text)
    entity_match = re.search(
        rf"\bentity\s+{re.escape(entity_name)}\s+is\b(.*?)\bend\b",
        s,
        flags=re.IGNORECASE | re.DOTALL,
    )
    if not entity_match:
        return []

    entity_body = entity_match.group(1)
    port_match = re.search(
        r"\bport\s*\((.*?)\)\s*;",
        entity_body,
        flags=re.IGNORECASE | re.DOTALL,
    )
    if not port_match:
        return []

    port_block = port_match.group(1)
    ports: List[Dict[str, str]] = []
    for stmt in port_block.split(";"):
        stmt = stmt.strip()
        if not stmt:
            continue
        m = re.match(
            r"(?P<names>[A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*:\s*(?P<dir>inout|in|out|buffer)\b",
            stmt,
            flags=re.IGNORECASE,
        )
        if not m:
            continue
        direction = m.group("dir").lower()
        names = [n.strip() for n in m.group("names").split(",") if n.strip()]
        for name in names:
            ports.append({"name": name, "dir": direction})

    seen = set()
    out = []
    for p in ports:
        if p["name"] in seen:
            continue
        seen.add(p["name"])
        out.append(p)
    return out


def _extract_clock_reset_from_vhdl(
    top_vhd_path: Path,
    prefer_entity: str,
    default_clk: str,
    default_rst: str,
) -> Tuple[List[Dict[str, str]], str]:
    vhd_text = _read_text(top_vhd_path)
    entity_name = _extract_vhdl_entity_name(vhd_text, prefer_entity)
    if not entity_name:
        clocks = [{"signal": default_clk}] if default_clk else []
        return clocks, default_rst

    ports = _extract_vhdl_ports(vhd_text, entity_name)
    input_names = [p["name"] for p in ports if p["dir"] == "in"]
    all_names = [p["name"] for p in ports]

    clocks_out = [{"signal": n} for n in input_names if _is_clock_name(n)]
    if not clocks_out and default_clk:
        clocks_out = [{"signal": default_clk}]

    reset = _pick_reset_from_names(input_names) or _pick_reset_from_names(all_names) or ""
    if not reset:
        reset = default_rst

    return clocks_out, reset


def _detect_top_module(top_path: Path, design_name: str) -> str:
    suffix = top_path.suffix.lower()
    text = _read_text(top_path)
    if suffix in VERILOG_EXTS:
        module_name, _, _ = _extract_verilog_module_text(text, design_name)
        if module_name:
            return module_name
        module_name, _, _ = _extract_verilog_module_text(text, top_path.stem)
        if module_name:
            return module_name
    elif suffix in VHDL_EXTS:
        entity_name = _extract_vhdl_entity_name(text, top_path.stem)
        if entity_name:
            return entity_name
        entity_name = _extract_vhdl_entity_name(text, design_name)
        if entity_name:
            return entity_name
    return top_path.stem


def _detect_clock_reset(
    top_path: Path,
    top_module: str,
    default_clk: str,
    default_rst: str,
) -> Tuple[List[Dict[str, str]], str]:
    suffix = top_path.suffix.lower()
    if suffix in VERILOG_EXTS:
        return _extract_clock_reset_from_verilog(
            top_v_path=top_path,
            prefer_module=top_module,
            default_clk=default_clk,
            default_rst=default_rst,
        )
    if suffix in VHDL_EXTS:
        return _extract_clock_reset_from_vhdl(
            top_vhd_path=top_path,
            prefer_entity=top_module,
            default_clk=default_clk,
            default_rst=default_rst,
        )
    clocks = [{"signal": default_clk}] if default_clk else []
    return clocks, default_rst


def _load_jg_bbox_modules(design_dir: Path) -> List[str]:
    jg_bbox_path = design_dir / "jg_bbox.json"
    if not jg_bbox_path.is_file():
        return []

    payload = json.loads(jg_bbox_path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise TypeError(f"{jg_bbox_path} must be a JSON object")
    if "blackbox_modules" not in payload:
        raise KeyError(f"{jg_bbox_path} missing required key: blackbox_modules")

    raw_modules = payload["blackbox_modules"]
    if not isinstance(raw_modules, list):
        raise TypeError(f"{jg_bbox_path}:blackbox_modules must be a list")

    modules: List[str] = []
    seen: Set[str] = set()
    for idx, item in enumerate(raw_modules):
        if not isinstance(item, str):
            raise TypeError(f"{jg_bbox_path}:blackbox_modules[{idx}] must be a string")
        name = item.strip()
        if not name:
            raise ValueError(f"{jg_bbox_path}:blackbox_modules[{idx}] must not be empty")
        if name in seen:
            continue
        seen.add(name)
        modules.append(name)

    return modules


def build_configs(
    root: Path,
    default_clk: str,
    default_rst: str,
    output_dir: Path,
) -> Dict[str, Dict]:
    all_cfg: Dict[str, Dict] = {}
    base_dir = Path.cwd().resolve()

    def rel(path: Path) -> str:
        return os.path.relpath(path.resolve(), base_dir)

    output_dir_str = rel(output_dir) if output_dir.is_absolute() else str(output_dir)

    for design_dir in _find_design_dirs(root):
        category_name = design_dir.parent.name
        design_name = design_dir.name

        top_path = _require_single_top_rtl_file(design_dir)
        spec_path = _require_spec_md_file(design_dir)

        top_module = _detect_top_module(top_path, design_name)
        include_files, incdirs = _collect_include_compile_units(design_dir)

        filelist = [rel(top_path)] + [rel(Path(p)) for p in include_files]
        seen = set()
        filelist = [f for f in filelist if not (f in seen or seen.add(f))]
        incdirs = [rel(Path(p)) for p in incdirs]

        clocks, reset = _detect_clock_reset(
            top_path=top_path,
            top_module=top_module,
            default_clk=default_clk,
            default_rst=default_rst,
        )

        key = f"assertllm2/{_slugify(category_name)}/{_slugify(design_name)}"
        if key in all_cfg:
            raise ValueError(
                f"config key collision: {key} for {design_dir} and {all_cfg[key]['_source_design_dir']}"
            )

        bbox_modules = _load_jg_bbox_modules(design_dir)

        entry: Dict[str, Dict] = {
            "spec_file": [rel(spec_path)],
            "rtl": {
                "filelist": filelist,
                "incdir": incdirs,
                "top_module": top_module,
            },
            "clock_reset": {
                "clocks": clocks,
                "reset": reset,
            },
            "output_dir": output_dir_str,
            "_source_design_dir": rel(design_dir),
        }
        if bbox_modules:
            entry["formal"] = {"bbox_modules": bbox_modules}

        all_cfg[key] = entry

    for entry in all_cfg.values():
        entry.pop("_source_design_dir", None)

    return all_cfg


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate design configs for AssertLLM2 designs")
    parser.add_argument(
        "--design-root",
        default="../designs",
        help="Root directory of AssertLLM2 designs",
    )
    parser.add_argument(
        "--out",
        default="configs/assertllm2_design_configs.json",
        help="Output JSON path",
    )
    parser.add_argument(
        "--default-clock",
        default="",
        help="Fallback clock if none is detected from top ports",
    )
    parser.add_argument(
        "--default-reset",
        default="",
        help="Fallback reset if none is detected from top ports",
    )
    parser.add_argument(
        "--output-dir",
        default="out",
        help="Per-design output_dir to write into generated entries",
    )
    args = parser.parse_args()

    root = Path(args.design_root).expanduser()
    out_path = Path(args.out).expanduser()
    output_dir = Path(args.output_dir).expanduser()

    if not root.is_dir():
        raise NotADirectoryError(f"AssertLLM2 design root not found: {root}")

    cfgs = build_configs(
        root=root,
        default_clk=args.default_clock,
        default_rst=args.default_reset,
        output_dir=output_dir,
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(cfgs, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"Wrote {len(cfgs)} AssertLLM2 design configs to: {out_path}")


if __name__ == "__main__":
    main()
