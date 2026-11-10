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
| Keep the period picked / the page open (no Edit Layout) | `PATCH /dashboard/layout { period, page }` |
| Reset to the default layout | `DELETE /dashboard/layout` |

Widgets: `{ sections [{ key, title }], widgets [{ key, section, title, icon, page, link, cols, rows }], cols: 8, max_pages: 6 }`.
`page` = the page id the widget's link opens (`opsctl`, `trips`, `scheduler`, `triphist`, `vehicles`, `drivers`, …: the same
ids as [integration.md](../integration.md)); `link` = the link's label ("Ops Control", "Trip History", "Vehicles", …).

| Key | Title | Who sees it |
| --- | --- | --- |
| `otp`, `late`, `today`, `unas`, `alerts`, `compl` | On-Time Starts, Late Starts and Missed Pick-ups, Trips, Unassigned Trips, Open Ops Control Alerts, Complaints and Incidents | Everyone |
| `util`, `off`, `docs`, `duty`, `noshow` | Fleet Utilisation, Vehicles Off the Road, Documents Expiring, Drivers, Driver No-Shows | Everyone |
| `rev` | Revenue | `finance`, `finview` or `vehfin` |
| `profit`, `topbot`, `loans` | Fleet Profit, Vehicles by Profit, Loan Instalments | `vehfin` |
| `coll`, `opp` | Collections, Operator Payments | `finance` or `finview` |
| `clotp`, `clrisk` | On-Time Starts by Client, Clients at Risk | Everyone |

Layout: `{ pages: [{ name, items: [{ widget, x, y, cols, rows }] }], period, page, saved, updated_at }` — `period` (default `d7`,
as the prototype) is the period to open with, `page` the index of the page open last (0 = first); send them with `PATCH`
when the user picks a period or a page (`422` on an unknown period). `saved: false` = the default
(one "Overview" page with every widget the user may see); `saved: true` = a layout is stored for the user. The first `PATCH` (period / page) stores the default pages with it, so `saved` is also `true` after it; only `DELETE` resets it. `page` is an index (0 = first), not a widget id. Save sends the whole layout; widgets the user may not see are
dropped. `422` "Pages can be 1 to 6", "Page 1 needs a name", "Page 1 has a widget out of the grid" (x + cols ≤ 8, rows 1–6).

## 2. Figures

`GET /dashboard?period=today|d7|d30|month|last_month&widgets[]=otp&widgets[]=rev` (no `widgets` = every widget the user may see):

```json
{ "period": { "key": "today", "from": "2026-11-02", "to": "2026-11-02", "compare": "same day last week" },
  "widgets": { "otp": { "available": true, "value": 50.0, "runs": 2, "on_time": 1, "change": null, "allowance": 5, "series": [...] },
               "noshow": { "available": false, "reason": "No-shows are not recorded yet" } } }
```

`period`: `today`, `d7` (7 days), `d30` (30 days), `month` (month to date), `last_month`; `change` is against `compare`.
Widgets that look at now or ahead have a `note` ("Shows today, so the period does not change it", …): show it under the widget.
`available: false` → show the `reason` in an empty widget (only `noshow`: no-shows are not recorded anywhere yet).

| Widget | Fields |
| --- | --- |
| `otp` | `value` (% runs with no stop later than the company's on-time minutes), `runs`, `on_time`, `change`, `allowance`, `series [{ date, pct }]` |
| `late` | `count` (late runs), `missed_pickups` (stops skipped), `series [{ date, count }]` (late + missed a day), `list [{ occurrence_id, date, trip_label, client, plate, driver, late_minutes }]` |
| `today` | `total`, `completed`, `scheduled`, `cancelled`, `change` (runs), `running` (started, not ended), `still_to_run`, `average_a_day`, `busiest { date, count }`, `by_client [{ client_id, name, runs }]`, `series [{ date, count }]` — Today: "Right Now" Done / Running / Still to run; other periods: Summary + Busiest day |
| `unas` | `count`, `list [{ occurrence_id, date, start_time, trip_label, title, client, missing: bus \| driver \| both }]` — next 7 days: runs with no bus, or an own bus with no driver ("No bus" / "No driver" / "No bus or driver") |
| `alerts` | `count` (trips flagged now), `action`, `at_risk`, `note`, `list [{ occurrence_id, plate, title, message, severity: 2 Action \| 1 At Risk }]` — live, from [Ops Control](ops-control.md); `period { raised, escalated, avg_ack_seconds }` = "In the Period" (alerts raised in the period, escalated to the Ops Manager, average time to acknowledge; `null` when none was acknowledged) |
| `compl` | `count`, `change`, `list [{ occurrence_id, date, trip_label, reason }]` — runs in the period with an issue raised (Raise Issue on a run in the Scheduler drawer / Trip History; `reason` = its text), latest 5 |
| `util` | `value` (% hours on runs of hours available: 12 a day per own vehicle), `change`, `vehicles` (**a count**: own vehicles), `hours_a_day` (12), `series [{ date, pct }]` (one per day of the period) |
| `off` | `count`, `list [{ vehicle_id, plate, reason, kind, back_on }]` (maintenance today, vehicle down); `kind` = the maintenance kind (Service, Repair, Tyres, Inspection, Other) or "Replaced" (badge), `back_on` = "Back dd/mm" (the day after the visit / the replacement) |
| `docs` | `count`, `expired`, `list [{ vehicle_id, plate, document: COE \| Road Tax \| Insurance, expires_on }]` — next 60 days |
| `duty` | `active`, `driving_today`, `without_bus`, `pending_invites` |
| `rev` | `value` (client price of runs not cancelled), `change`, `change_pct`, `series [{ date, amount }]`, `month { revenue, cost, profit }` (this month from Vehicle Financials; `null` without `vehfin`) |
| `profit` | `revenue`, `cost`, `profit`, `margin`, `change` (on last month), `ytd` (profit of this year's months), `vehicles [{ vehicle_id, plate, profit }]` (By Vehicle, best first), `chart [{ month: "2026-10", revenue, cost, profit }]` (12 months to this month, oldest first) — this month, from Vehicle Financials |
| `topbot` | `top` (best 5), `bottom` (lowest 5, empty with 5 vehicles or fewer) `[{ vehicle_id, plate, profit, change }]` — this month vs last |
| `coll` | `bills`, `billed`, `collected`, `outstanding`, `not_paid` (bills not fully paid), `overdue` (amount), `overdue_bills`, `note` — School Bus bills of the schools the user may open, as of today (the `kpis` of [Finance › School Bus Collections](finance.md)); "Overdue" tile = `overdue` + "`overdue_bills` bills past due and grace" |
| `opp` | `waiting`, `waiting_items`, `waiting_operators` ("from N operators"), `approved_unpaid`, `approved_unpaid_batches` ("N batch"), `next_pay { date, number, amount }` |
| `loans` | `due`, `count`, `overdue`, `overdue_amount`, `list [{ vehicle_id, plate, lender, due_on, amount, overdue }]` — this month and overdue |
| `clotp` | `target: 95`, `clients [{ client_id, name, runs, on_time, change }]` (`change` = points on the period before: "+1.2 pts on …") — also the source for the `otp` widget's "By Client" list (`on_time` = % of `runs`) |
| `clrisk` | `count`, `list [{ client_id, name, reasons: ["On time 88.5% (-2.1 pts)", "On time 91.0% (+0.7 pts)", "S$1200.00 overdue"], on_time, change, badge: Below Target \| Falling \| Overdue }]` — below 95 %, falling 1 point or more on the period before, or with overdue invoices |

Clicking an item opens its page (`page` of the widget; runs: Trip History / Scheduler by `occurrence_id`).
