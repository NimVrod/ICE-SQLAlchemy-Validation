from sqlalchemy import Column, Integer, String, Float, CheckConstraint
from sqlalchemy.orm import declarative_base

#from Events import check_not_null



Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String)
    email = Column(String)
    age = Column(Integer)
    balance = Column(Float)

    __table_args__ = (
        CheckConstraint("age >= 0 AND age <= 120", name="check_age"),
        CheckConstraint("balance >= 0", name="check_balance"),
        CheckConstraint("name != ''", name="check_name_not_empty"),
    )
    

