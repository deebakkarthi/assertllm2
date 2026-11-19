import argparse
import random
from pathlib import Path

from assertbench.core.bug_hunting import apply_bug_hunting_golden_output_dir_segment
from assertbench.core.pipeline import BenchmarkPipeline, CANONICAL_STAGES, load_config
from assertbench.core.rtl_metadata import detect_top_module_from_top_file
from assertbench.core.spec_input import apply_raw_spec_output_dir_segment, resolve_spec_input_source


def _expand_stages(stage_arg: str) -> list[str]:
    if stage_arg == "all":
        return list(CANONICAL_STAGES)
    return [stage.strip() for stage in stage_arg.split(",") if stage.strip()]


def main() -> None:
    parser = argparse.ArgumentParser(description="AssertLLM2 pipeline runner")
    parser.add_argument("--config", default="configs/config.json")
    parser.add_argument("--method", default="plain_prompt", help="Method: plain_prompt")
    parser.add_argument("--stage", default="all")
    parser.add_argument(
        "--bug-hunting-prompt-rtl-source",
        choices=["buggy", "golden"],
        default=None,
        help="Override bug_hunting.prompt_rtl_source for this run",
    )
    parser.add_argument(
        "--bug-hunting-prompt-context-mode",
        action="store_true",
        help="Enable bug hunting prompt context for this run (spec + RTL)",
    )
    parser.add_argument(
        "--spec-input-source",
        choices=["spec_md", "raw"],
        default=None,
        help="Override spec input source for this run",
    )
    args = parser.parse_args()

    cfg = load_config(Path(args.config))
    cfg.setdefault("output_dir", "out")
    cfg.setdefault("seed", 0)

    rtl_cfg = cfg.setdefault("rtl", {})
    rtl_files = rtl_cfg.get("filelist", [])
    configured_top = rtl_cfg.get("top_module", "")
    rtl_cfg["top_module"] = detect_top_module_from_top_file(rtl_files, configured_top)

    if args.bug_hunting_prompt_rtl_source is not None:
        cfg.setdefault("bug_hunting", {})
        cfg["bug_hunting"]["prompt_rtl_source"] = args.bug_hunting_prompt_rtl_source
    if args.bug_hunting_prompt_context_mode:
        cfg.setdefault("bug_hunting", {})
        cfg["bug_hunting"]["enabled"] = True
    if args.spec_input_source is not None:
        cfg["spec_input_source"] = args.spec_input_source

    apply_bug_hunting_golden_output_dir_segment(cfg)
    if resolve_spec_input_source(cfg.get("spec_input_source")) == "raw":
        apply_raw_spec_output_dir_segment(cfg)

    random.seed(cfg["seed"])

    pipeline = BenchmarkPipeline(cfg=cfg, method_id=args.method)
    pipeline.run(_expand_stages(args.stage))


if __name__ == "__main__":
    main()
