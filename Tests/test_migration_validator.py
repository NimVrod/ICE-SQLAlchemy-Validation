from __future__ import annotations

import pandas as pd

from src.engine import MigrationValidator
from Tests.models import MigrationUser


def test_migration_validator_returns_structured_errors(migration_engine, migration_session) -> None:
    df = pd.DataFrame(
        [
            {"id": 1, "email": "ok@example.com", "age": 20, "country": "PL", "city": "GDA", "nickname": "ok"},
            {"id": 2, "email": None, "age": -1, "country": "US", "city": "NYC", "nickname": None},
            {"id": 3, "email": "dup@example.com", "age": 30, "country": "DE", "city": "BER", "nickname": None},
            {"id": 4, "email": "dup@example.com", "age": 30, "country": "DE", "city": "BER", "nickname": None},
        ]
    )
    df.to_sql(MigrationUser.__tablename__, con=migration_engine, if_exists="replace", index=False)

    validator = MigrationValidator(migration_session)
    errors = validator.validate(MigrationUser)

    assert errors
    assert errors[0].table
    assert errors[0].id is not None
    validators = {error.validator for error in errors}
    assert {"null", "float_min", "duplicate"} <= validators
