from sqlalchemy import Column, Integer, String, Float, CheckConstraint
from sqlalchemy.orm import declarative_base, validates

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String)
    email = Column(String, unique=True)
    age = Column(Integer)
    balance = Column(Float)

    __table_args__ = (
        CheckConstraint("age >= 0 AND age <= 120", name="check_age"),
        CheckConstraint("balance >= 0", name="check_balance"),
    )

    @validates("email")
    def validate_email(self, key, value):
        if not value or "@" not in value:
            raise ValueError("Invalid email")
        return value

    @validates("age")
    def validate_age(self, key, value):
        if value < 0 or value > 120:
            raise ValueError("Invalid age")
        return value

    @validates("balance")
    def validate_balance(self, key, value):
        if value < 0:
            raise ValueError("Negative balance")
        return value

    @validates("name")
    def clean_name(self, key, value):
        for word in ["Dr.", "MD"]:
            value = value.replace(word, "").strip()
        return value