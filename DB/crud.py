import random

from faker import Faker
from sqlalchemy import select
from sqlalchemy.orm import Session

from DB.models import User

def seed_dirty_users(db: Session, count: int = 1000) -> list[User]:
    """Create a batch of intentionally dirty users using the shared CRUD session."""
    fake = Faker()
    users = []

    for _ in range(count):
        users.append(
            User(
                full_name=fake.name(),
                email=fake.email(),
                age=random.randint(18, 100),
                account_balance=round(random.uniform(100.0, 10000.0), 2),
            )
        )

    null_indices = random.sample(range(count), 50)
    for index in null_indices:
        users[index].email = None

    negative_age_indices = random.sample(range(count), 20)
    for index in negative_age_indices:
        users[index].age = -15

    duplicates = random.sample(users, 25)
    users.extend(duplicates)

    db.add_all(users)
    db.commit()
    return users


# CREATE
def create_user(db: Session, full_name: str, age: int, account_balance: int, email: str | None = None):
    db_user = User(
        full_name=full_name, 
        email=email, 
        age=age, 
        account_balance=account_balance
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# READ
def get_user(db: Session, user_id: int):
    return db.execute(select(User).where(User.id == user_id)).scalar_one_or_none()

# UPDATE
def update_user_balance(db: Session, user_id: int, new_balance: int):
    user = get_user(db, user_id)
    if user:
        user.account_balance = new_balance
        db.commit()
        db.refresh(user)
    return user

# DELETE
def delete_user(db: Session, user_id: int):
    user = get_user(db, user_id)
    if user:
        db.delete(user)
        db.commit()
        return True
    
    return False