from sqlalchemy import Integer, String, CheckConstraint, Numeric, Enum
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, validates
from typing import Optional
import re
import enum
from sqlalchemy.orm import object_session
from sqlalchemy import select



class UserStatus(enum.Enum):
    ACTIVE = "active"
    BANNED = "banned"
    PENDING = "pending"

class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    __table_args__ = (
        CheckConstraint('account_balance >= 0', name='check_min_balance'),
        CheckConstraint('age >= 0', name='check_positive_age'),
    )

    # Definiujemy kolumny naszej tabeli w standardzie SQLAlchemy 2.0
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    full_name: Mapped[str] = mapped_column(String(100), nullable=False)

    # Optional[str] pozwala na wstawianie wartości NULL (dla "błędnych" danych)
    email: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    age: Mapped[int] = mapped_column(Integer, nullable=False)
    account_balance: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)#account_balance: Mapped[float] = mapped_column(Integer, nullable=False) #zmiana int na float


    status: Mapped[UserStatus] = mapped_column(
        Enum(UserStatus), 
        default=UserStatus.PENDING,
        nullable=False
    )


    @validates('age')
    def validate_age(self, key, value):
        if not (0 <= value <= 120):
            raise ValueError(f"Nieprawidłowy wiek: {value}")
        return value

    @validates('email')
    def validate_email(self, key, address):
        if address is None:
            raise ValueError("Email nie może być pusty")

        address_str = str(address).strip()

        if address_str == "":
            raise ValueError("Email nie może być pusty")

        if not re.match(r"[^@]+@[^@]+\.[^@]+", address_str):
            raise ValueError(f"Błędny format adresu email: {address}")

        return address_str
    
    @validates('full_name')
    def validate_full_name(self, key, name):
        name = name.strip().title()

        session = object_session(self)
        if session:
            existing = session.scalar(
                select(User).where(
                    User.full_name == name,
                    User.age == self.age,
                    User.email == self.email
                )
            )
            if existing:
                raise ValueError("Duplikat użytkownika")

        return name