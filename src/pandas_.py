from __future__ import annotations

from collections.abc import Sequence
from dataclasses import asdict

import pandas as pd

from src.validation_types import ValidationError


REPORT_COLUMNS = ["table", "id", "field", "error", "validator"]


def errors_to_dataframe(errors: Sequence[ValidationError]) -> pd.DataFrame:
    if not errors:
        return pd.DataFrame(columns=REPORT_COLUMNS)
    return pd.DataFrame([asdict(error) for error in errors], columns=REPORT_COLUMNS)


def summarize_errors(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return pd.DataFrame(columns=["table", "field", "validator", "count"])
    return (
        df.groupby(["table", "field", "validator"], dropna=False)
        .size()
        .rename("count")
        .reset_index()
        .sort_values(["count", "table", "field"], ascending=[False, True, True])
        .reset_index(drop=True)
    )
