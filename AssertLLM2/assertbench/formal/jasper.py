import re
from pathlib import Path

from run_jasper import (
    _count_assert_statements_in_sv,
    _generate_mutant_tcl,
    _parse_baseline_results,
    _remove_erroneous_assertions,
    _run_jaspergold,
    _resolve_bbox_modules,
    _update_meta_after_cex_removal,
)

from assertbench.core.context import RunContext
from assertbench.formal.base import FormalEngine


class JasperFormalEngine(FormalEngine):
    def run_baseline(self, ctx: RunContext, assertions_file: Path) -> dict:
        baseline_dir = ctx.outdir / "baseline_eval"
        (baseline_dir / "jgproject").mkdir(parents=True, exist_ok=True)

        template_path = Path(__file__).resolve().parents[2] / "jp_run_template.tcl"
        if not template_path.exists():
            raise FileNotFoundError("Missing Jasper template: jp_run_template.tcl")

        top_module = ctx.cfg["rtl"].get("top_module", "top")
        params = ctx.cfg["rtl"].get("parameters", {})
        param_str = " ".join(f"-parameter {k} {v}" for k, v in params.items())
        bbox_modules = _resolve_bbox_modules(ctx.cfg)

        tcl_content = _generate_mutant_tcl(
            template=template_path.read_text(encoding="utf-8"),
            mutant_rtl=ctx.cfg["rtl"]["filelist"],
            assertions_file=str(assertions_file),
            top_module=top_module,
            clk=ctx.cfg.get("clock_reset", {}).get("clock", "clk"),
            rst=ctx.cfg.get("clock_reset", {}).get("reset", "rst"),
            param_str=param_str,
            work_dir=baseline_dir,
            bind_file=ctx.outdir / f"{top_module}_bind.sv",
            incdir=ctx.cfg["rtl"].get("incdir", []),
            bbox_modules=bbox_modules,
        )

        tcl_file = baseline_dir / "baseline_eval.tcl"
        tcl_file.write_text(tcl_content, encoding="utf-8")

        initial_assertion_count = max(_count_assert_statements_in_sv(assertions_file), 1)
        meta_file = ctx.outdir / "assertions_meta.json"
        print(f"initial_assertion_count: {initial_assertion_count}")

        jg_result = _run_jaspergold(tcl_file, baseline_dir)
        removed_by_syntax = 0
        max_clean_rounds = 8
        for _round in range(max_clean_rounds):
            log_text = ""
            for candidate in [baseline_dir / "jg.log", baseline_dir / "jgproject" / "jg.log"]:
                if candidate.exists():
                    log_text += "\n" + candidate.read_text(encoding="utf-8", errors="ignore")
            if not re.search(r"\[ERROR \(VERI-\d+\)\]|syntax error", log_text, re.IGNORECASE):
                break

            removed = _remove_erroneous_assertions(log_text, assertions_file)
            if removed <= 0:
                break
            removed_by_syntax += removed
            if meta_file.exists():
                _update_meta_after_cex_removal(meta_file, assertions_file)
            tcl_content = _generate_mutant_tcl(
                template=template_path.read_text(encoding="utf-8"),
                mutant_rtl=ctx.cfg["rtl"]["filelist"],
                assertions_file=str(assertions_file),
                top_module=top_module,
                clk=ctx.cfg.get("clock_reset", {}).get("clock", "clk"),
                rst=ctx.cfg.get("clock_reset", {}).get("reset", "rst"),
                param_str=param_str,
                work_dir=baseline_dir,
                bind_file=ctx.outdir / f"{top_module}_bind.sv",
                incdir=ctx.cfg["rtl"].get("incdir", []),
                bbox_modules=bbox_modules,
            )
            tcl_file.write_text(tcl_content, encoding="utf-8")
            jg_result = _run_jaspergold(tcl_file, baseline_dir)

        compile_error = False
        for candidate in [baseline_dir / "jg.log", baseline_dir / "jgproject" / "jg.log"]:
            if candidate.exists():
                log_text = candidate.read_text(encoding="utf-8", errors="ignore")
                if re.search(r"\[ERROR \(VERI-\d+\)\]|syntax error", log_text, re.IGNORECASE):
                    compile_error = True
                    break

        assertions_meta = []
        if meta_file.exists():
            import json

            assertions_meta = json.loads(meta_file.read_text(encoding="utf-8")).get("assertions", [])

        fpv_results, coverage, cex_assert_nums = _parse_baseline_results(
            baseline_dir,
            assertions_meta,
            assertions_file=assertions_file,
            meta_file=meta_file if meta_file.exists() else None,
        )

        proven = sum(1 for r in fpv_results if r["status"] == "proven")
        cex = sum(1 for r in fpv_results if r["status"] == "cex")
        undetermined = sum(1 for r in fpv_results if r["status"] == "undetermined")
        remaining_after_syntax = len(fpv_results)
        syntax_correctness = max(0.0, min(1.0, remaining_after_syntax / initial_assertion_count))
        print(f"remove assertions: {initial_assertion_count - remaining_after_syntax}")
        remaining_in_sv = _count_assert_statements_in_sv(assertions_file)

        return {
            "engine_status": jg_result.get("status", "error"),
            "engine_error": jg_result.get("error"),
            "compile_error": compile_error,
            "syntax_correctness": syntax_correctness,
            "Syntax_correctness": syntax_correctness,
            "initial_assertion_count": initial_assertion_count,
            "assertions_remaining_after_syntax": remaining_after_syntax,
            "assertions_removed_by_syntax": max(initial_assertion_count - remaining_after_syntax, 0),
            "assertions_remaining_in_sv": remaining_in_sv,
            "assertions_removed_total_in_sv": max(initial_assertion_count - remaining_in_sv, 0),
            "removed_block_count": removed_by_syntax,
            "cex_removed": sorted(cex_assert_nums),
            "fpv": fpv_results,
            "coverage": coverage,
            "summary": {
                "total_assertions": len(fpv_results),
                "proven": proven,
                "cex": cex,
                "undetermined": undetermined,
            },
        }
