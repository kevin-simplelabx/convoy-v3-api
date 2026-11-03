# Reports — API Guide

The Reports menu (rail icon `insert_chart`): the **Shuttle Report** for clients — one Corporate Shuttle route and period at
a time: utilisation, riders, on-time per stop against the timetable, and stop activity. Needs the `vehicles`, `finance` or
`finview` permission (read only). Conventions are in [README.md](README.md); paths start with `/api/v1`.

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

Clients with Corporate Shuttle routes; periods = the last 12 months, 5 quarters, 2 years. Empty `clients` → "No shuttle routes
yet. Add a Corporate Shuttle trip with a timetable in the Scheduler and its report builds itself".

## 2. The report

`GET /reports/shuttle?trip_id=12&period=m|2026-10` (no period = last month) →

```json
{ "trip": { "id": 12, "title": "MBC Campus Shuttle", "client": "Google Asia Pacific" },
  "period": { "from": "2026-10-01", "to": "2026-10-31", "label": "October 2026" },
  "on_time_allowance": 3, "early_minutes": 5, "has_data": true,
  "kpis": { "utilisation": 54.1, "utilisation_change": -0.1, "riders": 2437, "riders_change": 416, "avg_per_day": 110.8,
            "on_time": 81.3, "on_time_change": -1.6, "service_days": 22, "runs": 196, "seats": 23 },
  "timings": [ { "dep": "07:30", "direction": 1, "direction_label": "To MBC Tower 1", "utilisation": 71.2, "riders": 344, "avg": 15.6, "max": 21, "tag": "Busiest" } ],
  "stop_activity": [ { "direction": 1, "label": "To MBC Tower 1", "stops": [ { "name": "Labrador MRT", "boarded": 812, "pct": 60.2 } ] } ],
  "trend": [ { "month": "2026-10", "riders": 2437, "utilisation": 54.1, "on_time": 81.3, "in_period": true } ] }
```

- Utilisation = riders ÷ seats offered (each run's bus seats). Percentages to one decimal; `*_change` = against the period
  before of the same length (points for percentages, riders for riders); `null` when either has no data.
- On time = a stop reached from `early_minutes` (5) before the timetable to `on_time_allowance` minutes after it.
  Early (more than 5 minutes before) still counts on time; **Left Early** (left a pick-up before the timetable) and Late count
  against; skipped stops are left out. Change the allowance with `PATCH /clients/:id { client: { on_time_allowance } }` (0–15, −1 / +1).
- `timings`: Utilisation by Shuttle Timing, busiest first (`tag` Busiest / Quietest). `stop_activity`: boardings per pick-up per
  direction (routes with 3 or more stops; the destination is left out). `trend`: the 12 months to the period's end (`in_period` = shaded).

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

- `cells` / `on_time` follow `dates` (a `null` = the timing did not run that day). Stop `status`: `ok` (On Time), `early`
  (Early, pale green), `late`, `edep` (Left Early), `skip` (Skipped); `amended` = changed by Correct Record (badge).

## 4. Stop record and Amend Record

Clicking a riders count or a stop time opens that run's record: `GET /trip_history/:occurrence_id`. **Amend Record** is
Correct Record: `POST /trip_history/:occurrence_id/correction` ([trips § 5](trips.md#correct-record--post-trip_historyidcorrection));
the report uses the corrected values.
