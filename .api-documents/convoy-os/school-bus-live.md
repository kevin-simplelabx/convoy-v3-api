# School Bus › Dashboard and Live Ops — API Guide

This guide covers the two monitoring pages of one school in Convoy OS: the **School Dashboard** (Operations and Finance
tabs) and **Live Ops** (the school's buses for a session of a day, and one run in detail). Conventions are in
[README.md](../README.md). Paths start with `/api/v1`.

**Permissions**

| What | Who |
| --- | --- |
| Dashboard › Operations, Live Ops | Every company user, for the schools they may open |
| Dashboard › Finance | `finance` or `finview` (`data.finance_allowed`). Without them, hide the tabs: the Finance call answers 403 |

**Times.** Times are ISO 8601 in the company's time zone. Format them with Company Settings (24 or 12-hour). Session
times from Bus Sessions are `"HH:MM"`. Money is decimal strings, for example `"4200.0"`.

**Live data.** Live Ops reads real runs: their GPS and stops (written by the driver app and trackers, as on Live Map) and
each child's attendance (written by the driver or bus attendant app). Parents mark **Bus Not Required** in the Convoy
App. Until those apps send data, `bin/rails live_map:simulate` writes sample data (see [live-map.md](live-map.md)).

## Contents

1. [Live Ops: the session](#1-live-ops-the-session)
2. [Live Ops: one run](#2-live-ops-one-run)
3. [Dashboard › Operations](#3-dashboard--operations)
4. [Dashboard › Finance](#4-dashboard--finance)
5. [Not built yet](#5-not-built-yet)

---

## 1. Live Ops: the session

`GET /schools/:school_id/live?date=&session=&filter=`

| Param | Meaning |
| --- | --- |
| `date` | `YYYY-MM-DD`. Default today |
| `session` | `am` (Morning Pick-up), `pm` (Afternoon Drop-off) or `asa` (CCA Drop-off). Default: the session running now, else the next one to start, else the last of the day |
| `filter` | `all` (default), `road` (on the road), `late` (on the road and late, or GPS lost), `done` (arrived). Only `rows` is filtered |

Poll every 15 to 30 seconds while the page is open. A `date` that is not `YYYY-MM-DD` → `422` "Date must look like 2026-11-03".

**`data`:**

- `school`: `{ id, name, lat, lng }`. This is the school pin on the map.
- `date`, `now`.
- `sessions`: `[{ value, label, starts_at, ends_at, runs }]`. These are the sessions with runs that day, for the session
  picker. When the chosen session has not started (`kpis.buses.not_started == kpis.buses.total` and `now < starts_at`),
  show a "has not started" note with the session's `starts_at` (FE copy).
- `session`: the session shown.
- `kpis`:
  - `points`, `points_done`: the stops of every run, with the school counted as one point per run. Progress = done / points.
  - `buses`: `{ on_road, arrived, not_started, total }`.
  - `riders`: a count for each child status below, plus `absent` (= `not_required` + `no_show`) and `total`.
  - `completion`: `{ at, planned_at, late_minutes }`. This is when the last run ends (its school ETA in the morning,
    its last drop-off in the afternoon), against plan.
  - `attention`: `{ runs, issues }`.
- `attention`: what needs attention, most severe first. Each item is `{ occurrence_id, route, severity, kind, title, … }`:

  | `kind` | Severity | Extra fields |
  | --- | --- | --- |
  | `gps_lost` | 4 | `last_ping`, `near` (the last stop reached) |
  | `late` | 4 when 10 min or more, else 3 | `late_minutes`, `school_eta`, `planned_at` |
  | `no_show` | 2 | `rider: { rid, name }`, `stop`, `marked_by` |

  A run is late from 4 minutes. GPS is lost when a run on the road has had no position for 3 minutes (as in Ops Control).
The prototype also shows a `delay_expected` item (a run not yet started that will be late); it is not built, so Live Ops has these three kinds only.
- `filters`: the count for each filter.
- `rows`: one per run:
  - `occurrence_id`, `route_id`, `label`, `plate`, `driver: { name, phone }`.
  - `status`: `{ key, label, tone }`. The keys are `not_started`, `on_time`, `late`, `gps_lost` and `arrived`. When the
    key is `arrived`, `status.at` is the time it arrived. In the afternoon the label is "Completed".
  - `late_minutes`, `points`, `points_done`, `counts` (children by status, and `total`).
  - `next_stop`: `{ name, at_stop, expected_at }`. This is null once the run is done. When `at_stop` is true, show
    "Boarding now"; otherwise show "ETA" with `expected_at`.
  - `end_at`, `end_planned_at`: the school ETA (morning) or the last drop-off (afternoon), and its plan.
  - `starts_at`.
  - `line`: `[[lat, lng], …]`, the stops in order with the school last (morning) or first (afternoon).
  - `position`: `{ lat, lng, speed_kmh, heading, recorded_at }`: the live position while the run is on the road, and the last known position once it has arrived; `null` before it starts.

**Child status** (`counts`, and each child in § 2):

| Status | When |
| --- | --- |
| `waiting` | Nothing recorded yet, and the bus has not left the child's stop |
| `on_board` | Boarded |
| `at_school` | Alighted at the school (morning) |
| `dropped_off` | Alighted at their stop (afternoon) |
| `not_required` | Bus Not Required from the parent for that trip (`marked_by: "Parent"`), or marked "not boarding today" in the app |
| `no_show` | Marked "not boarded": the child was not at the stop |

**Lateness.** A run's lateness is the worst of two things: how late it arrived at the last stop it reached, and its ETA
at the next stop against plan. The ETA is a straight line from the bus's last position at 30 km/h, as on Live Map. A run
that is done shows how late it arrived at the school. The ETAs that follow add the lateness to their planned times.

The map's traffic layer, weather card and road incidents are not built (see § 5).

## 2. Live Ops: one run

`GET /schools/:school_id/live/runs/:id` (`id` = `occurrence_id`)

- `occurrence_id`, `route_id`, `label`, `session`, `date`.
- `bus`: `{ plate, type, bus_type, bus_type_label, seats, operator }`. `bus_type` is the bus size code (`"LARGE_40"`) and `bus_type_label` its label (`"40-seater"`), the same pair as Finance › Route Costs. `type` is the same as `bus_type_label` (kept; use `bus_type_label`); `operator`
  is `"Own fleet"` for our buses. A route made without a bus size shows the size nearest its seats (or the bus's seats);
  `null` only when neither is known.
- `status`, `alert`, `late_minutes`, `points`, `points_done`, `counts`, `on_board`, `stops_count`, `next_stop`
  (`{ index, name, at_stop, expected_at }`).
- `alert`: null, or `{ kind: gps_lost, tone, title, last_ping }`, or `{ kind: late, tone, title, school_eta, planned_at }`.
  Show it as the banner.
- `end`: `{ planned_at, at, done }`. This is the last row of the timeline (the school, or the last drop-off).
- `methods`: how the children who boarded did it: `{ tick, qr, card, palm }`. `tick` = marked by hand ("Manual").
- `crew`: `[{ role: "Driver" | "Bus Attendant", name, phone, photo }]`. "Call" opens `tel:`. `photo` is a signed thumbnail link
  (`/api/v1/downloads/…`), `null` when there is none (a replacement driver never has one).
- `log`: `[{ at, kind, text }]`, newest first, with only what has happened so far. The kinds are `started`, `arrived`,
  `boarded` / `dropped_off` (per stop), `no_show`, `manual` (a child marked present by hand), `alert_<kind>` /
  `cleared_<kind>` (Ops Control alerts on the run) and `at_school`.
- `school`: `{ name, lat, lng }`, and `position` (as in § 1).
- `stops`: one per stop:
  - `index`, `number`, `name`, `address`, `lat`, `lng`, `planned_at`. `address` is the PUDO point's description
    ("Bus stop opposite Kembangan MRT"), shown under the name; `null` when the stop is not linked to a point or it has none.
  - `state`: `done`, `at` (at the stop now) or `todo`.
  - `arrived_at`, `departed_at`, `late_minutes` (once left).
  - `expected_at`: for a stop not reached yet.
  - `riders`: one per child:
    - `rid`, `name`, `level`, `status`. A child nobody ticked is not left as `waiting` once the bus has left the stop
      (as the prototype): `on_board` in the morning (`at_school` when the run is done), `dropped_off` in the afternoon.
      Ticks, Bus Not Required and No Show always win.
    - `marked_by`: the attendant or driver, or "Parent".
    - `reason`: for Bus Not Required, for example "Unwell. Fever".
    - `boarded_at`, `board_method`.
    - `board`: `{ lat, lng, distance_m }`, where the pass was read and how far that was from the stop. Flag
      `distance_m > 50` as "check location".
    - `alighted_at`, `alight_method`.

The status filter and the search by name or `rid` on this view are done by the front end.

The bus's GPS track for the map comes from Live Map: `GET /live_map/runs/:id/track?since=` ([live-map.md](live-map.md)).

## 3. Dashboard › Operations

`GET /schools/:school_id/dashboard?bin=tier|1|2`

`data`: `{ school, finance_allowed, operations }`.

**`operations`:**

- `date`, `academic_year` (key or null).
- `day`: `{ kind, title, detail, runs }`. The kinds are `school_day`, `special_day` (runs; for example "Early Dismissal
  at 11:30 | Prize Giving Day"), `no_service` (not an operating day), `public_holiday`, `school_holiday`,
  `between_terms` and `no_year`.
- `sessions`: today's Bus Sessions, on a day the buses run. Each is:
  - `name`, `direction`, `cca`.
  - `different_today`: today has its own times; show "Different timing today".
  - `arrive_from`, `arrive_to` (to school) or `depart` (to home).
  - `routes`, `buses`, `riders`, `seats`, `seats_used_pct`, `without_bus`. `seats_used_pct` is `null` when there are no seats.

  The routes come from the plans running today: AM for to-school sessions, PM for to-home sessions, CCA for CCA sessions.
- `sessions_note`: on a day the buses run with no sessions: "Bus Sessions are not set up for this year", or "No sessions
  run on Tue".
- `today`: `{ routes_running, buses_assigned, routes, on_time_pct }`. `on_time_pct` is null for now (shown as N/A,
  "Shown once trips are tracked").
- `attention`: `[{ kind, title, detail, step? }]`:
  - `setup`: Year Setup steps not done, except the money steps, which are on Finance. `step` = the first step's key.
  - `no_bus`: trips without a bus. Opens Route Plans.
  - `stop_requests`: stops waiting for review. Opens the Stop Library.
- `upcoming`: up to 6 items in the next 3 months, each `{ date, kind, title, … }`. The kinds are `holiday` (with
  `ends_on`), `special_day` (with `time`, `detail`), `public_holiday` (on operating days), `term_start` and `term_end`.
- `ahead`: up to 8 items in the next 90 days, each `{ date, kind, title, … }`:
  - `plan_adopted`: with `routes`, and `replaces: { name, routes }`.
  - `plan_ends`.
  - `riders_start`: "Check they have a stop and a route".
  - `riders_leave`.
- `students` (the riders on the list today):
  - `total`, `on_route: { count, pct }`, `not_on_route` (when it is not 0, show "Check Stop Assignment").
  - `am_and_pm`, `am_only`, `pm_only`, `cca`: each `{ count, pct }`.
  - `distance`:
    - `bin`, and `bins` (the choices: `tier` when the fares go by distance tiers, `1`, `2`).
    - `histogram`: `[{ from, to, count, pct, cum, cum_pct }]`. `to: null` = "Over … km".
    - `average`, `median`, `furthest` (km), `located` (riders with a map location), `riders`.
    - Caption: "Straight-line, home to school, plus a 0.05 km buffer, rounded up to 0.1 km. Bills use the same distance."
  - `levels`: `[{ label, count }]` in the school's level order, with "Not given" last.

## 4. Dashboard › Finance

`GET /schools/:school_id/dashboard/finance?month=YYYY-MM` (default this month; `month=YYYY-MM`; a full date such as `2026-11-01` is read as its month. An invalid value → `422` "Month must look like 2026-11"). `data`:

- `month` (`"2026-11"`), `state`:
  - `closed`: a past month.
  - `in_progress`: "Actual to today, forecast for the rest of the month".
  - `forecast`: "From the plans, riders and charges dated for this month".
- `paid_month`: `false` when Operator Pay does not pay the month (the FE shows a "not a paid month" banner that points to Operator Pay; the costs are 0).
- `reference_day`: the day riders and seats are counted on. It is today for this month, else the month's first school day, else the 15th (a month with no school day).
- `kpis`:
  - `revenue`: null with `revenue_note` when it cannot be worked out, for example "Bus Fares for AY 2026 not saved yet".
    Otherwise it is the fares expected in the month. Each billing period's fares are worked out as Family Bills would
    draft them, for every rider on the routes (whether linked to a family or not). Each period's share is its school
    days in the month; a monthly bill counts in full in its month. When the school pays per bus, the bus rates are used.
    `revenue_basis` is `rider` or `bus`; `revenue_riders` and `academic_year` go in the caption.
  - `operator_cost`: the route pay of the month, as on School Finance › Operator Payments.
  - `profit`, `margin_pct`.
  - `cost_per_rider`, `riders`.
  - `seats`: `{ riders, seats, routes, pct }`, the riders and seats of the routes running on `reference_day`.
- `collections`: `{ expected, billable, billed, bills, collected, overdue: { bills, owed } }`:
  - `billable`: the bills of the billing periods that start in the month, in full (`null` when `expected` is) → with no bill
    issued yet: "Expected bills: S$`billable`. Not raised yet".
  - `billed`: the bills issued for the month.
  - `collected`: payments received in the month.
  - `overdue`: the bills overdue today, past their due date with something owed.
- `route_costs`: Finance › Route Costs and By Transport Operator for the month:
  `{ total, school_days, priced, routes, rows: [{ route, session, plan, bus_type (the size code: the route's own, else the one nearest its seats; display only, prices use the route's own), bus_type_label (its label, e.g. "40-seater"; show this), plate, operator, price, unpriced, days, of, amount, note, attendant }],
  by_operator: [{ key, operator_id, name, routes, amount }] }` (the same figures as School Finance › Operator Payments; `operator`
  "Our buses" / "Not assigned" for own buses / no bus; `attendant { amount, by }` as there).
- `year`: the academic year's 12 months, `[{ month ("2026-10"), revenue, cost, profit }]`, for the revenue against cost chart.
- `ahead`: up to 8 items in the next 90 days:
  - `plan_adopted`: `revenue_change` (only when the school pays per bus by the plan) and `cost_change`, both a month.
  - `route_charge`: `route`, `charge_kind`, `value`, `note`. When `value` is 0, the charge ends.
  - `extra_charge`: `charge_kind`, `value`.
  - `policy`: a Payment & Refund Policy version starts.
- `attention`:
  - `bus_rates`: bus sizes with no school rate.
  - `booked_runs`: more runs than booked.
  - `route_charges`: route charges to check (opens Bus Fares).
  - `setup`: the money steps not done, which are Bus Fares, Payment & Refund Policy and Operator Pay.
  - `unpriced`: routes not priced (opens Operator Pay).

This call takes about 1 to 2 seconds, because the year chart works out 12 months. Make it when the Finance tab opens.

## 5. Not built yet

- Recording attendance from the driver / bus attendant app (board, alight, not boarded, not boarding today), and Bus Not
  Required from the Convoy App. The tables and the reads are built; the apps' calls come with those apps.
- Live Ops weather (NEA 2-hour forecast), traffic (LTA Speed Bands) and road incidents. Hide them.
- On-Time Performance on the Dashboard (`today.on_time_pct` is null).
