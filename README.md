# ICE-SQLAlchemy-Validation

SQL Alchemy migration data-quality validation.

## Requirements
- Python 3.12
The rest of the dependencies are listed in `pyproject.toml`

## Running
### Using UV
```shell
uv run main.py
uv run python examples/migration_validation_demo.py
uv run python examples/validate_dirty_database.py
```

`validate_dirty_database.py` rebuilds `dirty_database.db` with Faker (same dirty-data pattern as `main.py`) and validates the `users` table.

### Jupyter report

```bash
uv sync --extra notebook
uv run jupyter notebook examples/validation_report.ipynb
```

The notebook loads Faker dirty data, runs the validator, and displays `report_df` / `summary_df` inline.

### Validation dashboard (Streamlit)

Live view of validation errors with auto-refresh and a configurable database connection (defaults to `dirty_database.db`):

```bash
uv sync --extra dashboard
uv run python examples/validate_dirty_database.py   # seed the default DB if needed
uv run streamlit run dashboard/app.py
```

In the sidebar you can paste a SQLAlchemy URL (for example `postgresql+psycopg2://user:pass@host/db`) or a SQLite file path.

## Running tests
```shell
pytest
```
Tests are located in the `Tests` directory.

## Migration validation library

Rules are declared in **one place** on the model. The engine picks SQL or Python automatically:

| Marker | Where | Check strategy |
|--------|--------|----------------|
| `Required()` | field `Annotated[...]` | SQL `IS NULL` |
| `Nullable()` | field `Annotated[...]` | skips required check |
| `Unique()` | field `Annotated[...]` | SQL `GROUP BY` / duplicate join |
| `UniqueComposite("a", "b")` | field `Annotated[...]` (on any one column) | SQL duplicate join |
| `FloatMin` / `FloatMax` | field `Annotated[...]` | SQL comparison |
| `NoNaN()` | field `Annotated[...]` | SQL non-null prefilter + Python `math.isnan` |

Non-optional `Mapped[T]` (without `Nullable`) still implies `Required()`.

### Example model (single declaration)

```python
from typing import Annotated, Optional
from sqlalchemy.orm import Mapped, mapped_column
from src.metadata import FloatMax, FloatMin, Required, Unique, UniqueComposite

class User(Base):
    __tablename__ = "users"

    email: Mapped[Annotated[str, Required(), Unique()]] = mapped_column(String(100))
    age: Mapped[Annotated[int, Required(), FloatMin(0), FloatMax(120)]] = mapped_column(Integer)
    country: Mapped[Annotated[str, Required(), UniqueComposite("country", "city")]] = mapped_column(String(40))
    city: Mapped[Annotated[str, Required()]] = mapped_column(String(40))
    nickname: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)
```

Legacy `Column` + `Annotated` on the same attribute is also supported.

### Run validation

```python
from sqlalchemy.orm import Session
from src.engine import MigrationValidator
from src.pandas_ import errors_to_dataframe, summarize_errors

with Session(engine) as session:
    errors = MigrationValidator(session).validate(User)
    report = errors_to_dataframe(errors)
```

Pytest: `migration_validator` fixture and `assert_table_valid(session, model_cls)` from `src.pytest_validation_plugin`.
