#from Database import engine, Session
from Models import Base, User
import Events
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine("sqlite:///test.db")
Session = sessionmaker(bind=engine)

Base.metadata.create_all(engine)

session = Session()
     
def test_cases():
    test_data = [
        {"name": "Alice", "email": "alice@test.com", "age": 25, "balance": 100},
            
        {"name": None, "email": "null@test.com", "age": 20, "balance": 50},
        
        {"name": "Greg", "email": None, "age": 20, "balance": 50},
        
        {"name": "Hank", "email": "null2@test.com", "age": None, "balance": 50},
            
        {"name": "Adrian", "email": "adrian@test.com", "age": 30, "balance": 1000},
        
        {"name": "Charlie", "email": "charlie@test.com", "age": 200, "balance": 100},
            
        {"name": "Dave", "email": "dave@test.com", "age": 40, "balance": -10},
            
        {"name": "", "email": "empty@test.com", "age": 22, "balance": 50},
            
        {"name": "Eve", "email": "alice@test.com", "age": 28, "balance": 300},
        
        {"name": "Luke", "email": "adrian@test.com", "age": 15, "balance": 300},
    ]

    for i, data in enumerate(test_data):
        try:
            user = User(**data)
            session.add(user)
            session.commit()
            print(f"[{i}] OK ->", data)
        except Exception as e:
            print(f"[{i}] ERROR ->", data, "|", e)
            session.rollback() 
        
if __name__ == "__main__":
    test_cases()