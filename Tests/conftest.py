import pytest
from ValidationExamples.Database import engine, Session
from ValidationExamples.Models import Base
import ValidationExamples.Events

@pytest.fixture(scope="function")
def session():
    Base.metadata.create_all(engine)
    session = Session()

    yield session

    session.close()
    Base.metadata.drop_all(engine)