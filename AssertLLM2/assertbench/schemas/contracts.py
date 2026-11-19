from pathlib import Path
from typing import Iterable

from assertbench.core.context import MethodSubmission, RunContext


class ContractError(ValueError):
    pass


def require_keys(payload: dict, keys: Iterable[str], name: str) -> None:
    missing = [k for k in keys if k not in payload]
    if missing:
        raise ContractError(f"{name} missing required keys: {missing}")


def stamp(ctx: RunContext, artifact_type: str, payload: dict) -> dict:
    out = dict(payload)
    out["schema_version"] = ctx.schema_version
    out["run_id"] = ctx.run_id
    out["method_id"] = ctx.method_id
    out["artifact_type"] = artifact_type
    out["design_id"] = ctx.cfg.get("rtl", {}).get("top_module", "top")
    return out


def validate_submission(submission: MethodSubmission) -> None:
    if not submission.assertions_path.exists():
        raise ContractError(f"Method submission missing assertions file: {submission.assertions_path}")
    if submission.assertions_path.suffix.lower() != ".sv":
        raise ContractError("Method submission must provide an assertions.sv file")
    if submission.extras_dir is not None and not Path(submission.extras_dir).exists():
        raise ContractError(f"Method extras dir does not exist: {submission.extras_dir}")
