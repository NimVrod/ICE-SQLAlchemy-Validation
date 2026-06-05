"""
Migration validation demo.

Creates a lax table with raw SQL (as after a messy import), seeds bad rows,
then validates against a model whose rules are declared only via Annotated markers.
"""

from __future__ import annotations

from typing import Annotated, Optional

from sqlalchemy import Integer, String, create_engine, text
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column

from src.engine import MigrationValidator
from src.metadata import FloatMax, FloatMin, Required, Unique, UniqueComposite
from src.pandas_ import errors_to_dataframe, summarize_errors


class DemoBase(DeclarativeBase):
    pass


class DemoUser(DemoBase):
    __tablename__ = "demo_users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[Annotated[str, Required(), Unique()]] = mapped_column(String(100))
    age: Mapped[Annotated[int, Required(), FloatMin(0), FloatMax(120)]] = mapped_column(Integer)
    country: Mapped[Annotated[str, Required(), UniqueComposite("country", "city")]] = mapped_column(String(40))
    city: Mapped[Annotated[str, Required()]] = mapped_column(String(40))
    nickname: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)


def create_lax_table(session: Session) -> None:
    """Create a permissive table (no DB-level checks) like a raw migration import."""
    session.execute(text("DROP TABLE IF EXISTS demo_users"))
    session.execute(
        text(
            """
            CREATE TABLE demo_users (
                id INTEGER PRIMARY KEY,
                email VARCHAR(100),
                age INTEGER,
                country VARCHAR(40),
                city VARCHAR(40),
                nickname VARCHAR(40)
            )
            """
        )
    )
    session.commit()


def seed_dirty_data(session: Session) -> None:
    """Insert rows that violate declared validation markers."""
    session.execute(
        text(
            """
            INSERT INTO demo_users (id, email, age, country, city, nickname)
            VALUES
                (1, 'alice@example.com', 30, 'PL', 'Gdansk', 'alice'),
                (2, NULL, 25, 'PL', 'Warsaw', NULL),
                (3, 'bob@example.com', -10, 'US', 'NYC', 'bob'),
                (4, 'carol@example.com', 999, 'US', 'LA', NULL),
                (5, 'dup@example.com', 40, 'DE', 'Berlin', NULL),
                (6, 'dup@example.com', 41, 'DE', 'Munich', NULL),
                (7, 'eve@example.com', 22, 'FR', 'Paris', NULL),
                (8, 'frank@example.com', 33, 'FR', 'Paris', NULL)
            """
        )
    )
    session.commit()


def main() -> None:
    engine = create_engine("sqlite+pysqlite:///example_validation.db", echo=False)

    with Session(engine) as session:
        print("Creating lax table and seeding dirty data with raw SQL...")
        create_lax_table(session)
        seed_dirty_data(session)

        print("Running migration validator (rules from column Annotated markers)...")
        validator = MigrationValidator(session)
        errors = validator.validate(DemoUser)

        report = errors_to_dataframe(errors)
        summary = summarize_errors(report)

        print(f"\nFound {len(errors)} validation error(s)\n")
        if report.empty:
            print("No errors detected.")
            return

        print("Detailed report:")
        print(report.to_string(index=False))

        print("\nSummary by rule:")
        print(summary.to_string(index=False))


if __name__ == "__main__":
    main()
