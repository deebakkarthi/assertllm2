import re
from collections import defaultdict, deque
from dataclasses import dataclass
from pathlib import Path


_IDENT_RE = re.compile(r"[A-Za-z_]\w*")
_MODULE_BLOCK_RE = re.compile(r"\bmodule\s+([A-Za-z_]\w*)\b(.*?)\bendmodule\b", re.DOTALL)
_PORT_DIRS = {"input", "output", "inout"}
_QUALIFIER_TOKENS = {
    "input",
    "output",
    "inout",
    "wire",
    "reg",
    "logic",
    "signed",
    "unsigned",
    "var",
    "const",
    "tri",
    "uwire",
    "supply0",
    "supply1",
}
_IF_COND_RE = re.compile(r"\bif\s*\(([^)]*)\)", re.IGNORECASE)
_CASE_EXPR_RE = re.compile(r"\bcase(?:x|z)?\s*\(([^)]*)\)", re.IGNORECASE)
_ASSIGN_LINE_RE = re.compile(
    r"^\s*([A-Za-z_]\w*)(?:\[[^\]]+\])?\s*(<=|=)\s*(.+?)\s*;?\s*$"
)
_RESET_HINTS = ("rst", "reset")
_ENABLE_HINTS = ("en", "enable", "we", "write", "load", "ld", "update")
_CLEAR_HINTS = ("clr", "clear")
_SET_HINTS = ("set",)
_SHIFT_HINTS = ("shift", "shf")
_STATE_HINTS = ("state", "fsm")
_HANDSHAKE_HINTS = ("valid", "ready", "req", "ack", "grant", "done", "start")


@dataclass
class InstanceDecl:
    module_type: str
    instance_name: str
    connections: dict[str, str]


@dataclass
class ModuleDef:
    module_type: str
    file: str
    port_order: list[str]
    signal_directions: dict[str, str]
    instances: list[InstanceDecl]


def _strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.DOTALL)
    text = re.sub(r"//[^\n]*", "", text)
    return text


def _strip_preprocessor_conditionals(text: str) -> str:
    """
    Remove all content inside `ifdef/`ifndef ... `endif blocks.
    This intentionally drops every branch (`elsif/`else) so optional
    signals are not considered for wrapper/bind generation.
    """
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    cond_depth = 0

    for line in lines:
        stripped = line.lstrip()
        directive_match = re.match(r"`(ifdef|ifndef|elsif|else|endif)\b", stripped)
        if not directive_match:
            if cond_depth == 0:
                out.append(line)
            continue

        directive = directive_match.group(1)
        if directive in {"ifdef", "ifndef"}:
            cond_depth += 1
            continue
        if directive == "endif":
            cond_depth = max(0, cond_depth - 1)
            continue
        # `elsif / `else inside conditional blocks are ignored.
        continue

    return "".join(out)


def _skip_ws(text: str, idx: int) -> int:
    n = len(text)
    while idx < n and text[idx].isspace():
        idx += 1
    return idx


def _find_matching(text: str, start: int, open_ch: str = "(", close_ch: str = ")") -> int:
    if start >= len(text) or text[start] != open_ch:
        return -1
    depth = 0
    for i in range(start, len(text)):
        ch = text[i]
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i
    return -1


def _split_top_level_csv(text: str) -> list[str]:
    parts = []
    start = 0
    p_depth = b_depth = c_depth = 0
    for idx, ch in enumerate(text):
        if ch == "(":
            p_depth += 1
        elif ch == ")":
            p_depth = max(0, p_depth - 1)
        elif ch == "[":
            b_depth += 1
        elif ch == "]":
            b_depth = max(0, b_depth - 1)
        elif ch == "{":
            c_depth += 1
        elif ch == "}":
            c_depth = max(0, c_depth - 1)
        elif ch == "," and p_depth == 0 and b_depth == 0 and c_depth == 0:
            part = text[start:idx].strip()
            if part:
                parts.append(part)
            start = idx + 1
    tail = text[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def _normalize_token(name: str) -> str:
    out = re.sub(r"[^A-Za-z0-9_]", "_", name or "")
    out = re.sub(r"_+", "_", out).strip("_")
    return out or "unnamed"


def _parse_header_ports(port_text: str) -> tuple[list[str], dict[str, str]]:
    port_order: list[str] = []
    directions: dict[str, str] = {}

    for item in _split_top_level_csv(port_text):
        cleaned = re.sub(r"\(\*.*?\*\)", " ", item, flags=re.DOTALL)
        cleaned = re.sub(r"=\s*.*$", "", cleaned).strip()
        if not cleaned:
            continue

        dir_match = re.match(r"\s*(input|output|inout)\b", cleaned, flags=re.IGNORECASE)
        direction = dir_match.group(1).lower() if dir_match else None

        name_match = re.search(r"([A-Za-z_]\w*)\s*(?:\[[^\]]+\]\s*)*$", cleaned)
        if not name_match:
            continue

        port_name = name_match.group(1)
        if port_name.lower() in _QUALIFIER_TOKENS:
            continue
        if port_name not in port_order:
            port_order.append(port_name)
        if direction:
            directions[port_name] = direction

    return port_order, directions


def _parse_module_header(block_text: str, module_name: str) -> tuple[list[str], dict[str, str], int]:
    mm = re.search(rf"\bmodule\s+{re.escape(module_name)}\b", block_text)
    if not mm:
        return [], {}, 0

    idx = _skip_ws(block_text, mm.end())
    if idx < len(block_text) and block_text[idx] == "#":
        idx = _skip_ws(block_text, idx + 1)
        if idx < len(block_text) and block_text[idx] == "(":
            end_param = _find_matching(block_text, idx, "(", ")")
            if end_param >= 0:
                idx = _skip_ws(block_text, end_param + 1)

    if idx >= len(block_text) or block_text[idx] != "(":
        return [], {}, 0

    end_ports = _find_matching(block_text, idx, "(", ")")
    if end_ports < 0:
        return [], {}, 0

    port_text = block_text[idx + 1 : end_ports]
    header_end = block_text.find(";", end_ports)
    if header_end < 0:
        header_end = end_ports

    port_order, port_dirs = _parse_header_ports(port_text)
    return port_order, port_dirs, header_end + 1


def _merge_direction(existing: str | None, new_dir: str) -> str:
    if existing in _PORT_DIRS:
        return existing
    if new_dir in _PORT_DIRS:
        return new_dir
    return existing or new_dir


def _parse_signal_directions(block_text: str, initial_dirs: dict[str, str]) -> dict[str, str]:
    signal_dirs = dict(initial_dirs)
    decl_re = re.compile(
        r"\b(input|output|inout|wire|reg|logic)\b\s*(?:(?:reg|wire|logic|signed|unsigned)\s+)*(?:\[[^\]]+\]\s*)?([^;]+);",
        re.IGNORECASE,
    )
    for match in decl_re.finditer(block_text):
        direction = match.group(1).lower()
        decl_body = match.group(2)
        for part in _split_top_level_csv(decl_body):
            leaf = re.sub(r"=\s*.*$", "", part).strip()
            if not leaf:
                continue
            tokens = [t for t in _IDENT_RE.findall(leaf) if t.lower() not in _QUALIFIER_TOKENS]
            if not tokens:
                continue
            signal = tokens[0]
            signal_dirs[signal] = _merge_direction(signal_dirs.get(signal), direction)
    return signal_dirs


def _parse_connection_map(conn_text: str, port_order: list[str]) -> dict[str, str]:
    conn_map: dict[str, str] = {}
    parts = _split_top_level_csv(conn_text)
    if not parts:
        return conn_map

    named_mode = any(p.strip().startswith(".") for p in parts)
    if named_mode:
        named_re = re.compile(r"^\.\s*([A-Za-z_]\w*)\s*\((.*)\)\s*$", re.DOTALL)
        for part in parts:
            stripped = part.strip()
            if not stripped:
                continue
            match = named_re.match(stripped)
            if not match:
                continue
            port = match.group(1).strip()
            expr = match.group(2).strip()
            if expr:
                conn_map[port] = expr
        return conn_map

    for idx, expr in enumerate(parts):
        if idx >= len(port_order):
            break
        value = expr.strip()
        if value:
            conn_map[port_order[idx]] = value
    return conn_map


def _parse_instances(module_body: str, module_types: set[str], module_port_orders: dict[str, list[str]]) -> list[InstanceDecl]:
    instances: list[InstanceDecl] = []
    idx = 0

    while idx < len(module_body):
        match = _IDENT_RE.search(module_body, idx)
        if not match:
            break

        cand_type = match.group(0)
        if cand_type not in module_types:
            idx = match.end()
            continue

        cursor = _skip_ws(module_body, match.end())
        if cursor < len(module_body) and module_body[cursor] == "#":
            cursor = _skip_ws(module_body, cursor + 1)
            if cursor >= len(module_body) or module_body[cursor] != "(":
                idx = match.end()
                continue
            end_param = _find_matching(module_body, cursor, "(", ")")
            if end_param < 0:
                idx = match.end()
                continue
            cursor = _skip_ws(module_body, end_param + 1)

        stmt_cursor = cursor
        parsed_any = False
        parsed_ok = False

        # Support both single-instance and comma-separated multi-instance forms:
        #   foo u0 (...);
        #   foo u0 (...), u1 (...), u2 (...);
        while True:
            inst_match = re.match(r"[A-Za-z_]\w*", module_body[stmt_cursor:])
            if not inst_match:
                break

            inst_name = inst_match.group(0)
            stmt_cursor += len(inst_name)
            stmt_cursor = _skip_ws(module_body, stmt_cursor)

            # Optional unpacked dimensions after instance name, e.g. u[0:3](...)
            while stmt_cursor < len(module_body) and module_body[stmt_cursor] == "[":
                end_dim = _find_matching(module_body, stmt_cursor, "[", "]")
                if end_dim < 0:
                    break
                stmt_cursor = _skip_ws(module_body, end_dim + 1)

            if stmt_cursor >= len(module_body) or module_body[stmt_cursor] != "(":
                break

            end_conn = _find_matching(module_body, stmt_cursor, "(", ")")
            if end_conn < 0:
                break

            conn_text = module_body[stmt_cursor + 1 : end_conn]
            connections = _parse_connection_map(conn_text, module_port_orders.get(cand_type, []))
            instances.append(
                InstanceDecl(module_type=cand_type, instance_name=inst_name, connections=connections)
            )
            parsed_any = True

            stmt_cursor = _skip_ws(module_body, end_conn + 1)
            if stmt_cursor >= len(module_body):
                break
            sep = module_body[stmt_cursor]
            if sep == ",":
                stmt_cursor = _skip_ws(module_body, stmt_cursor + 1)
                continue
            if sep == ";":
                idx = stmt_cursor + 1
                parsed_ok = True
            break

        if parsed_ok:
            continue

        if parsed_any:
            idx = max(idx + 1, stmt_cursor)
        else:
            idx = match.end()

    return instances


def _build_module_db(rtl_files: list[str]) -> tuple[dict[str, ModuleDef], list[str]]:
    module_raw: list[tuple[str, str, str]] = []
    for rtl in rtl_files:
        path = Path(rtl)
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        stripped = _strip_comments(text)
        stripped = _strip_preprocessor_conditionals(stripped)
        for match in _MODULE_BLOCK_RE.finditer(stripped):
            mod_name = match.group(1)
            block = match.group(0)
            module_raw.append((mod_name, rtl, block))

    module_types = {m[0] for m in module_raw}
    module_defs: dict[str, ModuleDef] = {}
    module_port_orders: dict[str, list[str]] = {}

    for mod_name, file_path, block in module_raw:
        port_order, port_dirs, header_end = _parse_module_header(block, mod_name)
        body = block[header_end:] if header_end > 0 else block
        signal_dirs = _parse_signal_directions(body, port_dirs)
        module_defs[mod_name] = ModuleDef(
            module_type=mod_name,
            file=file_path,
            port_order=port_order,
            signal_directions=signal_dirs,
            instances=[],
        )
        module_port_orders[mod_name] = port_order
        module_defs[mod_name].instances = _parse_instances(body, module_types, module_port_orders)

    return module_defs, sorted(module_types)


def _build_structural_index(structural: dict) -> dict[str, dict[str, dict]]:
    module_signals: dict[str, dict[str, dict]] = defaultdict(dict)
    for sig in structural.get("signals", []):
        module = sig.get("module")
        name = sig.get("name")
        if not module or not name:
            continue
        entry = {
            "width": sig.get("width", 1),
            "direction": sig.get("direction", "wire"),
            "signal_id": sig.get("signal_id", f"{module}.{name}"),
        }
        pr = sig.get("packed_range")
        if pr:
            entry["packed_range"] = pr
        module_signals[module][name] = entry
    return dict(module_signals)


def _path_to_str(path: tuple[str, ...]) -> str:
    return ".".join(path)


def _simple_ref_name(expr: str) -> str | None:
    if not expr:
        return None
    s = expr.strip()
    while s.startswith("(") and s.endswith(")"):
        s = s[1:-1].strip()
    match = re.match(r"^([A-Za-z_]\w*)(?:\[[^\]]+\])?$", s)
    if not match:
        return None
    return match.group(1)


def _build_instance_nodes(top_module: str, module_defs: dict[str, ModuleDef]) -> list[dict]:
    nodes: list[dict] = []
    if top_module not in module_defs:
        return nodes

    def walk(module_type: str, path: tuple[str, ...], ancestors: tuple[str, ...]) -> None:
        module = module_defs.get(module_type)
        if not module:
            return
        sorted_instances = sorted(module.instances, key=lambda i: i.instance_name)
        for inst in sorted_instances:
            child_path = path + (inst.instance_name,)
            node = {
                "module_type": inst.module_type,
                "instance_path": child_path,
                "instance_path_str": _path_to_str(child_path),
                "parent_module_type": module_type,
                "parent_instance_path": path,
                "port_connections": dict(inst.connections),
            }
            nodes.append(node)
            if inst.module_type in ancestors:
                continue
            walk(inst.module_type, child_path, ancestors + (inst.module_type,))

    walk(top_module, tuple(), (top_module,))
    return nodes


def _format_width(width) -> str:
    if isinstance(width, int):
        return f"[{width - 1}:0] " if width > 1 else ""
    if isinstance(width, str) and width.strip():
        w = width.strip()
        if w.startswith("[") and w.endswith("]"):
            return f"{w} "
        return f"[{w}-1:0] "
    return ""


def format_width_decl(width, packed_range: str | None = None) -> str:
    """
    SystemVerilog packed dimension for wrapper/checker ports.

    If the RTL range text includes a Verilog macro (`` ` ``), emit it verbatim so
    tools see the same `` `define `` names as the RTL. Otherwise the range uses plain
    parameter/localparam identifiers (e.g. APP_AW-1:0): use the elaborated numeric
    ``width`` from structural metadata instead of echoing those names.
    """
    pr = packed_range.strip() if packed_range and packed_range.strip() else ""
    if pr and ":" in pr and "`" in pr:
        return f"[{pr}] "
    return _format_width(width)


def _entry_base_name(top_module: str, module_type: str, signal: str, path: tuple[str, ...]) -> str:
    signal_token = _normalize_token(signal)
    if module_type == top_module and len(path) == 0:
        return f"top_{signal_token}"
    module_token = _normalize_token(module_type)
    return f"{module_token}_{signal_token}"


def _rtl_port_names_ordered(
    structural: dict, module: str, module_defs: dict[str, ModuleDef]
) -> list[str]:
    """Port names for a module: input/output/inout only, header order when available."""
    names: set[str] = set()
    for sig in structural.get("signals", []):
        if sig.get("module") != module:
            continue
        direction = (sig.get("direction") or "").lower()
        if direction not in _PORT_DIRS:
            continue
        n = sig.get("name")
        if n:
            names.add(n)
    mod_def = module_defs.get(module)
    if mod_def:
        # Only keep ports confirmed by the RTL parser after conditional
        # preprocessor blocks are removed.
        declared_ports = {
            sig
            for sig, direction in mod_def.signal_directions.items()
            if direction in _PORT_DIRS
        }
        if declared_ports:
            names = names.intersection(declared_ports)
        if mod_def.port_order:
            ordered = [p for p in mod_def.port_order if p in names]
            extra = sorted(names.difference(ordered))
            return ordered + extra
    return sorted(names)


def direct_instance_types_under_top(rtl_files: list[str], top_module: str) -> list[str]:
    """Module types instantiated directly under top_module (one hierarchy level)."""
    module_defs, _ = _build_module_db(rtl_files)
    top = module_defs.get(top_module)
    if not top:
        return []
    return sorted({inst.module_type for inst in top.instances})


def extract_rtl_module_signal_targets(
    structural: dict,
    rtl_files: list[str],
    top_module: str,
) -> dict:
    """
    Build module_targets from RTL only: top-level ports plus ports of modules
    instantiated directly under the top module. Does not read the natural-language spec.
    """
    module_defs, _ = _build_module_db(rtl_files)
    signal_to_modules: dict[str, set[str]] = defaultdict(set)
    for sig in structural.get("signals", []):
        mod = sig.get("module")
        name = sig.get("name")
        if mod and name:
            signal_to_modules[name].add(mod)
    module_names = {s.get("module") for s in structural.get("signals", []) if s.get("module")}

    direct_types = direct_instance_types_under_top(rtl_files, top_module)
    explicit_submodules = list(direct_types)

    module_targets: list[dict] = []
    top_ports = _rtl_port_names_ordered(structural, top_module, module_defs)
    if top_ports:
        module_targets.append(
            {
                "module": top_module,
                "signals": top_ports,
                "signal_ids": [f"{top_module}.{s}" for s in top_ports],
                "source": "rtl_top_ports",
            }
        )

    for mod in direct_types:
        ports = _rtl_port_names_ordered(structural, mod, module_defs)
        if not ports:
            continue
        module_targets.append(
            {
                "module": mod,
                "signals": ports,
                "signal_ids": [f"{mod}.{s}" for s in ports],
                "source": "rtl_direct_submodule_ports",
            }
        )

    spec_signal_to_modules: dict[str, list[str]] = defaultdict(list)
    for target in module_targets:
        mod = target["module"]
        for sig in target["signals"]:
            spec_signal_to_modules[sig].append(mod)
    for sig, mods in list(spec_signal_to_modules.items()):
        spec_signal_to_modules[sig] = sorted(set(mods))
    ambiguous_spec_signals = sorted(
        sig for sig, mods in spec_signal_to_modules.items() if len(mods) > 1
    )

    selected_submodules = list(direct_types)

    return {
        "top_module": top_module,
        "has_explicit_submodules": bool(direct_types),
        "explicit_submodules": explicit_submodules,
        "selected_submodules": selected_submodules,
        "module_targets": module_targets,
        "spec_signal_to_modules": dict(spec_signal_to_modules),
        "fallback_applied": "rtl_hierarchy",
        "diagnostics": {
            "unmatched_module_mentions": [],
            "ambiguous_spec_signals": ambiguous_spec_signals,
            "module_signal_counts": {t["module"]: len(t["signals"]) for t in module_targets},
            "direct_instance_types_under_top": direct_types,
        },
        "structural_summary": {
            "modules": sorted(module_names),
            "module_count": len(module_names),
            "signal_count": len(structural.get("signals", [])),
            "signal_to_modules": {sig: sorted(mods) for sig, mods in signal_to_modules.items()},
        },
    }


def _name_has_hint(name: str, hints: tuple[str, ...]) -> bool:
    lowered = (name or "").lower()
    return any(h in lowered for h in hints)


def _normalize_expr(expr: str) -> str:
    return re.sub(r"\s+", " ", (expr or "").strip())


def _has_balanced_parens(expr: str) -> bool:
    depth = 0
    for ch in expr:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def _extract_module_blocks(rtl_files: list[str], target_module: str) -> list[str]:
    blocks: list[str] = []
    for rtl in rtl_files:
        path = Path(rtl)
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        stripped = _strip_comments(text)
        stripped = _strip_preprocessor_conditionals(stripped)
        for match in _MODULE_BLOCK_RE.finditer(stripped):
            if match.group(1) == target_module:
                blocks.append(match.group(0))
    return blocks


def _collect_module_semantic_roles(
    rtl_files: list[str],
    target_module: str,
    available_signals: set[str],
) -> tuple[dict[str, set[str]], list[dict]]:
    roles: dict[str, set[str]] = {
        "updated": set(),
        "guards": set(),
        "resets": set(),
        "enables": set(),
        "clears": set(),
        "sets": set(),
        "shifts": set(),
        "handshakes": set(),
        "states": set(),
    }
    helpers: list[dict] = []
    seen_helpers: set[tuple[str, str]] = set()

    def mark_signal(sig: str, *, in_guard: bool = False) -> None:
        if sig not in available_signals:
            return
        if in_guard:
            roles["guards"].add(sig)
        if _name_has_hint(sig, _RESET_HINTS):
            roles["resets"].add(sig)
        if _name_has_hint(sig, _ENABLE_HINTS):
            roles["enables"].add(sig)
        if _name_has_hint(sig, _CLEAR_HINTS):
            roles["clears"].add(sig)
        if _name_has_hint(sig, _SET_HINTS):
            roles["sets"].add(sig)
        if _name_has_hint(sig, _SHIFT_HINTS):
            roles["shifts"].add(sig)
        if _name_has_hint(sig, _HANDSHAKE_HINTS):
            roles["handshakes"].add(sig)
        if _name_has_hint(sig, _STATE_HINTS):
            roles["states"].add(sig)

    def add_helper(kind: str, expr: str, support_signals: list[str]) -> None:
        expr_norm = _normalize_expr(expr)
        supports = sorted(set(s for s in support_signals if s in available_signals))
        if not expr_norm or not supports:
            return
        if len(expr_norm) > 180:
            return
        if not _has_balanced_parens(expr_norm):
            return
        key = (kind, expr_norm)
        if key in seen_helpers:
            return
        seen_helpers.add(key)
        helpers.append(
            {
                "kind": kind,
                "expr": expr_norm,
                "support_signals": supports,
            }
        )

    for block in _extract_module_blocks(rtl_files, target_module):
        for assign_m in _ASSIGN_RE.finditer(block):
            lhs_raw = assign_m.group(1)
            lhs = _simple_ref_name(lhs_raw)
            if lhs and lhs in available_signals:
                roles["updated"].add(lhs)
                mark_signal(lhs)

        for line in block.splitlines():
            stripped_line = line.strip()
            if not stripped_line:
                continue
            lower = stripped_line.lower()
            if lower.startswith(_DECL_LINE_PREFIXES):
                continue

            for cond in _IF_COND_RE.findall(stripped_line):
                cond_ids = [i for i in _IDENT_RE.findall(cond) if i in available_signals]
                if not cond_ids:
                    continue
                for sig in cond_ids:
                    mark_signal(sig, in_guard=True)
                if any(_name_has_hint(sig, _RESET_HINTS) for sig in cond_ids):
                    add_helper("reset_active", cond, cond_ids)
                elif any(_name_has_hint(sig, _CLEAR_HINTS) for sig in cond_ids):
                    add_helper("clear", cond, cond_ids)
                elif any(_name_has_hint(sig, _HANDSHAKE_HINTS) for sig in cond_ids):
                    add_helper("handshake", cond, cond_ids)
                else:
                    add_helper("update_en", cond, cond_ids)

            for expr in _CASE_EXPR_RE.findall(stripped_line):
                case_ids = [i for i in _IDENT_RE.findall(expr) if i in available_signals]
                if not case_ids:
                    continue
                for sig in case_ids:
                    mark_signal(sig, in_guard=True)
                add_helper("decode", expr, case_ids)

            m_assign = _ASSIGN_LINE_RE.match(stripped_line)
            if not m_assign:
                continue
            lhs = m_assign.group(1)
            rhs = m_assign.group(3)
            if lhs in available_signals:
                roles["updated"].add(lhs)
                mark_signal(lhs)
            rhs_ids = [i for i in _IDENT_RE.findall(rhs) if i in available_signals]
            for sig in rhs_ids:
                mark_signal(sig)
            if ("<<" in rhs or ">>" in rhs) and lhs in available_signals:
                roles["shifts"].add(lhs)

    update_helpers = [h for h in helpers if h["kind"] in {"update_en", "decode"}]
    for helper in update_helpers[:8]:
        add_helper("hold", f"!({helper['expr']})", helper["support_signals"])

    return roles, helpers


def _score_signal_candidate(
    signal: str,
    module_type: str,
    top_module: str,
    top_ports: set[str],
    module_ports: set[str],
    roles: dict[str, set[str]],
) -> int:
    score = 0
    if signal in module_ports:
        score += 130
    if module_type == top_module and signal in top_ports:
        score += 80
    if signal in roles["updated"]:
        score += 70
    if signal in roles["guards"]:
        score += 60
    if signal in roles["resets"]:
        score += 55
    if signal in roles["enables"]:
        score += 52
    if signal in roles["clears"]:
        score += 48
    if signal in roles["sets"]:
        score += 48
    if signal in roles["handshakes"]:
        score += 45
    if signal in roles["states"]:
        score += 44
    if signal in roles["shifts"]:
        score += 40
    return score


def _score_helper_candidate(helper: dict, module_type: str, top_module: str) -> int:
    kind = str(helper.get("kind", ""))
    base = {
        "reset_active": 130,
        "update_en": 120,
        "decode": 118,
        "clear": 116,
        "set": 114,
        "handshake": 112,
        "hold": 105,
    }.get(kind, 90)
    if module_type == top_module:
        base += 12
    base += min(8, len(helper.get("support_signals", [])))
    return base


def extract_golden_semantic_targets(
    structural: dict,
    rtl_files: list[str],
    top_module: str,
    namespace_cap: int = 400,
    helper_cap: int = 160,
) -> dict:
    module_defs, _ = _build_module_db(rtl_files)
    structural_index = _build_structural_index(structural)

    signal_to_modules: dict[str, set[str]] = defaultdict(set)
    for sig in structural.get("signals", []):
        mod = sig.get("module")
        name = sig.get("name")
        if mod and name:
            signal_to_modules[name].add(mod)
    module_names = {s.get("module") for s in structural.get("signals", []) if s.get("module")}

    direct_types = direct_instance_types_under_top(rtl_files, top_module)
    target_modules = [top_module] + [m for m in direct_types if m != top_module]

    namespace_cap = max(50, int(namespace_cap or 400))
    helper_cap = max(0, min(int(helper_cap or 0), namespace_cap))
    raw_cap = max(20, namespace_cap - helper_cap)

    top_raw_budget = min(raw_cap, max(24, int(raw_cap * 0.55)))
    remaining_budget = max(0, raw_cap - top_raw_budget)
    submods = [m for m in target_modules if m != top_module]

    module_budgets: dict[str, int] = {top_module: top_raw_budget}
    if submods:
        base_each = remaining_budget // len(submods)
        bonus = remaining_budget % len(submods)
        for idx, mod in enumerate(sorted(submods)):
            module_budgets[mod] = base_each + (1 if idx < bonus else 0)

    module_targets: list[dict] = []
    helper_candidates: list[dict] = []
    module_signal_counts: dict[str, int] = {}

    top_ports = set(_rtl_port_names_ordered(structural, top_module, module_defs))

    for module_type in target_modules:
        if module_type not in structural_index:
            continue
        available_signals = set(structural_index[module_type].keys())
        if not available_signals:
            continue

        module_ports = set(_rtl_port_names_ordered(structural, module_type, module_defs))
        roles, helpers = _collect_module_semantic_roles(rtl_files, module_type, available_signals)

        candidates = set(module_ports)
        for role_set in roles.values():
            candidates.update(role_set)

        ranked_signals = sorted(
            candidates,
            key=lambda s: (
                -_score_signal_candidate(
                    s,
                    module_type,
                    top_module,
                    top_ports,
                    module_ports,
                    roles,
                ),
                s,
            ),
        )

        module_budget = module_budgets.get(module_type, 0)
        if module_type == top_module:
            selected_signals = ranked_signals[: max(module_budget, 1)]
        else:
            selected_signals = ranked_signals[:module_budget] if module_budget > 0 else []

        if selected_signals:
            module_targets.append(
                {
                    "module": module_type,
                    "signals": selected_signals,
                    "signal_ids": [f"{module_type}.{s}" for s in selected_signals],
                    "source": "rtl_golden_semantic",
                }
            )
        module_signal_counts[module_type] = len(selected_signals)

        for helper in helpers:
            helper_candidates.append(
                {
                    "module": module_type,
                    "kind": helper["kind"],
                    "expr": helper["expr"],
                    "support_signals": helper["support_signals"],
                    "score": _score_helper_candidate(helper, module_type, top_module),
                }
            )

    ranked_helpers = sorted(
        helper_candidates,
        key=lambda h: (-h["score"], h["module"], h["kind"], h["expr"]),
    )
    selected_helpers = ranked_helpers[:helper_cap] if helper_cap > 0 else []

    helper_serials: dict[tuple[str, str], int] = defaultdict(int)
    semantic_helpers: list[dict] = []
    for helper in selected_helpers:
        key = (helper["module"], helper["kind"])
        helper_serials[key] += 1
        serial = helper_serials[key]
        semantic_helpers.append(
            {
                "module": helper["module"],
                "kind": helper["kind"],
                "expr": helper["expr"],
                "support_signals": helper["support_signals"],
                "helper_name": f"obs_{_normalize_token(helper['kind'])}_{serial:03d}",
            }
        )

    spec_signal_to_modules: dict[str, list[str]] = defaultdict(list)
    for target in module_targets:
        mod = target["module"]
        for sig in target["signals"]:
            spec_signal_to_modules[sig].append(mod)
    for sig, mods in list(spec_signal_to_modules.items()):
        spec_signal_to_modules[sig] = sorted(set(mods))
    ambiguous_spec_signals = sorted(
        sig for sig, mods in spec_signal_to_modules.items() if len(mods) > 1
    )

    return {
        "top_module": top_module,
        "has_explicit_submodules": bool(direct_types),
        "explicit_submodules": list(direct_types),
        "selected_submodules": list(direct_types),
        "module_targets": module_targets,
        "semantic_helpers": semantic_helpers,
        "spec_signal_to_modules": dict(spec_signal_to_modules),
        "fallback_applied": "golden_semantic",
        "diagnostics": {
            "unmatched_module_mentions": [],
            "ambiguous_spec_signals": ambiguous_spec_signals,
            "module_signal_counts": module_signal_counts,
            "direct_instance_types_under_top": direct_types,
            "raw_namespace_cap": raw_cap,
            "helper_cap": helper_cap,
            "helpers_selected": len(semantic_helpers),
            "helpers_candidates": len(helper_candidates),
        },
        "structural_summary": {
            "modules": sorted(module_names),
            "module_count": len(module_names),
            "signal_count": len(structural.get("signals", [])),
            "signal_to_modules": {sig: sorted(mods) for sig, mods in signal_to_modules.items()},
        },
    }


_ASSIGN_RE = re.compile(r"\bassign\b\s+([^;]+?)\s*=", re.DOTALL)


_DECL_LINE_PREFIXES = (
    "wire ", "wire\t", "reg ", "reg\t",
    "input ", "input\t", "output ", "output\t",
    "inout ", "inout\t", "parameter ", "parameter\t",
    "localparam ", "localparam\t",
)


def _collect_signals_with_logic(rtl_files: list[str], target_module: str) -> set[str]:
    """
    Return signals in *target_module* that appear on the LHS of assign
    statements or in procedural assignment lines (<=, =) -- i.e. they
    participate in logic, not just wire routing between submodule instances.

    Uses line-by-line scanning instead of always-block regex to correctly
    handle nested begin/end and else branches.
    """
    signals: set[str] = set()

    for rtl in rtl_files:
        path = Path(rtl)
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        stripped = _strip_comments(text)
        stripped = _strip_preprocessor_conditionals(stripped)

        for match in _MODULE_BLOCK_RE.finditer(stripped):
            if match.group(1) != target_module:
                continue
            body = match.group(0)

            for assign_m in _ASSIGN_RE.finditer(body):
                lhs = assign_m.group(1)
                for ident_m in _IDENT_RE.finditer(lhs):
                    tok = ident_m.group(0)
                    if tok.lower() not in _QUALIFIER_TOKENS:
                        signals.add(tok)

            for line in body.splitlines():
                stripped_line = line.strip()
                if not stripped_line:
                    continue
                lower = stripped_line.lower()
                if lower.startswith(_DECL_LINE_PREFIXES):
                    continue
                if "<=" not in stripped_line and "=" not in stripped_line:
                    continue
                if "<=" in stripped_line or (
                    "=" in stripped_line
                    and "==" not in stripped_line
                    and "!=" not in stripped_line
                    and ">=" not in stripped_line
                ):
                    for ident_m in _IDENT_RE.finditer(stripped_line):
                        tok = ident_m.group(0)
                        if tok.lower() not in _QUALIFIER_TOKENS:
                            signals.add(tok)

    return signals


_SV_EXPR_KEYWORDS = {
    "and",
    "or",
    "not",
    "iff",
    "inside",
    "dist",
    "with",
    "default",
    "posedge",
    "negedge",
    "disable",
    "unique",
    "priority",
    "casex",
    "casez",
    "case",
    "begin",
    "end",
}


def _helper_base_name(top_module: str, module_type: str, helper_name: str) -> str:
    token = _normalize_token(helper_name)
    if module_type == top_module:
        return f"top_{token}"
    return f"{_normalize_token(module_type)}_{token}"


def _qualify_helper_expression(
    expr: str,
    module_type: str,
    path: tuple[str, ...],
    structural_index: dict[str, dict[str, dict]],
) -> tuple[str, list[str]]:
    expr_norm = _normalize_expr(expr)
    if not expr_norm:
        return "", []

    module_signals = set(structural_index.get(module_type, {}).keys())
    path_prefix = _path_to_str(path)
    unknown: set[str] = set()

    def repl(match: re.Match) -> str:
        tok = match.group(0)
        low = tok.lower()
        if low in _QUALIFIER_TOKENS or low in _SV_EXPR_KEYWORDS:
            return tok
        if tok in module_signals:
            return f"{path_prefix}.{tok}" if path_prefix else tok
        if tok.isupper():
            return tok
        unknown.add(tok)
        return tok

    qualified = re.sub(r"\b[A-Za-z_]\w*\b", repl, expr_norm)
    if unknown:
        return "", sorted(unknown)
    return qualified, []


def _entry_priority_score(entry: dict) -> int:
    reasons = set(entry.get("source_reasons", []))
    score = 0

    if entry.get("source_kind") == "top":
        score += 220
    else:
        score += 140

    if "clock_signal" in reasons or "reset_signal" in reasons:
        score += 400
    if "golden_semantic_target" in reasons:
        score += 260
    elif "spec_target" in reasons:
        score += 240
    if "structural_closure" in reasons:
        score += 30

    if str(entry.get("direction", "")).lower() in _PORT_DIRS:
        score += 20

    if entry.get("is_helper"):
        score -= 80
    else:
        score += 20

    return score


def build_wrapper_schema(
    rtl_files: list[str],
    top_module: str,
    structural: dict,
    spec_targets: dict,
    clock_names: list[str],
    reset_name: str,
    semantic_helpers: list[dict] | None = None,
    namespace_cap: int | None = None,
    helper_cap: int | None = None,
) -> dict:
    module_defs, discovered_modules = _build_module_db(rtl_files)
    structural_index = _build_structural_index(structural)
    instance_nodes = _build_instance_nodes(top_module, module_defs)

    nodes_by_module: dict[str, list[dict]] = defaultdict(list)
    nodes_by_key: dict[tuple[str, tuple[str, ...]], dict] = {}
    for node in instance_nodes:
        nodes_by_module[node["module_type"]].append(node)
        nodes_by_key[(node["module_type"], tuple(node["instance_path"]))] = node

    endpoint_reasons: dict[tuple[str, str, tuple[str, ...]], set[str]] = defaultdict(set)
    endpoint_queue: deque[tuple[str, str, tuple[str, ...]]] = deque()
    dropped_targets: list[dict] = []

    def add_endpoint(module_type: str, signal: str, path: tuple[str, ...], reason: str) -> None:
        if module_type not in structural_index:
            dropped_targets.append(
                {
                    "module": module_type,
                    "signal": signal,
                    "instance_path": _path_to_str(path),
                    "reason": "module_not_found_in_structural",
                }
            )
            return
        if signal not in structural_index[module_type]:
            dropped_targets.append(
                {
                    "module": module_type,
                    "signal": signal,
                    "instance_path": _path_to_str(path),
                    "reason": "signal_not_found_in_module",
                }
            )
            return
        key = (module_type, signal, path)
        is_new = key not in endpoint_reasons
        endpoint_reasons[key].add(reason)
        if is_new:
            endpoint_queue.append(key)

    for target in spec_targets.get("module_targets", []):
        module_type = target.get("module")
        if not module_type:
            continue
        signals = sorted(set(target.get("signals", [])))
        source = str(target.get("source", ""))
        target_reason = "golden_semantic_target" if "golden_semantic" in source else "spec_target"

        if module_type == top_module:
            for sig in signals:
                add_endpoint(top_module, sig, tuple(), target_reason)
            continue

        matched_nodes = sorted(
            nodes_by_module.get(module_type, []),
            key=lambda n: n["instance_path_str"],
        )
        if not matched_nodes:
            for sig in signals:
                dropped_targets.append(
                    {
                        "module": module_type,
                        "signal": sig,
                        "instance_path": "",
                        "reason": "module_not_instantiated_under_top",
                    }
                )
            continue

        for node in matched_nodes:
            path = tuple(node["instance_path"])
            for sig in signals:
                add_endpoint(module_type, sig, path, target_reason)

    for clk in clock_names or []:
        add_endpoint(top_module, clk, tuple(), "clock_signal")
    if reset_name:
        add_endpoint(top_module, reset_name, tuple(), "reset_signal")

    top_port_names: set[str] = set()
    top_mod_def = module_defs.get(top_module)
    if top_mod_def:
        top_port_names = {
            sig for sig, d in top_mod_def.signal_directions.items()
            if d in _PORT_DIRS
        }
    top_logic_signals = _collect_signals_with_logic(rtl_files, top_module)
    skipped_pass_through: list[dict] = []

    closure_diagnostics = []
    while endpoint_queue:
        module_type, signal, path = endpoint_queue.popleft()
        if module_type == top_module and len(path) == 0:
            continue

        node = nodes_by_key.get((module_type, path))
        if not node:
            continue

        direction = module_defs.get(module_type, ModuleDef("", "", [], {}, [])).signal_directions.get(signal, "")
        if direction not in _PORT_DIRS:
            continue

        conn_expr = node["port_connections"].get(signal, "")
        parent_ref = _simple_ref_name(conn_expr)
        if not parent_ref:
            if conn_expr:
                closure_diagnostics.append(
                    {
                        "module": module_type,
                        "signal": signal,
                        "instance_path": _path_to_str(path),
                        "reason": "unsupported_connection_expression",
                        "expression": conn_expr,
                    }
                )
            continue

        parent_module = node.get("parent_module_type")
        parent_path = tuple(node.get("parent_instance_path", tuple()))
        if not parent_module:
            continue

        if (
            parent_module == top_module
            and len(parent_path) == 0
            and parent_ref not in top_port_names
            and parent_ref not in top_logic_signals
        ):
            skipped_pass_through.append(
                {
                    "module": module_type,
                    "signal": signal,
                    "parent_signal": parent_ref,
                    "instance_path": _path_to_str(path),
                    "reason": "top_pass_through_wire",
                }
            )
            continue

        add_endpoint(parent_module, parent_ref, parent_path, "structural_closure")

    raw_entries: list[dict] = []
    for module_type, signal, path in sorted(
        endpoint_reasons.keys(),
        key=lambda k: (k[0], _path_to_str(k[2]), k[1]),
    ):
        source_kind = "top" if module_type == top_module and len(path) == 0 else "submodule"
        bind_expr = signal if source_kind == "top" else f"{_path_to_str(path)}.{signal}"
        signal_meta = structural_index[module_type][signal]
        width = signal_meta.get("width", 1)
        packed_range = signal_meta.get("packed_range")
        direction = signal_meta.get("direction", "wire")
        row = {
            "module_type": module_type,
            "rtl_signal": signal,
            "instance_path": list(path),
            "instance_path_str": _path_to_str(path),
            "source_kind": source_kind,
            "width": width,
            "width_decl": format_width_decl(width, packed_range),
            "direction": direction,
            "signal_id": signal_meta.get("signal_id", f"{module_type}.{signal}"),
            "bind_expr": bind_expr,
            "source_reasons": sorted(endpoint_reasons[(module_type, signal, path)]),
            "base_name": _entry_base_name(top_module, module_type, signal, path),
            "is_helper": False,
            "mutation_eligible": True,
        }
        if packed_range:
            row["packed_range"] = packed_range
        raw_entries.append(row)

    helper_rows: list[dict] = []
    helper_dropped: list[dict] = []
    for helper in semantic_helpers or []:
        module_type = helper.get("module")
        expr = str(helper.get("expr", "")).strip()
        if not module_type or not expr:
            continue

        helper_kind = _normalize_token(str(helper.get("kind", "helper")))
        helper_name = _normalize_token(
            str(helper.get("helper_name") or f"obs_{helper_kind}")
        )

        if module_type == top_module:
            candidate_paths = [tuple()]
        else:
            candidate_paths = [
                tuple(node["instance_path"])
                for node in sorted(
                    nodes_by_module.get(module_type, []),
                    key=lambda n: n["instance_path_str"],
                )
            ]
            if not candidate_paths:
                helper_dropped.append(
                    {
                        "module": module_type,
                        "helper": helper_name,
                        "reason": "module_not_instantiated_under_top",
                    }
                )
                continue

        for path in candidate_paths:
            qualified_expr, unknown = _qualify_helper_expression(
                expr,
                module_type,
                path,
                structural_index,
            )
            if not qualified_expr:
                helper_dropped.append(
                    {
                        "module": module_type,
                        "helper": helper_name,
                        "instance_path": _path_to_str(path),
                        "reason": "helper_expression_unresolvable",
                        "unknown_tokens": unknown,
                    }
                )
                continue

            source_kind = "top" if module_type == top_module and len(path) == 0 else "submodule"
            helper_rows.append(
                {
                    "module_type": module_type,
                    "rtl_signal": helper_name,
                    "instance_path": list(path),
                    "instance_path_str": _path_to_str(path),
                    "source_kind": source_kind,
                    "width": 1,
                    "width_decl": "",
                    "direction": "logic",
                    "signal_id": f"{module_type}.__helper__.{helper_name}",
                    "bind_expr": qualified_expr,
                    "source_reasons": ["golden_semantic_helper"],
                    "base_name": _helper_base_name(top_module, module_type, helper_name),
                    "is_helper": True,
                    "mutation_eligible": False,
                    "helper_kind": helper_kind,
                }
            )

    raw_entries.extend(helper_rows)

    grouped: dict[str, list[dict]] = defaultdict(list)
    for entry in raw_entries:
        grouped[entry["base_name"]].append(entry)

    final_entries: list[dict] = []
    multi_instance_collapsed: list[dict] = []
    for base_name in sorted(grouped.keys()):
        group = sorted(grouped[base_name], key=lambda e: e["instance_path_str"])
        if len(group) == 1:
            e = dict(group[0])
            e["wrapper_name"] = base_name
            e["collision_group"] = None
            final_entries.append(e)
            continue

        e = dict(group[0])
        e["wrapper_name"] = base_name
        e["collision_group"] = None
        merged_reasons: set[str] = set()
        for x in group:
            merged_reasons.update(x["source_reasons"])
        e["source_reasons"] = sorted(merged_reasons)
        e["is_helper"] = any(bool(x.get("is_helper")) for x in group)
        e["mutation_eligible"] = all(bool(x.get("mutation_eligible", True)) for x in group)
        dropped_paths = [x["instance_path_str"] for x in group[1:]]
        if dropped_paths:
            multi_instance_collapsed.append(
                {
                    "base_name": base_name,
                    "module_type": e["module_type"],
                    "rtl_signal": e["rtl_signal"],
                    "chosen_path": e["instance_path_str"],
                    "dropped_paths": dropped_paths,
                }
            )
        final_entries.append(e)

    final_entries = sorted(final_entries, key=lambda e: e["wrapper_name"])

    wrapper_name_set = set()
    deduped_entries: list[dict] = []
    duplicate_names = []
    for entry in final_entries:
        wname = entry["wrapper_name"]
        if wname in wrapper_name_set:
            duplicate_names.append(wname)
            continue
        wrapper_name_set.add(wname)
        deduped_entries.append(entry)

    helper_cap_limit = None if helper_cap is None else max(0, int(helper_cap))
    namespace_cap_limit = None if namespace_cap is None else max(1, int(namespace_cap))

    entries_before_cap = len(deduped_entries)
    capped_entries: list[dict] = []

    ranked_for_cap = sorted(
        deduped_entries,
        key=lambda e: (-_entry_priority_score(e), e["wrapper_name"]),
    )

    if namespace_cap_limit is not None:
        selected: list[dict] = []
        helper_count = 0
        for entry in ranked_for_cap:
            if len(selected) >= namespace_cap_limit:
                capped_entries.append(
                    {
                        "wrapper_name": entry["wrapper_name"],
                        "reason": "namespace_cap",
                    }
                )
                continue
            if entry.get("is_helper") and helper_cap_limit is not None and helper_count >= helper_cap_limit:
                capped_entries.append(
                    {
                        "wrapper_name": entry["wrapper_name"],
                        "reason": "helper_cap",
                    }
                )
                continue
            selected.append(entry)
            if entry.get("is_helper"):
                helper_count += 1
        deduped_entries = sorted(selected, key=lambda e: e["wrapper_name"])
    elif helper_cap_limit is not None:
        selected = []
        helper_count = 0
        for entry in ranked_for_cap:
            if entry.get("is_helper") and helper_count >= helper_cap_limit:
                capped_entries.append(
                    {
                        "wrapper_name": entry["wrapper_name"],
                        "reason": "helper_cap",
                    }
                )
                continue
            selected.append(entry)
            if entry.get("is_helper"):
                helper_count += 1
        deduped_entries = sorted(selected, key=lambda e: e["wrapper_name"])

    module_coverage = defaultdict(int)
    for e in deduped_entries:
        module_coverage[e["module_type"]] += 1

    helper_after_cap = sum(1 for e in deduped_entries if e.get("is_helper"))

    return {
        "top_module": top_module,
        "naming_convention": {
            "top_signal": "top_<signal>",
            "submodule_signal": "<module>_<signal>",
            "helper_signal": "top_obs_* or <module>_obs_*",
            "multi_instance_rule": (
                "duplicate module_type+signal under different instance paths: "
                "one wrapper port named <module>_<signal>, bind_expr uses the "
                "lexicographically first instance_path_str"
            ),
        },
        "entries": deduped_entries,
        "allowed_wrapper_names": [e["wrapper_name"] for e in deduped_entries],
        "module_coverage": dict(sorted(module_coverage.items())),
        "instance_summary": {
            "discovered_modules": discovered_modules,
            "instance_count": len(instance_nodes),
            "submodule_modules_under_top": sorted(nodes_by_module.keys()),
        },
        "diagnostics": {
            "dropped_targets": dropped_targets,
            "closure_notes": closure_diagnostics,
            "duplicate_wrapper_names_dropped": sorted(set(duplicate_names)),
            "multi_instance_collapsed": multi_instance_collapsed,
            "skipped_pass_through": skipped_pass_through,
            "semantic_helpers": {
                "requested": len(semantic_helpers or []),
                "materialized_before_cap": len(helper_rows),
                "retained_after_cap": helper_after_cap,
                "dropped": helper_dropped,
            },
            "namespace_cap": {
                "configured": namespace_cap_limit,
                "helper_cap": helper_cap_limit,
                "entries_before": entries_before_cap,
                "entries_after": len(deduped_entries),
                "dropped": capped_entries,
            },
        },
    }
