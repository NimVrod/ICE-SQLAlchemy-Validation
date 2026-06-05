// ── Why and When to Use ICE SQLAlchemy Validation ─────────────────────────
// Companion deck to Error_refrences_SprintI/migration-data-quality-report.typ

// ── Theme colours (match the report) ────────────────────────────────────────
#let C_DARK   = rgb("#2c3e50")   // titles, strong text
#let C_MUTED  = rgb("#444b52")   // body text
#let C_FAINT  = rgb("#7a8088")   // footer, captions
#let C_RULE   = rgb("#2c3e50")   // accent rule under titles
#let C_BG     = rgb("#f7f8fa")   // slide background
#let C_CARD   = rgb("#ffffff")   // white panels
#let C_ALT    = rgb("#eceef1")   // alternating table rows
#let C_CODE   = rgb("#eef0f3")   // code background
#let C_RED    = rgb("#b03030")
#let C_ORANGE = rgb("#c47a20")
#let C_BLUE   = rgb("#2471a3")
#let C_GREEN  = rgb("#1e8449")

// ── Page ─────────────────────────────────────────────────────────────────────
#set page(
  paper: "a4",
  flipped: true,
  fill: C_BG,
  margin: (x: 1.5cm, top: 1.1cm, bottom: 1.15cm),
  footer: context [
    #set text(size: 7.5pt, fill: C_FAINT, font: "New Computer Modern")
    #line(length: 100%, stroke: 0.3pt + C_FAINT)
    #v(0.15em)
    #grid(
      columns: (1fr, auto, 1fr),
      align: (left, center, right),
      [ICE SQLAlchemy Validation],
      counter(page).display("1 / 1", both: true),
      [Data Quality in Database Migrations],
    )
  ],
)

// ── Base typography ───────────────────────────────────────────────────────────
#set text(font: "New Computer Modern", size: 12pt, fill: C_MUTED, lang: "en")
#set par(justify: false, leading: 0.78em)
#set list(indent: 0.6em, spacing: 0.7em, marker: text(fill: C_BLUE)[•])
#set enum(indent: 0.6em, spacing: 0.7em)

// ── Helpers ───────────────────────────────────────────────────────────────────

// Severity badges identical to the report
#let badge(label, col) = box(
  fill: col, inset: (x: 5pt, y: 2.5pt), radius: 2pt, baseline: 1.5pt,
)[#text(size: 7.5pt, fill: white, weight: "bold")[#label]]

#let CRITICAL = badge("CRITICAL", C_RED)
#let HIGH     = badge("HIGH",     C_ORANGE)
#let MEDIUM   = badge("MEDIUM",   C_BLUE)
#let LOW      = badge("LOW",      C_GREEN)
#let TOOL     = badge("TOOL",     C_GREEN)

// Bold section label inside a slide
#let slabel(body) = text(size: 13pt, weight: "bold", fill: C_DARK)[#body]

// Inline monospaced span
#let mono(body) = text(font: "DejaVu Sans Mono", size: 10pt, fill: C_DARK)[#body]

// Code block (self-sizing, no fixed height)
#let code(body) = block(
  width: 100%,
  fill: C_CODE,
  inset: 13pt,
  radius: 4pt,
  stroke: 0.5pt + rgb("#d0d2d8"),
)[
  #set text(font: "DejaVu Sans Mono", size: 9.5pt, fill: C_DARK)
  #set par(first-line-indent: 0em, leading: 0.7em)
  #body
]

// A table that already matches the deck theme
#let dtable(..args) = table(
  stroke: 0.4pt + rgb("#cfd2d7"),
  inset: (x: 11pt, y: 10pt),
  fill: (_, row) => if row == 0 { C_DARK } else if calc.odd(row) { C_CARD } else { C_ALT },
  ..args,
)
#let th(body) = text(fill: white, weight: "bold")[#body]

// ── Slide scaffold ───────────────────────────────────────────────────────────
// Title sits at the top; the body block expands to fill all remaining height,
// with content vertically centred so no space is left dead at the bottom.
#let slide(title, body, sub: none) = page[
  #block(width: 100%, height: 100%)[
    #grid(
      rows: (auto, 1fr),
      row-gutter: 0.55em,
      [
        #text(size: 26pt, weight: "bold", fill: C_DARK)[#title]
        #v(0.16em)
        #line(length: 22%, stroke: 1.4pt + C_RULE)
        #if sub != none {
          v(0.42em)
          text(size: 13.5pt, style: "italic", fill: C_FAINT)[#sub]
        }
      ],
      block(width: 100%, height: 100%, inset: (top: 0.4em))[
        #align(horizon)[#body]
      ],
    )
  ]
]

// ── Title slide ──────────────────────────────────────────────────────────────
#page(footer: none)[
  #align(center + horizon)[
    #text(size: 10pt, tracking: 1.2pt, fill: C_FAINT)[
      #upper[Data Quality in Database Migrations]
    ]
    #v(1.4em)
    #text(size: 34pt, weight: "bold", fill: C_DARK)[
      Why and When to Use \
      ICE SQLAlchemy Validation
    ]
    #v(0.7em)
    #text(size: 15pt, style: "italic", fill: C_FAINT)[
      Catching the data corruption that migration tools report as success
    ]
    #v(1.4em)
    #line(length: 30%, stroke: 0.7pt + C_FAINT)
    #v(1.4em)
    #text(size: 11pt, fill: C_FAINT)[
      Hubert Dec · Patryk Dziki · Adrian Czapka · Dominik Dziedzic · Beniamin Sujka
    ]
  ]
]

// ── Slide 2 — The silent failure ─────────────────────────────────────────────
#slide(
  [The migration succeeded. The data did not.],
  sub: [Six documented incidents where no error fired — yet the data came out wrong.],
)[
  #text(size: 12.5pt)[
    The dangerous migration failure is the one that *does not* announce itself.
    No exception, no alert, the row count matches, and the tooling reports success.
    The corruption surfaces days or weeks later — through a customer, an analyst, or a regulator.
  ]
  #v(1.1em)

  #dtable(
    columns: (auto, 1fr, auto, auto),
    align: (left + horizon, left + horizon, center + horizon, left + horizon),
    table.header(th[Organisation], th[What went wrong], th[Severity], th[Found by]),
    [Netflix Billing],  [Oracle `NUMBER` had no exact MySQL type — risk of silent truncation], MEDIUM,   [Pre-migration audit],
    [Insurance (EU)],   [127 000 policies from the 1940s migrated as issued in 2040],          MEDIUM,   [User, 3 weeks later],
    [MySQL → Postgres], [87 % of timestamps shifted by a whole timezone offset],               HIGH,     [Customer report],
    [OpenAI / Redis],   [Cache resequencing returned data to the wrong user sessions],         HIGH,     [User reports],
    [TSB Bank],         [1.3 billion records corrupted; customers saw strangers' accounts],     CRITICAL, [Customers, 20 min later],
    [TUI Aviation],     [Title "Miss" remapped to child mass — load sheet 1 244 kg light],     CRITICAL, [Post-flight audit],
  )
  #v(1.0em)

  #align(center)[
    #text(size: 12.5pt, fill: C_DARK)[
      Every one passed its structural checks. The only failing check was the one nobody ran:
      *does this value still mean what it meant before?*
    ]
  ]
]

// ── Slide 3 — What they all share ────────────────────────────────────────────
#slide(
  [What every incident has in common],
  sub: [Different engines, different domains — one structural pattern.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2.4em,
    row-gutter: 1.5em,
    [
      #slabel[1 · Validation confirmed movement, not meaning]
      #v(0.35em)
      Row counts matched, error logs were empty, connectivity checks passed.
      None of these verify that a value in the target carries the *same meaning*
      it had in the source. 87 % of timestamps were wrong while the migration
      reported a clean run.
    ],
    [
      #slabel[2 · Errors were self-concealing]
      #v(0.35em)
      A corrupted timestamp still looks like a valid timestamp. A misdated policy
      is still a well-formed date. A 1 244 kg-light load sheet still parses as a
      normal load sheet. The corruption hides *inside* the normal appearance of
      the data — which is what makes it more dangerous than a crash.
    ],
    [
      #slabel[3 · Testing covered the common case only]
      #v(0.35em)
      The insurance team validated date conversion on recent records and never
      reached the 1940s archive where the legacy two-digit-year bug lived.
      TUI tested typical passengers, not the "Miss" title against the weight
      calculation it actually fed.
    ],
    [
      #slabel[4 · Detection came from users, not monitoring]
      #v(0.35em)
      TSB's customers reported wrong accounts within 20 minutes of go-live.
      The timezone bug was reported by a customer, not an alert. OpenAI learned
      of the exposure from users. In no case did internal monitoring catch the
      corruption first.
    ],
  )
]

// ── Slide 4 — The gap ────────────────────────────────────────────────────────
#slide(
  [The gap in standard migration tooling],
  sub: [Schema constraints and ORM validators guard new writes — not the rows already loaded.],
)[
  #text(size: 12.5pt)[
    Bulk loads — `pandas.to_sql`, ETL pipelines, `COPY`, hand-written SQL — write straight to
    the table and *bypass ORM validation entirely*. Millions of migrated rows can hold violations
    the model would reject on a fresh insert, and nothing in the normal toolchain re-checks them.
  ]
  #v(1.1em)

  #dtable(
    columns: (1.6fr, 1fr, 1.4fr),
    align: (left + horizon, center + horizon, left + horizon),
    table.header(th[Mechanism], th[Catches a bad new INSERT?], th[Audits already-migrated rows?]),
    [`CheckConstraint` on the model], [Often], [Only if the DB enforces it *and* data is re-checked],
    [ORM `#"@validates"` hook],       [On flush], [Never — not triggered by bulk / raw SQL load],
    [Row count vs. source],           [—], [Volume only — says nothing about field correctness],
    [*MigrationValidator* #TOOL],     [—], [*Yes — scans every existing row with set-based SQL*],
  )
  #v(1.0em)

  #text(size: 11.5pt, fill: C_FAINT)[
    Worse: with constraints disabled for load performance (a common bulk-import step), an engine will
    happily accept a NULL into a `NOT NULL` column. The violation simply *stays* in the table —
    discoverable only by an explicit, row-level audit.
  ]
]

// ── Slide 5 — What the library does ─────────────────────────────────────────
#slide(
  [What ICE SQLAlchemy Validation does],
  sub: [Declare the rule once, on the column. Run it against the data already in the database.],
)[
  #grid(
    columns: (1.15fr, 0.85fr),
    column-gutter: 2.2em,
    [
      #text(size: 12pt)[
        Rules live directly on the ORM column as `Annotated` markers — same file, same code review,
        no parallel config to drift out of sync. The engine reads those markers and runs set-based
        SQL against the live table, returning every row that breaks a rule.
      ]
      #v(0.8em)
      #code[
```python
from typing import Annotated
from sqlalchemy.orm import Mapped, mapped_column
from src.metadata import (
    Required, Unique, FloatMin, FloatMax,
    UniqueComposite, NoNaN,
)

class User(Base):
    __tablename__ = "users"
    id:      Mapped[int]
    email:   Mapped[Annotated[str, Required(), Unique()]]
    age:     Mapped[Annotated[int, Required(),
                    FloatMin(0), FloatMax(120)]]
    country: Mapped[Annotated[str, Required(),
                    UniqueComposite("country", "city")]]
    city:    Mapped[Annotated[str, Required()]]
    score:   Mapped[Annotated[float, NoNaN()]]
```
      ]
    ],
    [
      #slabel[Markers available in v1]
      #v(0.5em)
      #dtable(
        columns: (auto, 1fr),
        align: (left + horizon, left + horizon),
        table.header(th[Marker], th[Meaning]),
        [`Required()`],      [Value must not be NULL],
        [`Nullable()`],      [Explicitly permits NULL],
        [`Unique()`],        [Column values must be unique],
        [`UniqueComposite`], [Multi-column unique rule],
        [`FloatMin(n)`],     [Numeric lower bound],
        [`FloatMax(n)`],     [Numeric upper bound],
        [`NoNaN()`],         [Reject IEEE NaN in a float],
      )
      #v(0.8em)
      #text(size: 11pt, fill: C_FAINT)[
        A non-optional `Mapped[T]` implies `Required()` automatically;
        `Mapped[T | None]` skips the null check. Legacy `Column(...)` with
        `Annotated` is supported too.
      ]
    ],
  )
]

// ── Slide 6 — Which failure modes it addresses ───────────────────────────────
#slide(
  [Which report failure modes does it catch?],
  sub: [Each v1 marker targets a specific top-10 pattern from the Sprint I report.],
)[
  #text(size: 12pt)[
    The library deliberately starts with the *structural* failure modes — the ones expressible as a
    per-row predicate. These are the patterns that bulk loads reintroduce most often and that
    field-level validation can verify with certainty.
  ]
  #v(1.0em)

  #dtable(
    columns: (1.3fr, 1.2fr, auto, 1.1fr),
    align: (left + horizon, left + horizon, center + horizon, left + horizon),
    table.header(th[Failure mode (report §3)], th[Real incident], th[Severity], th[Marker that catches it]),
    [Numeric precision / out-of-range value], [Netflix billing truncation],   MEDIUM,   [`FloatMin` / `FloatMax`],
    [Silent NULL after a bulk load],          [Insurance nulls, TSB FK gaps],  CRITICAL, [`Required()`],
    [Duplicate records from re-runs],         [Non-idempotent ETL pipelines],  LOW,      [`Unique()`],
    [NaN written into a float column],        [Pandas / ETL artefacts],        MEDIUM,   [`NoNaN()`],
    [Composite key uniqueness broken],        [Multi-tenant migrations],       HIGH,     [`UniqueComposite`],
  )
  #v(1.0em)

  #text(size: 11.5pt)[
    *Not yet in v1 (future work):* timezone / semantic drift, category remapping, encoding corruption,
    and cross-table referential integrity. Each needs a domain-specific or multi-table check —
    and the `parser.py` pipeline already accepts custom markers, so they slot in without engine changes.
  ]
]

// ── Slide 7 — How it runs ────────────────────────────────────────────────────
#slide(
  [How the validator runs],
  sub: [SQL-first, streaming, two passes — no ORM overhead and no full table held in memory.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2.2em,
    [
      #slabel[Pass 1 — Field rules]
      #v(0.3em)
      #text(size: 11.5pt)[
        `parser.py` reads the `Annotated` metadata of every mapped field and builds one validator per
        marker. Each emits a single SQL `SELECT` targeting *only* the violating rows
        (e.g. `WHERE age < 0`), streamed with `yield_per=5000` for constant memory use at any scale.
      ]
      #v(0.7em)
      #slabel[Pass 2 — Duplicate rules]
      #v(0.3em)
      #text(size: 11.5pt)[
        All `Unique()` and `UniqueComposite` targets are gathered, then a
        `GROUP BY … HAVING COUNT(*) > 1` query finds every duplicate key set in one round-trip
        per constraint.
      ]
      #v(0.7em)
      #slabel[Python only where SQL can't]
      #v(0.3em)
      #text(size: 11.5pt)[
        `NoNaN()` pre-filters non-null rows in SQL, then checks `math.isnan()` in Python — because
        NaN comparison behaviour is not portable across SQLite versions.
      ]
    ],
    [
      #slabel[Run it — three lines]
      #v(0.4em)
      #code[
```python
from sqlalchemy.orm import Session
from src.engine import MigrationValidator
from src.pandas_ import (
    errors_to_dataframe, summarize_errors,
)

with Session(engine) as session:
    errors = MigrationValidator(session) \
        .validate(User)

report  = errors_to_dataframe(errors)
summary = summarize_errors(report)
```
      ]
      #v(0.7em)
      #slabel[Example summary output]
      #v(0.4em)
      #code[
```text
kind        column   count
null        email       52
duplicate   email       50
float_min   age         20
```
      ]
    ],
  )
]

// ── Slide 8 — Pytest integration ─────────────────────────────────────────────
#slide(
  [Gate your migration pipeline with pytest],
  sub: [One assertion turns the whole audit into a pass/fail CI check.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2.2em,
    [
      #text(size: 12pt)[
        The library registers a pytest plugin through `pyproject.toml`, exposing a
        `migration_validator` fixture and an `assert_table_valid` helper. Point it at each model and
        the build fails the moment any row is dirty — no separate reporting step to remember.
      ]
      #v(0.8em)
      #code[
```python
# test_migration.py
from src.pytest_validation_plugin import (
    assert_table_valid,
)

def test_users_after_migration(session):
    assert_table_valid(session, User)

def test_policies_after_migration(session):
    assert_table_valid(session, Policy)
```
      ]
      #v(0.7em)
      #text(size: 11pt, fill: C_FAINT)[
        On failure the assertion prints the total error count and the summary DataFrame —
        identical to the pandas report.
      ]
    ],
    [
      #slabel[Plugin entry point]
      #v(0.4em)
      #code[
```toml
[project.entry-points.pytest11]
ice_sqlalchemy_validation = \
    "src.pytest_validation_plugin"
```
      ]
      #v(0.8em)
      #slabel[Add it to CI when…]
      #v(0.4em)
      - staging data mirrors production volume
      - an ETL / bulk load ran outside the ORM
      - the schema changed since the last migration
      - a hotfix touched legacy rows
      - cut-over needs a sign-off gate

      #v(0.8em)
      #text(size: 11.5pt, fill: C_DARK)[
        A red test here costs an engineer an hour.
        The same defect post-go-live cost TSB *£330 million*.
      ]
    ],
  )
]

// ── Slide 9 — When to run it ─────────────────────────────────────────────────
#slide(
  [When to run validation in a project],
  sub: [Not a one-off — a gate that fires every time data moves.],
)[
  #dtable(
    columns: (1.3fr, 1.2fr, 1.5fr),
    align: (left + horizon, left + horizon, left + horizon),
    table.header(th[Pipeline stage], th[Trigger], th[What to validate]),
    [After a bulk load to staging],      [Every ETL / `to_sql` run],   [All columns that carry markers],
    [Before UAT begins],                 [Manual gate or CI check],     [Every model; review the summary DataFrame],
    [After a hotfix on legacy data],     [On merge to the staging branch], [Only the affected models],
    [Before production cut-over],        [Required sign-off step],      [Full schema; diff summary against a baseline],
    [Just after production cut-over],    [Smoke test in the first 30 min], [Critical tables; alert on any error],
  )
  #v(1.1em)

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2.2em,
    [
      #slabel[The one principle]
      #v(0.3em)
      #text(size: 12pt)[
        Validate at the *volume and shape* of production data — never a 100-row sample. TSB's test
        environment never reached production scale, and that is exactly where its edge cases lived.
      ]
    ],
    [
      #slabel[Cheap to wire in]
      #v(0.3em)
      #text(size: 12pt)[
        Because the check is just SQL over an existing table, running it on staging adds seconds,
        not a new pipeline. The same models power the demo in `examples/validate_dirty_database.py`.
      ]
    ],
  )
]

// ── Slide 10 — Summary ───────────────────────────────────────────────────────
#slide(
  [Summary],
  sub: [Structural integrity today; semantic checks tomorrow — always declared on the model.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2.4em,
    row-gutter: 1.3em,
    [
      #slabel[Why it exists]
      #v(0.35em)
      - Real incidents prove a "successful" migration can still corrupt data
      - Row counts and clean logs never verify field-level correctness
      - Bulk loads bypass ORM validation, so violations survive undetected
      - Users find the problem before monitoring ever does
    ],
    [
      #slabel[What it covers now]
      #v(0.35em)
      - NULL violations — `Required()`
      - Numeric out-of-range — `FloatMin`, `FloatMax`
      - Uniqueness — `Unique`, `UniqueComposite`
      - IEEE NaN in floats — `NoNaN()`
    ],
    [
      #slabel[How to adopt it]
      #v(0.35em)
      + Annotate mapped columns with markers
      + Run `MigrationValidator(session).validate(Model)`
      + Review `errors_to_dataframe` / `summarize_errors`
      + Add `assert_table_valid` to the staging suite, gate cut-over on a clean run
    ],
    [
      #slabel[Where it's going]
      #v(0.35em)
      - Category / ENUM remapping validators
      - Cross-table referential integrity checks
      - Timezone-aware timestamp comparison
      - Custom domain markers via the existing `parser.py` pipeline
    ],
  )
  #v(1.1em)
  #align(center)[
    #text(size: 11.5pt, fill: C_FAINT)[
      `uv run pytest`  ·  `uv run python examples/validate_dirty_database.py`
    ]
  ]
]
