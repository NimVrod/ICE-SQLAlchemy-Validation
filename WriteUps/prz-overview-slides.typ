// ── ICE SQLAlchemy Validation — Project Overview (PRZ template) ──────────────
// Rzeszów University of Technology house style.
// Companion to: migration-data-quality-report.typ, why-and-when-slides.typ,
//               cost-benefit-analysis.typ

// ── Brand colours ───────────────────────────────────────────────────────────
#let NAVY = rgb("#00387a")   // PRZ primary navy
#let NAVY_D = rgb("#002a5c")   // darker navy
#let TEAL = rgb("#3a9aa6")   // faculty (WEiI) teal accent
#let C_DARK = rgb("#1f2733")   // strong body text
#let C_MUTED = rgb("#3a3f44")   // body text
#let C_FAINT = rgb("#6b7177")   // captions / footnotes
#let C_CARD = rgb("#ffffff")
#let C_ALT = rgb("#eaeef4")   // alternating table rows
#let C_CODE = rgb("#eef1f5")   // code background
#let C_BORD = rgb("#cdd3db")
#let C_RED = rgb("#b03030")
#let C_ORANGE = rgb("#c47a20")
#let C_BLUE = rgb("#2471a3")
#let C_GREEN = rgb("#1e8449")

// ── Layout constants ────────────────────────────────────────────────────────
#let BAR_W = 7pt       // black edge bars
#let HEADER_H = 1.55cm    // navy title band
#let FOOTER_H = 1.85cm    // logo / slogan band
#let PAD = 1.25cm    // inner horizontal padding
#let LOGO_H = 1.25cm    // footer PRZ logo height

// ── Page ────────────────────────────────────────────────────────────────────
#set page(paper: "presentation-16-9", margin: 0pt, fill: white)

#set text(font: "Calibri", size: 13pt, fill: C_MUTED, lang: "en")
#set par(justify: false, leading: 0.72em)
#set list(indent: 0.5em, spacing: 0.62em, marker: text(fill: NAVY)[•])
#set enum(indent: 0.5em, spacing: 0.62em)

// ── Helpers ─────────────────────────────────────────────────────────────────
#let badge(label, col) = box(
  fill: col,
  inset: (x: 5pt, y: 2.5pt),
  radius: 2pt,
  baseline: 1.5pt,
)[#text(size: 8pt, fill: white, weight: "bold")[#label]]
#let CRITICAL = badge("CRITICAL", C_RED)
#let HIGH = badge("HIGH", C_ORANGE)
#let MEDIUM = badge("MEDIUM", C_BLUE)
#let LOW = badge("LOW", C_GREEN)
#let TOOL = badge("ICE", C_GREEN)
#let YES = text(fill: C_GREEN, weight: "bold")[Yes]
#let NO = text(fill: C_RED, weight: "bold")[No]

#let slabel(body) = text(size: 13.5pt, weight: "bold", fill: NAVY)[#body]
#let mono(body) = text(font: "DejaVu Sans Mono", size: 10.5pt, fill: NAVY_D)[#body]

#let code(body) = block(
  width: 100%,
  fill: C_CODE,
  inset: 11pt,
  radius: 4pt,
  stroke: 0.5pt + C_BORD,
)[
  #set text(font: "DejaVu Sans Mono", size: 9.5pt, fill: C_DARK)
  #set par(first-line-indent: 0em, leading: 0.62em)
  #body
]

#let dtable(..args) = table(
  stroke: 0.4pt + C_BORD,
  inset: (x: 10pt, y: 8.5pt),
  fill: (_, row) => if row == 0 { NAVY } else if calc.odd(row) { C_CARD } else { C_ALT },
  ..args,
)
#let th(body) = text(fill: white, weight: "bold")[#body]

#let metric(value, label, accent) = block(
  width: 100%,
  height: 3.3cm,
  inset: 13pt,
  radius: 5pt,
  fill: C_CARD,
  stroke: (top: 3pt + accent, rest: 0.5pt + C_BORD),
)[
  #align(horizon + center)[
    \
    #text(size: 30pt, weight: "bold", fill: accent)[#value]
    #v(0.25em)
    #text(size: 10.5pt, fill: C_FAINT)[#label]
  ]
]

// ── Static chrome (edge bars + footer with logo + slogan) ───────────────────
#let edge-bars = {
  place(top + left, rect(width: BAR_W, height: 100%, fill: black))
  place(top + right, rect(width: BAR_W, height: 100%, fill: black))
}

#let footer-band = block(
  width: 100%,
  height: 100%,
  inset: (left: PAD, right: PAD, top: 0.2cm, bottom: 0.35cm),
)[
  #line(length: 100%, stroke: 1.2pt + NAVY)
  #v(1fr)
  #grid(
    columns: (auto, 1fr, auto),
    align: (left + horizon, center, right + horizon),
    image("Assets/prz_ang.png", height: LOGO_H),
    [],
    text(size: 14pt, weight: "bold", fill: NAVY, tracking: 0.5pt)[WE BUILD THE FUTURE!],
  )
  #v(1fr)
]

// ── Content slide scaffold ──────────────────────────────────────────────────
#let slide(title, body, sub: none) = page[
  #block(width: 100%, height: 100%)[
    #grid(
      rows: (HEADER_H, 1fr, FOOTER_H),
      block(width: 100%, height: 100%, fill: NAVY, inset: (left: PAD, right: PAD))[
        #align(horizon)[#text(size: 22pt, weight: "bold", fill: white)[#title]]
      ],
      block(
        width: 100%,
        height: 100%,
        inset: (left: PAD, right: PAD, top: 0.55cm, bottom: 0.3cm),
      )[
        #if sub != none {
          text(size: 13.5pt, style: "italic", fill: TEAL)[#sub]
          v(0.5em)
        }
        #align(horizon)[#body]
      ],
      footer-band,
    )
    #edge-bars
  ]
]

// ════════════════════════════════════════════════════════════════════════════
// TITLE SLIDE
// ════════════════════════════════════════════════════════════════════════════
#page[
  #block(width: 100%, height: 100%)[
    #grid(
      rows: (auto, 1fr, auto),
      // top — institutional logos
      block(width: 100%, inset: (left: PAD, right: PAD, top: 1.1cm))[
        #grid(
          columns: (auto, 1fr, auto),
          align: (left + horizon, center, right + horizon),
          image("Assets/prz_ang.png", height: 2.0cm), [], image("Assets/weii_ang.png", height: 1.5cm),
        )
      ],
      // centre — title block
      block(width: 100%, height: 100%, inset: (left: PAD, right: PAD))[
        #align(horizon)[
          #v(0.9em)
          #text(size: 40pt, weight: "bold", fill: NAVY)[
            SQLAlchemy Validation
          ]
          #v(0.45em)
          #text(size: 17pt, style: "italic", fill: C_FAINT)[
            Catching the data corruption that migration tools report as success
          ]
          #v(0.9em)
          #line(length: 32%, stroke: 1.4pt + NAVY)
          #v(0.9em)
          #text(size: 12.5pt, fill: C_MUTED)[
            Hubert Dec · Patryk Dziki · Adrian Czapka · Dominik Dziedzic · Beniamin Sujka
          ]
        ]
      ],
      // bottom — slogan band
      block(width: 100%, inset: (left: PAD, right: PAD, bottom: 0.7cm))[
        #line(length: 100%, stroke: 1pt + NAVY)
        #v(0.22cm)
        #grid(
          columns: (1fr, 1fr),
          align: (left + horizon, right + horizon),
          text(size: 11.5pt, fill: C_FAINT)[Ideas and Computer engineering],
          text(size: 13pt, weight: "bold", fill: NAVY, tracking: 0.4pt)[WE BUILD THE FUTURE!],
        )
      ],
    )
    #edge-bars
  ]
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 1 — The problem
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [The migration succeeded. The data did not.],
  sub: [Six documented incidents where no error fired — yet the data came out wrong.],
)[
  #text(size: 13pt)[
    The dangerous migration failure is the one that *does not* announce itself. No exception,
    no alert, the row count matches, and the tooling reports success. The corruption surfaces
    days or weeks later — through a customer, an analyst, or a regulator.
  ]
  #v(0.8em)
  #dtable(
    columns: (auto, 1fr, auto, auto),
    align: (left + horizon, left + horizon, center + horizon, left + horizon),
    table.header(th[Organisation], th[What went wrong], th[Severity], th[Found by]),
    [Netflix Billing],
    [Oracle `NUMBER` had no exact MySQL type — silent truncation risk],
    MEDIUM,
    [Pre-migration audit],
    [Insurance (EU)],
    [127 000 policies from the 1940s migrated as issued in 2040],
    MEDIUM,
    [User, 3 weeks later],
    [MySQL → Postgres],
    [87 % of timestamps shifted by a whole timezone offset],
    HIGH,
    [Customer report],
    [OpenAI / Redis],
    [Cache resequencing returned data to the wrong user sessions],
    HIGH,
    [User reports],
    [TSB Bank],
    [1.3 billion records corrupted; customers saw strangers' accounts],
    CRITICAL,
    [Customers, 20 min later],
    [TUI Aviation],
    [Title "Miss" remapped to child mass — load sheet 1 244 kg light],
    CRITICAL,
    [Post-flight audit],
  )
  #v(0.7em)
  #align(center)[
    #text(size: 12.5pt, fill: NAVY)[
      Every one passed its structural checks. The only failing check was the one nobody ran:
      *does this value still mean what it meant before?*
    ]
  ]
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 2 — The gap in standard tooling
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [The gap in standard migration tooling],
  sub: [Schema constraints and ORM validators guard new writes — not the rows already loaded.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,
    row-gutter: 1.1em,
    [
      #slabel[1 · Validation confirmed movement, not meaning]
      #v(0.3em)
      Row counts matched and logs were empty — yet none of that verifies a value still carries
      the *same meaning* it had in the source.
    ],
    [
      #slabel[2 · The errors were self-concealing]
      #v(0.3em)
      A corrupted timestamp is still a valid timestamp; a misdated policy is still a well-formed
      date. The corruption hides *inside* normal-looking data.
    ],

    [
      #slabel[3 · Bulk loads bypass the ORM]
      #v(0.3em)
      `pandas.to_sql`, `COPY`, and raw SQL write straight to the table — skipping every
      `@validates` hook and often disabling constraints for speed.
    ],
    [
      #slabel[4 · Detection came from users, not monitoring]
      #v(0.3em)
      TSB's customers reported wrong accounts within 20 minutes of go-live. In no case did
      internal monitoring catch the corruption first.
    ],
  )
  #v(1.0em)
  #align(center)[
    #block(fill: C_CARD, inset: (x: 14pt, y: 9pt), radius: 4pt, stroke: (left: 3pt + NAVY, rest: 0.5pt + C_BORD))[
      #text(size: 12.5pt, fill: NAVY)[
        Millions of migrated rows can hold violations the model would reject on a fresh insert —
        and *nothing in the normal toolchain re-checks them.*
      ]
    ]
  ]
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 3 — How we solve it (the stack)
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [How we solve it],
  sub: [One declarative engine, four proven tools — no parallel config to drift out of sync.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1.6em,
    row-gutter: 1.1em,
    block(width: 100%, inset: 13pt, radius: 5pt, fill: C_CARD, stroke: (left: 3pt + NAVY, rest: 0.5pt + C_BORD))[
      #slabel[SQLAlchemy] #h(0.4em) #mono[src/engine.py]
      #v(0.3em)
      Rules live on the ORM column as `Annotated` markers. The engine reads them and runs
      *set-based SQL* against the live table — streamed with `yield_per`, constant memory at any scale.
    ],
    block(width: 100%, inset: 13pt, radius: 5pt, fill: C_CARD, stroke: (left: 3pt + TEAL, rest: 0.5pt + C_BORD))[
      #text(size: 13.5pt, weight: "bold", fill: TEAL)[pandas] #h(0.4em) #mono[src/pandas\_.py]
      #v(0.3em)
      `errors_to_dataframe` / `summarize_errors` turn raw violations into a tidy report —
      grouped by `kind` and `column` for instant triage.
    ],

    block(width: 100%, inset: 13pt, radius: 5pt, fill: C_CARD, stroke: (left: 3pt + C_GREEN, rest: 0.5pt + C_BORD))[
      #text(size: 13.5pt, weight: "bold", fill: C_GREEN)[pytest] #h(0.4em) #mono[pytest plugin]
      #v(0.3em)
      A registered plugin exposes `assert_table_valid(session, Model)` — one assertion turns the
      whole audit into a pass/fail CI gate.
    ],
    block(width: 100%, inset: 13pt, radius: 5pt, fill: C_CARD, stroke: (left: 3pt + C_ORANGE, rest: 0.5pt + C_BORD))[
      #text(size: 13.5pt, weight: "bold", fill: C_ORANGE)[Streamlit] #h(0.4em) #mono[dashboard/app.py]
      #v(0.3em)
      A live dashboard with auto-refresh and a configurable connection string — paste any
      SQLAlchemy URL and watch violations in real time.
    ],
  )
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 4 — Declare the rule once
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [Declare the rule once, on the column],
  sub: [Same file, same code review — the validation lives next to the data it protects.],
)[
  #grid(
    columns: (1.18fr, 0.82fr),
    column-gutter: 1.8em,
    [
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
      #v(0.4em)
      #dtable(
        columns: (auto, 1fr),
        align: (left + horizon, left + horizon),
        table.header(th[Marker], th[Meaning]),
        [`Required()`],
        [Value must not be NULL],
        [`Nullable()`],
        [Explicitly permits NULL],
        [`Unique()`],
        [Values must be unique],
        [`UniqueComposite`],
        [Multi-column unique rule],
        [`FloatMin(n)`],
        [Numeric lower bound],
        [`FloatMax(n)`],
        [Numeric upper bound],
        [`NoNaN()`],
        [Reject IEEE NaN in a float],
      )
      #v(0.5em)
      #text(size: 10.5pt, fill: C_FAINT)[
        A non-optional `Mapped[T]` implies `Required()` automatically; `Mapped[T | None]`
        skips the null check.
      ]
    ],
  )
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 5 — Run it
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [Run it — three lines],
  sub: [SQL-first, streaming, two passes — no ORM overhead, no full table held in memory.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1.8em,
    [
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
      #v(0.5em)
      #slabel[Example summary output]
      #v(0.35em)
      #code[
        ```text
        kind        column   count
        null        email       52
        duplicate   email       50
        float_min   age         20
        ```
      ]
    ],
    [
      #slabel[Pass 1 · Field rules]
      #v(0.25em)
      #text(size: 12pt)[
        Each marker emits one `SELECT` for *only* the violating rows (e.g. `WHERE age < 0`),
        streamed with `yield_per=5000`.
      ]
      #v(0.6em)
      #slabel[Pass 2 · Duplicate rules]
      #v(0.25em)
      #text(size: 12pt)[
        `Unique` / `UniqueComposite` targets are gathered into one
        `GROUP BY … HAVING COUNT(*) > 1` per constraint.
      ]
      #v(0.6em)
      #slabel[Python only where SQL can't]
      #v(0.25em)
      #text(size: 12pt)[
        `NoNaN()` pre-filters non-null rows in SQL, then checks `math.isnan()` in Python —
        NaN comparison is not portable across engines.
      ]
    ],
  )
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 6 — How it compares
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [How it compares to the alternatives],
  sub: [Other tools either ignore the rows already in the table, or drift away from the model.],
)[
  #dtable(
    columns: (1.5fr, 1.2fr, 1.2fr, 1.1fr),
    align: (left + horizon, center + horizon, center + horizon, center + horizon),
    table.header(th[Approach], th[Audits existing rows?], th[Declared on the model?], th[Needs data in memory?]),
    [SQLAlchemy `#"@validates"`],
    [#NO #text(size: 9pt)[ (new writes only)]],
    [#YES],
    [#NO],
    [DB `CheckConstraint`],
    [#NO #text(size: 9pt)[ (new writes only)]],
    [#YES],
    [#NO],
    [Pandera schema],
    [#YES],
    [#NO #text(size: 9pt)[ (separate)]],
    [#YES #text(size: 9pt)[ (full DataFrame)]],
    [Great Expectations],
    [#YES],
    [#NO #text(size: 9pt)[ (suite)]],
    [#YES],
    [*SQLAlchemy Validation*],
    [#YES #text(size: 9pt)[ (set-based SQL)]],
    [#YES],
    [#NO #text(size: 9pt)[ (streamed)]],
  )
  #v(0.9em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1.8em,
    [
      #text(size: 11.5pt, fill: C_FAINT)[`@validates` — runs only on ORM flush, never on a bulk load:]
      #v(0.3em)
      #code[
        ```python
        class User(Base):
            @validates("age")
            def check_age(self, key, value):
                if value < 0:
                    raise ValueError("bad age")
                return value   # skipped by to_sql / COPY
        ```
      ]
    ],
    [
      #text(size: 11.5pt, fill: C_FAINT)[Our validation — one marker, audits every row already in the table:]
      #v(0.3em)
      #code[
        ```python
        class User(Base):
            age: Mapped[Annotated[int, FloatMin(0)]]

        # later, against the live DB:
        MigrationValidator(session).validate(User)
        ```
      ]
    ],
  )
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 7 — Gate the pipeline (pytest + streamlit)
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [Gate the pipeline, watch it live],
  sub: [The same models power a CI assertion and a real-time dashboard.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1.8em,
    [
      #slabel[pytest — pass/fail gate]
      #v(0.35em)
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
      #v(0.45em)
      #text(size: 11pt, fill: C_FAINT)[
        On failure the assertion prints the total error count and the summary DataFrame.
      ]
    ],
    [
      #slabel[Add it to CI when…]
      #v(0.35em)
      - an ETL / bulk load ran outside the ORM
      - staging data mirrors production volume
      - the schema changed since last migration
      - a hotfix touched legacy rows
      - cut-over needs a sign-off gate

      #v(0.7em)
      #slabel[Streamlit dashboard]
      #v(0.25em)
      #text(size: 12pt)[
        `uv run streamlit run dashboard/app.py` — paste any SQLAlchemy URL, auto-refresh, and
        triage violations by `kind` and `column` without writing a query.
      ]
    ],
  )
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 8 — Dashboard overview
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [Streamlit dashboard — overview],
  sub: [Live KPIs, rule summary, and pass/fail status on any SQLAlchemy connection.],
)[
  #image("Assets/dashboard.png", width: 100%)
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 9 — Dashboard error details
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [Drill into every error],
  sub: [Filter by table, field, and validator — then inspect row-level violations.],
)[
  #image("Assets/dashboard2.png", width: 100%)
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 10 — Cost-benefit
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [Cheap to run, expensive to skip],
  sub: [Benchmarks from examples/\_bench_timing.py — SQLite, four rules, 10 250 rows.],
)[
  #grid(
    columns: (1fr, 1fr, 1fr, 1fr),
    column-gutter: 1em,
    metric([≈ 0.03 s], [Automated check\ vs 80 min by hand], C_GREEN),
    metric([160 000×], [Faster than the\ manual equivalent], NAVY),
    metric([≈ 21 h], [Engineer time saved\ per year (base case)], C_BLUE),
    metric([£600], [One-time setup\ (~8 h to onboard)], C_ORANGE),
  )
  #v(1.0em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1.8em,
    [
      #slabel[Why it matters]
      #v(0.25em)
      #text(size: 12.5pt)[
        Manual checking grows with the data; the automated check stays under a second at every
        size tested. The real value, though, is *avoiding the late surprise* — not the time saved.
      ]
    ],
    [
      #slabel[Defects caught in the demo]
      #v(0.25em)
      #text(size: 12.5pt)[
        On ~1 025 deliberately dirty rows: *52 missing*, *46 duplicate*, *20 out-of-range* — 118
        bad records that a row-count check would have waved straight through.
      ]
    ],
  )
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 11 — Cost of a missed defect
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [The cost of a missed defect],
  sub: [Setup is a rounding error next to a single real incident.],
)[
  #let C_BG2 = rgb("#f3f5f8")
  #let bars = (
    ([Our setup], 0.0006, [£0.6k], C_GREEN),
    ([Yearly manual\ checking], 0.0024, [£2.4k], C_BLUE),
    ([Mid-size incident\ (estimate)], 2, [£2M], C_ORANGE),
    ([TSB Bank case\ (actual)], 330, [£330M], C_RED),
  )
  #let maxv = 330
  #block(width: 100%)[
    #grid(
      columns: (1fr,) * bars.len(), column-gutter: 22pt,
      ..bars.map(it => align(bottom + center)[
        #text(size: 12pt, weight: "bold", fill: C_DARK)[#it.at(2)]
        #v(4pt)
        #box(
          width: 2.2cm,
          height: calc.max(calc.log(calc.max(it.at(1), 0.0001)) / calc.log(maxv) * 5cm + 2.6cm, 0.35cm),
          fill: it.at(3),
          radius: (top: 3pt),
        )
      ])
    )
    #line(length: 100%, stroke: 0.7pt + C_FAINT)
    #v(5pt)
    #grid(
      columns: (1fr,) * bars.len(), column-gutter: 22pt,
      ..bars.map(it => align(center)[#text(size: 11pt, fill: C_MUTED)[#it.at(0)]])
    )
  ]
  #v(1.0em)
  #align(center)[
    #text(size: 12.5pt, fill: NAVY)[
      A red test costs an engineer an hour. The same defect post-go-live cost TSB *£330 million*,
      80 000 customers, and an £48.65 M regulatory fine.
    ]
  ]
]

// ════════════════════════════════════════════════════════════════════════════
// SLIDE 12 — Summary
// ════════════════════════════════════════════════════════════════════════════
#slide(
  [Summary],
  sub: [Structural integrity today; semantic checks tomorrow — always declared on the model.],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2.2em,
    row-gutter: 1.0em,
    [
      #slabel[Why it exists]
      #v(0.3em)
      - "Successful" migrations still corrupt data
      - Row counts never verify field-level correctness
      - Bulk loads bypass ORM validation
      - Users find the problem before monitoring does
    ],
    [
      #slabel[What it covers now]
      #v(0.3em)
      - NULL violations — `Required()`
      - Out-of-range — `FloatMin`, `FloatMax`
      - Uniqueness — `Unique`, `UniqueComposite`
      - IEEE NaN in floats — `NoNaN()`
    ],

    [
      #slabel[How to adopt it]
      #v(0.3em)
      + Annotate mapped columns with markers
      + Run `MigrationValidator(session).validate(Model)`
      + Review `errors_to_dataframe` / `summarize_errors`
      + Gate cut-over with `assert_table_valid`
    ],
    [
      #slabel[Where it's going]
      #v(0.3em)
      - Category / ENUM remapping validators
      - Cross-table referential integrity
      - Timezone-aware timestamp comparison
      - Custom domain markers via `parser.py`
    ],
  )
  #v(0.9em)
  #align(center)[
    #text(size: 12pt, fill: C_FAINT)[
      `uv run pytest`  ·  `uv run python examples/validate_dirty_database.py`  ·  `uv run streamlit run dashboard/app.py`
    ]
  ]
]
