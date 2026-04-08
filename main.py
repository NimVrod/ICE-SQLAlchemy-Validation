import pandas as pd
from faker import Faker
import random
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from DB.models import Base, User

def generate_dirty_data():
    fake = Faker()
    data = []
    for _ in range(1000):
        data.append({
            'full_name': fake.name(),
            'email': fake.email(),
            'age': random.randint(18, 100),
            'account_balance': round(random.uniform(100.0, 10000.0), 2),
        })

    df = pd.DataFrame(data)

    print("Wprowadzanie 'błędów' ")

    # 1. Puste maile (wartości NULL), w 50 losowych miejscach
    null_indices = random.sample(range(1000), 50)
    df.loc[null_indices, 'email'] = None

    # 2. Ujemny wiek, dla 20 osób
    negative_age_indices = random.sample(range(1000), 20)
    df.loc[negative_age_indices, 'age'] = -15

    # 3. Zduplikowani użytkownicy (skopiowanie 25 wierszy w dół)
    duplicates = df.sample(25)
    df = pd.concat([df, duplicates], ignore_index=True)

    return df

def main() -> None:
    # 1. Baza danych jako plik w folderze projektu
    engine = create_engine("sqlite+pysqlite:///dirty_database.db", echo=False)

    # 2. Utworzenie tabeli z models.py
    Base.metadata.drop_all(engine)  # wyczyszczenie pliku przy każdym uruchomieniu
    Base.metadata.create_all(engine)

    # 3. Wygenerowanie "brudnej" bazy danych
    df = generate_dirty_data()

    # 4. Zapis danych i wrzucenie ich do tabeli "users"
    df.to_sql('users', con=engine, if_exists='append', index=False)

    # 5. Test odczytu poprzez SQLAlchemy
    with Session(engine) as session:
        # session.add(TestModel(name="Alice"))
        # session.commit()

        rows = session.scalars(select(User)).all()
        print(f"\nW bazie znajduje się {len(rows)} rekordów")
        print("Pierwsze 50 z nich:")
        for i in range(50):
            print(f"ID: {rows[i].id} | Imię: {rows[i].full_name}| Email: {rows[i].email} | Wiek: {rows[i].age} | Stan konta: {rows[i].account_balance}")


if __name__ == "__main__":
    main()
