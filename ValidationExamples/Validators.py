from sqlalchemy.orm import validates
from Models import User

# 🔹 Email validation
@validates(User.email)
def validate_email(self, key, value):
    if not value or "@" not in value:
        raise ValueError("Invalid email")
    return value


# 🔹 Age validation
@validates(User.age)
def validate_age(self, key, value):
    if value < 0 or value > 120:
        raise ValueError("Invalid age")
    return value


# 🔹 Balance validation
@validates(User.balance)
def validate_balance(self, key, value):
    if value < 0:
        raise ValueError("Balance cannot be negative")
    return value


# 🔹 Name cleaning
@validates(User.name)
def validate_name(self, key, value):
    forbidden = ["Dr.", "MD", "Mr.", "Mrs."]
    for word in forbidden:
        value = value.replace(word, "").strip()
    return value