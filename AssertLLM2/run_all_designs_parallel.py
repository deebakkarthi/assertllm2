#!/usr/bin/env python3
"""
Parallel batch runner for AssertLLM2 pipeline.

This script is intentionally separate from run_all_designs.py.
It runs one design per worker process and keeps existing runners unchanged.

Design selection:
  --dataset lite|all   preset design set (default: all)
  --designs KEY ...    optional subset of the selected dataset
"""

from __future__ import annotations

import argparse
from concurrent.futures import FIRST_COMPLETED, ProcessPoolExecutor, wait
from copy import deepcopy
import json
import os
from pathlib import Path
import re
import sys
import time
import traceback
from typing import Any, Dict, Optional

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from assertbench.core.bug_hunting import apply_bug_hunting_golden_output_dir_segment
from assertbench.core.pipeline import BenchmarkPipeline, CANONICAL_STAGES
from assertbench.core.spec_input import apply_raw_spec_output_dir_segment, resolve_spec_input_source

DEFAULT_DESIGNS_JSON = SCRIPT_DIR / "configs" / "assertllm2_design_configs.json"
DEFAULT_LITE_JSON = SCRIPT_DIR / "configs" / "assertllm2_lite.json"
DEFAULT_BATCH_CONFIGS_DIR = SCRIPT_DIR / "configs" / "batch_configs_assertllm2_parallel"
DEFAULT_RESULTS_JSON = SCRIPT_DIR / "out" / "batch_results_assertllm2_parallel.json"
DEFAULT_OUTPUT_DIR = "out"
DEFAULT_METHOD = "plain_prompt"
DEFAULT_LLM_PROVIDER = "gemini"
DEFAULT_MODEL_ID = "gemini-3.5-flash-lite"

TEMPLATE_KEYS = ["llm", "formal", "mutation", "bug_hunting", "seed", "design_type", "spec_input_source"]

PLAIN_CONFIG_TEMPLATE = {
    "llm": {
        "provider": DEFAULT_LLM_PROVIDER,
        "model_id": DEFAULT_MODEL_ID,
    },
    "formal": {
        "engine": "jaspergold",
        "timeout_s": 60,
        "equivalence": "sec-preferred-screening",
    },
    "mutation": {
        "mode": "instrumented",
        "budget": 20,
        "operators": ["all"],
        "target_source": "rtl_hierarchy",
        "scope_policy": "top_and_direct_submodules",
        "include_top_with_submodules": True,
    },
    "seed": 7,
    "output_dir": DEFAULT_OUTPUT_DIR,
}


def _deep_merge_dict(base: dict, override: dict) -> dict:
    out = deepcopy(base)
    for key, value in override.items():
        if isinstance(out.get(key), dict) and isinstance(value, dict):
            out[key] = _deep_merge_dict(out[key], value)
        else:
            out[key] = deepcopy(value)
    return out


def _load_json(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def dataset_design_ids(lite_doc: dict, dataset: str, all_design_keys: set[str]) -> list[str]:
    """Return design keys for a preset. ``all`` is the full design index; other names are lists in the lite JSON."""
    if dataset == "all":
        return sorted(all_design_keys)
    raw_designs = lite_doc.get(dataset)
    if not isinstance(raw_designs, list) or not raw_designs:
        known = ", ".join(sorted([*lite_doc.keys(), "all"]))
        raise ValueError(f"Unknown dataset {dataset!r}. Known datasets: {known}")

    ids: list[str] = []
    for item in raw_designs:
        if not isinstance(item, str) or not item.strip():
            raise ValueError(f"Dataset {dataset!r} must be a list of design keys")
        ids.append(item.strip())

    if len(ids) != len(set(ids)):
        raise ValueError(f"Dataset {dataset!r} contains duplicate design ids")
    missing = [design_id for design_id in ids if design_id not in all_design_keys]
    if missing:
        joined = ", ".join(missing)
        raise ValueError(
            f"Dataset {dataset!r} references designs missing from the design index: {joined}"
        )
    return ids


def select_designs(
    all_designs: dict,
    dataset_ids: list[str],
    design_keys: Optional[list[str]],
    dataset_name: str,
) -> dict:
    """Keep ``dataset_ids``, then optionally narrow them with ``--designs``."""
    selected = {key: all_designs[key] for key in dataset_ids}
    if not design_keys:
        return selected

    filtered: dict = {}
    for key in design_keys:
        if key in selected:
            filtered[key] = selected[key]
        elif key in all_designs and dataset_name != "all":
            print(f"WARNING: {key} is not in dataset {dataset_name}")
        else:
            print(f"WARNING: {key} not found in designs JSON")
    return filtered


def _write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def _safe_name(design_key: str) -> str:
    raw = design_key.replace("/", "__")
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", raw)


def _safe_model_segment(merged: dict) -> str:
    """Sanitized llm.model_id for use as a single path component (replaces legacy parallel_runs/)."""
    mid = (merged.get("llm") or {}).get("model_id")
    if not mid or not str(mid).strip():
        seg = "parallel_runs"
    else:
        raw = str(mid).strip().replace("/", "__")
        seg = re.sub(r"[^A-Za-z0-9_.-]+", "_", raw)
    return seg


def _design_outdir(merged: dict) -> Optional[Path]:
    out = merged.get("output_dir")
    top = (merged.get("rtl") or {}).get("top_module")
    if not out or not top:
        return None
    return Path(out) / top


def collect_batch_metrics(merged: dict) -> dict:
    out: dict[str, Any] = {
        "syntax_correctness": None,
        "fpv": None,
        "coverage": None,
        "mutation_kill_rate": None,
        "mutation_killed": None,
        "mutation_survived": None,
        "mutation_errors": None,
        "mutation_total_tested": None,
    }
    outdir = _design_outdir(merged)
    if outdir is None or not outdir.is_dir():
        return out

    baseline_path = outdir / "baseline_eval.json"
    if baseline_path.exists():
        be = _load_json(baseline_path)
        sc = be.get("Syntax_correctness")
        if sc is None:
            sc = be.get("syntax_correctness")
        out["syntax_correctness"] = sc

        summ = be.get("summary") or {}
        if summ:
            out["fpv"] = {
                "proven": summ.get("proven"),
                "cex": summ.get("cex"),
                "undetermined": summ.get("undetermined"),
                "total_assertions": summ.get("total_assertions"),
            }

        cov = be.get("coverage")
        if cov:
            out["coverage"] = cov

    metrics_path = outdir / "metrics.json"
    if metrics_path.exists():
        m = _load_json(metrics_path)
        out["mutation_kill_rate"] = m.get("kill_ratio")
        out["mutation_killed"] = m.get("killed")
        out["mutation_survived"] = m.get("survived")
        out["mutation_errors"] = m.get("errors")
        out["mutation_total_tested"] = m.get("total_tested")

    return out


def plain_config_template() -> dict:
    return deepcopy(PLAIN_CONFIG_TEMPLATE)


def merge_config(design_cfg: dict, template_cfg: dict) -> dict:
    merged = {}
    merged["spec_file"] = design_cfg["spec_file"]
    merged["rtl"] = design_cfg["rtl"]

    clocks = design_cfg.get("clock_reset", {}).get("clocks", [])
    merged["clock_reset"] = {
        "clock": [c.get("signal", "") for c in clocks],
        "reset": design_cfg.get("clock_reset", {}).get("reset", ""),
    }

    for key in TEMPLATE_KEYS:
        if key in template_cfg:
            merged[key] = deepcopy(template_cfg[key])

    if template_cfg.get("output_dir") is not None:
        merged["output_dir"] = template_cfg["output_dir"]

    if design_cfg.get("output_dir") is not None:
        merged["output_dir"] = design_cfg["output_dir"]

    for key in TEMPLATE_KEYS:
        if key not in design_cfg:
            continue
        if isinstance(merged.get(key), dict) and isinstance(design_cfg[key], dict):
            merged[key] = _deep_merge_dict(merged[key], design_cfg[key])
        else:
            merged[key] = deepcopy(design_cfg[key])

    return merged


def apply_runtime_overrides(
    merged: dict,
    model_id: Optional[str],
    api_key: Optional[str],
    bug_hunting_prompt_rtl_source: Optional[str] = None,
    bug_hunting_prompt_context_mode: bool = False,
    spec_input_source: Optional[str] = None,
) -> dict:
    llm_cfg = dict(merged.get("llm", {}))
    llm_cfg.pop("API_KEY", None)
    if model_id:
        llm_cfg["model_id"] = model_id
    if api_key is not None:
        llm_cfg["API_KEY"] = api_key
    merged["llm"] = llm_cfg
    if bug_hunting_prompt_rtl_source is not None or bug_hunting_prompt_context_mode:
        bug_cfg = dict(merged.get("bug_hunting", {}))
        if bug_hunting_prompt_rtl_source is not None:
            bug_cfg["prompt_rtl_source"] = bug_hunting_prompt_rtl_source
        if bug_hunting_prompt_context_mode:
            bug_cfg["enabled"] = True
        merged["bug_hunting"] = bug_cfg
    if spec_input_source is not None:
        merged["spec_input_source"] = spec_input_source
    apply_bug_hunting_golden_output_dir_segment(merged)
    if resolve_spec_input_source(merged.get("spec_input_source")) == "raw":
        apply_raw_spec_output_dir_segment(merged)
    return merged


def _resolve_output_dir_for_run(
    merged: dict,
    safe_name: str,
    run_i: int,
    pass_k: int,
) -> str:
    base_out = Path(merged["output_dir"])
    scoped = base_out / _safe_model_segment(merged)
    if pass_k > 1:
        return str(scoped / f"{safe_name}_pass{run_i}")
    return str(scoped / safe_name)


def _run_design_task(task: dict) -> dict:
    name: str = task["name"]
    safe_name: str = task["safe_name"]
    design_cfg: dict = task["design_cfg"]
    template_cfg: dict = task["template_cfg"]
    stages: list[str] = task["stages"]
    method: str = task["method"]
    pass_k: int = task["pass_k"]
    dry_run: bool = task["dry_run"]
    batch_configs_dir = Path(task["batch_configs_dir"])
    model_id_override: Optional[str] = task.get("model_id")
    api_key_override: Optional[str] = task.get("api_key")
    bug_hunting_prompt_rtl_source: Optional[str] = task.get("bug_hunting_prompt_rtl_source")
    bug_hunting_prompt_context_mode: bool = bool(task.get("bug_hunting_prompt_context_mode"))
    spec_input_source: Optional[str] = task.get("spec_input_source")

    rows: dict[str, Any] = {}
    failures = 0
    t_design = time.time()

    for run_i in range(1, pass_k + 1):
        merged = merge_config(design_cfg, template_cfg)
        merged = apply_runtime_overrides(
            merged,
            model_id_override,
            api_key_override,
            bug_hunting_prompt_rtl_source,
            bug_hunting_prompt_context_mode,
            spec_input_source,
        )
        merged["output_dir"] = _resolve_output_dir_for_run(
            merged=merged,
            safe_name=safe_name,
            run_i=run_i,
            pass_k=pass_k,
        )

        result_key = f"{name}_{run_i}" if pass_k > 1 else name
        cfg_path = (
            batch_configs_dir / f"{safe_name}_pass{run_i}.json"
            if pass_k > 1
            else batch_configs_dir / f"{safe_name}.json"
        )
        _write_json(cfg_path, merged)

        if dry_run:
            rows[result_key] = "dry-run"
            continue

        t0 = time.time()
        try:
            pipeline = BenchmarkPipeline(cfg=merged, method_id=method)
            pipeline.run(stages)
            elapsed = time.time() - t0
            row: dict[str, Any] = {"status": "OK", "elapsed_s": round(elapsed, 1)}
            row.update(collect_batch_metrics(merged))
            rows[result_key] = row
        except Exception as exc:
            elapsed = time.time() - t0
            failures += 1
            rows[result_key] = {
                "status": f"FAIL: {exc}",
                "elapsed_s": round(elapsed, 1),
                "error_type": type(exc).__name__,
                "traceback": traceback.format_exc(limit=20),
            }

    design_status = "OK" if failures == 0 else "FAIL"
    return {
        "name": name,
        "status": design_status,
        "failures": failures,
        "elapsed_s": round(time.time() - t_design, 1),
        "rows": rows,
    }


def main() -> None:
    start_time = time.time()
    parser = argparse.ArgumentParser(
        description="Run AssertLLM2 pipeline in parallel (one design per process).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "examples:\n"
            "  python run_all_designs_parallel.py --dataset lite --model-id <model> --api-key \"$YOUR_API_KEY\"\n"
            "  python run_all_designs_parallel.py --dataset all --jobs 8 --api-key \"$YOUR_API_KEY\"\n"
            "  python run_all_designs_parallel.py --designs assertllm2/communication_controller/ethernet\n"
        ),
    )
    parser.add_argument(
        "--dataset",
        choices=["lite", "all"],
        default="all",
        help=(
            "Preset design set. lite is AssertLLM2-Lite (25 designs); "
            "all is the full benchmark (default). --designs further restricts this set."
        ),
    )
    parser.add_argument(
        "--designs",
        nargs="*",
        default=None,
        help="Only run these design keys. Intersected with --dataset when both are set.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Only write per-design configs")
    parser.add_argument("--model-id", default=None, help="Override merged config llm.model_id")
    parser.add_argument("--api-key", default=None, help="Set merged config llm.API_KEY for this run")
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
    parser.add_argument("--pass-k", type=int, default=1, metavar="K", help="Run each design K times")
    parser.add_argument("--jobs", type=int, default=None, help="Worker processes (default: auto)")
    args = parser.parse_args()

    if args.pass_k < 1:
        print("ERROR: --pass-k must be >= 1")
        sys.exit(1)
    if args.jobs is not None and args.jobs < 1:
        print("ERROR: --jobs must be >= 1")
        sys.exit(1)
    if args.api_key is not None:
        args.api_key = args.api_key.strip()
        if not args.api_key:
            print("ERROR: --api-key must not be empty")
            sys.exit(1)
    if args.spec_input_source is not None:
        args.spec_input_source = args.spec_input_source.strip()
        if not args.spec_input_source:
            print("ERROR: --spec-input-source must not be empty")
            sys.exit(1)

    designs_path = DEFAULT_DESIGNS_JSON
    batch_configs_dir = DEFAULT_BATCH_CONFIGS_DIR
    results_out = DEFAULT_RESULTS_JSON

    if not designs_path.exists():
        print(f"ERROR: Designs JSON not found: {designs_path}")
        sys.exit(1)

    all_designs = _load_json(designs_path)
    template_cfg = plain_config_template()

    dataset_name = args.dataset
    try:
        if dataset_name == "all":
            dataset_ids = dataset_design_ids({}, dataset_name, set(all_designs))
        else:
            if not DEFAULT_LITE_JSON.exists():
                print(f"ERROR: Lite JSON not found: {DEFAULT_LITE_JSON}")
                sys.exit(1)
            lite_doc = _load_json(DEFAULT_LITE_JSON)
            dataset_ids = dataset_design_ids(lite_doc, dataset_name, set(all_designs))
    except ValueError as exc:
        print(f"ERROR: {exc}")
        sys.exit(1)

    designs = select_designs(all_designs, dataset_ids, args.designs, dataset_name)

    if not designs:
        print("No designs to run.")
        sys.exit(0)

    sorted_items = sorted(designs.items())

    batch_configs_dir.mkdir(parents=True, exist_ok=True)

    auto_jobs = min(len(sorted_items), max(1, os.cpu_count() or 1))
    jobs = args.jobs if args.jobs is not None else auto_jobs

    print(
        f"AssertLLM2 parallel run: dataset={dataset_name}, designs={len(sorted_items)}, "
        f"jobs={jobs}, method={DEFAULT_METHOD}, pass_k={args.pass_k}"
    )
    if args.designs:
        print(f"Dataset preset {dataset_name} has {len(dataset_ids)} designs; --designs kept {len(sorted_items)}")
    print(f"Designs JSON: {designs_path}")
    if dataset_name != "all":
        print(f"Lite JSON: {DEFAULT_LITE_JSON}")
    print("Config template: built-in plain_prompt template")
    print(f"Batch configs: {batch_configs_dir}")
    print(f"Results out:  {results_out}")
    print("Output isolation: out/<model-id>/<design>")
    if args.model_id:
        print(f"Override model_id: {args.model_id}")
    if args.api_key:
        print("Override API key: provided")
    if args.bug_hunting_prompt_rtl_source:
        print(f"Override bug_hunting.prompt_rtl_source: {args.bug_hunting_prompt_rtl_source}")
    if args.bug_hunting_prompt_context_mode:
        print("Bug hunting prompt context: enabled (spec + RTL)")
    if args.spec_input_source:
        print(f"Override spec_input_source: {args.spec_input_source}")
    if args.dry_run:
        print("DRY-RUN: no pipeline execution")
    print()

    tasks: list[dict] = []
    for name, dcfg in sorted_items:
        tasks.append(
            {
                "name": name,
                "safe_name": _safe_name(name),
                "design_cfg": dcfg,
                "template_cfg": template_cfg,
                "stages": list(CANONICAL_STAGES),
                "method": DEFAULT_METHOD,
                "pass_k": args.pass_k,
                "dry_run": args.dry_run,
                "batch_configs_dir": str(batch_configs_dir),
                "model_id": args.model_id,
                "api_key": args.api_key,
                "bug_hunting_prompt_rtl_source": args.bug_hunting_prompt_rtl_source,
                "bug_hunting_prompt_context_mode": args.bug_hunting_prompt_context_mode,
                "spec_input_source": args.spec_input_source,
            }
        )

    results: dict[str, Any] = {}
    completed = 0

    pending = list(tasks)
    running: dict[Any, str] = {}

    with ProcessPoolExecutor(max_workers=jobs) as pool:
        while pending and len(running) < jobs:
            task = pending.pop(0)
            fut = pool.submit(_run_design_task, task)
            running[fut] = task["name"]

        while running:
            done, _ = wait(running.keys(), return_when=FIRST_COMPLETED)
            for fut in done:
                name = running.pop(fut)
                completed += 1
                try:
                    payload = fut.result()
                except Exception as exc:
                    payload = {
                        "name": name,
                        "status": "FAIL",
                        "failures": 1,
                        "elapsed_s": 0.0,
                        "rows": {
                            name: {
                                "status": f"FAIL: worker crashed: {exc}",
                                "error_type": type(exc).__name__,
                                "traceback": traceback.format_exc(limit=200),
                            }
                        },
                    }

                results.update(payload["rows"])
                print(f"[{completed}/{len(tasks)}] {payload['name']} -> {payload['status']} ({payload['elapsed_s']:.1f}s)")

            while pending and len(running) < jobs:
                task = pending.pop(0)
                fut = pool.submit(_run_design_task, task)
                running[fut] = task["name"]

    _write_json(results_out, results)
    print(f"\nResults saved to {results_out}")

    ok = sum(1 for v in results.values() if isinstance(v, dict) and v.get("status") == "OK")
    fail = sum(
        1
        for v in results.values()
        if isinstance(v, dict) and isinstance(v.get("status"), str) and v.get("status", "").startswith("FAIL")
    )
    other = len(results) - ok - fail
    print(f"Summary: {ok} OK, {fail} FAIL, {other} other")
    print(f"Total time: {time.time() - start_time:.2f} seconds")


if __name__ == "__main__":
    main()
