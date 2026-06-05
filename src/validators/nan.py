from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any, Literal, cast

from sqlalchemy.sql.elements import ColumnElement


@dataclass(frozen=True, slots=True)
class NaNValidator:
    field_name: str
    kind: Literal["nan"] = "nan"

    def build_sql_condition(self, column: ColumnElement[Any]) -> ColumnElement[bool]:
        # Portable prefilter: fetch populated values, confirm NaN in Python.
        return cast(ColumnElement[bool], column.is_not(None))

    def matches_python(self, value: Any, *, pk: Any) -> bool:
        del pk
        if value is None:
            return False
        if isinstance(value, float):
            return math.isnan(value)
        return False

    def format_error(self, value: Any) -> str:
        del value
        return f"Field '{self.field_name}' must not be NaN"
