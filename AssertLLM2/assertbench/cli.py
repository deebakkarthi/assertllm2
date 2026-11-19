import argparse
from pathlib import Path

from assertbench.core.bug_hunting import apply_bug_hunting_golden_output_dir_segment
from assertbench.core.pipeline import BenchmarkPipeline, CANONICAL_STAGES, load_config
from assertbench.core.spec_input import apply_raw_spec_output_dir_segment, resolve_spec_input_source


def main() -> None:
    default_cfg = Path("configs/config.json")
    if not default_cfg.exists():
        default_cfg = Path("config.json")

    parser = argparse.ArgumentParser(
        description="AssertLLM2 CLI (single design). For batch: python run_all_designs_parallel.py"
    )
    parser.add_argument("--config", default=str(default_cfg))
    parser.add_argument("--method", default="plain_prompt", help="Method: plain_prompt")
    parser.add_argument("--stage", default="all")
    parser.add_argument("--golden-only", action="store_true")
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
    if args.golden_only:
        cfg.setdefault("benchmark", {})
        cfg["benchmark"]["golden_only"] = True
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
    pipeline = BenchmarkPipeline(cfg=cfg, method_id=args.method)

    print("model_id: ", cfg["llm"]["model_id"])

    if args.stage == "all":
        stages = CANONICAL_STAGES
    else:
        stages = [s.strip() for s in args.stage.split(",") if s.strip()]

    pipeline.run(stages)


if __name__ == "__main__":
    main()
