from __future__ import annotations

from collections.abc import Sequence
from dataclasses import asdict
from html import escape
from pathlib import Path

import pandas as pd

from src.validation_types import ValidationError


REPORT_COLUMNS = ["table", "id", "field", "error", "validator"]
SUMMARY_COLUMNS = ["table", "field", "validator", "count"]

_HTML_STYLES = """
body { font-family: system-ui, sans-serif; margin: 2rem; color: #1a1a1a; }
h1 { margin-bottom: 0.25rem; }
.meta { color: #555; margin-bottom: 1.5rem; }
.status-passed { color: #0a7a2f; font-weight: 600; }
.status-failed { color: #b42318; font-weight: 600; }
section { margin-bottom: 2rem; }
h2 { font-size: 1.1rem; margin-bottom: 0.75rem; }
table.data-table { border-collapse: collapse; width: 100%; font-size: 0.9rem; }
table.data-table th, table.data-table td {
  border: 1px solid #d0d7de;
  padding: 0.5rem 0.75rem;
  text-align: left;
  vertical-align: top;
}
table.data-table th { background: #f6f8fa; }
table.data-table tbody tr:nth-child(even) { background: #fafbfc; }
.success { color: #0a7a2f; font-weight: 600; }
"""


def errors_to_dataframe(errors: Sequence[ValidationError]) -> pd.DataFrame:
    if not errors:
        return pd.DataFrame(columns=REPORT_COLUMNS)
    return pd.DataFrame([asdict(error) for error in errors], columns=REPORT_COLUMNS)


def summarize_errors(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return pd.DataFrame(columns=SUMMARY_COLUMNS)
    return (
        df.groupby(["table", "field", "validator"], dropna=False)
        .size()
        .rename("count")
        .reset_index()
        .sort_values(["count", "table", "field"], ascending=[False, True, True])
        .reset_index(drop=True)
    )


def _dataframe_to_html_table(df: pd.DataFrame) -> str:
    return df.to_html(index=False, border=0, classes="data-table", escape=True)


def errors_to_html(
    df: pd.DataFrame,
    *,
    title: str = "Migration Validation Report",
    summary: pd.DataFrame | None = None,
) -> str:
    if summary is None:
        summary = summarize_errors(df)

    total_errors = len(df)
    status_class = "status-passed" if total_errors == 0 else "status-failed"
    status_text = "PASSED" if total_errors == 0 else "FAILED"

    summary_section = ""
    if not summary.empty:
        summary_section = (
            "<section>\n"
            "  <h2>Summary</h2>\n"
            f"  {_dataframe_to_html_table(summary)}\n"
            "</section>"
        )

    if df.empty:
        detail_section = '<p class="success">No validation errors found.</p>'
    else:
        detail_section = (
            "<section>\n"
            "  <h2>Details</h2>\n"
            f"  {_dataframe_to_html_table(df)}\n"
            "</section>"
        )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{escape(title)}</title>
  <style>{_HTML_STYLES}</style>
</head>
<body>
  <h1>{escape(title)}</h1>
  <p class="meta">
    Status: <span class="{status_class}">{status_text}</span> |
    Total errors: {total_errors}
  </p>
  {summary_section}
  {detail_section}
</body>
</html>
"""


def write_errors_html(
    df: pd.DataFrame,
    path: str | Path,
    *,
    title: str = "Migration Validation Report",
    summary: pd.DataFrame | None = None,
) -> Path:
    output_path = Path(path)
    output_path.write_text(
        errors_to_html(df, title=title, summary=summary),
        encoding="utf-8",
    )
    return output_path
