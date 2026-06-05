from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal, cast

from sqlalchemy import and_
from sqlalchemy.sql.elements import ColumnElement


@dataclass(frozen=True, slots=True)
class MinFloatValidator:
    field_name: str
    min_val: float
    epsilon: float
    kind: Literal["float_min"] = "float_min"

    def build_sql_condition(self, column: ColumnElement[Any]) -> ColumnElement[bool]:
        threshold = self.min_val - self.epsilon
        return cast(
            ColumnElement[bool],
            and_(column.is_not(None), column < threshold),
        )

    def matches_python(self, value: Any, *, pk: Any) -> bool:
        del pk
        if value is None:
            return False
        if isinstance(value, (int, float)):
            return float(value) < (self.min_val - self.epsilon)
        return False

    def format_error(self, value: Any) -> str:
        return (
            f"Field '{self.field_name}' must be >= {self.min_val} "
            f"(epsilon={self.epsilon}), got {value!r}"
        )
