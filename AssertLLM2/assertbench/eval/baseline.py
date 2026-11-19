from assertbench.core.context import MethodSubmission, RunContext
from assertbench.core.io import write_json
from assertbench.formal.base import FormalEngine
from assertbench.schemas.contracts import stamp


def _coverage_line(name: str, report: dict) -> str:
    pct = report.get("percentage")
    if pct is None:
        pct_text = "N/A"
    else:
        pct_text = f"{pct:.2f}%"
    covered = report.get("covered", 0)
    total = report.get("total", 0)
    return f"    {name:15s}: {pct_text} ({covered}/{total})"


def evaluate_baseline(ctx: RunContext, engine: FormalEngine, submission: MethodSubmission) -> dict:
    print("[*] Baseline evaluation")
    result = engine.run_baseline(ctx, submission.assertions_path)
    syntax_correctness = float(
        result.get("syntax_correctness", 0.0 if result.get("compile_error") else 1.0)
    )
    payload = stamp(
        ctx,
        "baseline_eval",
        {
            **result,
            "syntax_correctness": syntax_correctness,
            "Syntax_correctness": syntax_correctness,
        },
    )
    write_json(ctx.outdir / "baseline_eval.json", payload)

    fpv_results = payload.get("fpv", []) or []
    summary = payload.get("summary") or {}
    proven_count = int(summary.get("proven", 0) or 0)
    undetermined_count = int(summary.get("undetermined", 0) or 0)
    total_assertions = int(summary.get("total_assertions", len(fpv_results)) or len(fpv_results))
    usable_signals = sum(
        1
        for row in fpv_results
        if row.get("signal_id") and row.get("status") in ("proven", "undetermined")
    )

    print("[*] Baseline Evaluation Complete:")
    print(f"    Syntax correctness: {syntax_correctness:.2f}")
    print(f"    FPV: {proven_count} proven, {undetermined_count} undetermined (total {total_assertions})")

    coverage = payload.get("coverage") or {}
    for cov_type in ("formal", "stimuli", "checker_coi", "checker_proof"):
        if cov_type in coverage:
            print(_coverage_line(cov_type, coverage[cov_type] or {}))
    return payload
