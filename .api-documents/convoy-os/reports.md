# Reports — API Guide

The Reports menu (rail icon `insert_chart`): the **Shuttle Report** for clients — one Corporate Shuttle route and period at
a time: utilisation, riders, on-time per stop against the timetable, and stop activity. Needs the `vehicles`, `finance` or
`finview` permission (read only; a Convoy Admin sees it too). Conventions are in [README.md](../README.md); paths start with `/api/v1`.

Numbers come from what was recorded at each stop of each run (the driver app / telematics stop events), with Correct Record
values first. Runs with nothing recorded are left out. **Export CSV** and **Export PDF** are made by the front end from the data.

## Contents

1. [Filters](#1-filters)
2. [The report](#2-the-report)
3. [Month grids](#3-month-grids)
4. [Stop record and Amend Record](#4-stop-record-and-amend-record)

---

## 1. Filters

`GET /reports/shuttle/options` →

```json
{ "clients": [ { "id": 1, "name": "Google Asia Pacific", "on_time_allowance": 3,
                 "routes": [ { "id": 12, "title": "MBC Campus Shuttle", "ref": "T-000012" } ] } ],
  "periods": [ { "value": "m|2026-10", "label": "October 2026" }, { "value": "q|2026-4", "label": "Q4 2026" }, { "value": "y|2026", "label": "2026" } ] }
```

Clients with Corporate Shuttle routes; periods = the last 12 months, 5 quarters, 2 years. Empty `clients`: the FE shows its
empty state (FE copy, not an API message: "No shuttle routes yet. Add a Corporate Shuttle trip with a timetable in the Scheduler").

## 2. The report

`GET /reports/shuttle?trip_id=12&period=m|2026-10` (no period = last month) →

```json
{ "trip": { "id": 12, "title": "MBC Campus Shuttle", "client": "Google Asia Pacific", "days_text": "Mon to Fri", "plate": "PC7475L" },
  "period": { "from": "2026-10-01", "to": "2026-10-31", "label": "October 2026",
              "last_year": { "from": "2025-10-01", "to": "2025-10-31", "label": "October 2025" } },
  "on_time_allowance": 3, "early_minutes": 5, "has_data": true,
  "kpis": { "utilisation": 54.1, "utilisation_change": -0.1, "riders": 2437, "riders_change": 416, "avg_per_day": 110.8,
            "utilisation_change_ly": 3.2, "riders_change_ly": 512, "on_time": 81.3, "on_time_change": -1.6, "on_time_change_ly": 0.4,
            "late": 41, "left_early": 6, "service_days": 22, "runs": 196, "runs_a_day": 9, "seats": 23 },
  "timings": [ { "dep": "07:30", "direction": 1, "direction_label": "To MBC Tower 1", "utilisation": 71.2, "riders": 344, "avg": 15.6, "max": 21, "tag": "Busiest" } ],
  "stop_activity": [ { "direction": 1, "label": "To MBC Tower 1", "stops": [ { "name": "Labrador MRT", "boarded": 812, "pct": 60.2 } ] } ],
  "trend": [ { "month": "2026-10", "riders": 2437, "utilisation": 54.1, "on_time": 81.3, "in_period": true } ] }
```

- Utilisation = riders ÷ seats offered (each run's bus seats). Percentages to one decimal; `*_change` = against the period
  before of the same length (points for percentages, riders for riders); `null` when either has no data. `*_change_ly` = against
  the same period last year (`period.last_year`); `null` for a year period or with no data a year before (hide the second line).
- Chips: Days `trip.days_text`, Bus `trip.plate` (the bus of the latest run; `null` when none) + `kpis.seats` seats.
  Service Days sub-line: "`days_text` | `runs_a_day` runs a day"; On-Time sub-line: "`late` late | `left_early` left early" (stops).
- On time = a stop reached from `early_minutes` (5) before the timetable to `on_time_allowance` minutes after it.
  Early (more than 5 minutes before) still counts on time; **Left Early** (left a pick-up before the timetable) and Late count
  against; skipped stops are left out. Change the allowance with `PATCH /clients/:id { client: { on_time_allowance } }` (0–15, −1 / +1); any company user may (no extra permission, as in the prototype), a Convoy Admin gets `403`.
- `timings`: Utilisation by Shuttle Timing, busiest first (`tag` Busiest / Quietest). `stop_activity`: boardings per pick-up per
  direction (routes with 3 or more stops; the destination is left out). `trend`: the 12 months to the period's end (`in_period` = shaded).
- A `period` that is not `m|2026-10`, `q|2026-4` or `y|2026` → `422` "Period must look like m|2026-10, q|2026-4 or y|2026".

## 3. Month grids

`GET /reports/shuttle/grid?trip_id=12&month=2026-10` → Riders per Timing per Day and the On Time Report of one month:

```json
{ "month": "2026-10", "dates": ["2026-10-01", "…"],
  "rows": [ { "timing": { "key": "1-0", "direction": 1, "position": 0, "dep": "07:30" },
              "cells": [ { "date": "2026-10-01", "occurrence_id": 5512, "riders": 16, "amended": false }, null ],
              "total": 344, "avg": 15.6, "max": 21, "util": 71.2,
              "stops": [ { "name": "Labrador MRT", "planned": "07:30" } ],
              "on_time": [ { "date": "2026-10-01", "occurrence_id": 5512,
                             "stops": [ { "status": "ok", "arrived": "07:29", "amended": false } ] } ] } ],
  "on_time": { "ok": 640, "early": 21, "late": 118, "edep": 3, "skip": 9, "pct": 84.5 },
  "worst_timing": "17:30", "worst_day": "2026-10-14" }
```

- A `month` that is not `YYYY-MM` → `422` "Month must look like 2026-10".
- `cells` / `on_time` follow `dates` (a `null` = the timing did not run that day). Stop `status`: `ok` (On Time), `early`
  (Early, pale green), `late`, `edep` (Left Early), `skip` (Skipped); `amended` = changed by Correct Record (badge).

## 4. Stop record and Amend Record

Clicking a riders count or a stop time opens that run's record: `GET /trip_history/:occurrence_id`. **Amend Record** is
Correct Record: `POST /trip_history/:occurrence_id/correction` ([trips § 5](trips.md#correct-record--post-trip_historyidcorrection));
the report uses the corrected values.
