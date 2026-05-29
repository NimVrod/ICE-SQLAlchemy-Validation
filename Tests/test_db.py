import time
import pytest
from sqlalchemy import create_engine, select, func
from sqlalchemy.orm import sessionmaker

from DB.models import Base, User

from DB.crud import create_user, get_user, update_user_balance, delete_user

@pytest.fixture
def db():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(bind=engine)
    session = TestingSessionLocal()
    
    yield session
    
    session.close()

def test_crud_operations(db):
    # CREATE - test zapisu
    user = create_user(db, "Jan Kowalski", 22, 1500, "jan@test.com")
    assert user.id is not None
    
    # READ - test odczytu
    db_user = get_user(db, user.id)
    assert db_user.full_name == "Jan Kowalski"
    assert db_user.age == 22
    
    # UPDATE - test aktualizacji
    updated_user = update_user_balance(db, user.id, 5000)
    assert updated_user.account_balance == 5000
    
    # DELETE - test usuwania
    is_deleted = delete_user(db, user.id)
    assert is_deleted is True
    assert get_user(db, user.id) is None
    is_deleted_fake = delete_user(db, 9999)
    assert is_deleted_fake is False
def test_1000_row_performance(db):
    start_time = time.time()

    users_to_insert = [
        User(
            full_name=f"Student {i}", 
            email=f"student{i}@test.com", 
            age=20 + (i % 5), 
            account_balance=100 * i
        )
        for i in range(1000)
    ]
    
    db.add_all(users_to_insert)
    db.commit()
    
    duration = time.time() - start_time
    print(f"\n---> ZAPIS 1000 REKORDÓW ZAJĄŁ: {duration:.4f} sekundy <---")
    count = db.execute(select(func.count(User.id))).scalar()
    assert count == 1000
    assert duration < 1.0 