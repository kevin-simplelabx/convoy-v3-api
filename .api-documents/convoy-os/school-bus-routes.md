# School Bus › Route Plans & Feasibility Studies — API Guide

Route Plans is the third mode of the School Bus map screen, after Stop Library and Stop Assignment
([school-bus-stops.md](school-bus-stops.md)). Feasibility Studies is a company-level sandbox. Conventions are in
[README.md](../README.md); paths start with `/api/v1`.

The **routing engine** (Convoy Pathfinder, the prototype's engine unchanged) runs in the routing service on the server.
The FE never calls it. Rails builds its input from the database, runs it in the background, and stores every run.
Road travel times come from OSRM (`router.project-osrm.org`, as in the prototype). The engine refuses to plan without
them ("Road travel times could not be loaded…").

**Permissions**

| What | Who |
| --- | --- |
| Read plans and studies | Every company user (only the schools they may open) |
| Run Routing, edit plans, adopt, Feasibility Studies | `plans` |
| Route prices and Route Charges | `finance` |

## Contents

1. [Parameters](#1-parameters)
2. [Run Routing](#2-run-routing)
3. [Plans](#3-plans)
4. [Hand edits and Route Again](#4-hand-edits-and-route-again)
5. [Adopt Plan and rider assignments](#5-adopt-plan-and-rider-assignments)
6. [Route bus and money](#6-route-bus-and-money)
7. [Feasibility Studies](#7-feasibility-studies)
8. [Front-end only and not built yet](#8-front-end-only-and-not-built-yet)

---

## 1. Parameters

| Call | What it does |
| --- | --- |
| `GET /routing/settings` | The engine's metadata and the company's saved parameters (below) |
| `PUT /routing/settings { params: {…} }` | Save Parameters. `{}` resets to Convoy Defaults |

The `GET` response:

```json
{ "defaults": { "session": "AM", "hardCap": 75, "targetCap": 50, "amTarget": "07:20", "effort": "high", "types": [ … ], … },
  "types": [ { "type": "LARGE_45", "label": "45-seater", "seats": 45, "headroom": 0.1, "floorPct": 0.6, "on": true, "max": null } ],
  "presets": { "FEWEST_BUSES": { "label": "Fewest Buses", "desc": "…" }, "BALANCED": {…}, "SHORTEST_RIDES": {…} },
  "effort": { "low": { "label": "Low", "runs": 1, "sec": 15 }, … }, "effort_keys": ["low", …], "max_effort": "high",
  "engines": { "SWEEP_ACO": "Convoy Pathfinder", "RUIN_RECREATE": "Ruin & Recreate only (jsprit method)" },
  "params": { "preset": "BALANCED", "effort": "high" } }
```

- `defaults` comes from the engine. `params` holds the company's overrides; show `defaults` merged with `params`.
- The Parameters panel edits engine parameters by their engine names (`hardCap`, `amTarget`, `baseDwell`, `perStudent`,
  `types[].on|headroom|floorPct|max`, `stability`, `effort`, `preset`, …).
- `max_effort` caps the effort levels the company may pick.
- Each run keeps a copy of the parameters it used (plan `params`).

## 2. Run Routing

`POST /schools/:id/routing_runs { session: am|pm|asa, date, params: { preset, effort, … } }` returns **202** with the
run. Poll `GET /routing_runs/:id` until `status` is `done` or `failed` (it takes up to the effort time: 15–120 s).

```json
{ "id": 9, "school_id": 3, "session": "am", "plan_date": "2026-11-02", "status": "queued" | "running" | "done" | "failed",
  "error": null, "riders": 65, "stops": 7, "no_stop": [ { "rid": "S-1044", "name": "Tan Wei Ling" } ], "conflicts": [], "ms": 41250, "plan_id": 21,
  "progress": { "step": "solving", "frac": 0.42, "run": 2, "runs": 4, "elapsed": 18400, "left": 31600,
                "work": { "phase": "Swap and relocate pass", "i": 3, "n": 9, "extra": "Best 12,345 pts", "evals": 184230 },
                "log": [ { "run": 1, "phase": "Sweep start angle", "i": 24, "n": 24 } ] }, … }
```

**Loader** (poll about every second): `progress` while `running` (`null` when the routing service cannot tell, e.g.
restarted; keep polling), `{ step: "done", frac: 1, work: { evals } }` when done, `null` otherwise.

- `step`: `queued`, `matrix` → "Step 1 of 2 | Loading road travel times" (bar 4 %), `solving` → "Step 2 of 2 | Searching for
  the best routes | Run `run` of `runs` | `elapsed`/1000 s" (bar 10 + 90 × `frac` %).
- Time left: from `frac` > 0.04, min(elapsed / frac × (1 − frac), `left`) → "About N s left", "Almost done" at 1 s or less,
  else "Estimating time left" (ms values).
- "Route options checked: `work.evals`"; the current phase "`work.phase` `work.i` of `work.n`" + `work.extra`; `log` = the
  last 4 phases ("Run k | phase", "i of n").

**What the engine is given:**

- The riders on the Plan For `date` who ride the session (AM, PM, or CCA days for ASA).
- Each rider whose PUDO points all belong to **one stop** (from Stop Assignment), grouped by that stop with the stop's
  points the school uses.
- Riders with no stop are listed in `no_stop`; riders with more than one stop are listed in `conflicts`, both as
  `[{ rid, name }]`. Neither goes into the run; the plan lists each of them in `unassigned` (reason `RIDER_NO_STOP` /
  `RIDER_IN_CONFLICT`, `label` = the rider's name). Show "N riders need a stop" / "N riders have more than one stop".
- The current plan of the session, for "Keep Current".
- The company's parameters, the run's `params`, the session, and the school's bus attendant rule.

| Result | Meaning |
| --- | --- |
| `done`, plan with no routes | No rider of the session has a stop: the run still goes (as the prototype) and every rider is in `unassigned` |
| `failed` with the engine's message | The engine refused, for example no road times |
| `failed` with "The routing service is not available…" | The routing service could not be reached |
| `done` | `plan_id` is the new **draft** plan |

## 3. Plans

| Call | What it does |
| --- | --- |
| `GET /schools/:id/plans?session=am` | The plan list, newest first |
| `GET /plans/:id` | One plan (fields below) |
| `GET /schools/:id/routes?date=` | The routes of the plans in use that day (default today), AM / PM / CCA by number: `[{ id, label, session, plan_id, riders_count, start_time, end_time, vehicle_plate }]`. A light list for pickers (School route notices, [scheduler.md § 12](scheduler.md#12-notice-form)) |
| `POST /schools/:id/plans { session, date }` | **Draw Routes** (prototype `createManualPlan`): an empty plan (`source: "manual"`) for the Plan For `date` (default today, `effective_from`). Every rider of the session is in `unassigned`: riders at a stop by stop (`NOT_ROUTED`, `label` = stop code), riders with no stop / more than one on their own (`RIDER_NO_STOP` / `RIDER_IN_CONFLICT`, `label` = name). `summary` (no routes, all riders unassigned) and `params` (engine defaults + the company's + session) are set. `422` "Date must look like 2026-11-02" |
| `PATCH /plans/:id { plan: { name, effective_from, effective_to } }` | Rename, or change the run dates |
| `DELETE /plans/:id` | Delete a draft (only drafts) |
| `POST /plans/:id/comments { body }` / `DELETE /plans/:id/comments/:comment_id` | Comments |
| `GET /plans/:id/compare?with=:other_id` | Compare Plans: the engine's comparison, with names `a` (this plan) / `b` (`with`) |

```json
{ "id": 21, "name": "AM Plan 3", "session": "am", "source": "engine" | "manual", "priority": "BALANCED", "state": "draft" | "scheduled" | "current" | "replaced",
  "effective_from": "2026-11-02", "effective_to": null, "created_at": "…", "created_by": "…", "adopted_at": null,
  "routes_count": 4, "riders": 65, "bus_mix": { "MEDIUM_23": 3, "SMALL_13": 1 }, "unassigned_count": 0, "comments_count": 1, "out_of_date": false,
  "summary": { "routes": 4, "riders": 65, "assigned": 65, "unassigned": 0, "byType": { "MEDIUM_23": 3, "SMALL_13": 1 }, "avgJourney": 38.2, "maxJourney": 52.4,
               "avgFill": 0.71, "fixed": 1920, "run": 140.5, "overtime": 12.0, "floor": 0, "stability": 0, "total": 2072.5, "slots": { "07:15": 2, "07:20": 2 } },
  "params": {…}, "unassigned": [ { "gid": "rm:S-1001", "riders": ["S-1001"], "n": 1, "reason": "ADMIN_REMOVED", "label": "Tan Wei Ling" } ],
  "routing_run": { "id": 9, "no_stop": [ { "rid": "S-1044", "name": "Lim Jun Hao" } ], "conflicts": [], "ms": 41250 },
  "routes": [ { "id": 51, "number": 1, "label": "AM 1", "route_key": "R01", "bus_type": "MEDIUM_23", "seats": 23, "student_seats": 23, "capacity": 20,
                "floor": 12, "fill": 0.8, "span_seconds": 2700, "ride_minutes": 420, "badges": ["Buffer used"], "locked": false, "hidden": false,
                "edited": false, "manual": false, "vias": [], "riders_count": 18, "start_time": "06:35", "end_time": "07:20",
                "attendant": null, "regular_vehicle_id": 12, "vehicles": [ { "id": 3, "from": "2026-11-02", "vehicle_id": 12, "plate": "PD6604E", "by": "Marcus Lim" } ],
                "prices": [], "charges": [],
                "stops": [ { "id": 301, "position": 0, "name": "Blk 101 Bedok North", "lat": 1.3204, "lng": 103.9203, "time": "06:35",
                             "riders_count": 9, "dwell_seconds": 75, "stop_id": 12, "stop_code": "BDSZ03-0001", "stop_point_id": 31,
                             "pudo_code": "BDSZ03-0001A", "riders": ["S-1001", "…"] } ] } ],
  "comments": [ { "id": 1, "body": "…", "by": "…", "at": "…" } ] }
```

**Compare Plans** response. Pairs are `[a, b]` (this plan, the other one):

```json
{ "data": { "a": "AM Plan 3", "b": "AM Plan 2",
            "byType": [ { "type": "MEDIUM_23", "a": 3, "b": 4 }, { "type": "SMALL_13", "a": 1, "b": 0 } ],
            "routes": [4, 4], "avg": [38.2, 41.0], "max": [52.4, 55.1], "cost": [412.6, 430.0], "fill": [0.71, 0.66], "unassigned": [0, 2],
            "moved": 6, "shifted": 11, "movedList": ["S-1001", "S-1014"] } }
```

`avg` / `max` = journey minutes, `cost` = the engine's cost figure, `fill` = average fill (0–1), `moved` = riders on another
stop, `shifted` = riders whose time changes by more than 5 minutes. `503`-like `422` "The routing service is not available (…)".

**State badges:**

| `state` | Meaning |
| --- | --- |
| `draft` | Not adopted |
| `scheduled` | Adopted from a later date |
| `current` | In use now |
| `replaced` | A later plan took over |

**Other badges and figures:**

- `out_of_date: true` means the school's stops or catchments changed after the plan was made. Show "Out of Date" and
  offer to run again.
- KPIs, the bus mix and slots come from `summary`, the same keys as the engine's (also after hand edits, Route Again and
  Draw Routes): `riders`, `assigned`, `unassigned`, `routes`, `byType`, `avgJourney` / `maxJourney` (min), `avgFill`
  (0–1), the optimisation score by part `fixed` (buses), `run` (running), `overtime`, `floor` (below min fill),
  `stability`, `total` = fixed + run + overtime + floor ("Optimisation score N pts"), and `slots` = buses per 5-minute
  slot (`"HH:MM"`: arrival at school for AM, departure for PM / CCA).
- The Students list: each route's `stops[].riders` (rider IDs) with the stop and time.
- The Unassigned list is `unassigned`: `[{ gid, riders: [rid], n, reason, label }]`. `reason` is a code; label it as the
  prototype (`REASONS`): `NOT_ROUTED` "Not on a route yet", `ADMIN_REMOVED` "Removed by admin", `RIDER_NO_STOP` "No stop
  covers this rider", `RIDER_IN_CONFLICT` "Covered by more than one stop", `HARD_CAP_UNREACHABLE` "Too far from school for
  the hard journey cap", `NO_FEASIBLE_ROUTE` "No bus type fits the limits", `NO_BUS_TYPE_FOR_POINT` "Point only allows bus
  sizes that are turned off", `FLEET_LIMIT` "Over the Max Buses limit". `label` = stop code (groups) or rider name. Tone
  "danger" when any reason is not `NOT_ROUTED` / `ADMIN_REMOVED`.

**Route fields:**

- `badges`: strings from the engine, shown as chips: `Edited`, `Over capacity`, `Buffer used`, `Over max journey`,
  `Over soft cap`, `Underfilled`, `Loop-back` (AM) / `Not inside-out` (PM) and the like. A route drawn by hand
  (`manual: true`) leads with `Manual` instead of `Edited`.
- `attendant`: the Bus Attendant on the route `{ id, name, phone }`, or `null`.
- `vehicles`: the regular bus history `[{ from, vehicle_id, plate }]` (`vehicle_id: null` = no bus from that date).
- `prices` (the operator's monthly price history, [§ 6](#6-route-bus-and-money)):
  `[{ "id": 8, "effective_from": "2026-11-01", "mode": "fixed", "monthly": "1500.0", "base_price": null, "riders_included": null, "per_rider": null, "by": "Marcus Lim" }]`
  or `mode: "rider"` with `base_price`, `riders_included`, `per_rider` (`monthly: null`). Empty = the school's default for the bus size.
- `pay_setup`: `{ "attendant_required": null, "attendant_provided_by": null, "attendant_price": null, "pay_to": null, "pay_to_operator": null }`.
  `null` = the school's default (Bus Attendants: `needed_sizes`, `provided_by`, and the BA prices per bus size): show "School
  default", else "Changed for this route". Sending the school's default value saves `null`; changing BA Provided By clears
  the BA price; an empty BA price = the default price for the size and provider. The BA price is added to the route's
  monthly price (operator pay, "Incl. S$x BA (ours / theirs)"); it does not change school or family bills.
  Paid To (only for a route with **no bus**; with a bus, the bus's operator is paid: "<Operator> | owns <plate>"): `pay_to`
  `own` ("<Company> (own buses)", not paid), `operator` (+ `pay_to_operator { id, name }`), or `null` ("Not assigned"); the
  pay run shows "No bus, set by hand". These values go with the routes when a plan is copied from a date.
- `charges` (Route Charges on this route): `[{ "id": 4, "starts_on": "2026-11-02", "kind": "amt", "value": "150.0", "reason": "Long route", "note": null, "status": "ok" }]`;
  `kind` `amt` (S$) / `pct` (% of the rate), `status` `ok` / `check` (carried from an old plan, to confirm).

### Plan Estimate

`GET /plans/:id/estimate?month=2026-11` (`month` = the Plan For month; `finance` or `finview`, else `403`: hide the line) →
the plan card's Est. Revenue / Operator Cost / Gross Profit and the Details dialog "Estimate for <Mon YYYY>":

```json
{ "month": "2027-01-01", "title": "Estimate for Jan 2027", "sub": "Term 1 AM | Jan 2027", "paid_month": true,
  "riders": 3, "operator_cost": "3000.0", "unpriced": 0,
  "routes": [ { "route_id": 41, "label": "AM 1", "bus_type": "MEDIUM_23", "amount": "3000.0" } ],
  "revenue": "210.0", "to_collect": "1260.0", "gross_profit": "-2790.0", "margin_pct": -1328.6,
  "basis": "distance", "two_way": 3, "no_fare": 0,
  "bands": [ { "label": "0 to 3 km", "tier_id": 7, "riders": 3, "one_way": 0, "two_way": 3, "share": 100.0, "revenue": "210.0", "to_collect": "1260.0" } ],
  "pl": { "one_way": { "riders": 0, "amount": "0.0" }, "two_way": { "riders": 3, "total": "420.0", "half": "210.0" } },
  "notes": [ "Revenue is a year of fares spread over 12 months. To Collect is what is billed in Jan 2027, when a term starts. Two-way riders count half here, half in the other session" ] }
```

- A month Operator Pay does not pay: `{ paid_month: false, note: "<Mon YYYY> is not a paid month" }` (cards show it).
- Operator Cost = every route of the plan for the whole month at its price (`routes[].amount`; `null` = "Not priced";
  `unpriced` routes add the note "N routes not priced, so cost is low").
- Revenue (as the prototype): each rider of the plan on the rider list pays their Bus Fares fare (tier by straight-line
  distance or zone; two-way when the rider data has both AM and PM): Revenue = the yearly fare / 12 (+ the month's one-off
  charges), To Collect = what is billed in the month. Two-way riders count half (the other half is on the plan of the
  other session). `null` with `revenue_none`: "No academic year covers <Mon>", "Bus Fares for AY <key> not saved yet",
  "School is billed per bus for the whole fleet, so revenue is on the Dashboard".
- `bands` = "Riders by Distance" / "Riders by Zone" (`basis`): Band, Riders, Share (%), Fare Type ("`two_way` two-way |
  `one_way` one-way"), Revenue, To Collect (this plan's share); a "No fare set" band (`no_fare: true`) for riders with no
  fare. `pl` = the Profit and Loss lines: "Fares from N one-way riders, in full", "Half of the two-way fares from N riders
  (S$total in total)" (+ `half`).
- `margin_pct` = gross profit ÷ revenue, a **number** with 1 decimal (`null` when revenue is 0). The School Dashboard › Finance `kpis.margin_pct` is a number too.

## 4. Hand edits and Route Again

Each edit is re-timed by the engine on the server. Every call returns the whole plan, with the route's new times,
`badges` (including "Edited") and `summary`.

| Call | Tool |
| --- | --- |
| `PUT /routes/:id/stops { stops: [{ stop_point_id, riders: [rid] }], vias: [[[lat, lng], …], …] }` | Reorder stops, move a stop or a rider here, add or remove riders, via points (one list per leg) |
| `POST /plans/:plan_id/routes { bus_type, stops: [...] }` | New Route (R): the route is locked and badged "Manual" |
| `PATCH /routes/:id { route: { bus_type, locked, hidden, attendant_id } }` | Bus Type, Lock, Hide, Attendant |
| `DELETE /routes/:id` | Delete a route |
| `POST /routes/:id/reset` | Reset Route to the engine's version |
| `POST /routes/:id/optimise` | Optimise: re-order the route's stops to cut passenger ride time and journey (disabled under 2 stops) |
| `POST /plans/:plan_id/optimise` | Optimise All: re-order the stops inside every route (riders stay on their routes) |
| `POST /plans/:plan_id/reset` | Reset All: routes drawn by hand go, every route goes back to the engine's result, and so does the unassigned list |
| `POST /plans/:plan_id/route_again { params: {…}, fleet: { MEDIUM_23: 2, SMALL_13: 0 } }` | Route Again |

Rules:

- A rider placed on a route leaves any other route of the plan. A route left without riders goes.
- A rider taken off a route (removed from its stops, route deleted, Reset Route) goes to `unassigned` on their own:
  `{ gid: "rm:<rid>", riders: [rid], n: 1, reason: "ADMIN_REMOVED", label: <rider name> }`.
- A route drawn by hand cannot be reset.
- Reset Route and Reset All keep the bus size picked with Bus Type (stops and times go back to the engine's), as the
  prototype.
- Routes of an **adopted** plan can be edited (their runs on the Scheduler follow) but not deleted ("Make a new plan to
  remove a route").

**Optimise / Optimise All / Reset All** return the plan and `meta.message`, the toast as the prototype words it:
"AM 1 re-ordered. Journey 30 to 25 min, avg ride 6 to 5 min", "AM 1 is already in the best order for its passengers",
"2 routes re-ordered (AM 1, AM 3). 9 bus-min saved", "Every route is already in its best stop order", "All manual edits
cleared, including routes drawn by hand". The best order is the one that costs least for the bus and its passengers (up
to 7 stops every order is tried); re-ordered routes are marked edited; via points stay only on legs that still join the
same stops. On an adopted plan the runs follow (runs already started stay). Reset All needs an engine result (`422` "This
plan was not made by the routing engine, so there is nothing to reset to"); on an adopted plan a route drawn by hand cannot
be removed (`422` "… is in an adopted plan and runs on the Scheduler. Make a new plan to remove a route"). Undo is not
in the API yet.

**Route Again** plans again every rider not on a locked route (draft plans only). Its routes take the numbers the
locked routes leave free (R01, R02 …): the unlocked route with that number is **updated in place** (same `id`; its bus
history, prices, charges and attendant stay; hand edits, via points and Hide are cleared), unlocked routes left over are
deleted, and extra routes are added. Locked routes stay as they are and can still be reset. `summary`, `params` and
`unassigned` come from the new run.

- `fleet` caps buses of a size; 0 turns a size off.
- It returns 202 `{ id, status, kind: "again", plan_id }`. Poll `GET /routing_runs/:id`, then reload the plan.
- 422 "Every rider is on a locked route. Unlock a route to route again".
- 422 "Make a new plan to route again" on an adopted plan (scheduled / current / replaced). If the plan is adopted while
  the run is going, the run ends `failed` with that message.

## 5. Adopt Plan and rider assignments

| Call | What it does |
| --- | --- |
| `POST /plans/:id/adopt { from }` | Adopt the plan from a date |
| `POST /plans/:id/cancel_adoption` | A scheduled plan goes back to draft; the plan it would have replaced runs on |

**Adopt rules:**

- `from` must be the 1st of this month or later, and not before the current plan's start.
- The plan runs on the **Scheduler** from that date: `scheduled` before the date, `current` from it.
- The plan of the same session in use on that date ends the day before. A plan scheduled after the date is cancelled.
- From the very day the current plan started, the current plan is taken out of use as if it never ran: it goes back to
  `draft` (its Route Charges move to the new plan, its runs leave the Scheduler; runs already started stay).
- Runs are re-synced in the background.
- `DELETE /plans/:id` (draft) and deleting routes clean everything on the routes; a route with runs on the Scheduler
  that started or have records (Driver app, notes, reports) cannot go: `422` "AM 1 has runs on the Scheduler that started
  or have records, so it cannot be removed".

| Error (422) | Cause |
| --- | --- |
| "Pick a date from the 1st of this month" | `from` before the 1st of this month |
| "AM Plan 1 was only adopted on 2 Nov 2026. Pick that day or later" | `from` before the current plan's start |
| "The plan has no routes" | Empty plan |
| "This plan is already adopted" | Plan already in use |

**Rider assignments.** An **AM** plan assigns each of its riders the PUDO point they use **when it starts** (prototype
`promotePlan`): at once when adopted from today or an earlier day, else on its start day (the daily job, about 01:30).
Scheduling a plan for a later date changes nothing yet, so Cancel has nothing to undo; moving a scheduled plan's start to
today with `PATCH /plans/:id` assigns at once. Stop Assignment (`GET /schools/:id/stop_assignment`) then shows `assigned`
for each rider, and `meta.counts.assigned` / `notified`. Riders set by hand keep their point.

| Call | Tool |
| --- | --- |
| `POST /schools/:id/rider_assignments { rids: [], stop_point_id }` | Set as assigned (by hand) |
| `POST /schools/:id/rider_assignments/remove { rids: [] }` | Unassign: the riders lose their PUDO. Returns `{ removed }`; `422` "None of these riders have a PUDO" |
| `POST /schools/:id/rider_assignments/move { stop_point_id }` | Move All Riders Here: the riders assigned to the other points of that stop move to this one. Returns `{ moved }` |
| `POST /schools/:id/rider_assignments/notify` | Notify: returns `{ notified: n }`. Show "Assigned PUDO sent to N riders". Recorded only; sending comes with the app |

## 6. Route bus and money

| Call | What it does |
| --- | --- |
| `POST /routes/:id/vehicle { vehicle_id, from }` | The regular bus from a date (empty `vehicle_id` = no bus). The history is in route `vehicles`. Short-term replacement buses: the drawer's Replacement Buses (below), or drag the run on the Scheduler (`POST /occurrences/:id/move`, `scope: range`, [scheduler § 3.2](scheduler.md#32-confirm-post-occurrencesidmove)) |
| `GET /routes/:id/replacements` | Replacement Buses: `[{ id, starts_on, ends_on, vehicle { id, plate, seats }, company, arranged_by: operator\|us, daily_rate, deduct_from_operator, reason, school_days, by, created_at }]`, latest first |
| `POST /routes/:id/replacements { from, to, vehicle_id \| plate + (operator_id \| company), arranged_by: operator\|us, daily_rate, deduct, reason }` | Add Replacement → `201` the list. When the bus is the route's own regular bus nothing is added: the dates are cut out of any replacement there, so those days go back to the regular bus and the list can come back empty (not an error; the prototype says "Back on its regular bus"). "Bus not in our list": `plate` with a Transport Operator (`operator_id`: the bus joins its fleet) or a company typed in (`company`: added as an External Vehicle, within the external vehicle limit); a plate the company already has is that bus. `422`: "Pick the start date", "End date is before the start date", "Enter the replacement bus plate", "Enter the company that owns the bus", "Enter the cost per day" (arranged by us) |
| `DELETE /route_replacements/:id` | Remove a replacement (`204`); the regular bus comes back on runs not started yet |
| `PATCH /routes/:id/pay_setup { attendant_required, attendant_provided_by: operator\|us, attendant_price, pay_to: own\|operator\|"", pay_to_operator_id }` | The price card's Bus Attendant Required / BA Provided By / BA Price and, for a route with no bus, Paid To (plans or finance; `attendant_price` needs finance: `422` "Needs the Fares & Billing permission"). Returns `pay_setup` |
| `DELETE /routes/:route_id/vehicle_changes/:id` | Bus History "Remove this change" (not the first one: `422` "The first bus of the route cannot be removed. Change it instead"); returns `{ vehicles, prices }`, the runs follow |
| `DELETE /routes/:route_id/prices/:id` | Remove a price from the history (`finance`); returns `{ vehicles, prices }` |
| `POST /routes/:id/prices { effective_from, mode: fixed\|rider, monthly \| base_price + riders_included + per_rider }` | The operator's monthly price from a date (`finance`). The history is in route `prices`. With no price, the school's default for the bus size applies (Operator Pay) |
| `GET /schools/:id/route_charges?date=` | Route Charges: each AM / PM run of the adopted plans, only when the school is billed per bus on `date` (below) |
| `POST /routes/:id/charges { starts_on, kind: amt\|pct, value, reason, note }` | A charge change from a date (the 1st of this month or later; it can be mid-month). `value: 0` ends the charge. `reason`: Long route, Peak timing, ERP cover, Extra stop or Other. Only on a route of an AM / PM plan in use (`422` "Route Charges are for runs of an AM or PM plan in use") and when the school is billed per bus on `starts_on` (`422` "The school is not billed per bus") |
| `PATCH /route_charges/:id { school_route_id, status: "ok" }` | Confirm a carried charge (`status: "ok"`), or move it to another run: `school_route_id` = the **route `id`** (`runs[].route_id`) of an AM / PM plan in use (`422` "Pick a run of an AM or PM plan in use"), of the same session as the charge's run (`422` "Pick a run of the AM plan"). Both can go in one call. `422` "The school is not billed per bus" when not billed per bus on the charge's date |
| `DELETE /route_charges/:id` | Remove a change that has not started, or drop a carried charge |

`GET /schools/:id/route_charges` returns:

```json
{ "per_bus": true,
  "runs": [ { "route_id": 51, "plan_id": 21, "session": "am", "label": "AM 1", "bus_type": "MEDIUM_23", "rate": "1500.0", "extra": "150.0", "total": "1650.0",
              "now": { "id": 4, "starts_on": "2026-11-02", "kind": "amt", "value": "150.0", "reason": "Long route", "status": "ok", … } | null,
              "next": {…} | null, "history": [...] } ],
  "unmatched": [ …charges with no run… ], "to_check": 1 }
```

**Billed per bus** (prototype `F.locked && payer === 'bus'`): the academic year covering the date has its Bus Fares
saved and locked with `payer: "bus"`. `per_bus` is `true` then, even before any bus rate is set (`rate: null`). Otherwise
the answer is `{ "per_bus": false, "runs": [], "unmatched": [], "to_check": 0 }`: hide the Route Charges card.

When a new plan is adopted, each old run's charge moves to the new run that shares the most riders (then stops) with it,
with `status: "check"`. A charge with no match is listed in `unmatched` ("Charges With No Matching Run").

## 7. Feasibility Studies

Feasibility Studies are a sandbox: nothing touches real riders, stops or plans. Permission: **`plans`** (the menu's page
id is `feas`, see [integration.md](../integration.md); the permission is `plans`). Reading needs it too, since studies hold
bus prices and break-even: without `plans` every call is `403` (hide the menu).

| Call | What it does |
| --- | --- |
| `GET /feasibility_studies` | The studies: `id`, `name`, `school`, `students`, `scenarios`, `updated_at`, `best` (fewest runs: `buses`, `runs`, `total`, `break_even`) |
| `POST /feasibility_studies { study: { name, school_mode: existing\|prospect, school_id \| prospect_name + prospect_postal, pickup: door\|lib, walk_m } }` | New study. Every field is checked first (`422` with `details` for each wrong field: empty `name`, a `prospect_postal` that is not 6 digits, `walk_m` below 0), then a prospect's postal code is placed on OneMap (`422` "Postal code not found on OneMap"). The study starts with "Scenario 1" and default `bus_prices` for every bus size (SGD per month: 45-seater 5200, 40-seater 4800, 23-seater 3600, 13-seater 2400, 9-seater 2000; attendant add-on 900 on the large buses, 450 on the others) unless the body sends `bus_prices` |
| `GET /feasibility_studies/:id` | The study, with its scenarios worked out (below) |
| `DELETE /feasibility_studies/:id` | Delete the study (`204`) |
| `PATCH /feasibility_studies/:id { study: {…}, bus_prices: [{ bus_type, monthly, attendant }], fare_tiers: [{ max_km, fare, one_way_fare }] }` | Change the study, its bus prices (monthly per bus size plus the attendant add-on) or its fare tiers (monthly; the last tier has no `max_km`) |
| `POST /feasibility_studies/:id/rows { text }` | Paste or upload students. Each postal code is then looked up on OneMap in the background: poll the study until `geocode.pending` is `0` |
| `POST /feasibility_studies/:id/geocode` | Check Again: looks up the postal codes OneMap has not answered yet (`202`, the study). Codes already `found` / `not_found` are not asked again |
| `DELETE /feasibility_studies/:id/rows` | Clear the students |
| `DELETE /feasibility_studies/:id/rows/:row_id` | Remove one line of students (results go stale); returns the study |
| `POST /feasibility_studies/:id/copy` | Copy Study: "<name> copy" with its students, bus prices, fare tiers and scenarios, without results (`201`, the new study) |
| `POST /feasibility_studies/:id/scenarios { from_id }` | Add Scenario, or copy one |
| `PATCH /feasibility_scenarios/:id { scenario: { name, sizes: ["MEDIUM_23"], attendant: STATUTORY\|ALL_BUSES, hard_cap, target_cap, margin_pct, extra_buses: { AM: { SMALL_13: 1 } }, params: {…} } }` | Change a scenario. `hard_cap` and `target_cap` are whole numbers above 0, `margin_pct` 0–90, `sizes` bus sizes of the engine (`[]` is allowed while editing; Run then asks for one), else `422`. `params` blank = company parameters; the keys are listed under [Scenario parameters](#scenario-parameters) |
| `DELETE /feasibility_scenarios/:id` | Delete a scenario (keep at least one) |
| `POST /feasibility_scenarios/:id/run` | Plans AM and PM in the background (`202`). What the screen can check is answered at once with `422` and no run starts: "Set the school location first", "Add student postal codes first", "Pick at least one bus size". Poll the study until the scenario's `status` is `done` or `failed` (with `error`, e.g. "2 postal codes could not be checked on OneMap. Use Check Again, then run") |
| `POST /feasibility_scenarios/:id/use_suggested_fares` | The study's tiers take the suggested fares |
| `GET /feasibility_studies/fare_source?school_id=` | A school's locked distance fares as monthly tiers ("Use the school's fares") |

**The study (`GET /feasibility_studies/:id`)** = the list row plus:

```json
{ "id": 2, "name": "Tampines prospect", "school": "Tampines Primary", "students": 44, "scenarios": 2, "updated_at": "…",
  "best": { "buses": 2, "runs": 4, "total": "12400.0", "break_even": "295.24" },
  "school_mode": "prospect", "school_id": null, "prospect_name": "Tampines Primary", "prospect_postal": "529426",
  "place": { "name": "Tampines Primary", "short": "Tampines Primary", "address": "10 Tampines Street 21", "lat": 1.3496, "lng": 103.9437 },
  "pickup": "door", "walk_m": 300, "ran_at": "2026-11-02T09:00:00.000+08:00",
  "geocode": { "postals": 3, "pending": 1, "not_found": 1 },
  "rows": [ { "id": 11, "postal": "460101", "riders": 3, "session": "both", "level": "P4",
              "status": "found", "address": "Blk 460101", "lat": 1.324, "lng": 103.93 } ],
  "bus_prices": [ { "bus_type": "MEDIUM_23", "monthly": "3000.0", "attendant": "450.0" } ],
  "fare_tiers": [ { "max_km": "3.0", "fare": "150.0", "one_way_fare": "100.0" }, { "max_km": null, "fare": "220.0", "one_way_fare": "150.0" } ],
  "scenarios": [ "…each scenario, below…" ] }
```

`place` is `null` until the school (or the prospect's postal code) has a location; `place.address` is the school's address
(a prospect's comes from OneMap). `ran_at` is when the latest scenario was planned (`null` before any run); each scenario
has its own `ran_at` ("Run 2 Nov 09:00").

**Postal codes on the map (`rows[].status`).** Each line shows what OneMap said about its postal code:
`found` (`address`, `lat`, `lng` are filled), `not_found` (no such postal code: those students have no stop and are
reported as unassigned `RIDER_NO_STOP`; shown in red, not looked up again for a week) or `pending` (not asked yet, or
OneMap could not be reached). `geocode` counts them for the study (`postals` = different codes). Adding students starts
the lookups in the background; poll `GET /feasibility_studies/:id` until `geocode.pending` is `0`. When it stays above 0,
OneMap is busy: show **Check Again** (`POST …/geocode`). A run looks up what is still pending first.

**Students (`rows`):**

- Each line holds a postal code, in any column, with an optional count, AM / PM / both, and level. For example
  `460101, 3, AM, P4`.
- Columns are separated by commas, tabs or semicolons.
- Lines without a postal code are skipped and counted in `meta.skipped`.
- The same postal code, session and level add up.
- Adding or removing students marks scenarios that already ran as `stale`.

**`stale`** (the result no longer matches the study; the screen shows "Run Again"). Same as the prototype:

| Makes scenarios that ran stale | Does not |
| --- | --- |
| Adding, removing or clearing students; changing `school_mode`, the school, the prospect's postal code (its place), `pickup` or `walk_m`; in a scenario: `sizes`, `attendant`, `hard_cap`, `target_cap`, `params` | `name`, bus prices, fare tiers, `margin_pct`, `extra_buses` (buffer buses): these only change the cost, which is worked out live |

A stale scenario stays stale after any other edit; only a new run clears it.

**Each scenario in `GET /feasibility_studies/:id`:**

```json
{ "id": 3, "name": "Big buses", "status": "done", "stale": false, "error": null, "ran_at": "2026-11-02T09:00:00.000+08:00", …settings…,
  "result": { "need": 44, "served": 42, "sv": { "460101|both": 9 },
              "AM": { "road": true, "summary": {…}, "routes": [ { "type": "LARGE_45", "label": "45-seater", "attendant": true, "load": 38, "seats": 44, "minutes": 46,
                                                    "startT": "06:30", "endT": "07:16", "stops": [ { "ll": [1.32, 103.92], "n": 9, "time": "06:30", "name": "…", "postals": "460100 x9" } ] } ],
                      "unassigned": [ { "n": 2, "reason": "HARD_CAP_UNREACHABLE", "label": "…", "riders": ["fz3", "fz4"] } ] },
              "PM": {…} },
  "cost": { "buses": 2, "runs": 4, "buffer": 1, "total": "12400.0", "attendant_cost": "1350.0", "served": 42, "margin": "0.25",
            "break_even": "295.24", "target_fare": "393.65", "missing": [], "by_session": { "AM": { "buses": {…}, "attendants": {…}, "buffer": {…}, "n": 2 }, "PM": {…} } },
  "fares": { "tiers": [ { "max_km": "3.0", "n": 20, "n2": 15, "n1": 5, "fare": "150.0", "one_way": "100.0", "revenue": "2750.0", "suggested": 170, "suggested_one_way": 114 } ],
             "revenue": "…", "missing": false, "exact": true, "scaled": true, "students": 42, "fare_margin": "0.21" } }
```

`road: false` = the engine had no road times and used straight-line times: show "straight-line times" next to that
session. `unassigned[].riders` lists the students of each entry (ids only meaningful inside this result: the same student
has the same id in AM and PM, so count different ids per `reason` to show "N students" for both sessions together).
`n` is the entry's student count. Students whose postal code was not found come one entry each (`RIDER_NO_STOP`, `label` =
the postal code).

**Other fields.** `result.AM.summary` = `routes`, `assigned`, `unassigned` (counts), `avgJourney`, `maxJourney` (minutes),
`avgFill` (0–1). `cost.by_session.AM` = `on` (the session was planned), `buses` and `attendants` (count per bus size), `buffer`
(buffer buses per size), `n` (buses) and `buffer_n` (buffer buses). `fares.exact` is `true` when the tiers count the students
served by the last run and `false` when they count every uploaded student (no run yet). `fare_tiers[].max_km` is `null` on the
last, open tier ("Above N km").

**Answers.** `PATCH /feasibility_studies/:id`, `POST` / `DELETE …/rows` (`DELETE …/rows/:row_id` too), `POST …/scenarios`,
`PATCH /feasibility_scenarios/:id`, `POST …/copy` and `POST …/use_suggested_fares` answer with the whole study (`200`, or `201`
for creating); `DELETE /feasibility_scenarios/:id` and `DELETE /feasibility_studies/:id` are `204`; `POST …/run` is
`202 { data: { id, status: "running" } }`.

#### Scenario parameters

`params` overrides the company's routing parameters for this scenario (the prototype's Routing Parameters card). Send
only what changed; an empty value or `{}` = company setting. Anything else is `422` ("<key> cannot be changed here").

| Key | Meaning | Values |
| --- | --- | --- |
| `amTarget` / `pmTarget` | AM Arrival at School / PM Dismissal | `"HH:MM"`. The planning window follows it: AM `target − 5 min … target + 10 min`, PM `target − 15 min … target` |
| `baseDwell`, `perStudent` | Stop Dwell, Per Student | seconds, 0 or more |
| `amTraffic`, `pmTraffic` | AM / PM Traffic (1.4 = 40% slower) | number from 0.1 |
| `headroom` | **Seat Buffer**: seats kept empty on every bus, replacing each bus size's own buffer | fraction 0–0.9 (the screen shows %: send `0.1` for 10%) |
| `effort` | Search effort | `low`, `medium`, `high`, `extra`, `max` |

Bus sizes without a company setting come from the engine's defaults (`GET /routing/settings` → `defaults.types`).

How the figures are worked out:

| Figure | How |
| --- | --- |
| Monthly cost | Each session's buses (plus buffer buses) × price, plus attendants at their add-on. `missing` lists sizes with no price |
| Buses | The larger session's count |
| Break-even | Cost ÷ students served |
| Target fare | Cost ÷ (1 − margin) ÷ served |
| Fares | Students per tier by straight-line km from the school: 2-way for both sessions, 1-way otherwise |
| Suggested fares | Scale the tier fares to reach the target, or one flat fare when a fare is missing |

The map view, "Compare Scenarios" and Export are built by the FE from this data.

## 8. Front-end only and not built yet

FE only:

- The map: lasso and select tools, dragging the route line to add via points, route geometry (the FE calls OSRM
  `/route`, as in the prototype).
- Route sheets (xlsx), Google Maps links, the loading animation and How It Works.

Not built yet:

- Moving stops between routes in the Feasibility map view (prototype `fzMove`).
- Applying confirmed mid-year changes from Requests to the plan in use: this comes with Families & Requests.
- Self-hosted OSRM: in the backlog.
