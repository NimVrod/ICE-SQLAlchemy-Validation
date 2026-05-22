from sqlalchemy import select
from sqlalchemy.orm import Session
from DB.models import User

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