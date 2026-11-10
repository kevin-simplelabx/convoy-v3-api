# HR — API Guide

The HR menu (rail icon `badge`): driver pay. Pages: **Drivers**, **Earnings**, **Pay Schemes**, **Rate Plans**,
**Bonuses**, **Points**, **Rewards**, **Salary Simulator**, **Audit Log**. What is not built yet is in [§ 10](#10-not-built-yet).

Conventions (sign-in, errors, paging, files) are in [README.md](../README.md). All paths start with `/api/v1`.

**Permissions.** HR needs the `finance` or `finview` permission (`403` otherwise); changing anything needs `finance`.
**Unlock** and **Reopen Month** need an Admin (admin, Super Admin, or the `users` permission). A Convoy Admin can only read.

**Locking.** Rate plans, pay schemes and bonuses can be locked once announced to drivers: a locked one can't be saved or
deleted (`422` "<name> is locked. Unlock it to make changes" for an Admin, "… Ask an Admin to unlock it" for others).
Each has `locked`, `locked_at`, `locked_by { id, name }`; buttons: `POST …/:id/lock`, `POST …/:id/unlock`, and
"Save and Lock" = the save call with `"lock": true`.

## Contents

1. [Rate Plans](#1-rate-plans)
2. [Pay Schemes](#2-pay-schemes)
3. [Drivers](#3-drivers)
4. [Salary Simulator](#4-salary-simulator)
5. [Earnings](#5-earnings)
6. [Bonuses](#6-bonuses)
7. [Points and Rewards](#7-points-and-rewards)
8. [Audit Log](#8-audit-log)
9. [How pay is worked out](#9-how-pay-is-worked-out)
10. [Not built yet](#10-not-built-yet)
11. [Changes to existing endpoints (02/11/2026)](#11-changes-to-existing-endpoints-02112026)

---

## 1. Rate Plans

| Action | Call |
| --- | --- |
| List | `GET /pay/rate_plans` |
| Open a plan | `GET /pay/rate_plans/:id` |
| Add Rate Plan → Save / Save and Lock | `POST /pay/rate_plans` (with `"lock": true` to lock) |
| Save / Save and Lock | `PATCH /pay/rate_plans/:id` |
| Lock / Unlock | `POST /pay/rate_plans/:id/lock`, `POST /pay/rate_plans/:id/unlock` |
| Delete Plan | `DELETE /pay/rate_plans/:id` (confirm "Delete <name>?") |
| Coverage card | `GET /pay/rate_plans/:id/coverage` |

List row: `{ id, name, description, periods_count, used_by: ["Basic + Trips"], locked, locked_at, locked_by }`.
Sub line: "<n> periods | Used by <n> schemes" or "Not used yet".

### 1.1 The plan (save body = response)

```json
{ "rate_plan": {
  "name": "Standard", "description": "Weekday, peak, night and weekend rates",
  "vehicle_type_ids": [3, 5],
  "periods": [
    { "name": "Night", "days": ["mon", "tue", "wed", "thu", "fri"], "takes_priority": false,
      "ranges": [ { "start_time": "21:00", "end_time": "05:00" } ],
      "rates": [ { "vehicle_type_id": 3, "per_trip": 17, "per_hour": 13 } ] }
  ] },
  "lock": false }
```

- The whole plan is sent each time and replaces what was saved (periods are recreated, so their ids change).
- `days`: `mon` … `sun`, `ph` (public holiday). `takes_priority` = **Takes Priority**.
- A range whose end is before its start runs past midnight (`ends_next_day: true` in the response: "Ends the next day").
  `23:59` as the end means the end of the day.
- Rates: one per vehicle type of the plan; empty = S$0 (allowed, Coverage warns).
- `422`: "Enter a plan name", "Pick at least one vehicle type", "Add at least one period", "Name every period",
  "Pick the days for <period>", "Add a time for <period>", "Name is already used by another rate plan".
- Delete: `422` "Used by <schemes>. Pick another rate plan there first", or the lock message.

### 1.2 Coverage

```json
{ "rows": [ { "day": "mon", "cells": [null, null, 12, "… 48 period ids or null"] } ],
  "periods": [ { "id": 12, "name": "Off Peak" } ],
  "gaps": [ { "day": "mon", "from": "00:00", "to": "05:00" } ],
  "empty_rates": [ { "period": "Peak", "vehicle_type": "Coach" } ] }
```

8 rows (Mon … Sun, PH) × 48 half hours; a cell holds the period that pays its middle (colour by period order), `null` =
no rate (orange). Warnings: "No rate for Mon 00:00 to 05:00 … Jobs at these times are paid S$0"; "Rates still empty for
Peak, Coach …". The rule for which period pays is in [§ 9](#9-how-pay-is-worked-out).

## 2. Pay Schemes

| Action | Call |
| --- | --- |
| List | `GET /pay/schemes` → `{ id, name, description, is_default, scheme_type, type_label, pay_rate_plan_id, locked, … }` |
| Open | `GET /pay/schemes/:id` |
| Add Pay Scheme → Save / Save and Lock | `POST /pay/schemes { scheme: {...}, lock: false }` |
| Save / Save and Lock | `PATCH /pay/schemes/:id` |
| Lock / Unlock | `POST /pay/schemes/:id/lock`, `POST /pay/schemes/:id/unlock` |
| Delete Scheme | `DELETE /pay/schemes/:id` |
| Open Rate Plan | `GET /pay/rate_plans/:id` (`rate_plan.id`) |

### 2.1 Fields (save body = response)

| Screen | Field | Default |
| --- | --- | --- |
| Scheme Name, Description | `name`, `description` | |
| Default Scheme | `is_default` (saving one as default clears the others; there is always one) | |
| Scheme Type | `scheme_type`: `basic_plus_trips`, `monthly_with_minimum`, `shift_based` (`type_label`) | `basic_plus_trips` |
| Rate Plan | `pay_rate_plan_id` (response also `rate_plan { id, name }`) | |
| **Basic Salary** (Basic + Trips) | `basic_salary`; `basic_covers_daily_trips`, `basic_covered_daily_trips`, `basic_covered_schedule`, `basic_cover_ph` | 0; false, 1, `mon-fri`, false |
| Disposal Hours Count as Trips | `disposal_counts_as_trips` | false |
| **Monthly Pay** | `monthly_pay_amount`, `monthly_minimum_type` (`daily` / `monthly`), `monthly_daily_trips`, `monthly_schedule`, `monthly_cover_ph`, `monthly_trips` | 2200, daily, 6, mon-fri, false, 150 |
| **Shift** | `shift_salary`, `shift_start_time`, `shift_end_time` ("HH:MM"), `shift_working_days` (`mon`…`sun`), `shift_overtime_pay_type` (`trip_rates` / `hourly_rate`), `shift_overtime_hourly_rate` | 0, 08:00, 18:00, Mon–Fri, trip_rates, 0 |
| **School Routes** | `school_routes_pay` (Monthly Route Retainer), `route_bands [{ up_to_minutes, monthly_amount }]` (last band `up_to_minutes: null` = Longer Routes), `school_routes_count`, `school_routes_in_guarantee` | off, —, off, on |
| **Guarantee** (Basic + Trips) | `has_guarantee`, `guaranteed_amount`, `on_top_ph`, `on_top_sat`, `on_top_sun`, `has_post_guarantee_boost`, `post_guarantee_boost_type` (`percentage` / `flat` / `fixed_rate`), `post_guarantee_boost_value` | off, 2200, off ×3, off, percentage, 50 |
| **Rejection Penalty** | `has_rejection_penalty`, `rejection_allowed_jobs`, `rejection_fallback_basic`, `rejection_keeps_incentives` | off, 0, 0, on |
| **Daily Volume Incentive** | `has_daily_volume_incentive`, `daily_volume_in_guarantee`, `volume_tiers [{ from_trip, to_trip (null = no limit), boost_type (flat / percentage / fixed_rate), boost_value }]` | off |
| **Weekly Target Incentive** | `has_weekly_target_incentive`, `weekly_target_in_guarantee`, `weekly_tiers [{ target_trips, pay_as (lump_sum / per_trip), amount }]` | off |
| **Monthly Target Incentive** | `has_monthly_target_incentive`, `monthly_target_in_guarantee`, `monthly_tiers [...]` | off |

Schedules (`basic_covered_schedule`, `monthly_schedule`): `mon-fri` (Mon to Fri), `mon-sat`, `mon-fri-sun` (Mon to Fri + Sun),
`6-days` (6 Days a Week), `all-days` (Every Day).

- Each list sent replaces the saved one; a list left out is kept. Send the new scheme's default bands and tiers from the
  prototype when the user adds a scheme.
- `422` (`details` holds each field's message): `name`: "can't be blank" / "is already used by another pay scheme"; `rate_plan`: "must be picked",
  "Enter the monthly pay for every route band", the lock message.
- Delete: "Keep at least one pay scheme", "Make another scheme the default first", the lock message.

## 3. Drivers

Own drivers (active), with the pay scheme and vehicle type used to work out their pay. Operator drivers are paid by
their operator and are not listed.

| Action | Call |
| --- | --- |
| List, Search (name) | `GET /pay/drivers?q=` |
| Open a driver | `GET /pay/drivers/:id` |
| Assign Scheme | `POST /pay/drivers/:id/schemes { assignment: { pay_scheme_id, starts_on, ends_on } }` |
| Change a scheme row (scheme, start, end) | `PATCH /pay/drivers/:id/schemes/:assignment_id { assignment: {...} }` |
| Remove a scheme row (confirm "Remove this assignment?") | `DELETE /pay/drivers/:id/schemes/:assignment_id` |
| Assign Vehicle Type / change / remove | Same on `/pay/drivers/:id/vehicle_types` with `vehicle_type_id` |

Row: `{ id, name, phone, photo, age, vehicle { id, plate }, vehicle_type { id, name }, scheme_today { id, name } | null, warning }`.
Sub line: "<plate | No vehicle> | <scheme_today.name | No pay scheme>"; "Age <age>" (from the driver's KYC, `null` when not shared).
Each change saves at once and returns the driver.

Driver (`GET /pay/drivers/:id` and every change) adds:
- `pay_schemes [{ id, pay_scheme { id, name }, starts_on, ends_on, tag }]`, `tag` = `upcoming` / `current` / `ended`.
- `vehicle_types [{ id, vehicle_type { id, name }, starts_on, ends_on, tag, warning }]`.
- `min_start` (start dates can go back up to 1 month: "Start dates can go back up to 1 month, to <date>").
- `default_scheme { id, name }`: no scheme rows → "No scheme assigned yet, so <name> is paid on the default scheme, <default>".

Rules: rows never overlap — a new row ends the one before it on the day before (`ends_on` is set for you). A driver with
scheme rows that don't cover a date has **no scheme** that day (paid S$0 → "No pay scheme today"). Without vehicle type
rows, each job is paid at the type of its bus (by seats). `warning`: "Rate plan <plan> of <scheme> has no rates for <type>,
so these jobs are paid S$0". `422` (`details`): `starts_on`: "can go back up to 1 month, to 2 Oct 2026" / "already has an assignment"; `ends_on`: "is before the start date".

## 4. Salary Simulator

Try a pay scheme on a made-up month. Nothing is saved (except templates). The calendar, the day editor and the
working month live on the front end (browser storage); each change calls `POST /pay/simulate` with the whole month.

| Action | Call |
| --- | --- |
| Work out the month | `POST /pay/simulate` |
| Fill Sample Month | `GET /pay/simulate/sample?month=2026-11` → `{ month, jobs }` (load the jobs, then simulate) |
| Templates window (5 slots) | `GET /pay/simulator_templates` → `[{ slot, template | null }]` |
| Save Current Month / Save Over | `PUT /pay/simulator_templates/:slot { template: {...} }` |
| Delete template (confirm "Delete template <name>?") | `DELETE /pay/simulator_templates/:slot` |

### 4.1 Simulate

```json
{ "scheme_id": 4, "vehicle_type_id": 3, "month": "2026-11",
  "jobs": { "2026-11-03": [ { "type": "trip", "start_time": "07:00", "tv": 1.5 },
                            { "type": "disposal", "start_time": "17:00", "end_time": "23:00" } ] },
  "routes": [ { "name": "AM1", "minutes": 45, "start_time": "06:30" } ],
  "school_holidays": { "from": "2026-11-20", "to": "2026-12-31" },
  "rejected": 0, "on_time_percent": 100, "attendance_percent": 100 }
```

Response:

```json
{ "total": "834.0", "trips": "21.0",
  "parts": [ { "from": "2026-11-01", "to": "2026-11-30", "scheme": { "id": 4, "name": "Basic + Trips" }, "total": "834.0", "penalty": false,
               "amounts": { "base": "500.0", "route_pay": "300.0", "trip_pay": "14.0", "hour_pay": "20.0", "daily_volume": "0.0",
                            "weekly_target": "0.0", "monthly_target": "0.0", "after_guarantee": "0.0", "top_up": "0.0" },
               "rows": [ { "label": "Basic Salary", "amount": "500.0" }, { "label": "Trips Counted", "text": "21 trips" },
                         { "label": "Trip Pay", "amount": "14.0", "units": [ { "rate": "14.0", "units": "1.0", "on_top": false } ] } ],
               "weeks": [ { "from": "2026-11-02", "to": "2026-11-08", "trips": "22.0", "target": 20, "first_target": 20, "amount": "50.0" } ] } ],
  "days": { "2026-11-03": { "amount": "34.0", "trips": "2.0", "on_top": false, "holiday": null,
                            "lines": [ { "time": "07:00", "detail": "All Day", "amount": "14.0", "units": "1 x S$14.00" } ] } },
  "bonuses": [] }
```

- `rows` are the breakdown rows of the right panel, in order (only those that apply). `amounts` feed the stacked bar.
- `days` = the calendar cells (amount, trips, PH name, "On top") and the day's breakdown lines.
- A job is `trip` (`tv` = trip value, default 1) or `disposal` (paid by the hour from start to end; an end before the start
  runs past midnight). Without the route retainer, each school route is driven as a trip on school weekdays.
- `bonuses`: see [§ 6](#6-bonuses).

### 4.2 Templates

Template: `{ slot, name, description, month, pay_scheme_id, vehicle_type_id, rejected, on_time_percent, attendance_percent,
school_holidays_from, school_holidays_to, routes, jobs, days_with_jobs, saved_by { id, name }, updated_at }`.
Meta line: "<Mon YYYY> | <days_with_jobs> days with jobs, <routes.size> routes | Saved by <name> on <date>".
Save body: the same fields (`jobs` = that month's jobs only). `422` `details.name`: "can't be blank".

## 5. Earnings

What each driver earned in a month from the trips on the Scheduler. A run counts once it has run and no issue is raised
on it; cancelled, skipped and upcoming runs earn nothing.

| Action | Call |
| --- | --- |
| Month select, Search, the driver list and totals | `GET /pay/earnings?month=2026-10&q=` |
| Open a driver | `GET /pay/earnings/:driver_id?month=2026-10` |
| Raise an Issue / Clear Issue on a run | `POST /occurrences/:id/issue { reason }` / `DELETE /occurrences/:id/issue` ([scheduler](scheduler.md)), then reload |
| Confirm Month (confirm text in the prototype) | `POST /pay/earnings/:driver_id/confirm?month=2026-10` |
| Reopen Month (Admin; confirm "Reopen <Month> for <driver>?") | `DELETE /pay/earnings/:driver_id/confirm?month=2026-10` |
| Click a Trip ID | Scheduler day view of that run (`date`, run `id`) |

List row: `{ driver_id, name, month, total, completed, held, vehicle { id, plate }, status, confirmed }`;
`meta { month, completed, held, total, confirmed, drivers }` ("<confirmed> of <drivers> confirmed").
`status`: `confirmed` (badge Confirmed), `held` (a run has an issue: Held), `to_confirm` (month ended: To Confirm), `open` (Open).
`confirmed`: `{ by, at, total }` or `null`. A confirmed month shows the frozen `total`.

Driver (`GET /pay/earnings/:driver_id`, and the answer of Confirm / Reopen) adds:

| Field | |
| --- | --- |
| `schemes` | `[{ from, to, id, name, rate_plan }]` — "<scheme> \| <rate plan>" (two when the scheme changed mid-month) |
| `counts` | `{ completed, issue, cancelled, upcoming, running }` (KPIs) |
| `can_confirm`, `why` | `why`: "The month can be confirmed from 1 Dec 2026", "No pay scheme assigned. Pick one in Drivers", "1 trip has an issue raised. Clear them first" |
| `breakdown` | Per part of the month: `{ from, to, scheme, rows, amounts, weeks }` (same rows as the simulator; a confirmed month: the frozen rows) |
| `runs` | `[{ id, date, start_time, end_time, trip_id, trip_label, kind, plate, trip_value, hours, status, issue { reason, at }, amount }]` |

Run `status`: `completed` (Completed), `issue` (Issue Raised: pay held), `running`, `upcoming`, `cancelled`. `amount` = what the
run earned (completed runs only). `hours` is set for runs paid by the hour (disposal, or trips priced by the hour), to the
quarter hour (rounded as the trip says: up by default); others show `trip_value`.

Confirm `422`: the `why` texts, "<Month> is already confirmed". Once a month is confirmed, raising or clearing an issue on
its runs answers `422` "Driver pay for October 2026 is confirmed. Reopen it in HR, Earnings first".

**Export Statement** is printed by the front end from this data (header "Earnings Statement", the breakdown, the runs;
"Provisional, not yet confirmed" until confirmed).

## 6. Bonuses

| Action | Call |
| --- | --- |
| List | `GET /pay/bonuses` → `{ id, name, description, plan_type, type_label, frequency, starts_on, last_period_on, ends_on, status, locked, … }` |
| Open | `GET /pay/bonuses/:id` |
| Add Bonus → Save / Save and Lock | `POST /pay/bonuses { bonus: {...}, lock: false }` |
| Save / Save and Lock | `PATCH /pay/bonuses/:id` |
| Lock / Unlock / Delete Bonus | `POST /pay/bonuses/:id/lock`, `POST /pay/bonuses/:id/unlock`, `DELETE /pay/bonuses/:id` |
| First / Last Period options | `GET /pay/bonuses/periods?frequency=weekly` → `[{ value: "2026-11-02", label: "Week of Mon 2 Nov 2026" }]` |

List sub line: "<type_label> | <frequency> | <Upcoming / Running / Ended> | Locked". `status`: `upcoming`, `running`, `ended`.

### 6.1 Fields (save body = response)

```json
{ "bonus": {
  "name": "Year-End Trip Bonus", "description": "",
  "plan_type": "trip_target", "frequency": "monthly",
  "starts_on": "2026-11-01", "last_period_on": "2026-12-01",
  "payout_type": "end_of_period", "payout_delay_months": 1,
  "payments": [ { "percentage": 50, "months_after": 1 }, { "percentage": 50, "months_after": 3 } ],
  "scheme_ids": [], "eligible_driver_ids": [],
  "requires_sign_up": false, "sign_up_from": null, "sign_up_to": null, "terms": "", "signed_up_driver_ids": [],
  "overlap_daily": "additive", "overlap_weekly": "additive", "overlap_monthly": "additive",
  "tiers": [ { "target_trips": 80, "pay_as": "lump_sum", "amount": 100, "points": 50 } ],
  "excluded_periods": [ { "name": "Year-end shutdown", "starts_on": "2026-12-24", "ends_on": "2026-12-26" } ] },
  "lock": false }
```

- `plan_type`: `trip_target` (Trip Target), `reliability_otp` (On-Time Performance), `reliability_attendance` (Attendance).
- `frequency`: `daily`, `weekly`, `monthly`, `quarterly`, `half_yearly`, `yearly` (on-time and attendance: monthly or longer).
  Daily bonuses use dates for `starts_on` / `last_period_on`; others the period `value` from the options. `last_period_on` = the
  **start** of the last period (`null` = No end date); `ends_on` (response) is its last day.
- `payout_type`: `next_payroll_cycle` (Next Payroll, daily / weekly), `end_of_period`, `x_months_later` (with `payout_delay_months`),
  `split_trenches` (with `payments`, adding up to 100%).
- Who Can Join: `scheme_ids` (`[]` = All Schemes), `eligible_driver_ids` (`[]` = every driver on an eligible scheme),
  `requires_sign_up` with dates and terms; `signed_up_driver_ids` = drivers ticked by hand (the driver app signs up later).
- When the Scheme Also Pays (daily / weekly / monthly): `overlap_<frequency>` = `additive` (Bonus Adds), `supercede` (Bonus Supersedes),
  `prevail` (Scheme Prevails).
- Tiers: trip types `target_trips`, `pay_as` (`lump_sum` / `rate_increase` = per trip), `amount`, `points`; on-time / attendance
  `metric_min`, `metric_max` (%), `amount`, `points`. Excluded Days only for Attendance.
- `422`: "Enter a bonus name", "Add at least one tier", "The split payments add up to 80%. They must add up to 100%",
  "Set the sign-up dates", "Sign-up ends before it starts", "The last period is before the first",
  "On-time and attendance bonuses run monthly or longer", the lock message.

### 6.2 What a driver earns

The Salary Simulator (`bonuses` of `POST /pay/simulate`) and Earnings (`bonuses` of a driver's month) list each bonus that
covers the month and the scheme (Earnings: also the driver's eligibility and sign-up):

```json
{ "bonus_id": 3, "name": "Year-End Trip Bonus", "sub": "Target reached", "amount": "100.0", "adjust": "0.0", "points": 50,
  "paid_now": true, "note": null }
```

- Trip Target: daily — each day ("12 of 21 days reached a tier"); weekly — Monday–Sunday weeks inside the month; monthly —
  the month. The highest tier reached is paid (`rate_increase`: amount × trips).
- On-time / attendance (monthly): the simulator uses `on_time_percent` / `attendance_percent` (default 100). Earnings works
  them out from what the Convoy Driver app recorded over the bonus's days in the month (its start / end), less its Excluded
  Days, up to now — `sub` "95.0% on time", "71.4% attendance":
  - **on time**: of the completed runs with arrivals recorded, the share within the company's On Time allowance (Company
    Settings, default 5 min; the same figure as Trip History and the Dashboard). Runs with no arrival recorded do not count.
  - **attendance**: of the runs given to the driver (not cancelled by the office or the client; a trip the driver skipped
    counts as missed), the share the driver started in the app.
  - Nothing recorded yet: `amount` 0, `sub` "No arrivals recorded yet for on time" / "No trips recorded yet for attendance".
- Quarterly and longer: "…periods are not worked out for one month".
- `adjust`: Bonus Supersedes takes the scheme's incentive of the same period off (negative); Scheme Prevails pays 0.
- `paid_now`: paid this month (end of period / next payroll) → counted in Earnings `total` and the simulator's
  `total_with_bonuses`; otherwise `note` ("Paid 2 months after the period", "Paid later in 2 parts").
- Points of a bonus paid this month go to the driver's points when the month is confirmed ([§ 7](#7-points-and-rewards)).

## 7. Points and Rewards

### 7.1 Points

| Action | Call |
| --- | --- |
| Driver list with balances | `GET /pay/points` → `[{ id, name, plate, balance }]` |
| Balance card and History | `GET /pay/points/:driver_id` |
| Award Points / Deduct Points | `POST /pay/points/:driver_id { kind: "award" \| "deduct", points, reason }` (`201`, the driver's points) |

```json
{ "driver": { "id": 4, "name": "Eric Pang" }, "balance": 230, "earned": 350, "used": 120, "expired": 0, "expiring_soon": 0,
  "history": [ { "kind": "deduct", "id": 2, "points": -120, "reason": "S$10 Grab voucher", "on": "2026-11-02", "by": "SimpleDrive Ops", "status": "used" },
               { "kind": "award", "id": 7, "points": 300, "remaining": 180, "reason": "Safe driving, Q3 2026", "source": "manual",
                 "on": "2026-11-02", "expires_on": "2028-11-02", "by": "SimpleDrive Ops", "status": "active" } ] }
```

- Points are kept as lots: each award lasts 24 months; a deduction takes points from the lots expiring first, so an expired
  lot only loses what was left of it. `status` of an award: `active`, `used` (nothing left), `expired` (some left and expired).
- Texts: "{expiring_soon} points expire in the next 60 days"; "Awarded points expire after 24 months"; "Deducted points come off
  the balance now, up to {balance}". `source: "bonus"` = points of a bonus paid in a confirmed month ("Bonus: <name>, Oct 2026").
- `422`: "Enter the number of points", "Enter a reason", "Eric Pang has only 30 points".

### 7.2 Rewards

| Action | Call |
| --- | --- |
| List | `GET /pay/rewards` |
| Add Reward / Save | `POST /pay/rewards`, `PATCH /pay/rewards/:id` (multipart when a photo is sent) |
| Delete Reward (confirm "Delete <title>?") | `DELETE /pay/rewards/:id` |

Reward: `{ id, title, description, points_required, status: "active" | "inactive", photo { url, thumb_url } }`.
Body: `reward[title]`, `reward[description]`, `reward[points_required]`, `reward[status]`, `reward[photo]` (JPEG, PNG or WebP,
under 2 MB, kept at most 480 px), `reward[remove_photo]=true`. Only active rewards show in the driver app.
`422` `details`: `title`: "can't be blank"; `points_required`: "must be greater than 0"; `photo` (type / size).

## 8. Audit Log

`GET /pay/audit_log?q=&action_type=&item=&page=` — every change to rate plans, pay schemes, bonuses, rewards, driver
assignments, points and confirmed months, newest first (the latest 500 changes). Entries can't be edited.

```json
{ "data": [ { "id": 62, "at": "2026-11-02T09:00:00+08:00", "user": "Olivia Owner", "action": "award", "item": "points",
              "item_label": "Points", "name": "Eric Pang", "details": "Awarded 20 points: Good conduct" } ],
  "meta": { "page": 1, "limit": 50, "count": 6, "pages": 1,
            "actions": ["create", "update", "delete", "lock", "unlock", "award", "deduct", "confirm", "reopen"],
            "items": { "rate_plan": "Rate Plan", "pay_scheme": "Pay Scheme", "campaign_bonus": "Bonus", "reward": "Reward",
                       "driver_assignment": "Driver", "driver_pay": "Driver Pay", "points": "Points" } } }
```

- Filters: `q` (user, name or details), `action_type` (one of `meta.actions`; labels Created, Updated, Deleted, Locked, Unlocked,
  Awarded, Deducted, Confirmed, Reopened), `item` (a key of `meta.items`).
- Columns: When (`at`, local date and HH:MM) | Who | Action (chip) | Item (`item_label` + `name`) | Details.

## 9. How pay is worked out

The same engine works out Earnings and the Salary Simulator (the rules of the prototype's `DriverPay.simulate`).

**Parts of a month.** A month is split into parts by the driver's pay scheme (a scheme change mid-month, or joining /
leaving mid-month). Each part is worked out on its own scheme; fixed pay (basic, monthly pay, shift salary, the guarantee,
the route retainer) and monthly trip targets follow the part's share of the month's days (10 of 30 days → a third).

**Which rate applies.** A date is "PH" when it is a public holiday (then only periods with `ph` match), otherwise its
weekday. A range past midnight belongs to its start day. Where periods overlap, the first with Takes Priority wins,
otherwise the first in the list. No period → S$0.

**Which runs are paid (Earnings).** Runs the driver drives on an own bus in the month. Completed (ended, or past their end
time) and with no issue raised → paid; issue → held; cancelled, skipped, upcoming → nothing. Hourly runs (disposal, or trips
priced by the hour) are paid by the hour at the rate plan's per-hour rate; others by trip value × per-trip rate. The vehicle
type is the driver's assigned type that day, else the type of the run's bus (by seats). School route runs under a route
retainer count as trips and are paid by the retainer (one per route driven in the month, by its length band).

**The scheme rules** follow the prototype: included trips (basic / monthly minimum / shift), on-top days, guarantee top-up,
after-guarantee boost, daily volume tiers (by the trip's number in the day), weekly targets (Monday–Sunday weeks inside the
month), monthly targets, the rejection penalty (simulator only: rejected jobs are typed in), the route retainer.

## 10. Not built yet

- Rejected jobs from real data: the driver app has no offers to reject yet, so the rejection penalty works only in the
  Salary Simulator.
- Quarterly / half-yearly / yearly bonuses, bonuses paid months later or in split payments.
- Driver app: bonus sign-up, redeeming rewards, the driver's own statement.
- Payroll: payslips, CPF, allowances and deductions, bank export, maker-checker for driver pay.
- Shifts that run past midnight; partial weeks at the start and end of a month for weekly targets (as in the prototype).

## 11. Changes to existing endpoints (02/11/2026)

| Endpoint | Before | Now |
| --- | --- | --- |
| `POST` / `DELETE /occurrences/:id/issue` | Always allowed on a done run | `422` "Driver pay for <Month> is confirmed. Reopen it in HR, Earnings first" once the driver's month is confirmed |
