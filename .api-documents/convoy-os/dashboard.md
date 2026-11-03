# Dashboard — API Guide

The Dashboard (rail icon `dashboard`, the Company Dashboard): widgets in four sections — Operations, Fleet and People,
Money, Clients — on up to 6 pages of an 8-column grid that each user arranges (drag, resize, add from the tray, remove).
Conventions are in [README.md](../README.md); paths start with `/api/v1`. Everyone in the company sees the Dashboard; Money
widgets follow permissions. A Convoy Admin can read but not save a layout.

## Contents

1. [Widgets and layout](#1-widgets-and-layout)
2. [Figures](#2-figures)

---

## 1. Widgets and layout

| Action | Call |
| --- | --- |
| The widgets this user may see (tray, sections, default sizes) | `GET /dashboard/widgets` |
| The user's layout | `GET /dashboard/layout` |
| Save the layout (after editing) | `PUT /dashboard/layout { pages: [...] }` |
| Reset to the default layout | `DELETE /dashboard/layout` |

Widgets: `{ sections [{ key, title }], widgets [{ key, section, title, icon, page, link, cols, rows }], cols: 8, max_pages: 6 }`.
`page` / `link` = where the widget's link opens ("Ops Control", "Vehicles", …).

| Key | Title | Who sees it |
| --- | --- | --- |
| `otp`, `late`, `today`, `unas`, `alerts`, `compl` | On-Time Starts, Late Starts and Missed Pick-ups, Trips, Unassigned Trips, Open Ops Control Alerts, Complaints and Incidents | Everyone |
| `util`, `off`, `docs`, `duty`, `noshow` | Fleet Utilisation, Vehicles Off the Road, Documents Expiring, Drivers, Driver No-Shows | Everyone |
| `rev` | Revenue | `finance`, `finview` or `vehfin` |
| `profit`, `topbot`, `loans` | Fleet Profit, Vehicles by Profit, Loan Instalments | `vehfin` |
| `coll`, `opp` | Collections, Operator Payments | `finance` or `finview` |
| `clotp`, `clrisk` | On-Time Starts by Client, Clients at Risk | Everyone |

Layout: `{ pages: [{ name, items: [{ widget, x, y, cols, rows }] }], saved, updated_at }` — `saved: false` = the default
(one "Overview" page with every widget the user may see). Save sends the whole layout; widgets the user may not see are
dropped. `422` "Pages can be 1 to 6", "Page 1 needs a name", "Page 1 has a widget out of the grid" (x + cols ≤ 8, rows 1–6).

## 2. Figures

`GET /dashboard?period=today|d7|d30|month|last_month&widgets[]=otp&widgets[]=rev` (no `widgets` = every widget the user may see):

```json
{ "period": { "key": "today", "from": "2026-11-02", "to": "2026-11-02", "compare": "same day last week" },
  "widgets": { "otp": { "available": true, "value": 50.0, "runs": 2, "on_time": 1, "change": null, "allowance": 5, "series": [...] },
               "noshow": { "available": false, "reason": "Comes with the Driver app" } } }
```

`period`: `today`, `d7` (7 days), `d30` (30 days), `month` (month to date), `last_month`; `change` is against `compare`.
Widgets that look at now or ahead have a `note` ("Shows today, so the period does not change it", …): show it under the widget.
`available: false` → show the `reason` in an empty widget (`noshow` Driver app, `coll` School Bus).

| Widget | Fields |
| --- | --- |
| `otp` | `value` (% runs with no stop later than the company's on-time minutes), `runs`, `on_time`, `change`, `allowance`, `series [{ date, pct }]` |
| `late` | `count` (late runs), `missed_pickups` (stops skipped), `list [{ occurrence_id, date, trip_label, client, plate, driver, late_minutes }]` |
| `today` | `total`, `completed`, `scheduled`, `cancelled`, `change` (runs) |
| `unas` | `count`, `list [{ occurrence_id, date, start_time, trip_label, client }]` — next 7 days |
| `alerts` | `count` (trips flagged now), `action`, `at_risk`, `note`, `list [{ occurrence_id, plate, title, message, severity: 2 Action \| 1 At Risk }]` — live, from [Ops Control](ops-control.md) |
| `compl` | `count`, `change`, `list [{ occurrence_id, date, trip_label, reason }]` (issues raised) |
| `util` | `value` (% hours on runs of hours available: 12 a day per own vehicle), `change`, `vehicles`, `hours_a_day`, `series` |
| `off` | `count`, `list [{ vehicle_id, plate, reason }]` (maintenance today, vehicle down) |
| `docs` | `count`, `expired`, `list [{ vehicle_id, plate, document: COE \\| Road Tax \\| Insurance, expires_on }]` — next 60 days |
| `duty` | `active`, `driving_today`, `without_bus`, `pending_invites` |
| `rev` | `value` (client price of runs not cancelled), `change`, `change_pct`, `series [{ date, amount }]` |
| `profit` | `revenue`, `cost`, `profit`, `margin`, `chart` (12 months) — this month, from Vehicle Financials |
| `topbot` | `top`, `bottom` `[{ vehicle_id, plate, profit, change }]` — this month vs last |
| `opp` | `waiting`, `waiting_items`, `approved_unpaid`, `next_pay { date, number, amount }` |
| `loans` | `due`, `count`, `overdue`, `overdue_amount`, `list [{ vehicle_id, plate, lender, due_on, amount, overdue }]` — this month and overdue |
| `clotp` | `target: 95`, `clients [{ client_id, name, runs, on_time }]` |
| `clrisk` | `count`, `list [{ client_id, name, reasons: ["On time 88.5%", "S$1200.00 overdue"] }]` |

Clicking an item opens its page (`page` of the widget; runs: Trip History / Scheduler by `occurrence_id`).
