import re
from collections import defaultdict
from typing import Dict, List, Set


_BACKTICK_TOKEN_RE = re.compile(r"`([A-Za-z_]\w*)`")
_HEADING_RE = re.compile(r"^\s{0,3}(#{1,6})\s*(.+?)\s*$")


def _extract_modules_from_text(text: str, module_names: Set[str]) -> Set[str]:
    hits = set()
    for token in _BACKTICK_TOKEN_RE.findall(text):
        if token in module_names:
            hits.add(token)
    return hits


def _extract_backtick_tokens(text: str) -> List[str]:
    return _BACKTICK_TOKEN_RE.findall(text)


def _build_structural_indexes(structural: dict) -> tuple[Dict[str, Set[str]], Dict[str, Set[str]]]:
    module_to_signals: Dict[str, Set[str]] = defaultdict(set)
    signal_to_modules: Dict[str, Set[str]] = defaultdict(set)
    for sig in structural.get("signals", []):
        mod = sig.get("module")
        name = sig.get("name")
        if not mod or not name:
            continue
        module_to_signals[mod].add(name)
        signal_to_modules[name].add(mod)
    return module_to_signals, signal_to_modules


def extract_spec_module_signal_targets(
    spec_text: str,
    structural: dict,
    top_module: str,
    include_top_with_submodules: bool = True,
    no_submodule_fallback: str = "top_only",
) -> dict:
    """
    Deterministically extract module/signal targets from explicit submodule sections.

    This parser intentionally relies on markdown-like section structure and backticked
    identifiers to stay deterministic (no LLM dependency).
    """
    module_to_signals, signal_to_modules = _build_structural_indexes(structural)
    module_names = set(module_to_signals.keys())
    lines = spec_text.splitlines()

    # Track explicit submodule region + current module subsection.
    in_submodule_region = False
    submodule_level = 0
    current_module = None
    current_module_level = 0

    explicit_submodules: Set[str] = set()
    module_section_lines: Dict[str, List[str]] = defaultdict(list)
    unmatched_module_mentions: Set[str] = set()

    for raw_line in lines:
        line = raw_line.rstrip("\n")
        heading_match = _HEADING_RE.match(line)
        if heading_match:
            level = len(heading_match.group(1))
            title = heading_match.group(2).strip()
            title_lower = title.lower()

            if in_submodule_region and level <= submodule_level and "submodule" not in title_lower:
                in_submodule_region = False
                current_module = None
                current_module_level = 0

            if "submodule" in title_lower:
                in_submodule_region = True
                submodule_level = level
                current_module = None
                current_module_level = 0

            if in_submodule_region:
                mods = _extract_modules_from_text(title, module_names)
                if mods:
                    for mod in mods:
                        if mod != top_module:
                            explicit_submodules.add(mod)
                    if len(mods) == 1:
                        current_module = next(iter(mods))
                        current_module_level = level
                    else:
                        current_module = None
                        current_module_level = 0
                elif current_module and level <= current_module_level:
                    current_module = None
                    current_module_level = 0
            continue

        if not in_submodule_region:
            # Explicit "one `foo` instance" style declarations outside the submodule heading.
            if re.search(r"\b(instance|submodule)\b", line, re.IGNORECASE):
                mods = _extract_modules_from_text(line, module_names)
                for mod in mods:
                    if mod != top_module:
                        explicit_submodules.add(mod)
            continue

        mods_in_line = _extract_modules_from_text(line, module_names)
        if mods_in_line and re.search(r"\b(instance|module)\b", line, re.IGNORECASE):
            for mod in mods_in_line:
                if mod != top_module:
                    explicit_submodules.add(mod)
            if len(mods_in_line) == 1:
                current_module = next(iter(mods_in_line))

        # Capture unknown module tokens in backticks for diagnostics.
        for token in _extract_backtick_tokens(line):
            if token not in module_names and re.search(r"\b(module|submodule|instance)\b", line, re.IGNORECASE):
                unmatched_module_mentions.add(token)

        if current_module:
            module_section_lines[current_module].append(line)

    module_signal_mentions: Dict[str, Set[str]] = defaultdict(set)
    for mod in sorted(explicit_submodules):
        valid_signals = module_to_signals.get(mod, set())
        if not valid_signals:
            continue
        for line in module_section_lines.get(mod, []):
            for token in _extract_backtick_tokens(line):
                if token in valid_signals:
                    module_signal_mentions[mod].add(token)

    all_backtick_tokens = _extract_backtick_tokens(spec_text)
    top_signals = module_to_signals.get(top_module, set())
    top_signal_mentions = {tok for tok in all_backtick_tokens if tok in top_signals}

    has_explicit_submodules = len(explicit_submodules) > 0
    selected_submodules = sorted(
        mod for mod in explicit_submodules if module_signal_mentions.get(mod)
    )

    fallback_applied = "none"
    if not selected_submodules and has_explicit_submodules and no_submodule_fallback == "top_only":
        fallback_applied = "top_only_no_submodule_signals"
    elif not selected_submodules and not has_explicit_submodules and no_submodule_fallback == "top_only":
        fallback_applied = "top_only_no_explicit_submodules"

    module_targets = []
    for mod in selected_submodules:
        signals = sorted(module_signal_mentions.get(mod, set()))
        if not signals:
            continue
        module_targets.append(
            {
                "module": mod,
                "signals": signals,
                "signal_ids": [f"{mod}.{sig}" for sig in signals],
                "source": "spec_submodule_section",
            }
        )

    if include_top_with_submodules and top_signal_mentions:
        module_targets.append(
            {
                "module": top_module,
                "signals": sorted(top_signal_mentions),
                "signal_ids": [f"{top_module}.{sig}" for sig in sorted(top_signal_mentions)],
                "source": "top_spec_mentions",
            }
        )
    elif (not selected_submodules) and no_submodule_fallback == "top_only" and top_signal_mentions:
        module_targets = [
            {
                "module": top_module,
                "signals": sorted(top_signal_mentions),
                "signal_ids": [f"{top_module}.{sig}" for sig in sorted(top_signal_mentions)],
                "source": "top_only_fallback",
            }
        ]

    spec_signal_to_modules: Dict[str, List[str]] = defaultdict(list)
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
        "has_explicit_submodules": has_explicit_submodules,
        "explicit_submodules": sorted(explicit_submodules),
        "selected_submodules": selected_submodules,
        "module_targets": module_targets,
        "spec_signal_to_modules": dict(spec_signal_to_modules),
        "fallback_applied": fallback_applied,
        "diagnostics": {
            "unmatched_module_mentions": sorted(unmatched_module_mentions),
            "ambiguous_spec_signals": ambiguous_spec_signals,
            "module_signal_counts": {
                t["module"]: len(t["signals"]) for t in module_targets
            },
        },
        "structural_summary": {
            "modules": sorted(module_names),
            "module_count": len(module_names),
            "signal_count": len(structural.get("signals", [])),
            "signal_to_modules": {
                sig: sorted(mods) for sig, mods in signal_to_modules.items()
            },
        },
    }
