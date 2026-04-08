from sqlalchemy import Integer, String
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from typing import Optional


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    # Definiujemy kolumny naszej tabeli w standardzie SQLAlchemy 2.0
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    full_name: Mapped[str] = mapped_column(String(100), nullable=False)

    # Optional[str] pozwala na wstawianie wartości NULL (dla "błędnych" danych)
    email: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    age: Mapped[int] = mapped_column(Integer, nullable=False)
    account_balance: Mapped[int] = mapped_column(Integer, nullable=False)