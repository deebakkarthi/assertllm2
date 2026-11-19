"""
Multi-mutation driver for MutationOperators (PyVerilog AST).
- Applies K random mutations sequentially on the SAME design (single AST instance).
- Supports selective signal-targeted mutations via TARGET_SIGNAL environment variable.
- Uses a dispatch table (no long if/elif chains).
- Logs each mutation with human-readable location: node type + line number + snippet.
"""

import copy
import os
import random
import re
from random import randint

import MutationOperators
import pyverilog.vparser.ast as vast
from pyverilog.ast_code_generator.codegen import ASTCodeGenerator
from pyverilog.vparser.parser import parse


# One shared code generator for both snippet logging and final emission.
_CODEGEN = ASTCodeGenerator()

# Structural-delete operators are allowed only as fallback by default.
PRIMARY_OPS = ["DMO", "DMS", "DMI", "DIE", "CMC", "SMC", "CMP", "LOR", "CSW", "CCW", "AVC", "CSE"]
FALLBACK_OPS = ["SRA", "SRI", "SRC", "TRA", "CDP"]
DEFAULT_OPERATOR_PROFILE = PRIMARY_OPS + FALLBACK_OPS

# Restore declaration initializers after PyVerilog codegen rewrites
#   reg x = 1'b0;
# into
#   reg x; assign x = 1'b0;
_DECL_INIT_ASSIGN_RE = re.compile(
    r"(?P<decl>\b(?:reg|logic|integer)\b[^;\n]*?\b(?P<name>[A-Za-z_]\w*)\b\s*);\s*assign\s+(?P=name)\s*=\s*(?P<expr>[^;]+);",
    flags=re.IGNORECASE,
)

_PROC_SKIP_PREFIXES = (
    "assign",
    "wire",
    "reg",
    "logic",
    "input",
    "output",
    "inout",
    "parameter",
    "localparam",
    "typedef",
)

_CLOCK_RESET_HINT_RE = re.compile(r"(^|_)(clk|clock|rst|reset|areset|nreset|rst_n|reset_n)($|_)", re.IGNORECASE)

_LOR_SWAP = {
    "Plus": "Minus",
    "Minus": "Plus",
    "And": "Or",
    "Or": "And",
    "Land": "Lor",
    "Lor": "Land",
    "Eq": "NotEq",
    "NotEq": "Eq",
    "Sll": "Srl",
    "Srl": "Sll",
}


def signal_in_node(node, target_signal):
    """Check if target_signal is referenced in this node's subtree."""
    if not target_signal:
        return True  # No filtering if target_signal is empty

    try:
        code = _CODEGEN.visit(node)
        return target_signal in code
    except Exception:
        return False


def collect_node_ids_by_type_in_module(ast, module_name=None, target_signal=None):
    """
    Collect node_ids grouped by AST node class name.

    If module_name is provided, only nodes under that ModuleDef are collected.
    If target_signal is provided, only nodes that reference that signal are collected.
    """
    type2ids = {}

    def dfs(n, cur_module=None):
        if n is None:
            return

        if n.__class__.__name__ == "ModuleDef":
            cur_module = getattr(n, "name", cur_module)

        in_scope = module_name is None or cur_module == module_name

        if in_scope:
            if target_signal and not signal_in_node(n, target_signal):
                for ch in n.children():
                    dfs(ch, cur_module)
                return

            node_id = getattr(n, "node_id", None)
            if node_id is not None:
                type2ids.setdefault(n.__class__.__name__, []).append(node_id)

        for ch in n.children():
            dfs(ch, cur_module)

    dfs(ast)
    return type2ids


def collect_node_ids_by_type(ast, target_signal=None):
    """
    Backward-compatible helper: collect from all modules.
    """
    return collect_node_ids_by_type_in_module(ast, None, target_signal)


def pick_id(type2ids, type_name):
    """Pick one random node_id for a given node type; return None if none exist."""
    ids = type2ids.get(type_name, [])
    return random.choice(ids) if ids else None


def find_node_by_id(ast, target_id):
    """Find the first node whose node_id == target_id."""
    found = None

    def dfs(n):
        nonlocal found
        if n is None or found is not None:
            return
        if getattr(n, "node_id", None) == target_id:
            found = n
            return
        for ch in n.children():
            dfs(ch)

    dfs(ast)
    return found


def pretty_node(ast, node_id, max_len=140):
    """
    Produce a human-readable locator for a node:
    - node type
    - line number (if available)
    - a compact code snippet for that node/subtree
    """
    n = find_node_by_id(ast, node_id)
    if n is None:
        return "(node not found)"

    t = n.__class__.__name__
    line = getattr(n, "lineno", None)
    line_s = f"line {line}" if line is not None else "line ?"

    try:
        snippet = _CODEGEN.visit(n)
        snippet = " ".join(snippet.split())
        if len(snippet) > max_len:
            snippet = snippet[: max_len - 3] + "..."
    except Exception:
        snippet = t

    return f"{t} @ {line_s}: {snippet}"


def _strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.DOTALL)
    text = re.sub(r"//[^\n]*", "", text)
    return text


def _lhs_names_from_expr(lhs_expr: str) -> set[str]:
    lhs_expr = lhs_expr.strip()
    if not lhs_expr:
        return set()

    if lhs_expr.startswith("{") and lhs_expr.endswith("}"):
        return set(re.findall(r"[A-Za-z_]\w*", lhs_expr))

    m = re.match(r"^([A-Za-z_]\w*)(?:\s*\[[^\]]+\])?$", lhs_expr)
    if m:
        return {m.group(1)}

    # Fallback: first identifier in expression.
    tokens = re.findall(r"[A-Za-z_]\w*", lhs_expr)
    return {tokens[0]} if tokens else set()


# Tail token before a procedural assign at statement level (write target only — not RHS reads).
_LHS_TAIL_BEFORE_ASSIGN_RE = re.compile(r"([A-Za-z_]\w*(?:\s*\[[^\]]+\])?)\s*$")

_LHS_TAIL_KEYWORDS = frozenset(
    {
        "begin",
        "end",
        "else",
        "if",
        "for",
        "while",
        "case",
        "return",
        "do",
        "posedge",
        "negedge",
        "or",
        "and",
    }
)


def _procedural_write_lhs_from_prefix(prefix: str) -> set[str]:
    """
    Extract the written signal for one procedural assignment, from text before '=' or '<='.

    Only the assignment target counts (multi-source / mixed-driver rule). Names used on the
    RHS or inside conditions are reads and must not be collected here.
    """
    s = prefix.rstrip()
    while s.endswith(";"):
        s = s[:-1].rstrip()
    if not s:
        return set()

    if ":" in s:
        s = s.rsplit(":", 1)[1].strip()

    s = re.sub(r"^(begin|end|else)\b\s*", "", s).strip()
    if not s:
        return set()

    m = _LHS_TAIL_BEFORE_ASSIGN_RE.search(s)
    if not m:
        return set()
    raw = m.group(1).strip()
    base_m = re.match(r"^([A-Za-z_]\w*)", raw)
    if base_m and base_m.group(1).lower() in _LHS_TAIL_KEYWORDS:
        return set()
    return _lhs_names_from_expr(raw)


def _collect_continuous_assign_lhs_names(text: str) -> set[str]:
    """Identifiers driven (written) by continuous assign — LHS of assign only."""
    names: set[str] = set()
    clean = _strip_comments(text)
    for m in re.finditer(r"\bassign\b\s+([^;]+?)\s*=", clean, flags=re.DOTALL):
        lhs = m.group(1)
        names.update(_lhs_names_from_expr(lhs))
    return names


def _procedural_write_lhs_in_line(line: str) -> set[str]:
    """
    Identifiers driven by procedural blocking '=' or nonblocking '<=' on this line.

    Verilog uses the same token '<=' for relational compare and for NBA. Comparisons in
    subexpressions (e.g. if (a <= b)) are reads, not writes — they sit inside a balanced
    '('...')' region, so we only treat '<=' at nesting depth 0 as a procedural write.
    """
    names: set[str] = set()
    depth = 0
    i = 0
    n = len(line)

    while i < n:
        c = line[i]
        if c == "(":
            depth += 1
            i += 1
            continue
        if c == ")":
            depth = max(0, depth - 1)
            i += 1
            continue

        if i + 1 < n and line[i : i + 2] == "<=":
            if depth == 0:
                names.update(_procedural_write_lhs_from_prefix(line[:i]))
            i += 2
            continue

        if c == "=" and depth == 0:
            if i + 1 < n and line[i + 1] == "=":
                i += 2
                continue
            if i > 0 and line[i - 1] in ("=", "!", ">", "<"):
                i += 1
                continue
            names.update(_procedural_write_lhs_from_prefix(line[:i]))
            i += 1
            continue

        i += 1

    return names


def _collect_procedural_lhs_names(text: str) -> set[str]:
    """Set of identifiers that receive a procedural (blocking or nonblocking) write."""
    names: set[str] = set()
    clean = _strip_comments(text)

    for raw in clean.splitlines():
        line = raw.strip()
        if not line:
            continue

        lower = line.lower()
        if lower.startswith(_PROC_SKIP_PREFIXES):
            continue

        names.update(_procedural_write_lhs_in_line(line))

    return names


def detect_mixed_assignment_signals(code: str) -> list[str]:
    """
    Detect multi-source driving: the same identifier is written by both continuous assign
    and procedural assignment (illegal in typical synthesis / elaboration).

    Uses assignment LHS only. Reads — RHS references, if (sig), case (sig), relational
    operators, etc. — do not count as driving that net and are ignored.
    """
    cont = _collect_continuous_assign_lhs_names(code)
    proc = _collect_procedural_lhs_names(code)
    return sorted(cont & proc)


def restore_declaration_initializers(code: str) -> tuple[str, list[dict]]:
    """
    Convert
      reg/logic/integer <name>; assign <name> = <expr>;
    back to
      reg/logic/integer <name> = <expr>;
    """
    actions: list[dict] = []

    def repl(match: re.Match) -> str:
        decl = match.group("decl").strip()
        name = match.group("name")
        expr = match.group("expr").strip()

        # Multi-name declarations are ambiguous for safe rewrite.
        if "," in decl:
            return match.group(0)

        actions.append(
            {
                "kind": "restore_decl_initializer",
                "signal": name,
                "expr": expr,
            }
        )
        return f"{decl} = {expr};"

    rewritten = _DECL_INIT_ASSIGN_RE.sub(repl, code)
    return rewritten, actions


def sanitize_mutated_rtl_text(code: str) -> tuple[str, dict]:
    """Normalize emitted RTL; flag nets that would be both assign-driven and procedurally driven."""
    sanitized, actions = restore_declaration_initializers(code)
    mixed = detect_mixed_assignment_signals(sanitized)
    return sanitized, {
        "changed": sanitized != code,
        "restored_decl_initializers": len(actions),
        "actions": actions,
        "mixed_assignment_signals": mixed,
    }


def resolve_requested_operators(cfg_ops) -> list[str]:
    """
    Resolve operator list from config.
    - "all" => logic/connectivity-primary profile + fallback structural ops.
    - explicit list => keep valid operators only.
    """
    if isinstance(cfg_ops, str):
        cfg_ops = [cfg_ops]

    ops = [str(x).strip() for x in (cfg_ops or []) if str(x).strip()]
    if not ops or any(op.lower() == "all" for op in ops):
        return [op for op in DEFAULT_OPERATOR_PROFILE if op in OP_DISPATCH]

    out = [op for op in ops if op in OP_DISPATCH]
    if not out:
        return [op for op in DEFAULT_OPERATOR_PROFILE if op in OP_DISPATCH]
    return out


def get_op_node_types(op: str) -> list[str]:
    node_type = OP_NODE_TYPE.get(op)
    if node_type is None:
        return []
    if isinstance(node_type, (list, tuple, set)):
        return [str(t) for t in node_type if t]
    return [str(node_type)]


def op_applicable(type2ids: dict, op: str) -> bool:
    node_types = get_op_node_types(op)
    if not node_types:
        return False
    return any(type2ids.get(t) for t in node_types)


def select_applicable_ops(
    type2ids: dict,
    requested_ops: list[str],
    enable_structural_fallback: bool = True,
) -> tuple[list[str], str]:
    """
    Pick applicable operators in two phases:
      1) primary (logic/connectivity)
      2) structural fallback (optional)
    Returns (ops, profile_used) where profile_used is primary/fallback/none.
    """
    requested_ops = [op for op in requested_ops if op in OP_DISPATCH]
    if not requested_ops:
        return [], "none"

    fallback_set = set(FALLBACK_OPS)
    primary_requested = [op for op in requested_ops if op not in fallback_set]
    fallback_requested = [op for op in requested_ops if op in fallback_set]

    primary_applicable = [op for op in primary_requested if op_applicable(type2ids, op)]
    if primary_applicable:
        return primary_applicable, "primary"

    if enable_structural_fallback:
        fallback_applicable = [op for op in fallback_requested if op_applicable(type2ids, op)]
        if fallback_applicable:
            return fallback_applicable, "fallback"

    return [], "none"


def _get_pointer_max_index(ast, pointer_nid, Mutation):
    """
    For a Pointer node (e.g. dcnt[0]), find the declared width of its
    base signal to determine the valid index range.
    Returns max valid index (inclusive), or None if undetermined.
    """
    node = find_node_by_id(ast, pointer_nid)
    if node is None:
        return None
    var = getattr(node, "var", None)
    if var is None:
        return None
    sig_name = getattr(var, "name", None)
    if sig_name is None:
        return None
    rng = Mutation._get_signal_range(ast, sig_name)
    if rng is None:
        return None
    hi, _ = max(rng), min(rng)
    return hi


def _op_DMO(Mutation, ast, type2ids):
    """DMO: mutate Pointer index constant."""
    nid = pick_id(type2ids, "Pointer")
    if nid is None:
        return None

    Mutation._root = ast
    max_idx = _get_pointer_max_index(ast, nid, Mutation)
    if max_idx is None or max_idx < 1:
        return None

    before = pretty_node(ast, nid)
    new_const = vast.IntConst(str(randint(0, max_idx)))
    Mutation.DMO(ast, nid, new_const)
    after = pretty_node(ast, nid)

    if before == after:
        return None
    return f"DMO -> {before}  ==>  {after} (new index={new_const.value})"


def _get_srl_width(ast, srl_nid, Mutation):
    """
    For a Srl node (a >> b), try to determine the bit-width of the
    left operand so the shift amount stays within bounds.
    Returns the width (int) or None.
    """
    node = find_node_by_id(ast, srl_nid)
    if node is None:
        return None
    left = getattr(node, "left", None)
    if left is None:
        return None
    sig_name = getattr(left, "name", None)
    if sig_name is None:
        return None
    rng = Mutation._get_signal_range(ast, sig_name)
    if rng is None:
        return None
    return abs(rng[0] - rng[1]) + 1


def _op_DMS(Mutation, ast, type2ids):
    """DMS: mutate shift amount in Srl (>>)."""
    nid = pick_id(type2ids, "Srl")
    if nid is None:
        return None

    Mutation._root = ast
    width = _get_srl_width(ast, nid, Mutation)
    max_shift = width if width and width > 1 else 8

    before = pretty_node(ast, nid)
    new_const = vast.IntConst(str(randint(1, max_shift)))
    Mutation.DMS(ast, nid, new_const)
    after = pretty_node(ast, nid)

    if before == after:
        return None
    return f"DMS -> {before}  ==>  {after} (new shift={new_const.value})"


def _op_DMI(Mutation, ast, type2ids):
    """DMI: decrement IntConst endpoints inside a Partselect.
    Skip if any endpoint is already 0 (decrementing would go negative)."""
    nid = pick_id(type2ids, "Partselect")
    if nid is None:
        return None

    node = find_node_by_id(ast, nid)
    if node is None:
        return None

    ints = [
        c
        for c in node.children()
        if c is not None and c.__class__.__name__ == "IntConst"
    ]
    if len(ints) < 2:
        return None
    if any(int(ic.value) <= 0 for ic in ints):
        return None

    before = pretty_node(ast, nid)
    Mutation.DMI(ast, nid)
    after = pretty_node(ast, nid)

    if before == after:
        return None
    return f"DMI -> {before}  ==>  {after}"


def _op_DIE(Mutation, ast, type2ids):
    """
    DIE: endian-related Partselect mutation (same slice width).
    Requires Mutation._root to be set to the current AST root.
    """
    nid = pick_id(type2ids, "Partselect")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    Mutation._root = ast
    Mutation.DIE(ast, nid)
    after = pretty_node(ast, nid)

    if before == after:
        return None
    return f"DIE -> {before}  ==>  {after}"


def _op_SRA(Mutation, ast, type2ids):
    """SRA: delete an Assign node."""
    nid = pick_id(type2ids, "Assign")
    if nid is None:
        return None

    target = pretty_node(ast, nid)
    Mutation.SRA(ast, nid)
    return f"SRA -> deleted {target}"


def _op_SRR(Mutation, ast, type2ids):
    """SRR: disabled - deleting Reg declarations leaves dangling references."""
    return None


def _op_SRW(Mutation, ast, type2ids):
    """SRW: disabled - deleting Wire declarations leaves dangling references."""
    return None


def _op_TRA(Mutation, ast, type2ids):
    """TRA: delete an Always block node."""
    nid = pick_id(type2ids, "Always")
    if nid is None:
        return None

    target = pretty_node(ast, nid)
    Mutation.TRA(ast, nid)
    return f"TRA -> deleted {target}"


def _op_SRI(Mutation, ast, type2ids):
    """SRI: delete an IfStatement node."""
    nid = pick_id(type2ids, "IfStatement")
    if nid is None:
        return None

    target = pretty_node(ast, nid)
    Mutation.SRI(ast, nid)
    return f"SRI -> deleted {target}"


def _op_SRC(Mutation, ast, type2ids):
    """SRC: delete a Case node."""
    nid = pick_id(type2ids, "Case")
    if nid is None:
        return None

    target = pretty_node(ast, nid)
    Mutation.SRC(ast, nid)
    return f"SRC -> deleted {target}"


def _op_TMD(Mutation, ast, type2ids):
    """TMD: mutate a DelayStatement constant."""
    nid = pick_id(type2ids, "DelayStatement")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    Mutation.TMD(ast, nid)
    after = pretty_node(ast, nid)

    return f"TMD -> {before}  ==>  {after}"


def _op_CMC(Mutation, ast, type2ids):
    """CMC: mutate ternary condition (sel ? a : b)."""
    nid = pick_id(type2ids, "Cond")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    mode = random.choice([0, 1, 2])
    mode_names = {0: "true_only", 1: "false_only", 2: "swap"}
    Mutation._root = ast
    Mutation.CMC(ast, nid, mode)
    after = pretty_node(ast, nid) if mode == 2 else "(cond removed)"

    return f"CMC({mode_names[mode]}) -> {before}  ==>  {after}"


def _op_CMP(Mutation, ast, type2ids):
    """CMP: mutate IntConst in Instance parameter arguments."""
    nid = pick_id(type2ids, "Instance")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    Mutation.CMP(ast, nid)
    after = pretty_node(ast, nid)
    if before == after:
        return None
    return f"CMP -> {before}  ==>  {after}"


def _op_CDP(Mutation, ast, type2ids):
    """CDP: delete PortArg from an Instance node."""
    nid = pick_id(type2ids, "Instance")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    Mutation.CDP(ast, nid)
    after = pretty_node(ast, nid)
    if before == after:
        return None
    return f"CDP -> {before}  ==>  {after}"


def _op_CGA(Mutation, ast, type2ids):
    """CGA: insert a mutated assignment copy into a Block."""
    nid = pick_id(type2ids, "Block")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    Mutation.CGA(ast, nid)
    after = pretty_node(ast, nid)
    if before == after:
        return None
    return f"CGA -> {before}  ==>  {after}"


def _op_CRV(Mutation, ast, type2ids):
    """CRV: replace 'valid' identifier with constant 1 in IfStatement."""
    nid = pick_id(type2ids, "IfStatement")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    Mutation.CRV(ast, nid)
    after = pretty_node(ast, nid)
    if before == after:
        return None
    return f"CRV -> {before}  ==>  {after}"


def _op_TAA(Mutation, ast, type2ids):
    """TAA: duplicate an assignment statement into a Block."""
    nid = pick_id(type2ids, "Block")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    Mutation.TAA(ast, nid)
    after = pretty_node(ast, nid)
    if before == after:
        return None
    return f"TAA -> {before}  ==>  {after}"


def _op_SMC(Mutation, ast, type2ids):
    """SMC (SME_constant): mutate IntConst values inside assignments in a Block."""
    nid = pick_id(type2ids, "Block")
    if nid is None:
        return None

    before = pretty_node(ast, nid)
    Mutation.SME_constant(ast, nid)
    after = pretty_node(ast, nid)
    if before == after:
        return None
    return f"SMC -> {before}  ==>  {after}"


def _iter_subtree_nodes(node):
    if node is None:
        return
    yield node
    for ch in node.children():
        if ch is not None:
            yield from _iter_subtree_nodes(ch)


def _collect_rhs_intconst_nodes(assign_node):
    right = getattr(assign_node, "right", None)
    if right is None:
        return []
    return [n for n in _iter_subtree_nodes(right) if n.__class__.__name__ == "IntConst"]


def _op_AVC(Mutation, ast, type2ids):
    """AVC: mutate one RHS IntConst in assignment-like nodes."""
    candidate_ids = []
    for node_type in ("Assign", "BlockingSubstitution", "NonblockingSubstitution"):
        candidate_ids.extend(type2ids.get(node_type, []))
    if not candidate_ids:
        return None

    random.shuffle(candidate_ids)
    for nid in candidate_ids:
        node = find_node_by_id(ast, nid)
        if node is None:
            continue

        rhs_consts = _collect_rhs_intconst_nodes(node)
        if not rhs_consts:
            continue

        victim = random.choice(rhs_consts)
        old_value = str(getattr(victim, "value", ""))
        if not old_value:
            continue

        new_value = MutationOperators._perturb_intconst_value(old_value)
        if new_value == old_value:
            continue

        before = pretty_node(ast, nid)
        victim.value = new_value
        after = pretty_node(ast, nid)

        # Do not use truncated pretty text as mutation success criteria;
        # constant changed already guarantees semantic delta on this node.
        return f"AVC({old_value}->{new_value}) -> {before}  ==>  {after}"

    return None


def _extract_swappable_case_items(case_node):
    caselist = getattr(case_node, "caselist", None)
    if not isinstance(caselist, (list, tuple)):
        return []

    items = []
    for item in caselist:
        if item is None:
            continue

        cond = getattr(item, "cond", None)
        if cond is None:
            continue

        if isinstance(cond, (list, tuple)):
            cond_nodes = [c for c in cond if c is not None]
        else:
            cond_nodes = [cond]

        # Keep CSE stable: swap only single IntConst case labels, skip default and composite labels.
        if len(cond_nodes) != 1:
            continue
        cond_node = cond_nodes[0]
        if cond_node.__class__.__name__ != "IntConst":
            continue

        signature = " ".join(_CODEGEN.visit(cond_node).split())
        if not signature:
            continue

        items.append((item, signature))

    return items


def _op_CSE(Mutation, ast, type2ids):
    """CSE: swap two case-entry IntConst labels inside one case block."""
    case_ids = []
    case_ids.extend(type2ids.get("Case", []))
    case_ids.extend(type2ids.get("CaseStatement", []))
    if not case_ids:
        return None

    random.shuffle(case_ids)
    for nid in case_ids:
        node = find_node_by_id(ast, nid)
        if node is None or getattr(node, "caselist", None) is None:
            continue

        items = _extract_swappable_case_items(node)
        if len(items) < 2:
            continue

        # Enforce unique labels; if duplicates already exist, skip this case block.
        sigs = [sig for _, sig in items]
        if len(set(sigs)) != len(sigs):
            continue

        pair = random.sample(items, 2)
        (item_a, sig_a), (item_b, sig_b) = pair
        old_cond_a = copy.deepcopy(item_a.cond)
        old_cond_b = copy.deepcopy(item_b.cond)

        before = pretty_node(ast, nid)
        item_a.cond = old_cond_b
        item_b.cond = old_cond_a
        after = pretty_node(ast, nid)

        # Swap of distinct labels is a real mutation even if pretty text is truncated.
        return f"CSE({sig_a}<->{sig_b}) -> {before}  ==>  {after}"

    return None


def _build_node_to_module(ast) -> dict[int, str]:
    node_to_module: dict[int, str] = {}

    def dfs(n, cur_module=None):
        if n is None:
            return

        if n.__class__.__name__ == "ModuleDef":
            cur_module = getattr(n, "name", cur_module)

        nid = getattr(n, "node_id", None)
        if nid is not None and cur_module:
            node_to_module[nid] = cur_module

        for ch in n.children():
            dfs(ch, cur_module)

    dfs(ast, None)
    return node_to_module


def _parse_intconst_value(value: str) -> int | None:
    try:
        if "'" in value:
            _, literal = value.split("'", 1)
            if not literal:
                return None
            base = literal[0].lower()
            digits = literal[1:].replace("_", "")
            if base == "b":
                return int(digits, 2)
            if base == "h":
                return int(digits, 16)
            if base == "o":
                return int(digits, 8)
            if base == "d":
                return int(digits, 10)
            return None
        return int(value)
    except Exception:
        return None


def _intconst_width(node) -> int | None:
    value = getattr(node, "value", "")
    if not isinstance(value, str):
        return None

    if "'" in value:
        width_text = value.split("'", 1)[0].strip()
        if width_text.isdigit():
            return int(width_text)
        return None

    ival = _parse_intconst_value(value)
    if ival is None:
        return None
    if ival <= 0:
        return 1
    return ival.bit_length()


def _node_decl_width(node) -> int | None:
    width = getattr(node, "width", None)
    if width is None:
        return 1
    ints = [
        c
        for c in width.children()
        if c is not None and c.__class__.__name__ == "IntConst"
    ]
    if len(ints) >= 2:
        try:
            msb = _parse_intconst_value(ints[0].value)
            lsb = _parse_intconst_value(ints[1].value)
            if msb is not None and lsb is not None:
                return abs(msb - lsb) + 1
        except Exception:
            return None
    return None


def _collect_module_signal_widths(ast) -> dict[str, dict[str, int | None]]:
    out: dict[str, dict[str, int | None]] = {}

    def walk_module(mod_node):
        module_name = getattr(mod_node, "name", None)
        if not module_name:
            return
        widths: dict[str, int | None] = {}

        for n in mod_node.children():
            if n is None:
                continue

            if n.__class__.__name__ == "Ioport":
                for ch in n.children():
                    if ch is None:
                        continue
                    name = getattr(ch, "name", None)
                    if name:
                        w = _node_decl_width(ch)
                        widths[name] = w if w is not None else widths.get(name)

            if n.__class__.__name__ == "Decl":
                for ch in n.children():
                    if ch is None:
                        continue
                    name = getattr(ch, "name", None)
                    if name:
                        w = _node_decl_width(ch)
                        widths[name] = w if w is not None else widths.get(name)

        out[module_name] = widths

    def dfs(n):
        if n is None:
            return
        if n.__class__.__name__ == "ModuleDef":
            walk_module(n)
        for ch in n.children():
            dfs(ch)

    dfs(ast)
    return out


def _infer_expr_width(node, signal_widths: dict[str, int | None]) -> int | None:
    if node is None:
        return None

    cls = node.__class__.__name__
    if cls == "Identifier":
        return signal_widths.get(getattr(node, "name", ""), None)
    if cls == "Pointer":
        return 1
    if cls == "Partselect":
        msb = getattr(node, "msb", None)
        lsb = getattr(node, "lsb", None)
        if msb is None or lsb is None:
            return None
        if msb.__class__.__name__ == "IntConst" and lsb.__class__.__name__ == "IntConst":
            hi = _parse_intconst_value(msb.value)
            lo = _parse_intconst_value(lsb.value)
            if hi is None or lo is None:
                return None
            return abs(hi - lo) + 1
        return None
    if cls == "IntConst":
        return _intconst_width(node)
    if cls == "Concat":
        total = 0
        for ch in node.children():
            w = _infer_expr_width(ch, signal_widths)
            if w is None:
                return None
            total += w
        return total

    # Conservative fallback for unsupported expression kinds.
    return None


def _is_clock_or_reset_name(name: str) -> bool:
    return bool(_CLOCK_RESET_HINT_RE.search(name or ""))


def _concat_element_base_name(node) -> str | None:
    """Return base signal name for concat elements that map to variables."""
    if node is None:
        return None

    cls = node.__class__.__name__
    if cls == "Identifier":
        return getattr(node, "name", None)

    if cls in {"Pointer", "Partselect"}:
        var = getattr(node, "var", None)
        if var is not None and var.__class__.__name__ == "Identifier":
            return getattr(var, "name", None)

    return None


def _is_concat_swap_eligible(node) -> bool:
    """Allow only variable-like concat elements and skip clock/reset signals."""
    if node is None:
        return False

    if node.__class__.__name__ not in {"Identifier", "Pointer", "Partselect"}:
        return False

    base = _concat_element_base_name(node)
    if not base:
        return False
    if _is_clock_or_reset_name(base):
        return False
    return True


def _op_CCW(Mutation, ast, type2ids):
    """
    CCW: swap two eligible elements inside a concat expression.

    Targets variable-like concat entries in both continuous/procedural assignments.
    """
    concat_ids = []
    concat_ids.extend(type2ids.get("Concat", []))
    concat_ids.extend(type2ids.get("LConcat", []))
    if not concat_ids:
        return None

    viable = []
    for nid in concat_ids:
        node = find_node_by_id(ast, nid)
        if node is None or node.__class__.__name__ not in {"Concat", "LConcat"}:
            continue

        items = getattr(node, "list", None)
        if not isinstance(items, (list, tuple)):
            continue

        seq = list(items)
        if len(seq) < 2:
            continue

        eligible_idx = [i for i, ch in enumerate(seq) if _is_concat_swap_eligible(ch)]
        if len(eligible_idx) < 2:
            continue

        pairs = []
        for i in range(len(eligible_idx)):
            for j in range(i + 1, len(eligible_idx)):
                ai = eligible_idx[i]
                bi = eligible_idx[j]
                a_code = " ".join(_CODEGEN.visit(seq[ai]).split())
                b_code = " ".join(_CODEGEN.visit(seq[bi]).split())
                if a_code == b_code:
                    continue
                pairs.append((ai, bi))

        if not pairs:
            continue

        viable.append((nid, node, items, seq, pairs))

    if not viable:
        return None

    nid, node, items, seq, pairs = random.choice(viable)
    before = pretty_node(ast, nid)
    ai, bi = random.choice(pairs)
    seq[ai], seq[bi] = seq[bi], seq[ai]

    if isinstance(items, tuple):
        node.list = tuple(seq)
    else:
        node.list = seq

    after = pretty_node(ast, nid)
    if before == after:
        return None
    return f"CCW({ai}<->{bi}) -> {before}  ==>  {after}"


def _op_LOR(Mutation, ast, type2ids):
    """LOR: mutate logic/operator kind while keeping operands unchanged."""
    candidates = []
    for cls_name in sorted(set(_LOR_SWAP.keys())):
        for nid in type2ids.get(cls_name, []):
            candidates.append((nid, cls_name))

    if not candidates:
        return None

    nid, src_cls = random.choice(candidates)
    node = find_node_by_id(ast, nid)
    if node is None:
        return None

    dst_cls_name = _LOR_SWAP.get(src_cls)
    dst_cls = getattr(vast, dst_cls_name, None)
    if dst_cls is None:
        return None

    left = getattr(node, "left", None)
    right = getattr(node, "right", None)
    if left is None or right is None:
        return None

    before = pretty_node(ast, nid)
    new_node = dst_cls(copy.deepcopy(left), copy.deepcopy(right))
    new_node.node_id = nid
    Mutation.mutationop.replace_with_node(ast, nid, new_node)
    after = pretty_node(ast, nid)

    if before == after or "(node not found)" in after:
        return None
    return f"LOR({src_cls}->{dst_cls_name}) -> {before}  ==>  {after}"


def _op_CSW(Mutation, ast, type2ids):
    """
    CSW: swap two named instance connections when both expression widths match.
    This targets connectivity-level semantic bugs while preserving compile readiness.
    """
    nid = pick_id(type2ids, "Instance")
    if nid is None:
        return None

    node = find_node_by_id(ast, nid)
    if node is None or node.__class__.__name__ != "Instance":
        return None

    before = pretty_node(ast, nid)

    # Build caches once per AST root.
    cache_key = id(ast)
    if getattr(Mutation, "_csw_cache_key", None) != cache_key:
        Mutation._csw_cache_key = cache_key
        Mutation._csw_node_to_module = _build_node_to_module(ast)
        Mutation._csw_widths = _collect_module_signal_widths(ast)

    node_to_module = getattr(Mutation, "_csw_node_to_module", {})
    module_widths = getattr(Mutation, "_csw_widths", {})

    parent_module = node_to_module.get(nid)
    if not parent_module:
        return None

    child_module = getattr(node, "module", None)
    parent_widths = module_widths.get(parent_module, {})
    child_widths = module_widths.get(child_module, {}) if child_module else {}

    port_args = [
        p
        for p in node.children()
        if p is not None and p.__class__.__name__ == "PortArg" and getattr(p, "portname", None) and getattr(p, "argname", None)
    ]
    if len(port_args) < 2:
        return None

    candidates = []
    for i in range(len(port_args)):
        for j in range(i + 1, len(port_args)):
            p1 = port_args[i]
            p2 = port_args[j]

            port1 = (getattr(p1, "portname", "") or "").strip()
            port2 = (getattr(p2, "portname", "") or "").strip()
            if not port1 or not port2:
                continue
            if _is_clock_or_reset_name(port1) or _is_clock_or_reset_name(port2):
                continue

            arg1 = getattr(p1, "argname", None)
            arg2 = getattr(p2, "argname", None)
            if arg1 is None or arg2 is None:
                continue

            w1 = _infer_expr_width(arg1, parent_widths)
            w2 = _infer_expr_width(arg2, parent_widths)
            if w1 is None or w2 is None or w1 != w2:
                continue

            fw1 = child_widths.get(port1)
            fw2 = child_widths.get(port2)
            # If formal widths are known, keep them compatible as well.
            if fw1 is not None and fw2 is not None and fw1 != fw2:
                continue

            arg1_code = " ".join(_CODEGEN.visit(arg1).split())
            arg2_code = " ".join(_CODEGEN.visit(arg2).split())
            if arg1_code == arg2_code:
                continue

            candidates.append((p1, p2, port1, port2))

    if not candidates:
        return None

    p1, p2, port1, port2 = random.choice(candidates)
    arg1 = copy.deepcopy(p1.argname)
    arg2 = copy.deepcopy(p2.argname)
    p1.argname = arg2
    p2.argname = arg1

    after = pretty_node(ast, nid)
    if before == after:
        return None
    return f"CSW({port1}<->{port2}) -> {before}  ==>  {after}"


OP_DISPATCH = {
    # Data
    "DMO": _op_DMO,
    "DMS": _op_DMS,
    "DMI": _op_DMI,
    "DIE": _op_DIE,
    # Condition
    "CMC": _op_CMC,
    # Communication / connectivity
    "CMP": _op_CMP,
    "CDP": _op_CDP,
    "CGA": _op_CGA,
    "CRV": _op_CRV,
    "CSW": _op_CSW,
    "CCW": _op_CCW,
    # Timing
    "TAA": _op_TAA,
    "TMD": _op_TMD,
    "TRA": _op_TRA,
    # Semantic / logic
    "SMC": _op_SMC,
    "AVC": _op_AVC,
    "LOR": _op_LOR,
    "CSE": _op_CSE,
    "SRC": _op_SRC,
    "SRI": _op_SRI,
    "SRA": _op_SRA,
    "SRR": _op_SRR,
    "SRW": _op_SRW,
}

OP_WEIGHT = {
    # Primary logic/connectivity ops
    "DMO": 10,
    "DMS": 10,
    "DMI": 10,
    "DIE": 10,
    "CMC": 8,
    "SMC": 7,
    "AVC": 7,
    "CMP": 6,
    "LOR": 8,
    "CSE": 7,
    "CSW": 6,
    "CCW": 2,
    # Optional non-primary ops
    "CGA": 1,
    "CRV": 1,
    "TAA": 1,
    "TMD": 1,
    # Structural fallback ops
    "SRA": 1,
    "SRR": 0,
    "SRW": 0,
    "TRA": 1,
    "SRI": 1,
    "SRC": 1,
    "CDP": 1,
}

OP_NODE_TYPE = {
    "DMO": "Pointer",
    "DMS": "Srl",
    "DMI": "Partselect",
    "DIE": "Partselect",
    "CMC": "Cond",
    "CMP": "Instance",
    "CDP": "Instance",
    "CGA": "Block",
    "CRV": "IfStatement",
    "CSW": "Instance",
    "CCW": ["Concat", "LConcat"],
    "TAA": "Block",
    "TMD": "DelayStatement",
    "SMC": "Block",
    "AVC": ["Assign", "BlockingSubstitution", "NonblockingSubstitution"],
    "LOR": sorted(set(_LOR_SWAP.keys())),
    "CSE": ["Case", "CaseStatement"],
    "SRA": "Assign",
    "SRR": "Reg",
    "SRW": "Wire",
    "TRA": "Always",
    "SRI": "IfStatement",
    "SRC": "Case",
}


def apply_mutations(ast, Mutation, ops, max_tries, target_signal=None, target_module=None):
    """
    Apply one random mutation on the AST using weighted operator selection.

    target_signal narrows candidates by signal reference.
    target_module narrows candidates to one ModuleDef when provided.
    Returns a list with one log string on success, or empty list on failure.
    """
    ops = [op for op in ops if op in OP_DISPATCH]
    if not ops:
        return []

    weights = [OP_WEIGHT.get(o, 1) for o in ops]
    logs = []
    tries = 0

    while tries < max_tries:
        tries += 1

        type2ids = collect_node_ids_by_type_in_module(ast, target_module, target_signal)

        op = random.choices(ops, weights=weights, k=1)[0]
        fn = OP_DISPATCH.get(op)
        if fn is None:
            continue

        try:
            msg = fn(Mutation, ast, type2ids)
            if msg is None:
                continue
            logs.append(f"applied. {msg}")
            break
        except Exception:
            continue

    return logs


if __name__ == "__main__":
    # Input RTL file to mutate.
    SRC = os.environ.get("SRC", "test.v")

    # Output file for the single, multi-mutated design.
    OUT = os.environ.get("OUT", "mutant.v")

    # Target signal for selective mutation (optional)
    TARGET_SIGNAL = os.environ.get("TARGET_SIGNAL", "state").strip()

    # How many total attempts before giving up (some ops may not be applicable).
    MAX_TRIES = int(os.environ.get("MAX_TRIES", str(50)))

    # Which mutation operators are enabled.
    # Override via: OPS="DMO,DIE,DMS" environment variable.
    ops_env = os.environ.get("OPS", "")
    if ops_env.strip():
        OPS = resolve_requested_operators([s.strip() for s in ops_env.split(",") if s.strip()])
    else:
        OPS = resolve_requested_operators(["all"])

    # Parse RTL into PyVerilog AST.
    ast, _ = parse([SRC])

    # Instantiate operator set.
    Mutation = MutationOperators.MutationOperators(None, None, None)
    Mutation._root = ast  # Used by DIE for width/range lookup.

    # Apply K mutations on the SAME AST (optionally filtered by target signal).
    logs = apply_mutations(ast, Mutation, OPS, MAX_TRIES, TARGET_SIGNAL)

    # Emit mutated RTL with safety normalization.
    mutated_rtl_raw = _CODEGEN.visit(ast)
    mutated_rtl, sanitize_meta = sanitize_mutated_rtl_text(mutated_rtl_raw)
    with open(OUT, "w") as f:
        f.write(mutated_rtl)

    # Print summary.
    print(f"Input : {SRC}")
    print(f"Output: {OUT}")
    if TARGET_SIGNAL:
        print(f"Target signal: {TARGET_SIGNAL}")
    print(f"Applied mutations  : {len(logs)}")
    if sanitize_meta.get("restored_decl_initializers", 0):
        print(f"Sanitizer restored declaration initializers: {sanitize_meta['restored_decl_initializers']}")
    if sanitize_meta.get("mixed_assignment_signals"):
        print(f"Sanitizer detected mixed assignment signals: {sanitize_meta['mixed_assignment_signals']}")
    print("Mutation trace:")
    for line in logs:
        print("  -", line)
