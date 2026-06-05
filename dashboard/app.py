"""Streamlit dashboard for live migration validation errors."""

from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path

import pandas as pd
import streamlit as st
from sqlalchemy import create_engine, func, inspect, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from dashboard.models import DEFAULT_DATABASE_URL, VALIDATION_MODELS
from src.engine import MigrationValidator
from src.pandas_ import errors_to_dataframe, summarize_errors


def normalize_database_url(url: str) -> str:
    value = url.strip() or DEFAULT_DATABASE_URL
    if "://" in value:
        return value
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = Path(__file__).resolve().parents[1] / path
    return f"sqlite+pysqlite:///{path.resolve().as_posix()}"


@st.cache_resource(show_spinner=False)
def get_engine(database_url: str):
    return create_engine(database_url, echo=False)


def run_validation(database_url: str) -> tuple[pd.DataFrame, pd.DataFrame, int, str | None]:
    engine = get_engine(database_url)
    try:
        with engine.connect() as connection:
            inspector = inspect(connection)
            if not inspector.get_table_names():
                return (
                    pd.DataFrame(),
                    pd.DataFrame(),
                    0,
                    "Database has no tables. Run `uv run python examples/validate_dirty_database.py` to seed `dirty_database.db`.",
                )

        with Session(engine) as session:
            row_count = 0
            for model_cls in VALIDATION_MODELS:
                if inspect(engine).has_table(model_cls.__tablename__):
                    row_count += session.scalar(
                        select(func.count()).select_from(model_cls.__table__)
                    ) or 0

            errors = MigrationValidator(session).validate_all(*VALIDATION_MODELS)
            report = errors_to_dataframe(errors)
            summary = summarize_errors(report)
            return report, summary, row_count, None
    except SQLAlchemyError as exc:
        return pd.DataFrame(), pd.DataFrame(), 0, str(exc)


def filter_report(report: pd.DataFrame) -> pd.DataFrame:
    if report.empty:
        return report

    filtered = report
    for column, label in (
        ("validator", "Validator"),
        ("field", "Field"),
        ("table", "Table"),
    ):
        options = sorted(filtered[column].dropna().unique())
        selected = st.multiselect(label, options, default=options, key=f"filter_{column}")
        if selected:
            filtered = filtered[filtered[column].isin(selected)]
    return filtered


def render_validation(database_url: str) -> None:
    report, summary, row_count, error = run_validation(database_url)
    checked_at = datetime.now(UTC).strftime("%Y-%m-%d %H:%M:%S UTC")

    st.caption(f"Last checked: {checked_at}")

    if error:
        st.error(error)
        return

    total_errors = len(report)
    status = "PASSED" if total_errors == 0 else "FAILED"

    metric_cols = st.columns(4)
    metric_cols[0].metric("Rows scanned", f"{row_count:,}")
    metric_cols[1].metric("Total errors", f"{total_errors:,}")
    metric_cols[2].metric("Status", status)
    metric_cols[3].metric("Tables", len({model.__tablename__ for model in VALIDATION_MODELS}))

    if total_errors == 0:
        st.success("No validation errors found.")
        return

    st.subheader("Summary by rule")
    chart_data = summary.set_index("field")[["count"]] if not summary.empty else summary
    if not chart_data.empty:
        st.bar_chart(chart_data)
    st.dataframe(summary, use_container_width=True, hide_index=True)

    st.subheader("Error details")
    filtered = filter_report(report)
    st.dataframe(filtered, use_container_width=True, hide_index=True)
    st.caption(f"Showing {len(filtered):,} of {total_errors:,} errors")


def main() -> None:
    st.set_page_config(
        page_title="Migration Validation Dashboard",
        page_icon=":mag:",
        layout="wide",
    )
    st.title("Migration Validation Dashboard")
    st.write(
        "Live view of data-quality errors detected by `MigrationValidator` against the connected database."
    )

    with st.sidebar:
        st.header("Connection")
        database_input = st.text_input(
            "Database URL or SQLite file path",
            value=DEFAULT_DATABASE_URL,
            help=(
                "SQLAlchemy connection string, e.g. `sqlite+pysqlite:///path/to/db.db`, "
                "or a relative/absolute path to a SQLite file."
            ),
        )
        database_url = normalize_database_url(database_input)

        st.divider()
        st.header("Refresh")
        refresh_seconds = st.slider(
            "Auto-refresh interval (seconds)",
            min_value=0,
            max_value=60,
            value=5,
            help="Set to 0 to disable automatic refresh.",
        )
        if st.button("Refresh now", use_container_width=True):
            get_engine.clear()
            st.rerun()

        st.divider()
        st.caption("Default database: `dirty_database.db` in the project root.")
        st.code(database_url, language="text")

    if refresh_seconds > 0:

        @st.fragment(run_every=refresh_seconds)
        def auto_refresh_panel() -> None:
            render_validation(database_url)

        auto_refresh_panel()
    else:
        render_validation(database_url)


if __name__ == "__main__":
    main()
