from abc import ABC, abstractmethod

from assertbench.core.context import MethodSubmission, RunContext


class MethodBundle(ABC):
    method_id: str
    method_version: str

    @abstractmethod
    def execute(self, ctx: RunContext) -> MethodSubmission:
        raise NotImplementedError
