from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "sqlite:///dirty_database.db"

# connect_args={"check_same_thread": False} zapobiega błędom w SQLite
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Session = SessionLocal

def get_db():
    """
    Connection helper function.
    Zarządza sesją bazy danych - otwiera ją i gwarantuje bezpieczne zamknięcie.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()