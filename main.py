from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from DB.models import Base, TestModel


def main() -> None:
    engine = create_engine("sqlite+pysqlite:///:memory:", echo=False)
    Base.metadata.create_all(engine)

    with Session(engine) as session:
        session.add(TestModel(name="Alice"))
        session.commit()

        rows = session.scalars(select(TestModel)).all()
        for row in rows:
            print(f"TestModel(id={row.id}, name={row.name})")


if __name__ == "__main__":
    main()
