import sqlalchemy

def test_basic() -> None:
    assert True

def test_connection() -> None:
    try:
        engine = sqlalchemy.create_engine("sqlite+pysqlite:///:memory:", echo=False)
        with engine.connect() as connection:
            result = connection.execute(sqlalchemy.text("SELECT 1"))
            assert result.scalar() == 1
    except Exception as e:
        assert False, f"Database connection failed: {e}"