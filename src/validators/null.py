from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal, cast

from sqlalchemy.sql.elements import ColumnElement


@dataclass(frozen=True, slots=True)
class NullValidator:
    field_name: str
    kind: Literal["null"] = "null"
    requires_python: bool = False

    def build_sql_condition(self, column: ColumnElement[Any]) -> ColumnElement[bool]:
        return cast(ColumnElement[bool], column.is_(None))

    def matches_python(self, value: Any, *, pk: Any) -> bool:
        del pk
        return value is None

    def format_error(self, value: Any) -> str:
        del value
        return f"Field '{self.field_name}' must not be NULL"
