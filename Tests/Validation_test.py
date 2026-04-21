import pytest
from ValidationExamples.Models import User


def test_valid_user(session):
    user = User(name="John", email="john@test.com", age=30, balance=100)
    session.add(user)
    session.commit()
    assert user.id is not None


def test_invalid_email(session):
    with pytest.raises(ValueError):
        user = User(name="John", email="wrong", age=30, balance=100)
        session.add(user)
        session.commit()


def test_negative_age(session):
    with pytest.raises(ValueError):
        user = User(name="John", email="a@test.com", age=-1, balance=100)
        session.add(user)
        session.commit()


def test_negative_balance(session):
    with pytest.raises(ValueError):
        user = User(name="John", email="a@test.com", age=30, balance=-10)
        session.add(user)
        session.commit()


def test_duplicate_email(session):
    user1 = User(name="A", email="dup@test.com", age=30, balance=100)
    session.add(user1)
    session.commit()

    with pytest.raises(Exception):
        user2 = User(name="B", email="dup@test.com", age=40, balance=200)
        session.add(user2)
        session.commit()


def test_name_cleaning(session):
    user = User(name="Dr. Alice MD", email="alice@test.com", age=25, balance=100)
    session.add(user)
    session.commit()
    assert user.name == "Alice"


def test_suspicious_user(session):
    with pytest.raises(ValueError):
        user = User(name="Kid", email="kid@test.com", age=15, balance=20000)
        session.add(user)
        session.commit()


def test_age_upper_bound(session):
    user = User(name="Bob", email="bob@test.com", age=120, balance=0)
    session.add(user)
    session.commit()
    assert user.id is not None


def test_null_email(session):
    with pytest.raises(ValueError):
        user = User(name="John", email=None, age=30, balance=100)
        session.add(user)
        session.commit()


def test_zero_balance(session):
    user = User(name="Zero", email="zero@test.com", age=40, balance=0)
    session.add(user)
    session.commit()
    assert user.balance == 0