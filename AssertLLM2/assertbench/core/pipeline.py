import hashlib
import random
import time
from pathlib import Path
from typing import Iterable, List

from assertbench.compat.legacy_stages import normalize_stage
from assertbench.core.context import MethodSubmission, RunContext, make_run_id
from assertbench.core.io import read_json, write_json
from assertbench.core.registry import get_method_bundle
from assertbench.eval.baseline import evaluate_baseline
from assertbench.eval.mutation import evaluate_mutants
from assertbench.formal.jasper import JasperFormalEngine
from assertbench.schemas.contracts import stamp, validate_submission

CANONICAL_STAGES = [
    "init_run",
    "execute_method_bundle",
    "evaluate_baseline",
    "evaluate_mutants",
    "finalize_manifest",
]


def _is_golden_only(cfg: dict) -> bool:
    return bool(cfg.get("benchmark", {}).get("golden_only", False))


def _validate_golden_only_mode(cfg: dict, method_id: str) -> None:
    if _is_golden_only(cfg) and method_id != "plain_prompt":
        raise ValueError(
            "benchmark.golden_only is currently supported only with method='plain_prompt'. "
            f"Got method='{method_id}'."
        )


class BenchmarkPipeline:
    def __init__(self, cfg: dict, method_id: str = "plain_prompt"):
        _validate_golden_only_mode(cfg, method_id)

        top = cfg.get("rtl", {}).get("top_module", "top")
        outdir = Path(cfg["output_dir"]) / top
        outdir.mkdir(parents=True, exist_ok=True)

        self.ctx = RunContext(
            cfg=cfg,
            outdir=outdir,
            rng=random.Random(cfg.get("seed", 0)),
            run_id=make_run_id(cfg),
            method_id=method_id,
        )
        self.method_bundle = get_method_bundle(method_id)
        self.formal_engine = JasperFormalEngine()
        self.submission: MethodSubmission | None = None

    def run(self, stages: Iterable[str]) -> None:
        normalized: List[str] = [normalize_stage(s.strip()) for s in stages if s.strip()]
        for stage in normalized:
            self.run_stage(stage)

    def run_stage(self, stage: str):
        if stage == "init_run":
            return self.init_run()
        if stage == "execute_method_bundle":
            return self.execute_method_bundle()
        if stage == "evaluate_baseline":
            return self.evaluate_baseline()
        if stage == "evaluate_mutants":
            return self.evaluate_mutants()
        if stage == "finalize_manifest":
            return self.finalize_manifest()
        raise ValueError(f"Unknown stage '{stage}'")

    def init_run(self) -> dict:
        rtl_files = self.ctx.cfg.get("rtl", {}).get("filelist", [])
        missing = [p for p in rtl_files if not Path(p).exists()]
        if missing:
            raise FileNotFoundError(f"Missing RTL files: {missing}")

        manifest = stamp(
            self.ctx,
            "run_manifest",
            {
                "timestamps": {"start": int(time.time())},
                "config_hash": hashlib.sha256(str(self.ctx.cfg).encode("utf-8")).hexdigest(),
                "config": self.ctx.cfg,
                "method": {
                    "id": self.method_bundle.method_id,
                    "version": self.method_bundle.method_version,
                },
            },
        )
        write_json(self.ctx.outdir / "manifest.json", manifest)
        return manifest

    def execute_method_bundle(self) -> dict:
        submission = self.method_bundle.execute(self.ctx)
        validate_submission(submission)
        self.submission = submission

        payload = stamp(
            self.ctx,
            "method_submission",
            {
                "assertions_file": str(submission.assertions_path),
                "method_version": submission.method_version,
                "extras_dir": str(submission.extras_dir) if submission.extras_dir else None,
            },
        )
        write_json(self.ctx.outdir / "method_submission.json", payload)
        return payload

    def evaluate_baseline(self) -> dict:
        submission = self.submission or self._load_submission_from_disk()
        return evaluate_baseline(self.ctx, self.formal_engine, submission)

    def evaluate_mutants(self) -> dict:
        return evaluate_mutants(self.ctx)

    def finalize_manifest(self) -> dict:
        manifest = read_json(self.ctx.outdir / "manifest.json")
        manifest.setdefault("timestamps", {})["end"] = int(time.time())

        checksums = {}
        for file_path in sorted(self.ctx.outdir.glob("*")):
            if file_path.is_file():
                checksums[file_path.name] = hashlib.sha256(file_path.read_bytes()).hexdigest()
        manifest["checksums"] = checksums
        write_json(self.ctx.outdir / "manifest.json", manifest)

        baseline = read_json(self.ctx.outdir / "baseline_eval.json") if (self.ctx.outdir / "baseline_eval.json").exists() else {}
        metrics = read_json(self.ctx.outdir / "metrics.json") if (self.ctx.outdir / "metrics.json").exists() else {}

        scorecard = stamp(
            self.ctx,
            "scorecard",
            {
                "syntax_correctness": baseline.get("syntax_correctness"),
                "kill_ratio": metrics.get("kill_ratio"),
                "killed": metrics.get("killed"),
                "survived": metrics.get("survived"),
                "errors": metrics.get("errors"),
                "total_assertions": baseline.get("summary", {}).get("total_assertions"),
            },
        )
        return scorecard

    def _load_submission_from_disk(self) -> MethodSubmission:
        submission_path = self.ctx.outdir / "method_submission.json"
        if submission_path.exists():
            payload = read_json(submission_path)
            method_version = payload.get("method_version", "unknown")
            assertions_file = Path(payload["assertions_file"])
            return MethodSubmission(
                assertions_path=assertions_file,
                method_id=self.ctx.method_id,
                method_version=method_version,
                extras_dir=Path(payload["extras_dir"]) if payload.get("extras_dir") else None,
            )

        fallback = self.ctx.outdir / "assertions.sv"
        if fallback.exists():
            return MethodSubmission(
                assertions_path=fallback,
                method_id=self.ctx.method_id,
                method_version="unknown",
                extras_dir=None,
            )

        raise FileNotFoundError("No method submission found. Run execute_method_bundle first.")


def load_config(config_path: Path) -> dict:
    if config_path.suffix.lower() == ".json":
        return read_json(config_path)
    return __import__("yaml").safe_load(config_path.read_text(encoding="utf-8"))
