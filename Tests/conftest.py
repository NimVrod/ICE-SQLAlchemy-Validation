import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session as SQLASession

from ValidationExamples.Database import engine, Session
from ValidationExamples.Models import Base
import ValidationExamples.Events
from Tests.models import MigrationBase

@pytest.fixture(scope="function")
def session():
    Base.metadata.create_all(engine)
    session = Session()

    yield session

    session.close()
    Base.metadata.drop_all(engine)


@pytest.fixture(scope="function")
def migration_engine():
    engine = create_engine("sqlite+pysqlite:///:memory:", echo=False)
    MigrationBase.metadata.create_all(engine)
    try:
        yield engine
    finally:
        MigrationBase.metadata.drop_all(engine)


@pytest.fixture(scope="function")
def migration_session(migration_engine):
    with SQLASession(migration_engine) as session:
        yield session