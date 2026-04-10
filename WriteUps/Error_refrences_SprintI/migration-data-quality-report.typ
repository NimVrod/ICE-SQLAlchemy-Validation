// ── Variables ───────────────────────────────────────────────
#let title = [When Migration Changes Your Data]
#let subtitle = [Six Incidents, Ten Failure Modes, and What They Share]
#let author = [Engineering Research Report]
#let institution = [Data Quality in Database Migrations]
#let city = [April 2026]

// ── Page Setup ──────────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 2cm),

  header: context {
    let selector = heading.where(level: 1)
    let current-page = here().page()
    let next-h = query(selector.after(here()))
    let on-page = next-h.filter(h => h.location().page() == current-page)
    let prev-h = query(selector.before(here()))
    let target = if on-page.len() > 0 { on-page.first() } else if prev-h.len() > 0 { prev-h.last() } else { none }
    if target != none {
      set text(size: 9pt)
      grid(
        columns: (auto, 1fr, auto),
        align: (left, center, right),
        smallcaps[#institution],
        [],
        {
          let levels = counter(heading).at(target.location())
          if target.numbering != none {
            numbering(target.numbering, ..levels)
            h(0.4em)
          }
          smallcaps(target.body)
        },
      )
      line(length: 100%, stroke: 0.5pt)
    }
  },

  footer: context [
    #line(length: 100%, stroke: 0.5pt)
    #v(0.2em)
    #grid(
      columns: (1fr, auto, 1fr),
      align: (left, center, right),
      smallcaps[Data Quality in Migrations], smallcaps[#counter(page).display("1 / 1", both: true)], smallcaps[#city],
    )
  ],
)

// ── Typography ───────────────────────────────────────────────
#set text(font: "New Computer Modern", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.68em, first-line-indent: 1.2em)
#set heading(numbering: "1.1.")

#show heading.where(level: 1): it => {
  v(1.4em)
  block(it)
  v(0.5em)
}

#show heading.where(level: 2): it => {
  v(0.9em)
  block(it)
  v(0.3em)
}

// ── Inline superscript citation ──────────────────────────────

// ── Severity badge ───────────────────────────────────────────
#let badge(label, color) = box(
  fill: color,
  inset: (x: 5pt, y: 3pt),
  radius: 2pt,
)[#text(size: 8pt, fill: white, weight: "bold")[#label]]

#let critical = badge("CRITICAL", rgb("#b03030"))
#let high = badge("HIGH", rgb("#c47a20"))
#let medium = badge("MEDIUM", rgb("#2471a3"))
#let low = badge("LOW", rgb("#1e8449"))

// ── Incident block ───────────────────────────────────────────
#let incident(sev: [], source: [], title: [], body) = {
  block(
    width: 100%,
    inset: (x: 13pt, y: 11pt),
    radius: 3pt,
    stroke: (left: 3pt + rgb("#888888"), rest: 0.4pt + rgb("#dddddd")),
    fill: white,
    below: 1em,
  )[
    #grid(
      columns: (1fr, auto),
      align: (left + top, right + top),
      gutter: 6pt,
      text(weight: "bold", size: 11pt)[#title], sev,
    )
    #if source != [] [
      #v(0.15em)
      #text(size: 8.5pt, fill: rgb("#666666"), style: "italic")[#source]
    ]
    #v(0.5em)
    #set par(first-line-indent: 0em)
    #body
  ]
}

// ── Issue card ───────────────────────────────────────────────
#let issue(rank, title, sev, body) = block(
  width: 100%,
  inset: (x: 12pt, y: 10pt),
  radius: 3pt,
  stroke: 0.4pt + rgb("#cccccc"),
  fill: rgb("#fafafa"),
  below: 0.8em,
  breakable: false,
)[
  #grid(
    columns: (auto, 1fr, auto),
    align: (center + top, left + top, right + top),
    gutter: 9pt,
    text(size: 20pt, weight: "bold", fill: rgb("#2c3e50"))[#rank], text(weight: "bold")[#title], sev,
  )
  #v(0.3em)
  #pad(left: 29pt)[
    #set par(first-line-indent: 0em)
    #body
  ]
]

// ============================================================
// TITLE PAGE
// ============================================================
#page(numbering: none, header: none, footer: none)[
  #align(center)[
    #v(2cm)
    #text(size: 12pt, fill: rgb("#666666"), tracking: 1pt)[#upper[#institution]]
    #v(4cm)
    #text(weight: "bold", size: 24pt)[#title]
    #v(0.7cm)
    #text(size: 13pt, style: "italic", fill: rgb("#444444"))[#subtitle]
    #v(0.8cm)
    #line(length: 45%, stroke: 0.6pt)
    #v(3fr)
    #text(size: 10.5pt, fill: rgb("#555555"))[#author]
    #v(0.35cm)
    #text(size: 10.5pt, fill: rgb("#777777"))[#datetime.today().display("[day] [month repr:long] [year]")]
  ]
]

// ============================================================
// TABLE OF CONTENTS
// ============================================================
#page(header: none)[
  #outline(title: "Table of Contents", indent: 1.5em, depth: 2)
]

// ============================================================
// 1. INTRODUCTION
// ============================================================
= Introduction

There is a particular kind of database migration failure that does not announce itself. No error is thrown, no alert fires, the row count matches, and the migration tool reports success. The problem surfaces days or weeks later when a customer notices that their 1940s insurance policy has an issue date of 2040, or when a financial analyst sees transactions appearing to occur seconds before they were created, or --- in the worst case on record --- when a bank's customers log in and find themselves looking at someone else's money.

This report examines six documented incidents where a database migration did not lose data but changed it: values were transformed, timestamps shifted, categories misclassified, or records reassigned to the wrong owners. These cases are drawn from public postmortems, regulatory investigations, and engineering blog posts. Together they illustrate a failure mode that is systematically underappreciated in migration planning: not the crash that stops the system, but the corruption that keeps it running while feeding wrong answers downstream.

The incidents are presented in roughly ascending order of severity. Following the case studies, the report identifies the ten most common data quality failure patterns, with a severity classification and practical observations for each.

// ============================================================
// 2. THE SIX INCIDENTS
// ============================================================
= The Six Incidents

== Netflix Billing: Oracle NUMBER Has No MySQL Equivalent

#incident(
  sev: medium,
  source: [Netflix Technology Blog, "Netflix Billing Migration to AWS — Part III," 19 April 2017.@netflix2017billing],
  title: [Type System Mismatch — Silent Numeric Precision Risk],
)[
  Oracle's `NUMBER` datatype is, by design, flexible. It holds integers, decimals, and values up to 38 significant digits without the developer having to specify which. MySQL is not like that. It requires the engineer to declare upfront whether a column is an `INT`, a `BIGINT`, a `DECIMAL(10,2)`, or something else, and it enforces those choices strictly.

  When Netflix migrated its billing system from Oracle to MySQL on AWS, the team found that this flexibility had been used inconsistently across the legacy schema. Some `NUMBER` columns held integers. Others held decimals. And some contained values that exceeded 18 digits --- the ceiling for MySQL's `BIGINT`. Without a column-by-column audit, migrating these fields would silently truncate large values, round decimals, or store floating-point figures in integer columns. Billing data --- amounts, tax codes, account balances --- would have come out numerically wrong, with no error raised by either database.

  Netflix caught this during planning and completed the migration successfully.@netflix2017billing The case is included here not as a failure but as a clear illustration of a mechanism. Type system differences between database engines can change data at rest without anyone noticing, because the values that emerge look like valid numbers in the target system. The problem is structural: the source schema contained ambiguity that was only forced into the open by the stricter type requirements of MySQL. Had the team not audited at field level, the numbers would have changed and the migration would still have reported success.
]

#v(0.3em)

== Insurance Provider: 127,000 Policies Migrated as Issued in 2040

#incident(
  sev: medium,
  source: [Vovance, "Why Most Data Migration Projects Fail," Medium, December 2025.@vovance2025migration],
  title: [Undocumented Legacy Date Bug — Historical Data Transformed],
)[
  Date format conversion is among the most routine tasks in a migration. The legacy system stored dates as `MM/DD/YYYY`. The new system required `YYYY-MM-DD`. The transformation logic was straightforward, the test suite passed cleanly, and the migration went ahead.

  What the team did not know was that their legacy system had an undocumented bug: any date before 1950 had been stored using a two-digit year.@vovance2025migration The digit `47` meant 1947. The migration script, applying a standard format conversion, had no way to know this. It treated `47` as `2047`. The same for `38`, `43`, `49`. All 127,000 policies issued in the 1940s were migrated as having been issued in the 2040s. None of these records failed validation. They were present, non-null, in a correctly formatted date. Three weeks after go-live, someone noticed.

  The failure reveals a structural weakness in how migration testing is typically scoped. Teams build test suites against recent, representative data. This is sensible for confirming that transformation logic works in the common case. It does not work for historical edge cases that only exist deep in the archive, where legacy software quirks, deprecated encodings, and undocumented patches have accumulated over decades. The 1940s policies looked like any other record until a date arithmetic function returned an answer eight decades into the future.
]

#v(0.3em)

== MySQL to PostgreSQL: 87% of Timestamps Shifted

#incident(
  sev: high,
  source: [Dev Engineer, "The PostgreSQL Migration That Corrupted Every Timestamp," Medium, June 2025.@deveng2025timestamp],
  title: [Timezone Semantics Differ Between Engines — Dates Silently Rewritten],
)[
  MySQL and PostgreSQL handle timestamp storage differently in a way that is easy to overlook. In MySQL, a `TIMESTAMP` column automatically converts values to UTC on write and back to the server's local time on read. In PostgreSQL, `TIMESTAMP WITHOUT TIME ZONE` stores exactly what it receives --- no conversion, no adjustment. If the application inserts a local time, that local time is what gets stored, and if the server running PostgreSQL sits in a different timezone from the MySQL server, every timestamp in the migrated dataset is off by that difference.

  A team migrating from MySQL to PostgreSQL 13 used `TIMESTAMP WITHOUT TIME ZONE` without explicitly normalising timezone during the transfer. The migration completed without errors. Row counts matched. The data looked intact.@deveng2025timestamp

  Users found the problem. A customer reported that a report was showing yesterday's data as tomorrow's. Financial transaction records appeared to have been created before the events that triggered them. A post-migration comparison script, written after the fact, found that 87% of records contained timestamps that differed from their source values by more than one hour.@deveng2025timestamp

  The corrupted data passed every structural check a migration tool normally runs. It only failed the check that mattered: does this value mean the same thing it meant before?
]

#v(0.3em)

== OpenAI: Redis Cache Resequenced, Users Saw Others' Data

#incident(
  sev: high,
  source: [Dan Luu, postmortems collection, GitHub.@luu2024postmortems OpenAI, "March 20 ChatGPT outage: Here's what happened," March 2023.@openai2023outage],
  title: [Cache Layer State Corruption — Cross-User Data Exposure],
)[
  In March 2023, OpenAI disclosed that a bug in a Redis client library caused cached responses to be returned to the wrong users. The mechanism was a connection pool issue: during a Redis cluster configuration change, request and response queues fell out of sequence. Some responses were delivered to sessions they did not belong to.@openai2023outage

  The data exposed included chat history titles from other users' active sessions and, in some cases, payment information: the last four digits of card numbers, expiry dates, names, email addresses, and billing addresses. Around 1.2% of ChatGPT Plus subscribers were affected during a roughly nine-hour window before the issue was identified.

  What makes this relevant to migration data quality is the mechanism. No database record was altered. The corruption was a sequencing failure in the caching layer during a configuration change --- which is a form of state migration. The system continued operating, returning plausible-looking responses, while routing some of them to the wrong users. From the affected user's perspective the effect was identical to their data having been reassigned to someone else's account.

  The incident reinforces a point that goes beyond schema migrations: any operation that moves or reconfigures stateful infrastructure carries the same category of risk. Sequence, ordering, and ownership metadata must be treated as data, not as implementation detail.
]

#v(0.3em)

== TSB Bank: 1.3 Billion Records Corrupted, Customers See Each Other's Accounts

#incident(
  sev: critical,
  source: [Newton, "What Broke the Bank," Increment, 2019.@newton2019tsb Slaughter and May independent review, 2019.@slaughter2019tsb FCA/PRA Final Notice, December 2022.@fca2022tsb],
  title: [Full Production Migration Failure — Records Transformed and Misassigned],
)[
  On the evening of Sunday 22 April 2018, TSB Bank began migrating 5.4 million customer records from Lloyds Banking Group's legacy platform to Banco Sabadell's newly built Proteo4UK system. The migration window closed and, for a short period, everything appeared to have gone smoothly.

  Twenty minutes after the bank reopened customer access, the first reports came in.@newton2019tsb

  Customers logging into online banking found accounts that were not theirs. A user would authenticate correctly and be presented with a stranger's balance, transaction history, and personal details. Others found their own account but with figures that bore no relationship to what had been there the week before. Small transactions appeared on statements as having cost thousands of pounds.

  By 9 p.m. TSB had contacted the UK's Financial Conduct Authority. By midnight, both the FCA and the Prudential Regulation Authority were on a call with the bank's executives. The answer to their questions took months to establish fully: 1.3 billion customer records had been corrupted.@newton2019tsb

  The independent review by Slaughter and May identified several failures that compounded each other.@slaughter2019tsb The team building the new platform did not have direct access to the source system, so they were working from documentation rather than live data. Full-volume testing was never done: the test environment did not match production scale, and only read-only transactions were tested, not writes or updates. Open defect counts at the end of user acceptance testing were rising, not falling, and this was not treated as a reason to delay go-live.

  TSB did not reach normal operations until December 2018, eight months later. The total cost reached approximately £330 million. The bank lost 80,000 customers and received 225,492 formal complaints. Regulators fined it £48.65 million in 2022.@fca2022tsb The former CIO was personally fined £81,620 for governance failures.

  TSB is the most expensively documented example of a migration that did not crash a system but changed what the system believed to be true about its customers.
]

#v(0.3em)

== TUI Aviation: Gender Title Misclassified as Age, Aircraft Mass Understated by 1,244 kg

#incident(
  sev: critical,
  source: [Dan Luu, postmortems collection, GitHub.@luu2024postmortems UK Air Accidents Investigation Branch report.@aaib2019tui],
  title: [Category Field Misread After System Upgrade — Safety-Critical Weight Error],
)[
  This incident is different from the others in this report. The data that was changed was not financial, not personal, and not a business record. It was the calculated weight of an aircraft about to take off.

  Following an upgrade to TUI's reservation and load-management system, a fault emerged in how passenger titles were classified. Female passengers who had checked in under the title "Miss" were being categorised as children by the upgraded system. A child's standard mass in the load calculation is 35 kg. The standard mass for an adult female is 69 kg. The system was allocating the wrong value to every affected passenger.@aaib2019tui

  On the specific departure in question, 38 female passengers had checked in as "Miss." Each was assigned a mass 34 kg below the correct figure. The cumulative error was 1,244 kg. The load sheet handed to the flight crew showed a takeoff mass that was 1,244 kg lighter than the aircraft actually was. The crew reported no anomaly. The error was identified in a post-flight audit of the load documentation.

  At the data level this is the same failure mode as several other cases in this report. The field "Miss" was present, non-null, a valid string. The system read it and made a decision based on it --- the wrong decision, because the upgrade had changed the mapping between that string and the category it represented. The downstream consequence was a wrong number in a context where wrong numbers are measured in kilograms and runway length rather than currency.

  The incident is worth including precisely because it is not a financial or privacy case. It shows that the risk of silent category remapping during migration is not bounded to any particular domain. It applies wherever a field's value drives a calculation, and the severity of getting it wrong tracks the severity of the downstream use, not the magnitude of the data change itself.
]

// ============================================================
// 3. TOP 10 DATA QUALITY FAILURE MODES
// ============================================================
= Top 10 Data Quality Failure Modes

The incidents above, alongside related patterns in the public postmortem literature, converge on a consistent set of underlying failure mechanisms. The following list ranks the ten most prevalent and dangerous, weighted by frequency of occurrence and how often they remain undetected until after go-live.

#v(0.4em)

#let issue-count = counter("issue")
#issue-count.update(1)

#issue(context issue-count.display(), [Timestamp and Timezone Semantic Mismatch], critical)[
  The MySQL-to-PostgreSQL incident is the sharpest example, but this failure appears wherever two systems handle time differently. One stores UTC and converts to local time on read; the other stores local time as-is. The migration moves bytes correctly while meaning changes. Financial records, audit logs, compliance timestamps, and event sequences are all affected. Because the values remain syntactically valid dates, this corruption passes every structural check and only surfaces in a direct comparison of values between source and target.
]
#issue-count.step()

#issue(context issue-count.display(), [Cross-User Record Association], critical)[
  Seen in both TSB and OpenAI: records become linked to the wrong user or session. In TSB's case the consequence was customers viewing each other's bank accounts. In OpenAI's case it was billing details and conversation history. This is the most severe outcome because it combines data corruption with a privacy breach and, in regulated industries, an automatic regulatory violation. It typically originates from a sequencing or ordering error during migration that disrupts the mapping between identity keys and data rows.
]
#issue-count.step()
#issue(context issue-count.display(), [Enumeration and Category Field Remapping Errors], critical)[
  The TUI incident is the extreme case, but category misclassification is common wherever ENUM values, lookup table IDs, or status codes differ between source and target schemas. The value in the migrated field may look entirely valid in the new system while carrying a different meaning. Downstream logic that branches on those values produces wrong outputs without raising any error. This failure is particularly difficult to detect because the field passes every validation check; only the calculation that uses it reveals the problem.
]
#issue-count.step()
#issue(context issue-count.display(), [Numeric Type Precision Loss Across Engines], high)[
  Source databases frequently use permissive numeric types with no direct equivalent in the target. Oracle `NUMBER`, SQLite's typeless storage, and application-level `Decimal` objects are all at risk when migrating to engines with strict type enforcement. Values are silently truncated, rounded, or wrapped without error. Netflix caught this in planning; the cases where it goes unnoticed result in billing figures, measurement values, and financial calculations that are systematically wrong by amounts that may not be immediately obvious.
]
#issue-count.step()
#issue(context issue-count.display(), [Sequence and Auto-Increment State Not Replicated], high)[
  Documented explicitly in RevenueCat's Aurora PostgreSQL upgrade: logical replication copies table data but not sequence state. After cutover, new inserts generate primary key values that already exist in the table, causing write failures or, in the worst case, silent record collisions. PostgreSQL's documentation notes this limitation, but it is consistently missed in migration planning because it only manifests at the first write after cutover --- which is rarely part of a pre-go-live test.
]
#issue-count.step()
#issue(context issue-count.display(), [Historical Data Harbouring Undocumented Legacy Behaviour], medium)[
  The 2040 insurance policies are a textbook case. Legacy systems accumulate bugs, format changes, and undocumented workarounds over decades. Data written under those conditions looks entirely normal to the application that wrote it, but a migration script applying a standard transformation will interpret it incorrectly. Testing against recent records will not expose the problem. Sampling from the oldest 10--20% of the archive, particularly data created during system transitions or before major software upgrades, is the only reliable way to surface these anomalies before cutover.
]
#issue-count.step()
#issue(context issue-count.display(), [Character Encoding Corruption on Engine or OS Change], medium)[
  Moving between `latin1` and `UTF-8`, or between database servers with different default locale settings, corrupts characters outside ASCII. Customer names, addresses, and free-text fields containing accented or non-Latin characters become question marks, replacement characters, or garbled byte sequences. Affected rows remain present and non-null, so row count validation passes. In customer databases serving multiple languages or regions, this can affect a significant proportion of name and address data.
]
#issue-count.step()
#issue(context issue-count.display(), [Silent String Truncation on Insert], medium)[
  When a target column is defined with a shorter maximum length than the corresponding source column, the behaviour on overflow depends on the database configuration. In permissive mode --- the default in several MySQL configurations --- values are silently truncated rather than rejected. A `VARCHAR(100)` receiving a 120-character value stores 100 characters and discards the rest. Reference codes, deep-linked URLs, and longer free-text entries are most at risk. Because the truncated records are otherwise valid, this failure only surfaces when the cut-off portion of a value is actually used.
]
#issue-count.step()
#issue(
  context issue-count.display(),
  [Referential Integrity Broken by Migration Order or Disabled Constraints],
  medium,
)[
  Large bulk migrations frequently disable foreign key checks to improve insert performance, with the intention of re-enabling them after the data is loaded. When this step is missed, or when tables are migrated in an order that creates child records before their parents exist, the target database contains structurally invalid data. Individual rows look correct in isolation. Queries that join across the broken relationship silently return nulls or incorrect results. The failure is invisible until a specific query that traverses the relationship is executed.
]
#issue-count.step()
#issue(context issue-count.display(), [Duplicate Records from Non-Idempotent Re-runs], low)[
  When a migration job fails partway through and is re-run without idempotency controls, records that were already transferred are inserted again. Row counts in the target exceed the source by an amount that may not be immediately apparent in aggregate checks. The duplicates propagate into analytics as inflated event counts, double-counted revenue, and incorrect user metrics. Because each individual record is valid, they pass field-level validation. Catching them requires a record-level diff against the source, not a count comparison.
]

// ============================================================
// 4. WHAT THE INCIDENTS SHARE
// ============================================================
= What the Incidents Share

Looking across the six cases, a few structural patterns appear consistently regardless of the specific failure mechanism.

*Validation confirmed movement, not correctness.* In every incident, the migration was declared complete based on evidence that data had transferred: row counts, absence of error logs, connectivity checks. None of these verify that values in the target carry the same meaning they carried in the source. The MySQL timestamp migration completed without errors while 87% of dates were wrong. TSB's migration tools did not flag the corruption affecting 1.3 billion records.

*Testing was scoped to the common case.* The insurance provider's test suite validated date transformation correctly for recent policies. It never reached the 1940s records where the legacy bug lived. TUI's system upgrade was presumably tested against typical passenger categories; the "Miss" classification edge case either was not tested or was not tested against the downstream weight calculation it fed into.

*The errors were self-concealing.* Corrupted timestamps look like valid timestamps. Misdated policy records look like valid dates. A customer associated with the wrong account looks, from the database's perspective, like a normal account-customer relationship. The corruption hides inside the normal appearance of the data. This is what makes it more dangerous than a clear failure: the system signals health while the data is wrong.

*Detection came from users, not from monitoring.* In the MySQL timestamp case, a customer reported the anomaly. TSB's customers reported account access problems within 20 minutes of go-live. OpenAI received user reports of cross-session data exposure. In none of these cases did internal monitoring identify the corruption before an affected user encountered it directly.

// ============================================================
// 5. REFERENCES
// ============================================================
#bibliography("references.bib", style: "ieee")
