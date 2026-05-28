from __future__ import annotations

import pandas as pd

from src.engine import MigrationValidator
from Tests.models import MigrationUser


def test_float_bounds_validation_reports_invalid_age(migration_engine, migration_session) -> None:
    df = pd.DataFrame(
        [
            {"id": 1, "email": "a@example.com", "age": 30, "country": "PL", "city": "GDA", "nickname": "a"},
            {"id": 2, "email": "b@example.com", "age": -5, "country": "PL", "city": "WAW", "nickname": "b"},
            {"id": 3, "email": "c@example.com", "age": 200, "country": "US", "city": "NYC", "nickname": None},
        ]
    )
    df.to_sql(MigrationUser.__tablename__, con=migration_engine, if_exists="replace", index=False)

    errors = MigrationValidator(migration_session).validate(MigrationUser)
    bounds_errors = [error for error in errors if error.validator in {"float_min", "float_max"}]

    assert len(bounds_errors) == 2
    assert {error.field for error in bounds_errors} == {"age"}
