import re
from pathlib import Path

from client import RealLLMClient

from assertbench.core.bug_hunting import bug_hunting_enabled, get_bug_hunting_prompt_rtl_files
from assertbench.core.context import MethodSubmission, RunContext
from assertbench.core.io import write_json
from assertbench.core.rtl_metadata import extract_structural_metadata
from assertbench.core.rtl_wrapper_schema import build_wrapper_schema, format_width_decl
from assertbench.core.spec_input import (
    load_spec_text_from_paths,
    resolve_raw_spec_files_from_config,
    resolve_spec_input_source,
)
from assertbench.methods.base import MethodBundle


# _SYSTEM_PROMPT = """You are an expert verification engineer specializing in SystemVerilog Assertions (SVA).

# Generate assertions from specification text only. Do not assume hidden implementation details.
# Use only wrapper-safe signal names provided in the prompt namespace.

# Output format is strict:
# // [signal] <wrapper_signal_name>
# ```systemverilog
# <assertions for this wrapper signal>
# ```

# Rules:
# - Use ONLY wrapper-safe names listed in the namespace section.
# - Do NOT use raw RTL names.
# - Do NOT use hierarchy paths.
# - Do NOT use module.signal names.
# - Keep assertions syntactically valid.
# - Do NOT emit prose outside signal blocks.
# - Do NOT emit markdown fences "```".
# - Do NOT emit the word `systemverilog`.
# - The signal line must be a comment line, exactly in the form:
#   // [signal] <wrapper_signal_name>
# """

_PROMPT_DIR = Path(__file__).resolve().parent
_SYSTEM_PROMPT = (_PROMPT_DIR / "system_prompt_detailed.txt").read_text(encoding="utf-8")
_BUG_HUNTING_SYSTEM_PROMPT = (_PROMPT_DIR / "system_prompt_bug_hunting.txt").read_text(encoding="utf-8")

_GOLDEN_ONLY_SYSTEM_PROMPT = """You are an expert verification engineer specializing in SystemVerilog Assertions (SVA).

Use the provided golden RTL text as the only behavioral source of truth.
Translate explicit RTL behavior into assertions using only the canonical wrapper-safe signal names.
Do not infer or invent behavior that is not explicitly supported by the RTL text and guards.

Output contract (must be followed exactly):
- Output one or more signal blocks.
- Each block starts with: [signal] <canonical_wrapper_name>
- After the header, output plain SystemVerilog assertion text only.
- Do not emit markdown code fences.
- Do not emit the word `systemverilog`.
- Do not emit prose outside signal blocks.
- Do not emit module/bind/property declarations; emit inline assertion text only.
"""

def _list_existing_paths(paths: list[str]) -> list[str]:
    existing = []
    for p in paths:
        path = Path(p)
        if path.exists():
            existing.append(str(path))
    return existing


def _load_spec_text(cfg: dict) -> str:
    spec_paths = cfg.get("spec_file") or []
    parts = []
    for p in spec_paths:
        path = Path(p)
        if path.exists():
            parts.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n\n---\n\n".join(parts) if parts else ""


def _load_golden_rtl_text(cfg: dict) -> tuple[str, list[str]]:
    rtl_paths = cfg.get("rtl", {}).get("filelist", []) or []
    parts = []
    loaded_paths = []
    for p in rtl_paths:
        path = Path(p)
        if not path.exists():
            continue
        loaded_paths.append(str(path))
        rtl_text = path.read_text(encoding="utf-8", errors="ignore")
        parts.append(f"// RTL file: {path}\n{rtl_text}")
    return "\n\n// ---\n\n".join(parts) if parts else "", loaded_paths


def _extract_include_files(path: str) -> list[str]:
    with open(path, "r", encoding="utf-8", errors="ignore") as file:
        text = file.read()
    pattern = re.compile(
        r"`include\s+(?:\"([^\"]*)\"|'([^']*)'|<([^>]+)>)",
        re.IGNORECASE,
    )
    matches: list[str] = []
    for groups in pattern.findall(text):
        fragment = next((g for g in groups if g), None)
        if fragment and not fragment.lower().endswith(".vh"):
            matches.append(fragment)
    return matches


def _normalize_clocks(clock_value) -> list[str]:
    if not clock_value:
        return []
    if isinstance(clock_value, str):
        return [clock_value]
    if isinstance(clock_value, list):
        return [c for c in clock_value if c]
    return []


def _strip_comments(code: str) -> str:
    code = re.sub(r"/\*.*?\*/", " ", code, flags=re.DOTALL)
    code = re.sub(r"//.*", "", code)
    return code


def _extract_identifiers(code: str) -> set[str]:
    return set(re.findall(r"\b[A-Za-z_]\w*\b", _strip_comments(code)))


def _clean_generated_code(code_block: str) -> str:
    code = code_block.strip()
    code = re.sub(r"^```(?:systemverilog|verilog|sv)?\s*", "", code, flags=re.IGNORECASE)
    code = re.sub(r"\s*```$", "", code)
    code = re.sub(r"\[Assertion\]", "", code, flags=re.IGNORECASE)
    return code.strip()


def _collect_include_lines(cfg: dict) -> list[str]:
    lines = []
    seen = set()

    for folder in cfg.get("rtl", {}).get("incdir", []):
        folder_path = Path(folder)
        candidate = folder_path / f"{folder_path.name}.v"
        if candidate.exists():
            inc = f'`include "{candidate}"'
            if inc not in seen:
                seen.add(inc)
                lines.append(inc)

    # for rtl_file in cfg.get("rtl", {}).get("filelist", []):
    rtl_file = cfg.get("rtl", {}).get("filelist", [])[0]
    rtl_path = Path(rtl_file)
    if not rtl_path.exists():
        pass
    else:
        for inc in _extract_include_files(str(rtl_path)):
            line = f'`include "{inc}"'
            if line not in seen:
                seen.add(line)
                lines.append(line)

    return lines


def _render_wrapper_namespace(entries: list[dict]) -> str:
    rows = []
    for entry in sorted(entries, key=lambda e: e["wrapper_name"]):
        width = entry.get("width", 1)
        module_type = entry.get("module_type", "")
        path = entry.get("instance_path_str", "")
        endpoint = f"{module_type}.{entry.get('rtl_signal', '')}"
        if path:
            endpoint = f"{path}.{entry.get('rtl_signal', '')}"
        rows.append(
            f"- {entry['wrapper_name']} (width={width}) -> {endpoint}"
        )
    return "\n".join(rows)

def _is_balanced_parens(expr: str) -> bool:
    depth = 0
    for ch in expr:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def _build_bind_reference_map(entries: list[dict]) -> dict[str, str]:
    out: dict[str, str] = {}
    for entry in entries:
        if entry.get("is_helper"):
            continue
        wrapper = entry.get("wrapper_name")
        signal = entry.get("rtl_signal")
        if not wrapper or not signal:
            continue
        path = entry.get("instance_path_str", "")
        if path:
            out[f"{path}.{signal}"] = wrapper
        else:
            out[signal] = wrapper
    return out


def _translate_helper_bind_expr(expr: str, ref_map: dict[str, str]) -> tuple[str, list[str]]:
    # Convert hierarchical refs in helper expressions into checker wrapper names.
    # Example: frontend_0.decode -> omsp_frontend_decode
    token_re = re.compile(r"\b((?:[A-Za-z_]\w*\.)*[A-Za-z_]\w*)(\[[^\]]+\])?")
    macro_like_re = re.compile(r"^[A-Z][A-Z0-9_]*$")
    unknown: set[str] = set()
    raw = (expr or "").strip()

    def _replace(match: re.Match) -> str:
        base = match.group(1)
        suffix = match.group(2) or ""
        mapped = ref_map.get(base)
        if mapped:
            return f"{mapped}{suffix}"

        # Macro-like uppercase tokens should be emitted with backtick.
        # Avoid double-backtick when source already has `TOKEN.
        prev_char = raw[match.start() - 1] if match.start() > 0 else ""
        if macro_like_re.match(base):
            prefix = "" if prev_char == "`" else "`"
            return f"{prefix}{base}{suffix}"

        if "." in base:
            unknown.add(base)
        return f"{base}{suffix}"

    translated = token_re.sub(_replace, raw)
    translated = re.sub(r"\s+", " ", translated).strip()
    if not translated:
        return "", sorted(unknown)
    if not _is_balanced_parens(translated):
        unknown.add("<unbalanced_parentheses>")
        return "", sorted(unknown)
    return translated, sorted(unknown)





class PlainPromptBundle(MethodBundle):
    method_id = "plain_prompt"
    method_version = "1.5.0"

    def execute(self, ctx: RunContext) -> MethodSubmission:
        benchmark_cfg = ctx.cfg.get("benchmark", {})
        golden_only = bool(benchmark_cfg.get("golden_only", False))
        bug_hunting = bug_hunting_enabled(ctx.cfg)
        bug_cfg = ctx.cfg.get("bug_hunting", {})
        task_prompt = benchmark_cfg.get("plain_prompt", "")
        prompt_file = benchmark_cfg.get("plain_prompt_file")

        if prompt_file and not task_prompt:
            task_prompt = Path(prompt_file).read_text(encoding="utf-8")

        if not task_prompt:
            if bug_hunting:
                task_prompt = (
                    """
                    Generate syntactically correct SystemVerilog assertions that help expose
                    behavioral deviations in the provided RTL. Focus on direct, high-signal
                    checks supported by the visible context. Do not invent requirements.
                    """
                )
            elif golden_only:
                task_prompt = (
                    """
                    Generate syntactically correct SystemVerilog assertions by translating the golden RTL logic.
                    Treat the provided RTL as the only source of truth.
                    Generate high-value assertions only for behavior explicitly present in the RTL implementation.
                    Do not invent requirements, states, protocols, timing rules, or semantics not supported by the RTL text.
                    """
                )
            else:
                task_prompt = (
                    """
                    Generate syntactically correct SystemVerilog assertions that reflect the specification.
                    Generate as many high-value, specification-grounded assertions as possible.
                    You should aggressively cover:
                    - interface constraints,
                    - functional behavior,
                    - operational semantics,
                    - control/data relationships,
                    - protocol rules,
                    - timing and sequencing constraints,
                    - priorities and arbitration rules,
                    - stall / freeze / hold behavior,
                    - fault / exception handling,
                    - legal invariants,
                    - explicitly stated or strongly implied requirements.
                    """
                )

        spec_input_source = resolve_spec_input_source(
            ctx.cfg.get("spec_input_source") or benchmark_cfg.get("spec_input_source")
        )
        if spec_input_source == "raw":
            spec_source_files = resolve_raw_spec_files_from_config(ctx.cfg)
            spec_text = load_spec_text_from_paths(spec_source_files)
        else:
            spec_source_files = _list_existing_paths(ctx.cfg.get("spec_file") or [])
            spec_text = _load_spec_text(ctx.cfg)

        prompt_context_title = "Specification document"
        prompt_context_text = spec_text
        prompt_context_empty_message = "(No spec file provided in config.)"
        prompt_context_sources = spec_source_files
        prompt_context_sections = [
            (prompt_context_title, prompt_context_text, prompt_context_empty_message)
        ]
        prompt_rtl_files = list(ctx.cfg.get("rtl", {}).get("filelist", []) or [])
        if bug_hunting:
            bug_prompt_rtl_files = get_bug_hunting_prompt_rtl_files(ctx.cfg, ctx.outdir)
            if bug_prompt_rtl_files:
                prompt_rtl_files = bug_prompt_rtl_files
            rtl_context_text, rtl_context_sources = _load_golden_rtl_text(
                {"rtl": {"filelist": prompt_rtl_files}}
            )
            prompt_context_title = "Specification document and bug-hunting RTL source"
            prompt_context_text = "\n\n".join(
                part for part in [spec_text, rtl_context_text] if part.strip()
            )
            prompt_context_empty_message = "(No spec or RTL context available.)"
            prompt_context_sources = spec_source_files + rtl_context_sources
            prompt_context_sections = [
                ("Specification document", spec_text, "(No spec file provided in config.)"),
                (
                    "Bug-hunting RTL source",
                    rtl_context_text,
                    "(No RTL files available for bug-hunting prompt.)",
                ),
            ]
        elif golden_only:
            golden_rtl_text, golden_rtl_files = _load_golden_rtl_text(ctx.cfg)
            prompt_context_title = "Golden RTL source"
            prompt_context_text = golden_rtl_text
            prompt_context_empty_message = "(No RTL files provided in config.)"
            prompt_context_sources = golden_rtl_files
            prompt_context_sections = [
                (prompt_context_title, prompt_context_text, prompt_context_empty_message)
            ]

        top_module = ctx.cfg.get("rtl", {}).get("top_module", "top")
        clock_reset = ctx.cfg.get("clock_reset", {})
        clk_names = _normalize_clocks(clock_reset.get("clock", ""))
        rst_name = clock_reset.get("reset", "")
        design_type = "sequential" if clk_names else "combinational"

        assertions_path = ctx.outdir / "assertions.sv"
        bind_path = ctx.outdir / f"{top_module}_bind.sv"

        llm_cfg = ctx.cfg.get("llm", {})
        client = RealLLMClient(
            provider=llm_cfg["provider"],
            model=llm_cfg["model_id"],
            api_key=llm_cfg.get("API_KEY"),
        )

        structural = extract_structural_metadata(prompt_rtl_files, top_module)

        from assertbench.core.rtl_wrapper_schema import (
            extract_golden_semantic_targets,
            extract_rtl_module_signal_targets,
        )
        from assertbench.core.spec_targets import extract_spec_module_signal_targets

        mut_cfg = ctx.cfg.get("mutation", {})
        include_top_with_submodules = bool(mut_cfg.get("include_top_with_submodules", True))
        no_submodule_fallback = str(mut_cfg.get("no_submodule_fallback", "top_only"))
        target_source = str(mut_cfg.get("target_source", "rtl_hierarchy"))

        def _coerce_int(value, default: int) -> int:
            try:
                return int(value)
            except Exception:
                return default

        golden_namespace_cap = max(50, _coerce_int(mut_cfg.get("golden_namespace_cap", 400), 400))
        golden_helper_cap = max(0, _coerce_int(mut_cfg.get("golden_helper_cap", 160), 160))
        golden_helper_cap = min(golden_helper_cap, golden_namespace_cap)

        effective_target_source = target_source
        if golden_only:
            effective_target_source = "golden_semantic"
            spec_targets = extract_golden_semantic_targets(
                structural=structural,
                rtl_files=prompt_rtl_files,
                top_module=top_module,
                namespace_cap=golden_namespace_cap,
                helper_cap=golden_helper_cap,
            )
        elif target_source == "spec_submodule_signals":
            spec_targets = extract_spec_module_signal_targets(
                spec_text=spec_text,
                structural=structural,
                top_module=top_module,
                include_top_with_submodules=include_top_with_submodules,
                no_submodule_fallback=no_submodule_fallback,
            )
        else:
            spec_targets = extract_rtl_module_signal_targets(
                structural=structural,
                rtl_files=prompt_rtl_files,
                top_module=top_module,
            )
        spec_targets["config"] = {
            "include_top_with_submodules": include_top_with_submodules,
            "no_submodule_fallback": no_submodule_fallback,
            "target_source": effective_target_source,
            "requested_target_source": target_source,
            "golden_namespace_cap": golden_namespace_cap if golden_only else None,
            "golden_helper_cap": golden_helper_cap if golden_only else None,
        }
        write_json(ctx.outdir / "spec_mutation_targets.json", spec_targets)

        wrapper_schema = build_wrapper_schema(
            rtl_files=prompt_rtl_files,
            top_module=top_module,
            structural=structural,
            spec_targets=spec_targets,
            clock_names=clk_names,
            reset_name=rst_name,
            semantic_helpers=spec_targets.get("semantic_helpers", []) if golden_only else None,
            namespace_cap=golden_namespace_cap if golden_only else None,
            helper_cap=golden_helper_cap if golden_only else None,
        )

        entries = list(wrapper_schema.get("entries", []))
        if not entries:
            top_signals = [
                s for s in structural.get("signals", [])
                if s.get("module") == top_module and s.get("name")
            ]
            if top_signals:
                top_signals = sorted(top_signals, key=lambda s: s["name"])
                seed = top_signals[0]
                entries = [
                    {
                        "wrapper_name": f"top_{seed['name']}",
                        "module_type": top_module,
                        "rtl_signal": seed["name"],
                        "instance_path": [],
                        "instance_path_str": "",
                        "source_kind": "top",
                        "width": seed.get("width", 1),
                        "width_decl": format_width_decl(
                            seed.get("width", 1), seed.get("packed_range")
                        ),
                        "direction": seed.get("direction", "wire"),
                        "signal_id": seed.get("signal_id", f"{top_module}.{seed['name']}"),
                        "bind_expr": seed["name"],
                        "source_reasons": ["fallback_top_signal"],
                        "collision_group": None,
                        "is_helper": False,
                        "mutation_eligible": True,
                    }
                ]
                wrapper_schema["entries"] = entries
                wrapper_schema["allowed_wrapper_names"] = [entries[0]["wrapper_name"]]
                wrapper_schema.setdefault("diagnostics", {})["fallback_used"] = True

        raw_entries = [e for e in entries if not e.get("is_helper")]
        helper_entries = [e for e in entries if e.get("is_helper")]
        dropped_helper_bindings = []
        materialized_helper_entries = []

        if helper_entries:
            bind_ref_map = _build_bind_reference_map(raw_entries)
            for helper_entry in helper_entries:
                translated_expr, unknown_refs = _translate_helper_bind_expr(
                    str(helper_entry.get("bind_expr", "")),
                    bind_ref_map,
                )
                if not translated_expr:
                    dropped_helper_bindings.append(
                        {
                            "wrapper_name": helper_entry.get("wrapper_name"),
                            "module_type": helper_entry.get("module_type"),
                            "instance_path": helper_entry.get("instance_path_str", ""),
                            "reason": "unresolved_or_malformed_helper_expression",
                            "unknown_refs": unknown_refs,
                            "original_expr": helper_entry.get("bind_expr", ""),
                        }
                    )
                    continue
                h = dict(helper_entry)
                h["helper_wrapper_expr"] = translated_expr
                materialized_helper_entries.append(h)

        entries = sorted(raw_entries + materialized_helper_entries, key=lambda e: e["wrapper_name"])
        wrapper_schema["entries"] = entries
        wrapper_schema["allowed_wrapper_names"] = [e["wrapper_name"] for e in entries]
        helper_diag = wrapper_schema.setdefault("diagnostics", {}).setdefault("semantic_helpers", {})
        helper_diag["retained_after_wrapper_translation"] = len(materialized_helper_entries)
        helper_diag["dropped_after_wrapper_translation"] = dropped_helper_bindings

        wrappers_by_name = {e["wrapper_name"]: e for e in entries}
        allowed_wrapper_names = sorted(wrappers_by_name.keys())
        known_raw_signals = {
            s.get("name") for s in structural.get("signals", []) if s.get("name")
        }
        forbidden_raw_signals = known_raw_signals - set(allowed_wrapper_names)

        clock_wrappers = [
            e["wrapper_name"]
            for e in entries
            if e.get("source_kind") == "top" and e.get("rtl_signal") in clk_names
        ]
        reset_wrappers = [
            e["wrapper_name"]
            for e in entries
            if e.get("source_kind") == "top" and e.get("rtl_signal") == rst_name
        ]
        primary_clock = clock_wrappers[0] if clock_wrappers else ""
        primary_reset = reset_wrappers[0] if reset_wrappers else ""

        write_json(ctx.outdir / "wrapper_schema.json", wrapper_schema)

        if design_type == "combinational":
            design_ctx = (
                "## Design context\n"
                f"- Top module name: {top_module}\n"
                "- Design type: combinational (no clock). Use immediate assertions.\n\n"
            )
        else:
            design_ctx = (
                "## Design context\n"
                f"- Top module name: {top_module}\n"
                "- Design type: sequential. Use assert property (@(posedge ...)).\n"
                f"- Wrapper clock(s): {clock_wrappers or ['<none>']}\n"
                f"- Wrapper reset: {primary_reset or '<none>'}\n\n"
            )

        clock_reset_hint = ""
        if design_type == "sequential" and primary_clock:
            if primary_reset:
                # if reset end with _n, then use disable iff
                is_active_low = (
                    (primary_reset.endswith("n") and not primary_reset.endswith("in"))
                    or primary_reset.startswith("n")
                    or primary_reset.endswith("_b")
                    or primary_reset.endswith("_l")
                )
                if is_active_low:
                    clock_reset_hint = (
                        f"Use `@(posedge {primary_clock}) disable iff (!{primary_reset})` unless the requirement applies during reset."
                    )
                else:
                    clock_reset_hint = (
                        f"Use `@(posedge {primary_clock}) disable iff ({primary_reset})` unless the requirement applies during reset."
                    )
            else:
                clock_reset_hint = f"Use `@(posedge {primary_clock})` for sequential properties."

        namespace_text = _render_wrapper_namespace(entries)

        clock_rule_line = f"- {clock_reset_hint}\n" if clock_reset_hint else ""
        prompt_context_block = "".join(
            f"## {title}\n"
            "```\n"
            f"{text or empty_message}\n"
            "```\n\n"
            for title, text, empty_message in prompt_context_sections
        )

        if golden_only:
            system_prompt = _GOLDEN_ONLY_SYSTEM_PROMPT
            user_prompt = (
                design_ctx
                + prompt_context_block
                + "## Wrapper-safe signal namespace\n"
                f"{namespace_text or '- <empty namespace>'}\n\n"
                "## Task Definition\n"
                "- The RTL above is golden and is the only behavioral source of truth.\n"
                "- Translate RTL logic into assertions using canonical wrapper names only.\n"
                "- Generate as many directly supported, non-duplicate assertions as possible by exhaustively mining each procedural block, continuous assignment, and decode structure.\n"
                "- Prioritize correctness and explicit RTL support over sheer quantity.\n"
                "- Do not stop after reset-value and write-effect assertions; keep mining hold/stability/decode/gating families when directly supported.\n\n"
                "## Semantic Constraints\n"
                "- Derive assertions only from explicit RTL behavior under full enclosing guard structure.\n"
                "- Do NOT invent requirements, hidden states, or specification-style intent not visible in RTL.\n"
                "- Do NOT introduce cycle-accurate timing, persistence, or sequencing constraints unless directly evident in RTL guards/updates.\n"
                "- Avoid multiple cosmetic variants of the same property.\n"
                "- Avoid trivial assertions that only restate signal existence or static assignments unless verification-relevant.\n"
                "- If exact controlling signal/field is unavailable in canonical namespace, do not approximate; skip the assertion.\n"
                "- Before asserting from an assignment, analyze full enclosing always/case/if-else and account for higher-priority guards/overwrite paths.\n"
                "- Maximize assertion count in two tiers: Tier 1 exact local low-risk; Tier 2 richer guarded temporal only when all guards/state/completion conditions are explicit. Exhaust Tier 1 first.\n"
                "- Priority order: (1) exact single/same-cycle safety, (2) guarded multi-cycle safety with explicit RTL support, (3) bounded temporal progress only with explicit completion+gating, (4) no unbounded liveness unless explicit and self-contained in RTL.\n\n"
                "## Assertion Families To Mine\n"
                "For each eligible RTL logic block, attempt families directly supported by RTL:\n"
                "- reset value\n"
                "- write/update effect\n"
                "- hold/stability when no update occurs\n"
                "- hold when another address is written\n"
                "- hold under disabled conditions\n"
                "- field-specific stability for unaffected bits\n"
                "- decode/mux correspondence\n"
                "- constant outputs\n"
                "- one-cycle pulse behavior\n"
                "- gating/enable dependence\n"
                "- mutual exclusion or reserved-bit clearing\n"
                "For each eligible register/output with explicit update logic, try to mine 3-6 distinct assertions across these families when directly supported.\n\n"
                "## Naming Constraints\n"
                "- Use ONLY wrapper names from the namespace above.\n"
                "- Do NOT use raw RTL names.\n"
                "- Do NOT use hierarchy paths and do NOT use module.signal names.\n"
                "- Every [signal] label must be one wrapper name from the namespace.\n"
                + clock_rule_line
                + "\n"
                "## Output Format\n"
                "- Emit one or more blocks.\n"
                "- Each block must start with: [signal] <wrapper_name>\n"
                "- After header, emit plain SystemVerilog assertion text only.\n"
                "- Do NOT emit markdown fences.\n"
                "- Do NOT emit the word `systemverilog`.\n"
                "- Do NOT emit prose outside signal blocks.\n"
                "- Each block must contain at least one real assertion statement.\n"
                "- If no supported assertion exists for a candidate, omit that block.\n\n"
                "## Additional Task Instruction\n"
                f"{task_prompt}\n"
            )
        else:
            system_prompt = _BUG_HUNTING_SYSTEM_PROMPT if bug_hunting else _SYSTEM_PROMPT
            user_prompt = (
                design_ctx
                + prompt_context_block
                + "## Wrapper-safe signal namespace (STRICT)\n"
                f"{namespace_text or '- <empty namespace>'}\n\n"
                "## Mandatory naming rules\n"
                "- Use ONLY wrapper names from the namespace above.\n"
                "- Do NOT use raw RTL names.\n"
                "- Do NOT use hierarchy paths and do NOT use module.signal names.\n"
                "- Every [signal] label must be one wrapper name from the namespace.\n"
                "- Do NOT emit markdown fences.\n"
                "- Do NOT emit the word `systemverilog`.\n"
                + clock_rule_line
                + "\n"
                "## Your task\n"
                f"{task_prompt}\n\n"
                "Respond only with signal-comment blocks and plain SystemVerilog assertion text."
            )

        user_prompt_path = ctx.outdir / "llm_user_prompt.txt"
        full_prompt_path = ctx.outdir / "llm_full_prompt.txt"
        user_prompt_path.write_text(user_prompt, encoding="utf-8")
        full_prompt_path.write_text(
            "### SYSTEM PROMPT\n"
            f"{system_prompt}\n\n"
            "### USER PROMPT\n"
            f"{user_prompt}\n",
            encoding="utf-8",
        )

        print(" Calling LLM to generate assertions...")
        response = client.complete(system_prompt, user_prompt)
        if response is None:
            # Persist a breadcrumb; downstream regex expects a string.
            try:
                out_debug = ctx.outdir / "llm_response_null.json"
                out_debug.write_text(
                    '{"note":"RealLLMClient.complete returned None (expected str)."}\n',
                    encoding="utf-8",
                )
            except Exception:
                pass
            response = ""

        block_pattern = re.compile(
            r"\[signal\]\s*([A-Za-z_]\w*)\s*(.*?)(?=\[signal\]|$)",
            re.DOTALL | re.IGNORECASE,
        )
        matches = block_pattern.findall(response)

        if not matches and allowed_wrapper_names:
            fallback_body = _clean_generated_code(response)
            if fallback_body:
                matches = [(allowed_wrapper_names[0], fallback_body)]

        all_assertions = []
        dropped_assertions = []

        for raw_label, code_block in matches:
            raw_label = raw_label.strip()
            code = _clean_generated_code(code_block)
            if not code:
                dropped_assertions.append(
                    {
                        "signal_label_raw": raw_label,
                        "reason": "empty_code_block",
                    }
                )
                continue

            if raw_label not in wrappers_by_name:
                dropped_assertions.append(
                    {
                        "signal_label_raw": raw_label,
                        "reason": "unknown_wrapper_label",
                    }
                )
                continue

            if re.search(r"\b[A-Za-z_]\w*\s*\.\s*[A-Za-z_]\w*\b", _strip_comments(code)):
                dropped_assertions.append(
                    {
                        "signal_label_raw": raw_label,
                        "reason": "hierarchical_or_module_dot_reference_forbidden",
                    }
                )
                continue

            identifiers = _extract_identifiers(code)
            referenced_wrappers = sorted(i for i in identifiers if i in wrappers_by_name)
            if not referenced_wrappers:
                dropped_assertions.append(
                    {
                        "signal_label_raw": raw_label,
                        "reason": "no_wrapper_signal_reference",
                    }
                )
                continue

            raw_hits = sorted(i for i in identifiers if i in forbidden_raw_signals)
            if raw_hits:
                dropped_assertions.append(
                    {
                        "signal_label_raw": raw_label,
                        "reason": "raw_signal_name_used",
                        "details": raw_hits[:20],
                    }
                )
                continue

            wrapper_entry = wrappers_by_name[raw_label]
            unique_signal_label = raw_label
            resolved_signal_id = wrapper_entry.get("signal_id", "")
            inst_path = wrapper_entry.get("instance_path_str", "")
            if inst_path:
                resolved_signal_id = f"{resolved_signal_id}@{inst_path}"

            header = (
                f"\n//{'=' * 70}\n"
                f"// Assertions for Signal: {unique_signal_label}\n"
                f"// Primary label from model: {raw_label}\n"
                f"//{'=' * 70}\n"
            )
            final_code = header + code

            assertion_entry = {
                "signal_name": unique_signal_label,
                "signal_id": resolved_signal_id,
                "signal_label_raw": raw_label,
                "wrapper_name": raw_label,
                "source_module": wrapper_entry.get("module_type"),
                "source_signal": wrapper_entry.get("rtl_signal"),
                "source_instance_path": inst_path,
                "assertion_types": ["plain_prompt"],
                "code": final_code,
                "related_requirements": [],
                "referenced_wrappers": referenced_wrappers,
            }
            all_assertions.append(assertion_entry)

        if not all_assertions:
            fallback_label = allowed_wrapper_names[0] if allowed_wrapper_names else "top_unknown_signal"
            fallback_code = (
                "// Pseudo fallback assertion\n"
                "initial begin\n"
                "    assert (1'b1);\n"
                "end\n"
            )
            fallback_entry = {
                "signal_name": fallback_label,
                "signal_id": fallback_label,
                "signal_label_raw": fallback_label,
                "wrapper_name": fallback_label,
                "source_module": top_module,
                "source_signal": "unknown_signal",
                "source_instance_path": "",
                "assertion_types": ["plain_prompt_fallback"],
                "code": (
                    f"\n//{'=' * 70}\n"
                    f"// Assertions for Signal: {fallback_label}\n"
                    f"//{'=' * 70}\n"
                    f"{fallback_code}"
                ),
                "related_requirements": [],
                "referenced_wrappers": [fallback_label],
            }
            all_assertions.append(fallback_entry)

        checker_module_name = f"{top_module}_sva_global"

        sorted_entries = sorted(entries, key=lambda e: e["wrapper_name"])
        sorted_port_entries = [e for e in sorted_entries if not e.get("is_helper")]
        sorted_helper_entries = [
            e for e in sorted_entries
            if e.get("is_helper") and e.get("helper_wrapper_expr")
        ]

        port_defs = []
        bind_ports = []
        for entry in sorted_port_entries:
            width_str = entry.get("width_decl") or format_width_decl(
                entry.get("width", 1), entry.get("packed_range")
            )
            port_defs.append(f"    input logic {width_str}{entry['wrapper_name']}")
            bind_ports.append(f".{entry['wrapper_name']}({entry['bind_expr']})")

        if port_defs:
            ports_text = ",\n".join(port_defs)
            module_header = f"module {checker_module_name} (\n{ports_text}\n);"
        else:
            module_header = f"module {checker_module_name} ();"

        helper_lines = []
        if sorted_helper_entries:
            helper_lines.append("// Auto-generated helper observables")
            for entry in sorted_helper_entries:
                helper_lines.append(f"logic {entry['wrapper_name']};")
            for entry in sorted_helper_entries:
                helper_lines.append(
                    f"assign {entry['wrapper_name']} = {entry['helper_wrapper_expr']};"
                )

        body_parts = []
        if helper_lines:
            body_parts.append("\n".join(helper_lines))
        body_parts.append("\n\n".join(a["code"] for a in all_assertions))
        module_body = "\n\n".join(part for part in body_parts if part.strip())

        checker_text = (
            f"// Global checker bound to top module: {top_module}\n"
            f"{module_header}\n"
            f"{module_body}\n"
            "endmodule\n"
        )

        include_lines = _collect_include_lines(ctx.cfg)
        include_text = "\n".join(include_lines)

        sva_parts = []
        if include_text:
            sva_parts.append(include_text)
        sva_parts.append(f"// method: {self.method_id}")
        sva_parts.append(checker_text)
        sva_content = "\n\n".join(sva_parts) + "\n"
        assertions_path.write_text(sva_content, encoding="utf-8")

        if bind_ports:
            bind_ports_text = ",\n    ".join(bind_ports)
            bind_content = (
                "// Auto-generated global bind file for plain_prompt\n\n"
                f"bind {top_module} {checker_module_name} u_{checker_module_name} (\n"
                f"    {bind_ports_text}\n"
                ");\n"
            )
        else:
            bind_content = (
                "// Auto-generated global bind file for plain_prompt\n\n"
                f"bind {top_module} {checker_module_name} u_{checker_module_name} ();\n"
            )
        bind_path.write_text(bind_content, encoding="utf-8")

        checker_manifest = [
            {
                "bind_target": top_module,
                "checker_module": checker_module_name,
                "assertion_count": len(all_assertions),
                "port_count": len(sorted_port_entries),
                "ports": [e["wrapper_name"] for e in sorted_port_entries],
                "helper_count": len(sorted_helper_entries),
                "helpers": [e["wrapper_name"] for e in sorted_helper_entries],
            }
        ]

        write_json(
            ctx.outdir / "assertions_meta.json",
            {
                "assertions": all_assertions,
                "total_signals": len(all_assertions),
                "assertions_generated": len(all_assertions),
                "assertion_types": ["plain_prompt"],
                "generation_method": self.method_id,
                "clock": clk_names,
                "reset": rst_name,
                "wrapper_schema_file": str(ctx.outdir / "wrapper_schema.json"),
            },
        )

        return MethodSubmission(
            assertions_path=assertions_path,
            method_id=self.method_id,
            method_version=self.method_version,
            extras_dir=None,
        )
