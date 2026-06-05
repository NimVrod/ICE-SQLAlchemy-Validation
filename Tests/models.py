from __future__ import annotations

from typing import Annotated, Optional

from sqlalchemy import Integer, String
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

from src.metadata import FloatMax, FloatMin, Required, Unique, UniqueComposite


class MigrationBase(DeclarativeBase):
    pass


class MigrationUser(MigrationBase):
    __tablename__ = "migration_users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[Annotated[str, Required(), Unique()]] = mapped_column(String(100), nullable=False)
    age: Mapped[Annotated[int, Required(), FloatMin(0), FloatMax(120)]] = mapped_column(Integer, nullable=False)
    country: Mapped[Annotated[str, Required(), UniqueComposite("country", "city")]] = mapped_column(
        String(40), nullable=False
    )
    city: Mapped[Annotated[str, Required()]] = mapped_column(String(40), nullable=False)
    nickname: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)
