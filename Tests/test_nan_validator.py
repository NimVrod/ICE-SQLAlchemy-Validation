from __future__ import annotations

import math

from src.validators.nan import NaNValidator


def test_nan_validator_matches_python() -> None:
    validator = NaNValidator(field_name="revenue_yield")
    assert validator.matches_python(float("nan"), pk=1)
    assert not validator.matches_python(None, pk=1)
    assert not validator.matches_python(1.5, pk=1)


def test_nan_validator_format_error() -> None:
    validator = NaNValidator(field_name="variance_score")
    assert "variance_score" in validator.format_error(float("nan"))
    assert "NaN" in validator.format_error(float("nan"))


def test_nan_validator_python_nan_detection() -> None:
    value = float("nan")
    assert value is not None
    assert math.isnan(value)
