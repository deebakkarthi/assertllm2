from abc import ABC, abstractmethod
from pathlib import Path

from assertbench.core.context import RunContext


class FormalEngine(ABC):
    @abstractmethod
    def run_baseline(self, ctx: RunContext, assertions_file: Path) -> dict:
        raise NotImplementedError
