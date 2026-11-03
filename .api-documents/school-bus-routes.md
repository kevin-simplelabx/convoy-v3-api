# School Bus › Route Plans & Feasibility Studies — API Guide

Route Plans is the third mode of the School Bus map screen, after Stop Library and Stop Assignment
([school-bus-stops.md](school-bus-stops.md)). Feasibility Studies is a company-level sandbox. Conventions are in
[README.md](README.md); paths start with `/api/v1`.

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
  "error": null, "riders": 65, "stops": 7, "no_stop": ["S-1044"], "conflicts": [], "ms": 41250, "plan_id": 21, … }
```

**What the engine is given:**

- The riders on the Plan For `date` who ride the session (AM, PM, or CCA days for ASA).
- Each rider whose PUDO points all belong to **one stop** (from Stop Assignment), grouped by that stop with the stop's
  points the school uses.
- Riders with no stop are listed in `no_stop`; riders with more than one stop are listed in `conflicts`. Neither goes
  into the run. Show "N riders need a stop" / "N riders have more than one stop".
- The current plan of the session, for "Keep Current".
- The company's parameters, the run's `params`, the session, and the school's bus attendant rule.

| Result | Meaning |
| --- | --- |
| 422 `routing_blocked` (`details: { no_stop, conflicts }`) | No rider of the session has a stop |
| `failed` with the engine's message | The engine refused, for example no road times |
| `failed` with "The routing service is not available…" | The routing service could not be reached |
| `done` | `plan_id` is the new **draft** plan |

## 3. Plans

| Call | What it does |
| --- | --- |
| `GET /schools/:id/plans?session=am` | The plan list, newest first |
| `GET /plans/:id` | One plan (fields below) |
| `POST /schools/:id/plans { session }` | **Draw Routes**: an empty plan (`source: "manual"`) to draw routes on |
| `PATCH /plans/:id { plan: { name, effective_from, effective_to } }` | Rename, or change the run dates |
| `DELETE /plans/:id` | Delete a draft (only drafts) |
| `POST /plans/:id/comments { body }` / `DELETE /plans/:id/comments/:comment_id` | Comments |
| `GET /plans/:id/compare?with=:other_id` | Compare Plans: the engine's comparison, with names `a` / `b` |

```json
{ "id": 21, "name": "AM Plan 3", "session": "am", "source": "engine" | "manual", "priority": "BALANCED", "state": "draft" | "scheduled" | "current" | "replaced",
  "effective_from": "2026-11-02", "effective_to": null, "created_at": "…", "created_by": "…", "adopted_at": null,
  "routes_count": 4, "riders": 65, "bus_mix": { "MEDIUM_23": 3, "SMALL_13": 1 }, "unassigned_count": 0, "comments_count": 1, "out_of_date": false,
  "summary": { "routes": 4, "riders": 65, "assigned": 65, "unassigned": 0, "byType": {…}, "avgJourney": 38.2, "maxJourney": 52.4, "avgFill": 0.71, "total": 412.6, … },
  "params": {…}, "unassigned": [ { "riders": ["S-1001"], "n": 1, "reason": "…", "label": "…" } ],
  "routing_run": { "id": 9, "no_stop": [], "conflicts": [], "ms": 41250 },
  "routes": [ { "id": 51, "number": 1, "label": "AM 1", "route_key": "R01", "bus_type": "MEDIUM_23", "seats": 23, "student_seats": 23, "capacity": 20,
                "floor": 12, "fill": "0.8", "span_seconds": 2700, "ride_minutes": 420, "badges": ["Buffer used"], "locked": false, "hidden": false,
                "edited": false, "manual": false, "vias": [], "riders_count": 18, "start_time": "06:35", "end_time": "07:20",
                "attendant": null, "regular_vehicle_id": 12, "vehicles": [ { "from": "2026-11-02", "vehicle_id": 12, "plate": "PD6604E" } ],
                "prices": [], "charges": [],
                "stops": [ { "id": 301, "position": 0, "name": "Blk 101 Bedok North", "lat": 1.3204, "lng": 103.9203, "time": "06:35",
                             "riders_count": 9, "dwell_seconds": 75, "stop_id": 12, "stop_code": "BDSZ03-0001", "stop_point_id": 31,
                             "pudo_code": "BDSZ03-0001A", "riders": ["S-1001", "…"] } ] } ],
  "comments": [ { "id": 1, "body": "…", "by": "…", "at": "…" } ] }
```

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
- KPIs, the bus mix and slots come from `summary`.
- The Students list: each route's `stops[].riders` (rider IDs) with the stop and time.
- The Unassigned list is `unassigned` with each entry's `reason`.

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
| `POST /plans/:plan_id/route_again { params: {…}, fleet: { MEDIUM_23: 2, SMALL_13: 0 } }` | Route Again |

Rules:

- A rider placed on a route leaves any other route of the plan. A route left without riders goes.
- A rider taken off a route goes to `unassigned`, with the reason "Removed by hand", "Route deleted" or
  "Taken off by Reset Route".
- A route drawn by hand cannot be reset.
- Routes of an **adopted** plan can be edited (their runs on the Scheduler follow) but not deleted ("Make a new plan to
  remove a route").

**Route Again** plans again every rider not on a locked route. Its result replaces the unlocked routes of the same plan.

- `fleet` caps buses of a size; 0 turns a size off.
- It returns 202 `{ id, status, kind: "again", plan_id }`. Poll `GET /routing_runs/:id`, then reload the plan.
- 422 "Every rider is on a locked route. Unlock a route to route again".

## 5. Adopt Plan and rider assignments

| Call | What it does |
| --- | --- |
| `POST /plans/:id/adopt { from }` | Adopt the plan from a date |
| `POST /plans/:id/cancel_adoption` | A scheduled plan goes back to draft; the plan it would have replaced runs on |

**Adopt rules:**

- `from` must be the 1st of this month or later, and after the current plan's start.
- The plan runs on the **Scheduler** from that date: `scheduled` before the date, `current` from it.
- The plan of the same session in use on that date ends the day before. A plan scheduled after the date is cancelled.
- Runs are re-synced in the background.

| Error (422) | Cause |
| --- | --- |
| "Pick a date from the 1st of this month" | `from` before the 1st of this month |
| "Pick a date after 2 Nov 2026, when the current plan started" | `from` not after the current plan's start |
| "The plan has no routes" | Empty plan |
| "This plan is already adopted" | Plan already in use |

**Rider assignments.** Adopting an **AM** plan assigns each of its riders the PUDO point they use. Stop Assignment
(`GET /schools/:id/stop_assignment`) then shows `assigned` for each rider, and `meta.counts.assigned` / `notified`.
Riders set by hand keep their point.

| Call | Tool |
| --- | --- |
| `POST /schools/:id/rider_assignments { rids: [], stop_point_id }` | Set as assigned (by hand) |
| `POST /schools/:id/rider_assignments/move { stop_point_id }` | Move All Riders Here: the riders assigned to the other points of that stop move to this one. Returns `{ moved }` |
| `POST /schools/:id/rider_assignments/notify` | Notify: returns `{ notified: n }`. Show "Assigned PUDO sent to N riders". Recorded only; sending comes with the app |

## 6. Route bus and money

| Call | What it does |
| --- | --- |
| `POST /routes/:id/vehicle { vehicle_id, from }` | The regular bus from a date (empty `vehicle_id` = no bus). The history is in route `vehicles`. One-day or date-range replacements stay on the Scheduler |
| `POST /routes/:id/prices { effective_from, mode: fixed\|rider, monthly \| base_price + riders_included + per_rider }` | The operator's monthly price from a date (`finance`). The history is in route `prices`. With no price, the school's default for the bus size applies (Operator Pay) |
| `GET /schools/:id/route_charges?date=` | Route Charges (when the school pays per bus): each AM / PM run of the adopted plans |
| `POST /routes/:id/charges { starts_on, kind: amt\|pct, value, reason, note }` | A charge change from a date (the 1st of this month or later; it can be mid-month). `value: 0` ends the charge. `reason`: Long route, Peak timing, ERP cover, Extra stop or Other |
| `PATCH /route_charges/:id { school_route_id, status: "ok" }` | Confirm a carried charge, or move it to another run |
| `DELETE /route_charges/:id` | Remove a change that has not started, or drop a carried charge |

`GET /schools/:id/route_charges` returns:

```json
{ "per_bus": true,
  "runs": [ { "route_id": 51, "plan_id": 21, "session": "am", "label": "AM 1", "bus_type": "MEDIUM_23", "rate": "1500.0", "extra": "150.0", "total": "1650.0",
              "now": { "id": 4, "starts_on": "2026-11-02", "kind": "amt", "value": "150.0", "reason": "Long route", "status": "ok", … } | null,
              "next": {…} | null, "history": [...] } ],
  "unmatched": [ …charges with no run… ], "to_check": 1 }
```

When a new plan is adopted, each old run's charge moves to the new run that shares the most riders (then stops) with it,
with `status: "check"`. A charge with no match is listed in `unmatched` ("Charges With No Matching Run").

## 7. Feasibility Studies

Feasibility Studies are a sandbox: nothing touches real riders, stops or plans.

| Call | What it does |
| --- | --- |
| `GET /feasibility_studies` | The studies: `id`, `name`, `school`, `students`, `scenarios`, `updated_at`, `best` (fewest runs: `buses`, `runs`, `total`, `break_even`) |
| `POST /feasibility_studies { study: { name, school_mode: existing\|prospect, school_id \| prospect_name + prospect_postal, pickup: door\|lib, walk_m } }` | New study. A prospect's postal code is placed on OneMap. The study starts with "Scenario 1" |
| `GET /feasibility_studies/:id` | The study, with its scenarios worked out (below) |
| `PATCH /feasibility_studies/:id { study: {…}, bus_prices: [{ bus_type, monthly, attendant }], fare_tiers: [{ max_km, fare, one_way_fare }] }` | Change the study, its bus prices (monthly per bus size plus the attendant add-on) or its fare tiers (monthly; the last tier has no `max_km`) |
| `POST /feasibility_studies/:id/rows { text }` | Paste or upload students |
| `DELETE /feasibility_studies/:id/rows` | Clear the students |
| `POST /feasibility_studies/:id/scenarios { from_id }` | Add Scenario, or copy one |
| `PATCH /feasibility_scenarios/:id { scenario: { name, sizes: ["MEDIUM_23"], attendant: STATUTORY\|ALL_BUSES, hard_cap, target_cap, margin_pct, extra_buses: { AM: { SMALL_13: 1 } }, params: {…} } }` | Change a scenario. `params` blank = company parameters |
| `DELETE /feasibility_scenarios/:id` | Delete a scenario (keep at least one) |
| `POST /feasibility_scenarios/:id/run` | Plans AM and PM in the background (202). Poll the study until the scenario's `status` is `done` or `failed` (with `error`) |
| `POST /feasibility_scenarios/:id/use_suggested_fares` | The study's tiers take the suggested fares |
| `GET /feasibility_studies/fare_source?school_id=` | A school's locked distance fares as monthly tiers ("Use the school's fares") |

**Students (`rows`):**

- Each line holds a postal code, in any column, with an optional count, AM / PM / both, and level. For example
  `460101, 3, AM, P4`.
- Columns are separated by commas, tabs or semicolons.
- Lines without a postal code are skipped and counted in `meta.skipped`.
- The same postal code, session and level add up.
- Adding students marks scenarios that already ran as `stale`.

**Each scenario in `GET /feasibility_studies/:id`:**

```json
{ "id": 3, "name": "Big buses", "status": "done", "stale": false, "error": null, …settings…,
  "result": { "need": 44, "served": 42, "sv": { "460101|both": 9 },
              "AM": { "summary": {…}, "routes": [ { "type": "LARGE_45", "label": "45-seater", "attendant": true, "load": 38, "seats": 44, "minutes": 46,
                                                    "startT": "06:30", "endT": "07:16", "stops": [ { "ll": [1.32, 103.92], "n": 9, "time": "06:30", "name": "…", "postals": "460100 x9" } ] } ],
                      "unassigned": [ { "n": 2, "reason": "…", "label": "…" } ] },
              "PM": {…} },
  "cost": { "buses": 2, "runs": 4, "buffer": 1, "total": "12400.0", "attendant_cost": "1350.0", "served": 42, "margin": "0.25",
            "break_even": "295.24", "target_fare": "393.65", "missing": [], "by_session": { "AM": { "buses": {…}, "attendants": {…}, "buffer": {…}, "n": 2 }, "PM": {…} } },
  "fares": { "tiers": [ { "max_km": "3.0", "n": 20, "n2": 15, "n1": 5, "fare": "150.0", "one_way": "100.0", "revenue": "2750.0", "suggested": 170, "suggested_one_way": 114 } ],
             "revenue": "…", "missing": false, "exact": true, "scaled": true, "students": 42, "fare_margin": "0.21" } }
```

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
