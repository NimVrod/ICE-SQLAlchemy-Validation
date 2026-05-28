from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal, Protocol, TypeVar

from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.sql.elements import ColumnElement


ValidatorKind = Literal["null", "duplicate", "nan", "float_min", "float_max"]


@dataclass(frozen=True, slots=True)
class ValidationError:
    table: str
    id: int | str
    field: str
    error: str
    validator: ValidatorKind


ModelT = TypeVar("ModelT", bound=DeclarativeBase)


class BaseValidator(Protocol):
    kind: ValidatorKind
    field_name: str
    requires_python: bool

    def build_sql_condition(self, column: ColumnElement[Any]) -> ColumnElement[bool]:
        """Return a SQL condition that identifies invalid rows."""

    def matches_python(self, value: Any, *, pk: Any) -> bool:
        """Safely checks whether the row value violates this validator."""

    def format_error(self, value: Any) -> str:
        """Build a stable, user-facing error message."""
