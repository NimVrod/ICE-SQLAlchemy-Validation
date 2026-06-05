from __future__ import annotations

from pathlib import Path

import pandas as pd
import pytest

from src.engine import MigrationValidator
from src.pandas_ import errors_to_dataframe, errors_to_html, summarize_errors, write_errors_html
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


def test_errors_to_html_includes_summary_and_details(migration_engine, migration_session) -> None:
    df = pd.DataFrame(
        [
            {"id": 1, "email": None, "age": 20, "country": "PL", "city": "GDA", "nickname": None},
            {"id": 2, "email": "a@example.com", "age": -1, "country": "PL", "city": "WAW", "nickname": None},
        ]
    )
    df.to_sql(MigrationUser.__tablename__, con=migration_engine, if_exists="replace", index=False)

    report = errors_to_dataframe(MigrationValidator(migration_session).validate(MigrationUser))
    html = errors_to_html(report, title="Test Report")

    assert "<!DOCTYPE html>" in html
    assert "Test Report" in html
    assert "status-failed" in html
    assert "<h2>Summary</h2>" in html
    assert "<h2>Details</h2>" in html
    assert MigrationUser.__tablename__ in html


def test_errors_to_html_passed_when_no_errors() -> None:
    report = errors_to_dataframe([])
    html = errors_to_html(report)

    assert "status-passed" in html
    assert "No validation errors found." in html
    assert "<h2>Details</h2>" not in html


def test_write_errors_html_creates_file(tmp_path: Path, migration_engine, migration_session) -> None:
    df = pd.DataFrame(
        [
            {"id": 1, "email": None, "age": 20, "country": "PL", "city": "GDA", "nickname": None},
        ]
    )
    df.to_sql(MigrationUser.__tablename__, con=migration_engine, if_exists="replace", index=False)

    report = errors_to_dataframe(MigrationValidator(migration_session).validate(MigrationUser))
    output_path = write_errors_html(report, tmp_path / "report.html")

    assert output_path.exists()
    content = output_path.read_text(encoding="utf-8")
    assert "Migration Validation Report" in content
    assert MigrationUser.__tablename__ in content


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
