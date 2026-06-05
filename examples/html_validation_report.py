"""
Generate an HTML validation report from MigrationValidator results.

Creates a small dirty SQLite database, runs validation, and writes a
self-contained HTML report to examples/validation_report.html.
"""

from __future__ import annotations

import random
from pathlib import Path
from typing import Annotated

import pandas as pd
from faker import Faker
from sqlalchemy import Integer, String, create_engine
from sqlalchemy.orm import Mapped, Session, mapped_column

from DB.models import Base
from src.engine import MigrationValidator
from src.metadata import FloatMin, Required, Unique
from src.pandas_ import errors_to_dataframe, errors_to_html, summarize_errors, write_errors_html

EXAMPLES_DIR = Path(__file__).resolve().parent
DATABASE_PATH = EXAMPLES_DIR / "html_report_demo.db"
REPORT_PATH = EXAMPLES_DIR / "validation_report.html"
DATABASE_URL = f"sqlite+pysqlite:///{DATABASE_PATH}"


class ReportUser(Base):
    __tablename__ = "users"
    __table_args__ = {"extend_existing": True}

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    full_name: Mapped[Annotated[str, Required()]] = mapped_column(String(100), nullable=False)
    email: Mapped[Annotated[str, Required(), Unique()]] = mapped_column(String(100), nullable=True)
    age: Mapped[Annotated[int, Required(), FloatMin(0)]] = mapped_column(Integer, nullable=False)
    account_balance: Mapped[Annotated[float, Required(), FloatMin(0.0)]] = mapped_column(
        Integer, nullable=False
    )


def generate_dirty_data(row_count: int = 200) -> pd.DataFrame:
    fake = Faker()
    df = pd.DataFrame(
        [
            {
                "full_name": fake.name(),
                "email": fake.email(),
                "age": random.randint(18, 100),
                "account_balance": round(random.uniform(100.0, 10000.0), 2),
            }
            for _ in range(row_count)
        ]
    )
    df.loc[random.sample(range(row_count), 10), "email"] = None
    df.loc[random.sample(range(row_count), 5), "age"] = -15
    return pd.concat([df, df.sample(10)], ignore_index=True)


def seed_database(engine) -> int:
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)

    df = generate_dirty_data()
    df.to_sql("users", con=engine, if_exists="append", index=False)
    return len(df)


def main() -> None:
    engine = create_engine(DATABASE_URL, echo=False)
    row_count = seed_database(engine)

    with Session(engine) as session:
        errors = MigrationValidator(session).validate(ReportUser)

    report = errors_to_dataframe(errors)
    summary = summarize_errors(report)

    write_errors_html(
        report,
        REPORT_PATH,
        title="Migration validation report",
        summary=summary,
    )

    print(f"Loaded {row_count} rows into {DATABASE_PATH.name}")
    print(f"Found {len(errors)} validation error(s)")
    print(f"HTML report written to {REPORT_PATH.resolve()}")

    if not report.empty:
        print("\nSummary by rule:")
        print(summary.to_string(index=False))

    html_preview = errors_to_html(report, title="Migration validation report", summary=summary)
    print(f"\nHTML size: {len(html_preview):,} characters")


if __name__ == "__main__":
    main()
