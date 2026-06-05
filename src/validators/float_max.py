from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal, cast

from sqlalchemy import and_
from sqlalchemy.sql.elements import ColumnElement


@dataclass(frozen=True, slots=True)
class MaxFloatValidator:
    field_name: str
    max_val: float
    epsilon: float
    kind: Literal["float_max"] = "float_max"

    def build_sql_condition(self, column: ColumnElement[Any]) -> ColumnElement[bool]:
        threshold = self.max_val + self.epsilon
        return cast(
            ColumnElement[bool],
            and_(column.is_not(None), column > threshold),
        )

    def matches_python(self, value: Any, *, pk: Any) -> bool:
        del pk
        if value is None:
            return False
        if isinstance(value, (int, float)):
            return float(value) > (self.max_val + self.epsilon)
        return False

    def format_error(self, value: Any) -> str:
        return (
            f"Field '{self.field_name}' must be <= {self.max_val} "
            f"(epsilon={self.epsilon}), got {value!r}"
        )
