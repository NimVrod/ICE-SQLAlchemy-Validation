from __future__ import annotations

from typing import Annotated

from sqlalchemy import Column, Float, Integer, create_engine, text
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column

from src.engine import MigrationValidator
from src.metadata import FloatMin, NoNaN
from src.parser import parse_field_validators
from src.validators.float_min import MinFloatValidator
from src.validators.nan import NaNValidator
from src.validators.null import NullValidator


class AnnotatedBase(DeclarativeBase):
    pass


class FinancialMetricMapped(AnnotatedBase):
    """SQLAlchemy 2.0 Mapped + Annotated style."""

    __tablename__ = "financial_metrics_mapped"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    revenue_yield: Mapped[Annotated[float, NoNaN(), FloatMin(0.0)]] = mapped_column(Float, nullable=False)
    variance_score: Mapped[Annotated[float | None, NoNaN()]] = mapped_column(Float, nullable=True)


class FinancialMetricColumn(AnnotatedBase):
    """Legacy Column + Annotated style."""

    __tablename__ = "financial_metrics_column"

    id = Column(Integer, primary_key=True)
    revenue_yield: Annotated[float, NoNaN(), FloatMin(0.0)] = Column(Float, nullable=False)
    variance_score: Annotated[float | None, NoNaN()] = Column(Float, nullable=True)


def test_parse_annotated_mapped_field_validators() -> None:
    validators = parse_field_validators(
        FinancialMetricMapped,
        "revenue_yield",
        FinancialMetricMapped.__annotations__["revenue_yield"],
    )
    kinds = {type(v) for v in validators}
    assert NullValidator in kinds
    assert NaNValidator in kinds
    assert MinFloatValidator in kinds


def test_parse_annotated_optional_field_has_nan_but_not_null() -> None:
    validators = parse_field_validators(
        FinancialMetricMapped,
        "variance_score",
        FinancialMetricMapped.__annotations__["variance_score"],
    )
    assert not any(isinstance(v, NullValidator) for v in validators)
    assert any(isinstance(v, NaNValidator) for v in validators)


def test_parse_annotated_column_style() -> None:
    validators = parse_field_validators(
        FinancialMetricColumn,
        "revenue_yield",
        FinancialMetricColumn.__annotations__["revenue_yield"],
    )
    assert len(validators) == 3


def test_float_min_validation_mapped() -> None:
    engine = create_engine("sqlite+pysqlite:///:memory:")
    AnnotatedBase.metadata.create_all(engine)

    with Session(engine) as session:
        session.execute(
            text(
                """
                INSERT INTO financial_metrics_mapped (id, revenue_yield, variance_score)
                VALUES
                    (1, 1.5, 0.1),
                    (2, 2.0, NULL),
                    (3, -0.5, NULL)
                """
            )
        )
        session.commit()
        errors = MigrationValidator(session).validate(FinancialMetricMapped)

    float_min_errors = [e for e in errors if e.validator == "float_min"]
    assert len(float_min_errors) == 1
    assert float_min_errors[0].field == "revenue_yield"
    assert float_min_errors[0].id == 3


def test_float_min_validation_column_style() -> None:
    engine = create_engine("sqlite+pysqlite:///:memory:")
    AnnotatedBase.metadata.create_all(engine)

    with Session(engine) as session:
        session.execute(
            text(
                """
                INSERT INTO financial_metrics_column (id, revenue_yield, variance_score)
                VALUES
                    (1, 1.0, NULL),
                    (2, 2.0, 0.5),
                    (3, -1.0, NULL)
                """
            )
        )
        session.commit()
        errors = MigrationValidator(session).validate(FinancialMetricColumn)

    assert any(e.validator == "float_min" for e in errors)
