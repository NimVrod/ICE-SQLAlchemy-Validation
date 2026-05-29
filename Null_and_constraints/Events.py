from sqlalchemy.orm import Session
from Models import User
from sqlalchemy import event


def check_not_null(value, field_name):
    if value is None:
        raise ValueError(f"{field_name} cannot be NULL")

@event.listens_for(User, "before_insert")
def validate_user(mapper, connection, target):
    # NULL check
    check_not_null(target.name, "Name")
    check_not_null(target.email, "Email")
    check_not_null(target.age, "Age")
    check_not_null(target.balance, "Balance")

    # duplicate check
    session = Session(bind=connection)
    existing = session.query(User).filter_by(email=target.email).first()
    if existing:
        raise ValueError("Email already exists")
    