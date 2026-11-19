import hashlib
import random
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


SCHEMA_VERSION = "1.0.0"


@dataclass
class RunContext:
    cfg: dict
    outdir: Path
    rng: random.Random
    run_id: str
    method_id: str
    schema_version: str = SCHEMA_VERSION


@dataclass
class MethodSubmission:
    assertions_path: Path
    method_id: str
    method_version: str
    extras_dir: Optional[Path] = None


def make_run_id(cfg: dict) -> str:
    seed = str(cfg.get("seed", 0))
    top = cfg.get("rtl", {}).get("top_module", "top")
    now = str(int(time.time()))
    digest = hashlib.sha256(f"{top}:{seed}:{now}".encode("utf-8")).hexdigest()[:12]
    return f"{top}-{digest}"
