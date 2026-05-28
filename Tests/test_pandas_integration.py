from __future__ import annotations

import pandas as pd
import pytest

from src.engine import MigrationValidator
from src.pandas_ import errors_to_dataframe, summarize_errors
from src.pytest_validation_plugin import assert_table_valid
from Tests.models import MigrationUser


def test_errors_to_dataframe_and_summary(migration_engine, migration_session) -> None:
    df = pd.DataFrame(
        [
            {"id": 1, "email": None, "age": 20, "country": "PL", "city": "GDA", "nickname": None},
            {"id": 2, "email": "a@example.com", "age": -1, "country": "PL", "city": "WAW", "nickname": None},
            {"id": 3, "email": "x@example.com", "age": 30, "country": "DE", "city": "BER", "nickname": None},
            {"id": 4, "email": "x@example.com", "age": 31, "country": "DE", "city": "BER", "nickname": None},
        ]
    )
    df.to_sql(MigrationUser.__tablename__, con=migration_engine, if_exists="replace", index=False)

    errors = MigrationValidator(migration_session).validate(MigrationUser)
    report = errors_to_dataframe(errors)
    summary = summarize_errors(report)

    assert not report.empty
    assert list(report.columns) == ["table", "id", "field", "error", "validator"]
    assert not summary.empty
    assert "count" in summary.columns


def test_assert_table_valid_fails_when_data_is_dirty(migration_engine, migration_session) -> None:
    df = pd.DataFrame(
        [
            {"id": 1, "email": None, "age": 20, "country": "PL", "city": "GDA", "nickname": None},
            {"id": 2, "email": "a@example.com", "age": 30, "country": "PL", "city": "WAW", "nickname": None},
        ]
    )
    df.to_sql(MigrationUser.__tablename__, con=migration_engine, if_exists="replace", index=False)

    with pytest.raises(AssertionError):
        assert_table_valid(migration_session, MigrationUser)
