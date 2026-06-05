from __future__ import annotations

import pandas as pd

from src.engine import MigrationValidator
from Tests.models import MigrationUser


def test_duplicate_validation_reports_unique_column_and_composite_duplicates(
    migration_engine, migration_session
) -> None:
    df = pd.DataFrame(
        [
            {"id": 1, "email": "dup@example.com", "age": 30, "country": "PL", "city": "GDA", "nickname": None},
            {"id": 2, "email": "dup@example.com", "age": 40, "country": "PL", "city": "WAW", "nickname": None},
            {"id": 3, "email": "x@example.com", "age": 25, "country": "DE", "city": "BER", "nickname": None},
            {"id": 4, "email": "y@example.com", "age": 35, "country": "DE", "city": "BER", "nickname": None},
        ]
    )
    df.to_sql(MigrationUser.__tablename__, con=migration_engine, if_exists="replace", index=False)

    errors = MigrationValidator(migration_session).validate(MigrationUser)
    duplicate_errors = [error for error in errors if error.validator == "duplicate"]

    assert len(duplicate_errors) == 4
    assert any(error.field == "email" for error in duplicate_errors)
    assert any(error.field == "country,city" for error in duplicate_errors)
