from sqlalchemy import event
from Models import User

@event.listens_for(User, "before_insert")
def validate_user(mapper, connection, target):
    if target.age < 18 and target.balance > 10000:
        raise ValueError("Suspicious account: too much money for minor")