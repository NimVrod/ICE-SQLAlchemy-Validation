from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Required:
    """Field must not be NULL."""


@dataclass(frozen=True, slots=True)
class Nullable:
    """Field may be NULL (disables implicit required-from-type rule)."""


@dataclass(frozen=True, slots=True)
class Unique:
    """Values in this column must be unique (non-NULL duplicates are flagged)."""


@dataclass(frozen=True, slots=True)
class UniqueComposite:
    """Declare on one column: this tuple of columns must be unique together."""

    columns: tuple[str, ...]

    def __init__(self, *columns: str) -> None:
        if len(columns) < 2:
            raise ValueError("UniqueComposite requires at least two column names")
        object.__setattr__(self, "columns", columns)


@dataclass(frozen=True, slots=True)
class NoNaN:
    """When set, populated values must not be NaN. NULL is allowed on optional fields."""


@dataclass(frozen=True, slots=True)
class FloatMin:
    """Populated values must be >= value - epsilon. NULL is allowed on optional fields."""

    value: float
    epsilon: float = 0.0


@dataclass(frozen=True, slots=True)
class FloatMax:
    """Populated values must be <= value + epsilon. NULL is allowed on optional fields."""

    value: float
    epsilon: float = 0.0
