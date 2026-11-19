LEGACY_TO_CANONICAL = {
    "m0": "init_run",
    "m1": "execute_method_bundle",
    "m2": "evaluate_baseline",
    "m3": "evaluate_mutants",
    "m4": "finalize_manifest",
}


def normalize_stage(stage: str) -> str:
    return LEGACY_TO_CANONICAL.get(stage, stage)
