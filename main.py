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

    print("Introducing 'errors' ")

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


def generate_html_report(validation_log, passed_count, failed_count):
    # 1. Create pandas summary DataFrame
    report_df = pd.DataFrame(validation_log)

    # Export to Jupyter notebook (Tworzy plik CSV, który wczytamy w notatniku)
    report_df.to_csv("validation_results.csv", index=False)

    # Add pass/fail metrics
    total_records = passed_count + failed_count
    pass_rate = (passed_count / total_records) * 100 if total_records > 0 else 0
    failed_df = report_df[report_df['Status'] == 'FAIL']

    # 2. Generate HTML report
    html_content = f"""
    <html>
    <head>
        <title>Data Validation Report</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; }}
            h1 {{ color: #2C3E50; }}
            .metrics {{ background-color: #ecf0f1; padding: 20px; border-radius: 8px; width: 300px; }}
            .pass {{ color: #27ae60; font-weight: bold; }}
            .fail {{ color: #e74c3c; font-weight: bold; }}
            table {{ border-collapse: collapse; width: 100%; margin-top: 20px; }}
            th, td {{ text-align: left; padding: 8px; border: 1px solid #ddd; }}
            th {{ background-color: #2C3E50; color: white; }}
            tr:nth-child(even) {{background-color: #f2f2f2;}}
        </style>
    </head>
    <body>
        <h1>Data Migration and Validation Report</h1>
        <div class="metrics">
            <h3>Summary (Metrics)</h3>
            <p>Scanned records: <b>{total_records}</b></p>
            <p class="pass">Validated (PASS): {passed_count}</p>
            <p class="fail">Rejected (FAIL): {failed_count}</p>
            <p>Success rate: <b>{pass_rate:.2f}%</b></p>
        </div>
        <h3>Details of rejected records:</h3>
        {failed_df.to_html(index=False, classes="table")}
    </body>
    </html>
    """
    with open("validation_report.html", "w", encoding="utf-8") as f:
        f.write(html_content)
    print("\nCOMPLETED")
    print("Generated 'validation_report.html' (HTML Raport) and 'validation_results.csv' (For Jupyter)")

def main() -> None:
    # 1. Baza danych jako plik w folderze projektu
    engine = create_engine("sqlite+pysqlite:///dirty_database.db", echo=False)

    # 2. Utworzenie tabeli z models.py
    Base.metadata.drop_all(engine)  # wyczyszczenie pliku przy każdym uruchomieniu
    Base.metadata.create_all(engine)

    # 3. Wygenerowanie "brudnej" bazy danych
    df = generate_dirty_data()

    # Zmienne do logowania sukcesów i porażek
    validation_log = []
    passed_count = 0
    failed_count = 0

    print("\nStarting record validation...")

    # 5. Test odczytu poprzez SQLAlchemy
    with Session(engine) as session:
        # Przechodzimy przez każdy wygenerowany wiersz
        for index, row in df.iterrows():
            errors = []

            if pd.isna(row['email']):
                errors.append("No email (NULL)")

            if row['age'] < 0:
                errors.append("Negative age")

            # Sprawdzanie duplikatów
            existing = session.scalar(
                select(User).where(
                    User.full_name == row['full_name'],
                    User.email == row['email']
                )
            )
            if existing:
                errors.append("Duplicate in the database")

            # Jeśli zebraliśmy jakieś błędy, logujemy porażkę
            if errors:
                validation_log.append({
                    "Row ID": index,
                    "Status": "FAIL",
                    "Name and surname": row['full_name'],
                    "Email": row['email'],
                    "Reason for rejection": ", ".join(errors)
                })
                failed_count += 1
            else:
                # Jeśli przeszło walidację, dodajemy do bazy i logujemy sukces
                new_user = User(
                    full_name=row['full_name'],
                    email=row['email'],
                    age=row['age'],
                    account_balance=row['account_balance']
                )
                session.add(new_user)
                session.commit()

                validation_log.append({
                    "Row ID": index,
                    "Status": "PASS",
                    "Name and surname": row['full_name'],
                    "Email": row['email'],
                    "Reason for rejection": "-"
                })
                passed_count += 1

        # Na sam koniec generujemy podsumowanie z zebranych logów
        generate_html_report(validation_log, passed_count, failed_count)


if __name__ == "__main__":
    main()