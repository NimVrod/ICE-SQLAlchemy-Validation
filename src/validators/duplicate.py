from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal


@dataclass(frozen=True, slots=True)
class DuplicateValidator:
    field_name: str
    columns: tuple[str, ...]
    kind: Literal["duplicate"] = "duplicate"
    requires_python: bool = False

    def build_sql_condition(self, column: Any) -> Any:
        del column
        raise NotImplementedError("Duplicate checks are table-wide and built in the engine.")

    def matches_python(self, value: Any, *, pk: Any) -> bool:
        del value
        del pk
        return True

    def format_error(self, value: Any) -> str:
        if len(self.columns) == 1:
            return f"Duplicate value '{value}' for unique field '{self.columns[0]}'"
        return f"Duplicate value '{value}' for unique fields {self.columns}"
