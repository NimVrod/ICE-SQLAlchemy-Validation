from __future__ import annotations

from collections.abc import Callable
from typing import Any

import pytest
from sqlalchemy.orm import Session

from src.engine import MigrationValidator
from src.pandas_ import errors_to_dataframe
from src.validation_types import ValidationError


@pytest.fixture
def migration_validator(session: Session) -> MigrationValidator:
    return MigrationValidator(session)


@pytest.fixture
def validation_errors(
    migration_validator: MigrationValidator,
) -> Callable[[type[Any]], list[ValidationError]]:
    def _run(model_cls: type[Any]) -> list[ValidationError]:
        return migration_validator.validate(model_cls)

    return _run


def assert_table_valid(session: Session, model_cls: type[Any], *, max_rows: int = 10) -> None:
    validator = MigrationValidator(session)
    errors = validator.validate(model_cls)
    if not errors:
        return

    sample = errors_to_dataframe(errors).head(max_rows)
    raise AssertionError(
        f"Found {len(errors)} migration validation errors for {model_cls.__tablename__}:\n"
        f"{sample.to_string(index=False)}"
    )
