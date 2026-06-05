"""ORM models used by the validation dashboard."""

from __future__ import annotations

from pathlib import Path
from typing import Annotated

from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from DB.models import Base
from src.metadata import FloatMin, Required, Unique

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE_URL = f"sqlite+pysqlite:///{(PROJECT_ROOT / 'dirty_database.db').as_posix()}"


class ValidatedUser(Base):
    """Maps to `users` with validation rules (extends the table from DB.models.User)."""

    __tablename__ = "users"
    __table_args__ = {"extend_existing": True}

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    full_name: Mapped[Annotated[str, Required()]] = mapped_column(String(100), nullable=False)
    email: Mapped[Annotated[str, Required(), Unique()]] = mapped_column(String(100), nullable=True)
    age: Mapped[Annotated[int, Required(), FloatMin(0)]] = mapped_column(Integer, nullable=False)
    account_balance: Mapped[Annotated[float, Required(), FloatMin(0.0)]] = mapped_column(
        Integer, nullable=False
    )


VALIDATION_MODELS = [ValidatedUser]
