from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal, cast

from sqlalchemy import text
from sqlalchemy.sql.elements import ColumnElement


@dataclass(frozen=True, slots=True)
class ConstraintValidator:
    field_name: str
    constraint_name: str
    predicate_sql: str
    constraint_sql: str
    kind: Literal["constraint"] = "constraint"

    def build_sql_condition(self, column: ColumnElement[Any]) -> ColumnElement[bool]:
        del column
        return cast(ColumnElement[bool], text(f"NOT ({self.predicate_sql})"))

    def matches_python(self, value: Any, *, pk: Any) -> bool:
        del value
        del pk
        return True

    def format_error(self, value: Any) -> str:
        del value
        return (
            f"Constraint '{self.constraint_name}' failed for '{self.field_name}'. "
            f"Rule: {self.constraint_sql}"
        )
