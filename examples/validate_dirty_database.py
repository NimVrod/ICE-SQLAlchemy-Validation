"""
Validate the dirty_database.db produced by the same Faker workflow as main.py.

Creates a fresh sqlite file, loads ~1000 dirty rows into `users`, then runs
MigrationValidator against validation rules declared on columns only.
"""

from __future__ import annotations

import random
from pathlib import Path
from typing import Annotated, Optional

import pandas as pd
from faker import Faker
from sqlalchemy import Integer, String, create_engine, select
from sqlalchemy.orm import Mapped, Session, mapped_column

from DB.models import Base
from src.engine import MigrationValidator
from src.metadata import FloatMin, Required, Unique
from src.pandas_ import errors_to_dataframe, summarize_errors

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATABASE_URL = f"sqlite+pysqlite:///{PROJECT_ROOT / 'dirty_database.db'}"


class ValidatedUser(Base):
    """Maps to `users` with validation rules (extends the table from DB.models.User)."""

    __tablename__ = "users"
    __table_args__ = {"extend_existing": True}

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    full_name: Mapped[Annotated[str, Required()]] = mapped_column(String(100), nullable=False)
    email: Mapped[Annotated[str, Required(), Unique()]] = mapped_column(String(100), nullable=True)
    age: Mapped[Annotated[int, Required(), FloatMin(0)]] = mapped_column(Integer, nullable=False)
    account_balance: Mapped[Annotated[float, Required(), FloatMin(0.0)]] = mapped_column(Integer, nullable=False)


def generate_dirty_data(row_count: int = 1000) -> pd.DataFrame:
    fake = Faker()
    rows = [
        {
            "full_name": fake.name(),
            "email": fake.email(),
            "age": random.randint(18, 100),
            "account_balance": round(random.uniform(100.0, 10000.0), 2),
        }
        for _ in range(row_count)
    ]
    df = pd.DataFrame(rows)

    print(f"Injecting dirty data into {row_count} generated rows...")

    null_indices = random.sample(range(row_count), 50)
    df.loc[null_indices, "email"] = None

    negative_age_indices = random.sample(range(row_count), 20)
    df.loc[negative_age_indices, "age"] = -15

    duplicates = df.sample(25)
    return pd.concat([df, duplicates], ignore_index=True)


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
    stored = session.scalars(select(ValidatedUser.id)).all()
    print(f"\nLoaded {row_count} rows into dirty_database.db ({len(stored)} ids in table)")

    print("Running migration validator...")
    errors = MigrationValidator(session).validate(ValidatedUser)

    report = errors_to_dataframe(errors)
    summary = summarize_errors(report)

    print(f"\nFound {len(errors)} validation error(s)\n")
    if report.empty:
      print("No errors detected.")
      return

    print("Detailed report (first 25):")
    print(report.head(25).to_string(index=False))

    print("\nSummary by rule:")
    print(summary.to_string(index=False))


if __name__ == "__main__":
  main()
