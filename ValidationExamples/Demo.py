from Database import engine, Session
from Models import Base, User
import Validators
import Events

Base.metadata.create_all(engine)

session = Session()


def test_valid_user():
    user = User(
        name="Dr. Monica Boyer MD",
        email="guyfernandez@example.com",
        age=64,
        balance=6914.13
    )
    session.add(user)
    session.commit()
    print("Valid user added:", user.name)


def test_invalid_email():
    try:
        user = User(
            name="John Doe",
            email="wrongemail.com",
            age=30,
            balance=100
        )
        session.add(user)
        session.commit()
    except Exception as e:
        print("Email error:", e)
        session.rollback()


def test_duplicate_email():
    try:
        user = User(
            name="Another User",
            email="guyfernandez@example.com",
            age=40,
            balance=500
        )
        session.add(user)
        session.commit()
    except Exception as e:
        print("Duplicate email:", e)
        session.rollback()


if __name__ == "__main__":
    test_valid_user()
    test_invalid_email()
    test_duplicate_email()