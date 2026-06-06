// ── PM Deck: Cost-Benefit in Slides ─────────────────────────────────────────
// Audience: project managers and delivery leads.
//
// Core inputs from this repository:
// - examples/_bench_timing.py            (measured timings)
// - examples/validate_dirty_database.py  (real defect counts)
// - migration-data-quality-report.typ (documented real incidents)

#let title = [Migration Validation]
#let subtitle = [Cost–Benefit Analysis]
#let institution = [ICE SQLAlchemy Validation]
#let city = [June 2026]

// Benchmarks from examples/_bench_timing.py (SQLite, 4 rules)
#let rows = (1025, 10250, 102500)
#let auto-sec = (0.034, 0.030, 0.555)
#let manual-min = (62.0, 80.5, 265.0)

// Real defects found in examples/validate_dirty_database.py (~1,025 rows)
#let demo-null = 52
#let demo-dup = 46
#let demo-range = 20

// Business assumptions (editable)
#let engineer-rate = 75
#let setup-hours = 8
#let migration-cycles-per-year = 2
#let checks-per-cycle = 8
#let annual-checks = migration-cycles-per-year * checks-per-cycle

#let base-manual-min = manual-min.at(1)
#let base-auto-min = auto-sec.at(1) / 60
#let saved-min-per-check = base-manual-min - base-auto-min
#let annual-hours-saved = annual-checks * saved-min-per-check / 60
#let annual-saved-gbp = annual-hours-saved * engineer-rate
#let setup-cost-gbp = setup-hours * engineer-rate
#let annual-manual-gbp = annual-checks * base-manual-min / 60 * engineer-rate
#let speed-up = calc.round(manual-min.at(1) * 60 / auto-sec.at(1), digits: 0)

// Scenario inputs (hours per year saved)
#let low-hours = calc.round(annual-hours-saved * 0.6, digits: 1)
#let base-hours = calc.round(annual-hours-saved, digits: 1)
#let high-hours = calc.round(annual-hours-saved * 1.6, digits: 1)

// Incident costs (documented real cases) — real figures + one mid-size estimate
#let cost-setup = setup-cost-gbp
#let cost-annual-manual = annual-manual-gbp
#let cost-midsize = 2000000
#let cost-tsb = 330000000

// Theme
#let C_DARK = rgb("#2c3e50")
#let C_MUTED = rgb("#444b52")
#let C_FAINT = rgb("#7a8088")
#let C_RULE = rgb("#2c3e50")
#let C_BG = rgb("#f7f8fa")
#let C_CARD = rgb("#ffffff")
#let C_ALT = rgb("#eceef1")
#let C_BLUE = rgb("#2471a3")
#let C_GREEN = rgb("#1e8449")
#let C_ORANGE = rgb("#c47a20")
#let C_RED = rgb("#b03030")
#let C_BORDER = rgb("#d5d9df")

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
      [#institution],
      counter(page).display("1 / 1", both: true),
      [#city],
    )
  ],
)

#set text(font: "New Computer Modern", size: 12pt, fill: C_MUTED, lang: "en")
#set par(justify: false, leading: 0.78em)
#set list(indent: 0.6em, spacing: 0.6em)

#let dtable(..args) = table(
  stroke: 0.4pt + rgb("#cfd2d7"),
  inset: (x: 11pt, y: 9pt),
  fill: (_, row) => if row == 0 { C_DARK } else if calc.odd(row) { C_CARD } else { C_ALT },
  ..args,
)
#let th(body) = text(fill: white, weight: "bold")[#body]

#let money(v) = {
  if v >= 1000000 {
    "£" + str(calc.round(v / 1000000, digits: if v >= 10000000 { 0 } else { 1 })) + "M"
  } else if v >= 1000 {
    "£" + str(calc.round(v / 1000, digits: 1)) + "k"
  } else {
    "£" + str(calc.round(v, digits: 0))
  }
}

// Slide scaffold
#let slide(title, body, sub: none) = page[
  #block(width: 100%, height: 100%)[
    #grid(
      rows: (auto, 1fr),
      row-gutter: 0.55em,
      [
        #text(size: 26pt, weight: "bold", fill: C_DARK)[#title]
        #v(0.16em)
        #line(length: 24%, stroke: 1.4pt + C_RULE)
        #if sub != none {
          v(0.42em)
          text(size: 13pt, style: "italic", fill: C_FAINT)[#sub]
        }
      ],
      block(width: 100%, height: 100%, inset: (top: 0.4em))[
        #align(horizon)[#body]
      ],
    )
  ]
]

// Equal-height metric card (title / big value / caption)
#let card(title, value, caption, accent) = block(
  width: 100%,
  height: 3.7cm,
  inset: 14pt,
  radius: 5pt,
  fill: C_CARD,
  stroke: (top: 3pt + accent, rest: 0.5pt + C_BORDER),
)[
  #grid(
    rows: (auto, 1fr, auto),
    row-gutter: 6pt,
    text(size: 11.5pt, weight: "bold", fill: C_DARK)[#title],
    align(horizon + center)[#text(size: 27pt, weight: "bold", fill: accent)[#value]],
    text(size: 9.5pt, fill: C_FAINT)[#caption],
  )
]

// Vertical bar chart with a shared baseline.
// items: array of (label, value, display, color). Optional log scale.
#let vbars(items, max-val, height: 5cm, log: false, bar-w: 2cm) = {
  let bar-h(v) = {
    let f = if log { calc.log(calc.max(v, 1)) / calc.log(max-val) } else { v / max-val }
    calc.max(f * height, 0.32cm)
  }
  block(width: 100%)[
    #grid(
      columns: (1fr,) * items.len(),
      column-gutter: 14pt,
      ..items.map(it => align(bottom + center)[
        #text(size: 10.5pt, weight: "bold", fill: C_DARK)[#it.at(2)]
        #v(4pt)
        #box(width: bar-w, height: bar-h(it.at(1)), fill: it.at(3), radius: (top: 3pt))
      ])
    )
    #line(length: 100%, stroke: 0.6pt + C_FAINT)
    #v(5pt)
    #grid(
      columns: (1fr,) * items.len(),
      column-gutter: 14pt,
      ..items.map(it => align(center)[#text(size: 9.5pt, fill: C_MUTED)[#it.at(0)]])
    )
  ]
}

// Gantt-style timeline. tasks: array of (name, start, span, color), 1-indexed weeks.
#let gantt(tasks, weeks: 4) = block(width: 100%)[
  #grid(
    columns: (3.6cm, ..(1fr,) * weeks),
    align: left + horizon,
    column-gutter: 4pt,
    [],
    ..range(weeks).map(i => align(center)[#text(size: 9.5pt, fill: C_FAINT)[Week #(i + 1)]]),
  )
  #v(5pt)
  #stack(
    spacing: 7pt,
    ..tasks.map(t => {
      let (name, start, span, col) = t
      grid(
        columns: (3.6cm, ..(1fr,) * weeks),
        align: left + horizon,
        column-gutter: 4pt,
        text(size: 10.5pt, fill: C_DARK)[#name],
        ..range(weeks).map(i => {
          let w = i + 1
          if w >= start and w < start + span {
            box(width: 100%, height: 0.72cm, fill: col, radius: 2pt)
          } else {
            box(width: 100%, height: 0.72cm, fill: rgb("#eef0f3"), radius: 2pt)
          }
        }),
      )
    })
  )
]

// ── Title ───────────────────────────────────────────────────────────────────
#page(footer: none)[
  #align(center + horizon)[
    #text(size: 10pt, tracking: 1.2pt, fill: C_FAINT)[#upper[#institution]]
    #v(1.4em)
    #text(size: 34pt, weight: "bold", fill: C_DARK)[#title]
    #v(0.7em)
    #text(size: 15pt, style: "italic", fill: C_FAINT)[#subtitle]
    #v(1.2em)
    #line(length: 34%, stroke: 0.7pt + C_FAINT)
    #v(1.2em)
    #text(size: 11pt, fill: C_FAINT)[#city]
  ]
]

// ── Slide 1 — Summary cards ──────────────────────────────────────────────────
#slide(
  [Executive summary],
  sub: [Less manual checking, lower migration risk, faster sign-off.],
)[
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 1em,
    card(
      [Time per check],
      [≈ 0.03 s],
      [Automated, vs 80.5 min done by hand],
      C_GREEN,
    ),
    card(
      [Saved per year],
      [#calc.round(annual-hours-saved, digits: 0) h],
      [About #money(annual-saved-gbp) of engineer time],
      C_BLUE,
    ),
    card(
      [Setup cost],
      [#money(setup-cost-gbp)],
      [One-time, ~#setup-hours h to onboard],
      C_ORANGE,
    ),
  )
  #v(1.2em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1.6em,
    [
      *Why it matters* \
      The real value is avoiding expensive late surprises, not only saving time.
    ],
    [
      *The risk today* \
      Real incidents were found by customers after go-live, not by internal checks.
    ],
  )
]

// ── Slide 2 — Chart: manual effort grows, automated stays flat ───────────────
#slide(
  [Manual effort grows with data size],
  sub: [Automated checks stay under one second at every size tested.],
)[
  #vbars(
    (
      ([1,025 rows], manual-min.at(0), [62 min], C_BLUE),
      ([10,250 rows], manual-min.at(1), [80 min], C_BLUE),
      ([102,500 rows], manual-min.at(2), [265 min], C_ORANGE),
    ),
    manual-min.at(2),
    height: 5cm,
  )
  #v(0.9em)
  #align(center)[
    #block(fill: C_CARD, inset: (x: 14pt, y: 9pt), radius: 4pt, stroke: (left: 3pt + C_GREEN, rest: 0.5pt + C_BORDER))[
      #text(size: 11.5pt, fill: C_DARK)[
        Automated check: *0.03 – 0.56 seconds* across all three sizes — effectively a flat line near zero.
      ]
    ]
  ]
]

// ── Slide 3 — Chart: annual savings scenarios ────────────────────────────────
#slide(
  [Annual time saved],
  sub: [Low, base, and high activity levels for migration checks.],
)[
  #grid(
    columns: (1.1fr, 1fr),
    column-gutter: 1.8em,
    align: horizon,
    vbars(
      (
        ([Low activity], low-hours, [#low-hours h], C_BLUE),
        ([Base case], base-hours, [#base-hours h], C_GREEN),
        ([High activity], high-hours, [#high-hours h], C_ORANGE),
      ),
      high-hours,
      height: 4.6cm,
      bar-w: 1.7cm,
    ),
    dtable(
      columns: (auto, auto, auto),
      align: (left + horizon, center + horizon, center + horizon),
      table.header(th[Scenario], th[Hours / yr], th[Value / yr]),
      [Low], [#low-hours], [#money(low-hours * engineer-rate)],
      [Base], [#base-hours], [#money(base-hours * engineer-rate)],
      [High], [#high-hours], [#money(high-hours * engineer-rate)],
    ),
  )
]

// ── Slide 4 — Chart: real defects caught in the demo ─────────────────────────
#slide(
  [Defects found in validation],
  sub: [Sample run on ~1,025 rows with deliberately dirty data.],
)[
  #vbars(
    (
      ([Missing email], demo-null, [#demo-null], C_RED),
      ([Duplicate email], demo-dup, [#demo-dup], C_ORANGE),
      ([Invalid age], demo-range, [#demo-range], C_BLUE),
    ),
    demo-null,
    height: 4.6cm,
  )
  #v(0.9em)
  #align(center)[
    #text(size: 11.5pt, fill: C_DARK)[
      *#(demo-null + demo-dup + demo-range) bad records* would have passed a row-count check unnoticed.
      These are exactly the silent errors behind documented real incidents.
    ]
  ]
]

// ── Slide 5 — Chart: business impact (log scale) ─────────────────────────────
#slide(
  [Cost of a missed defect],
  sub: [Setup cost compared with manual checking and documented incidents (log scale).],
)[
  #vbars(
    (
      ([Our setup], cost-setup, [#money(cost-setup)], C_GREEN),
      ([Yearly manual\ checking], cost-annual-manual, [#money(cost-annual-manual)], C_BLUE),
      ([Mid-size incident\ (estimate)], cost-midsize, [#money(cost-midsize)], C_ORANGE),
      ([TSB bank case\ (actual)], cost-tsb, [#money(cost-tsb)], C_RED),
    ),
    cost-tsb,
    height: 5cm,
    log: true,
    bar-w: 2.1cm,
  )
  #v(0.8em)
  #align(center)[
    #text(size: 11pt, fill: C_FAINT)[
      Setup is a rounding error next to a single real incident.
      The TSB migration cost ~£330M; our control costs #money(cost-setup) once.
    ]
  ]
]

// ── Slide 6 — Chart: rollout timeline (Gantt) ────────────────────────────────
#slide(
  [Rollout plan],
  sub: [Four weeks to adopt alongside the current process.],
)[
  #gantt(
    (
      ([Configure in staging], 1, 1, C_BLUE),
      ([Run in parallel], 2, 2, C_GREEN),
      ([Agree sign-off rules], 3, 1, C_ORANGE),
      ([Go-live as gate], 4, 1, C_DARK),
    ),
    weeks: 4,
  )
  #v(1.0em)
  #dtable(
    columns: (auto, 1fr, auto),
    align: (left + horizon, left + horizon, left + horizon),
    table.header(th[Phase], th[Activity], th[Owner]),
    [Weeks 1], [Configure checks and capture a baseline], [Data engineer],
    [Weeks 2–3], [Run beside the manual process, compare results], [QA + PM],
    [Week 4], [Make it a required pre-release gate], [Release manager],
  )
]

// ── Slide 7 — Decision ───────────────────────────────────────────────────────
#slide(
  [Recommendation],
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1.4em,
    [
      #text(size: 13pt, weight: "bold", fill: C_DARK)[Approve now]
      #v(0.35em)
      - #setup-hours h budget for implementation
      - Pilot on the next migration cycle
      - Add a pass / fail gate before release
    ],
    [
      #text(size: 13pt, weight: "bold", fill: C_DARK)[Expected outcome]
      #v(0.35em)
      - Lower chance of post-go-live data incidents
      - Faster, evidence-based release confidence
      - Clear go / no-go signal for stakeholders
    ],
  )
  #v(1.2em)
  #block(fill: C_CARD, inset: 13pt, radius: 5pt, stroke: (left: 3pt + C_GREEN, rest: 0.5pt + C_BORDER))[
    #text(size: 12.5pt, fill: C_DARK)[
      *Bottom line:* a #money(setup-cost-gbp) one-time control that saves ~#money(annual-saved-gbp) a year
      and guards against incidents measured in millions. It improves predictability with
      almost no added process overhead.
    ]
  ]
]

// ── Slide 8 — Sources ────────────────────────────────────────────────────────
#slide(
  [References],
)[
  - `examples/_bench_timing.py` — measured manual vs automated timings
  - `examples/validate_dirty_database.py` — real defect categories and counts
  - `src/` — the validation engine used in the benchmark
  - Public migration incident reports — TSB, insurance, MySQL → PostgreSQL, OpenAI, TUI
]
