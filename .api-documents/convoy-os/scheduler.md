# Scheduler — API Guide

The Scheduler menu (rail icon `calendar_view_week`) and every screen it opens: the grid, the trip drawer, the vehicle panel,
the trip form, the Assign page, replacements, Change a Day, maintenance, notices, Edit Vehicle and the public tracking page.

Conventions (sign-in, errors, paging, files, background reads, runs) are in [README.md](../README.md).
All paths below start with `/api/v1`.

## Contents

1. [Load the grid](#1-load-the-grid)
2. [Toolbar](#2-toolbar)
3. [Drag and drop](#3-drag-and-drop)
4. [Empty slot menu](#4-empty-slot-menu)
5. [Trip drawer](#5-trip-drawer)
6. [Vehicle panel](#6-vehicle-panel)
7. [Trip form](#7-trip-form)
8. [Assign page](#8-assign-page)
9. [Replace dialog and Replacements list](#9-replace-dialog-and-replacements-list)
10. [Change a Day (calendars)](#10-change-a-day-calendars)
11. [Maintenance dialog and Workshops](#11-maintenance-dialog-and-workshops)
12. [Notice form](#12-notice-form)
13. [New External Vehicle](#13-new-external-vehicle)
14. [Edit Vehicle](#14-edit-vehicle)
15. [Lists the forms pick from](#15-lists-the-forms-pick-from)
16. [Public Trip Tracking page](#16-public-trip-tracking-page)
17. [Values reference](#17-values-reference)

---

## 1. Load the grid

### `GET /scheduler`

Everything the grid needs for a day (Day view) or a range (Week view): the vehicles (rows / lanes), the runs on them,
the unassigned runs (bottom or right tray) and the workshop visits (purple blocks).

| Param | Required | Description |
| --- | --- | --- |
| `from` | yes | First date, `YYYY-MM-DD` |
| `to` | no | Last date (default `from`). At most 42 days; longer or reversed → `400` "Pick up to 42 days" |
| `ownership[]` | no | Vehicle chips: `own`, `managed`, `external` (any picked matches) |
| `size[]` | no | `sedan` (≤4 seats), `mpv` (5–7), `small` (8–15), `medium` (16–30), `large` (31+) |
| `tags[]` | no | Tag chips (`Coach`, `Wheelchair`...); all picked must match |
| `vip` | no | `true` for the VIP chip (tag VIP, or VIP / Alphard / Vellfire in make or model) |
| `team_id` | no | Vehicle team id, or `none` for vehicles without a team |
| `q` | no | Search plate, make, model, driver, operator |
| `sort` | no | `type` (Own, Managed, External, then smallest; default), `smallest`, `largest` |

```json
{
  "data": {
    "vehicles": [ { "id": 14, "plate": "PC8841T", "seats": 23, "make": "Toyota", "model": "Coaster", "ownership": "own",
                    "size": "medium", "size_name": "Medium Bus", "vip": false, "tags": [], "default_picture": "coaster",
                    "photo": null, "driver": { "id": 10, "kind": "own", "name": "Siti Nurhaliza", "phone": "+6590034455", "photo": "/api/v1/downloads/<token>" },
                    "operator": null, "vehicle_team": { "id": 1, "name": "East", "color": "#0B6E6E" },
                    "insurance": { "insurer": null, "ends_on": null, "status": "none" }, "plate_conflict": false } ],
    "occurrences": [ { "id": 490, "key": "t8|2026-11-02|1|1|1", "date": "2026-11-02",
                       "trip_id": 8, "trip_run_id": 1, "run_key": "d1r0", "slot_no": 1, "part": 1, "school_route_id": null,
                       "trip_label": "TID103716-1", "kind": "corporate_shuttle", "title": "MBC Campus Shuttle",
                       "route_text": "Labrador Park MRT Exit A to Mapletree Business City",
                       "route_stops": [ { "name": "Labrador Park MRT Exit A", "address": "Labrador Villa Rd, Singapore 119187" }, { "name": "Mapletree Business City", "address": "10 Pasir Panjang Rd, #01-01, Singapore 117438" } ], "client_id": 2, "client_name": "Google Asia Pacific", "school_name": null,
                       "start_time": "07:45", "end_time": "08:00", "starts_at": "2026-11-02T07:45:00+08:00",
                       "ends_at": "2026-11-02T08:00:00+08:00", "ends_next_day": false, "shift_minutes": 0,
                       "vehicle_id": 14, "plate": "PC8841T", "original_vehicle_id": null, "original_plate": null,
                       "driver": { "kind": "own", "id": 10, "name": "Siti Nurhaliza", "phone": "+6590034455", "photo": "/api/v1/downloads/<token>" },
                       "operator_id": null, "pax": 0, "price": "76.19", "trip_value": "1.0", "operator_cost": null,
                       "status": "scheduled", "grid_status": "ok", "cancelled_at": null, "ended_at": null, "issue_reason": null, "issue_raised_at": null,
                       "recurring": true, "color": "#3267D6", "group_key": "g1", "pair_trip_id": null, "is_return": false,
                       "replacement_id": null, "trip_assignment_id": null, "overridden_fields": [], "lock_version": 0 } ],
    "unassigned": [ "same shape as occurrences, vehicle_id null" ],
    "maintenance": [ { "id": 1, "vehicle_id": 6, "plate": "PD1125G", "date": "2026-10-31", "start_time": "13:00", "end_time": "16:00",
                       "kind": "service", "kind_name": "Service", "status": "scheduled", "workshop_name": "Ah Huat Motor Works" } ]
  },
  "meta": {
    "from": "2026-11-02", "to": "2026-11-02", "horizon": "2027-03-02",
    "facets": { "ownership": { "own": 10, "managed": 2, "external": 1 },
                "size": { "sedan": 0, "mpv": 0, "small": 6, "medium": 2, "large": 5 }, "vip": 1,
                "tags": { "Coach": 5, "External": 1, "Wheelchair": 1 } },
    "unassigned_before": null, "unassigned_after": "2026-11-04"
  }
}
```

How to draw it:

- **Block position**: `vehicle_id` (row / lane), `date`, `start_time` / `end_time` (`ends_next_day` when it crosses midnight).
- **Colour / pattern**: `grid_status` — `ok`, `live` (running now), `done`, `unassigned`, `cancel`, `cancel_unassigned`,
  `replacement` (moved to another bus by a replacement: Vehicle Down, Crew Swap, Handover). A driver-only replacement
  (Driver Unavailable) stays `ok`; use `replacement_id` and `driver` to show it.
- **Ghost of a replaced run**: when `original_vehicle_id` is set, also draw a ghost block on that vehicle's row.
- **Link lines**: teal between runs with the same `group_key` (Runs That Move Together); orange from the ghost
  (`original_vehicle_id`) to the run; purple from a run to the run of `pair_trip_id` (two-way trips, `is_return` on the way back).
- **School Bus routes** come in the same lists: `kind: "school_route"`, `school_route_id`, `trip_id: null`, `school_name`, `pax` = riders.
- **Workshop visits** (`maintenance`) are not draggable; clicking one opens the maintenance dialog (section 11).
- **Filter chips**: `meta.facets` gives the count for every chip (over the whole fleet). Hide size chips with 0.
- **Unassigned tray arrows**: `meta.unassigned_before` / `unassigned_after` are the nearest dates with unassigned runs (or null).
- **Horizon**: there are no runs after `meta.horizon` (today + 120 days). Grey out those days and stop navigation there
  (see README, Runs). A range that goes past it simply returns the runs up to it.

### `GET /occurrences` — runs as a list (Table view, driver's day)

| Param | Description |
| --- | --- |
| `date` | One date |
| `from`, `to` | A range (both) |
| `driver_id` | Own driver |
| `operator_driver_id` | Operator driver |
| `vehicle_id`, `trip_id`, `client_id` | Filters |
| `status` | `scheduled`, `cancelled`, `completed` |
| `unassigned` | `true` = runs with no bus |
| `page`, `limit` | Paging |

Returns run rows (same shape as the grid) ordered by start, with `meta` paging. Example: a driver's runs today:
`GET /occurrences?driver_id=10&date=2026-11-02`.

---

## 2. Toolbar

| Control | Call |
| --- | --- |
| Day / Week, ‹ ›, date picker, Today | `GET /scheduler?from=&to=` with the new range |
| Search, chips, Sort | `GET /scheduler` with the filter params of section 1 |
| Assign Trips (badge = shuttles not fully assigned) | `GET /scheduler/assign_summary` → pick a shuttle → Assign page (section 8) |
| Replacements | `GET /replacements` (section 9) |
| Change a Day | Section 10 |
| Maintenance | `GET /maintenance_visits/new?vehicle_id=` (section 11) |
| External Vehicle | `POST /vehicles/external` (section 13) |
| New Trip | Trip form (section 7) |
| How It Works, Legend, Edit / View Only lock, zoom, link lines on / off | Front end only |

### `GET /scheduler/assign_summary`

```json
{ "data": [ { "trip_id": 8, "title": "MBC Campus Shuttle", "client_name": "Google Asia Pacific", "runs": 5, "vehicles": 2,
              "assigned": 10, "total": 10, "status": "all" } ],
  "meta": { "open": 0 } }
```

`status`: `all` (every run slot has a bus or operator), `some`, `none`. `meta.open` = shuttles not `all` (button badge).

---

## 3. Drag and drop

Dropping a block on a vehicle row (or on the Unassigned tray) opens the drop dialog.

### 3.1 Before the dialog: `GET /occurrences/:id/move_preview?vehicle_id=`

`vehicle_id` empty = dropped on Unassigned.

Trip run:

```json
{ "data": { "scopes": ["one", "later"], "members": 2,
            "warnings": ["PD3318K already has Google at 08:30–09:30 on 23/11/2026", "SX1 has 4 seats. This trip has 12 passengers",
                         "Hup Seng is set as valid until 20/11/2026", "PD3318K is at Ah Huat Motor 08:30–10:30"],
            "cost": { "amount": "95.0", "basis": "run", "source": "agreed" } } }
```

- `scopes`: the choices to offer. `one` = Just this date; `later` = From this date on (recurring trips, from the day after
  the first date). A one-off trip, or the first date of a series, only has `one` ("Move this trip").
- `members`: runs that move together (the run plus its Runs That Move Together group on that date).
- `warnings`: show them in the dialog; the drop is still allowed.
- `cost`: for a bus that is not ours, the cost to prefill: the pay agreed with that operator on this trip (`source: agreed`),
  else the trip's operator cost (`source: trip`; `basis: hour` for Disposal). `null` for own buses.

School Bus route run:

```json
{ "data": { "scopes": ["one", "range", "perm"], "members": 1, "warnings": [], "regular": "PD6604E",
            "operator": { "id": 5, "name": "Hup Seng" }, "same_operator": false, "ask_who_arranges": true } }
```

- `scopes`: `one` (Just this trip), `range` (Replacement for a date range), `perm` (Permanent change from this date / Make it the regular bus).
  Dropped on Unassigned: only `perm` ("Remove the bus from this date").
- `ask_who_arranges`: show "Who arranges it: [operator] / Us"; when Us, ask the cost per day.

### 3.2 Confirm: `POST /occurrences/:id/move`

Trip run:

| Param | Description |
| --- | --- |
| `vehicle_id` | Target bus; empty = Unassigned |
| `scope` | `one` or `later` |
| `cost` | Optional, for a bus that is not ours: operator cost |
| `cost_basis` | `run` (default), `day` (shared over the runs moved), `month` (also over the month's run days), `hour` (Disposal: × hours) |
| `lock_version` | Of the run |

School route run:

| Param | Description |
| --- | --- |
| `vehicle_id` | Target bus; empty only with `perm` |
| `scope` | `one`, `range`, `perm` |
| `starts_on`, `ends_on` | `range`: the dates; `perm`: `starts_on` = the date the change starts. Default: the run's date |
| `arranged_by` | `operator` (default: their pay is unchanged) or `us` |
| `daily_rate` | Required when `arranged_by=us`: cost per school day |
| `deduct` | `true` (default) = charge that cost to the route's operator |
| `reason` | Optional |

Response: the runs that moved (`{ "data": [ run, ... ] }`). Reload the grid range afterwards (other dates may change too).

What happens:

- `one`: only that date (the bus is set on the run; later edits of the trip keep it).
- `later`: becomes an assignment from that date (it shows on the Assign page, section 8).
- One-off trip, or `later` on the first date of a series: the trip's own bus is changed.
- Route `range` cuts any earlier replacement around the new one; dropping back on the regular bus removes the replacement for that day.

---

## 4. Empty slot menu

Clicking an empty 15-minute slot on a vehicle offers:

| Item | Call |
| --- | --- |
| New Trip | Trip form (section 7) with `vehicle_slots_attributes: [{ slot_no: 1, vehicle_id }]`, `starts_on`, `start_time` prefilled |
| Maintenance | `GET /maintenance_visits/new?vehicle_id=&date=&start_time=` (section 11; own buses only) |
| Inspection | Coming soon (no API) |

---

## 5. Trip drawer

### 5.1 Open a run: `GET /occurrences/:id`

Drawer response = the run row plus:

```json
{
  "data": {
    "id": 490, "...": "run fields as in section 1",
    "trip": { "full trip, same as GET /trips/:id (section 7.1); null for a school route run" },
    "route": null,
    "replacement": null,
    "notice": { "id": 3, "message": "Running 10 minutes late", "ends_at": "2026-11-02T08:15:00+08:00" },
    "bus_pattern": { "no_fixed_bus": false, "dates": 5, "moved": 3, "suggest": true, "top_vehicle_id": 15, "top_plate": "PD4472H" },
    "cancelled_by": null, "issue_raised_by": null, "ended_by": null,
    "changes": [ { "at": "2026-11-01T09:12:00+08:00", "by": "Rachel Tan", "action": "update",
                   "changes": { "status": ["scheduled", "cancelled"] } } ]
  }
}
```

- `route` (school route runs): `{ school {id, name, short_name}, plan {id, name, session}, label, riders, regular_vehicle_id,
  regular_plate, attendant {id, name, phone}, replacement {...} | null, stops: [{ name, time, riders, lat, lng }] }`.
- `replacement`: the replacement on this run (section 9 shape) — the box at the top of the drawer.
- `notice`: the banner notice active on this run now ("Notice on this trip").
- `bus_pattern` (recurring shuttle runs): `suggest: true` → show "A different bus on `moved` of its last `dates` dates" with
  "Make `top_plate` the Regular Bus" (= move with `scope: later` to `top_vehicle_id`) and "Set No Fixed Bus" (5.9).
- `changes`: Changes to This Trip / history of this run.
- `ended_at` (every run row) is when the run ended: the driver pressed End in the app, or someone used Force End Trip.
  `ended_by` (drawer) is the person who forced it (null when the driver ended it). Show "Ended by <ended_by> at HH:MM".

### 5.2 Drawer actions

| Action | Call | Notes |
| --- | --- | --- |
| Cancel | `PATCH /occurrences/:id/cancel` `{ lock_version, by_client }` | `by_client: true` = cancelled at the client's request (Trip History: Cancelled by Client); default by us |
| Restore | `PATCH /occurrences/:id/restore` `{ lock_version }` | |
| More › Force End Trip | `PATCH /occurrences/:id/end` `{ lock_version }` | Show it on a run on the road (`grid_status: "live"`). The run ends now: `status: "completed"`, `grid_status: "done"`, `ended_at`, `ended_by`; the planned `ends_at` / `end_time` stay. No undo. `422`: "This run has not started", "This run has already ended", "This run has no bus", "This run is cancelled" |
| Raise an Issue | `POST /occurrences/:id/issue` `{ reason }` | Only on a run that is done ("An issue can be raised on a completed run only"); holds the driver's pay. `422` "Driver pay for <Month YYYY> is confirmed. Reopen it in HR, Earnings first" once that month is confirmed; `422` "Say what the issue is" with no reason |
| Clear Issue | `DELETE /occurrences/:id/issue` | |
| Change the pick-up time: Today Only | `PATCH /occurrences/:id/time` `{ scope: "today", start_time: "08:20" }` | Recurring trips only. This run moves (`shift_minutes`, "Moved +20 min"); every stop moves by the same amount |
| Change the pick-up time: Save (one-off trip) / Every Run From Today | `PATCH /occurrences/:id/time` `{ scope: "from_here", start_time: "07:45" }` | See "Save Time" below; shuttles: this timing only |
| Undo time change | `PATCH /occurrences/:id/time` `{ scope: "reset" }` | Back to the planned time |
| Change Vehicle | Same as a drop: `move_preview` then `move` (section 3) | |
| Back to Regular Bus | `PATCH /occurrences/:id/regular_bus` | Drops a bus set by hand on this run |
| Assign External Vehicle | `POST /vehicles/external` (section 13), then `move` to it | |
| Replace | Section 9 (`occurrence_id`) | Driver Unavailable, Vehicle Down, Crew Swap, Handover |
| Send Notice | Section 12, prefilled with `trip_id` (or `school_id`) and the run's timing | |
| Share Tracking Link | `POST /occurrences/:id/tracking_link` → `201` | Section 16 |
| Replace Driver (this run only) | `POST /replacements` `{ occurrence_id, replacement: { kind: "drv", driver_name, driver_phone } }` | Trip-only driver: name and phone for one run. The run must have a bus (`422` "This run has no bus to replace"). A later replacement on the run replaces it |
| Use Regular Driver | `DELETE /replacements/:id` (the id in `replacement` of the drawer) | The run goes back to the regular bus and driver |
| Edit Trip | `GET /trips/:trip_id` → trip form (section 7) | |
| Delete trip | `DELETE /trips/:trip_id` | Future runs go; past runs stay |
| Copy Info, Street View, call buttons | Front end only | |

All of them answer with the drawer data of 5.1 (except tracking link and delete). Time changes are refused on school route
runs ("School route times are set in School Bus").

**Save Time (`scope: "from_here"`).** A one-off trip (`recurring: false`) shows one **Save** button; a recurring trip shows
**Today Only** and **Every Run From Today**. What `from_here` does depends on the run:

| Run | Result |
| --- | --- |
| A one-off trip, or the first run of a recurring trip (with no earlier time change) | The trip itself moves: its start and end and every stop time (on a shuttle: this timing's times) move by the same amount. The flight time stays. Any Today Only shift on its runs is dropped, so the run shows the new time with `shift_minutes: 0` (no "Moved" label), and the trip form (`GET /trips/:id`) shows it too |
| A later run of a recurring trip | The trip is split from this date: this run and the later ones move, earlier runs keep the old time (`GET /trips/:id` keeps the first time) |

`422`: "Pick a different time", "This run has started", "Pick a time on the same day".

### 5.3 Passenger List (School Run)

`GET /occurrences/:id/passengers`

```json
{ "data": { "list": "AM13 route list Nov.pdf",
            "stops": [ { "name": "Bedok Court Main Gate", "time": "06:35",
                         "students": [ { "key": "2d9ea1b7-...", "name": "Lim Jia Hui", "class_name": "P3", "parent_name": "Mdm Lim",
                                         "phone": "91234567", "phone2": null, "note": null, "status": "expected",
                                         "boarded_at": null, "alighted_at": null, "by": null, "at": null } ] } ] } }
```

- The list is the route list in force on that date (an earlier list for dates before an import's Apply From).
- Mark: `PATCH /occurrences/:id/passengers/:key` `{ "mark": "boarded" | "alighted" | "not_boarded" | "expected" }` → the whole
  list again (`expected` clears the mark).
- `status`: `expected` (not marked), `boarded`, `alighted`, `not_boarded` (not at the stop: show "Absent"), `not_boarding`
  (the driver marked them not riding today, before the trip). The Convoy Driver app writes the same marks; `by` is who
  marked (a user's name, or the driver's).

### 5.4 Stop photos (Stops section of the drawer)

| Action | Call |
| --- | --- |
| Add a photo | `POST /trips/:trip_id/stops/:stop_id/photos` (multipart `photo`) → `{ data: { id, url, thumb_url, ... } }` (max 3 per stop) |
| Remove a photo | `DELETE /trips/:trip_id/stops/:stop_id/photos/:id` |

The same photos show in the trip form.

### 5.5 Runs That Move Together (shuttles)

| Action | Call |
| --- | --- |
| Group runs | `POST /trips/:trip_id/run_groups` `{ "slots": ["d1r0|1", "d1r1|1"] }` → `201` `{ data: { group_key: "g4", slots } }`; under two slots → `422` "Pick two or more runs" |
| Ungroup | `DELETE /trips/:trip_id/run_groups/:id` (`id` = the number in `group_key`, `g4` → `4`) |

A slot key is `<run_key>|<slot_no>`, for example `d1r0|1` = Direction 1, first timing, vehicle 1.

### 5.6 No Fixed Bus

`PATCH /trips/:trip_id` `{ "trip": { "no_fixed_bus": true } }` — riders are not alerted about bus changes on this trip.

---

## 6. Vehicle panel

Clicking a vehicle name opens the panel.

| Item | Call |
| --- | --- |
| Vehicle details, driver | From the grid's `vehicles` row, or `GET /vehicles/:id` |
| Replacements on this vehicle | `GET /replacements?vehicle_id=` |
| Driver Away | `POST /replacements` with `kind: "drv", scope: "range"` (section 9) |
| Vehicle Down | `POST /replacements` with `kind: "veh", scope: "range"` (section 9) |
| Edit / remove a listed replacement | `PATCH` / `DELETE /replacements/:id` |
| Edit Vehicle | Section 14 |

---

## 7. Trip form

### 7.1 Open

- New trip: start empty (front end), optionally prefilled from the empty slot or from Fill from Message (7.8).
- Edit: `GET /trips/:id` → the whole trip:

```json
{ "data": {
  "id": 8, "trip_no": 100035, "trip_id": "TID100035", "kind": "corporate_shuttle", "kind_name": "Corporate Shuttle",
  "title": "MBC Campus Shuttle", "label": null, "client_id": 2, "client_name": "Google Asia Pacific", "client_site_id": null,
  "starts_on": "2026-09-07", "start_time": "07:45", "end_time": "08:00", "ends_next_day": false, "days": [1,2,3,4,5],
  "end_mode": "never", "ends_on": null, "occurrence_count": null, "repeat_text": "Every weekday",
  "skip_public_holidays": true, "calendar_id": 2, "pax": 0, "vehicles_count": 2, "vehicles_required_text": "2 x 23-seater",
  "stops": [ { "id": 14, "direction": 1, "position": 0, "name": "Labrador Park MRT Exit A", "use": "pu", "address": null,
               "lat": "1.2722", "lng": "103.8026", "driver_note": "Exit A, across the road from the bus stop",
               "street_view_url": null, "client_site_id": null, "scheduled_time": null, "photos": [], "students": [] } ],
  "route_vias": [ { "id": 1, "direction": 1, "from_position": 0, "position": 0, "lat": "1.27", "lng": "103.80" } ],
  "vehicle_requirements": [ { "id": 8, "vehicle_type_id": 5, "count": 2, "label": "2 x 23-seater" } ],
  "vehicle_slots": [ { "id": 1, "slot_no": 1, "vehicle_id": 14, "plate": "PC8841T", "price": null } ],
  "standby": { "id": 2, "location": "Labrador Park bus bay", "minutes": 10, "lat": "1.2725", "lng": "103.8021",
               "address": null, "note": null, "street_view_url": null, "report_time": "07:35", "photos": [] },
  "runs": [ { "id": 1, "key": "d1r0", "direction": 1, "position": 0, "start_time": "07:45", "end_time": "08:00",
              "times": ["07:45", "07:52", "08:00"], "trip_value": null, "standby_needed": true,
              "slots": [ { "id": 1, "key": "d1r0|1", "slot_no": 1, "vehicle_id": 14, "plate": "PC8841T", "unassigned": false, "group_key": "g1" } ] } ],
  "price_table": [ { "row": "d1", "col": "all", "amount": "9600.0" } ],
  "attachments": [ { "id": 3, "url": "...", "name": "itinerary.pdf", "size": 52000, "content_type": "application/pdf", "created_at": "..." } ],
  "pair": null, "pair_id": null, "is_return": false, "lock_version": 0,
  "...": "every other field of the tables in 7.3"
} }
```

### 7.2 Save

| Action | Call |
| --- | --- |
| Create | `POST /trips` `{ "trip": { ... }, "return_trip": { ... } }` → `201` `{ data: trip, meta: { return_trip: trip or null } }` |
| Save changes | `PATCH /trips/:id` `{ "trip": { ..., "lock_version": 0 } }` → `200` `{ data: trip }` |
| Delete | `DELETE /trips/:id` → `204` |

`return_trip` (Two-Way Trip, new Ad Hoc / Charter only): `{ start_time, end_time, stops_attributes, route_vias_attributes,
vehicle_slots_attributes, standby_attributes, return_billing }`. The rest is copied from the outbound trip; the return is
titled "… (Return)" and the two trips point at each other (`pair_id`). `return_billing` is worked out by the server when
every stop has a pin (two-way when every stop on the way back is within 200 m of one on the way there), else taken from the form.

Validation messages follow the trip form: "Pick the client", "Enter the pick-up point", "Enter the drop-off point",
"Enter how many vehicles are needed", "End time must be different from the start time", "Hours must be greater than 0",
"Wait minutes must be entered for an arrival", "The return starts before the outbound trip ends"...

`driver.photo` (grid vehicle rows, run rows and the drawer) is the driver's thumbnail link (`/api/v1/downloads/:token`), `null`
when the driver has no photo or is a replacement / external driver typed by name. `client_name` is on every run row. `route_stops` is the run's stops in travel order (`[{ name, address }]`, `[]` for School Bus route runs): build "A > +N > B" from them with the prototype's `street(name, address)` / `routeSum` (`format.js`); `route_text` stays as it was.

**Next Trip ID preview:** `GET /trips/next_number` → `{ "data": { "trip_id": "TID100731" } }` for the New Trip header. It
reserves nothing (the number is taken when the trip is saved) so another save can take it first; show it as informational
and read the real `trip_id` from the create answer. Same permission as creating a trip.

### 7.3 Trip fields (`trip`)

**All kinds**

| Field | Type | Description |
| --- | --- | --- |
| `kind` | string | `ad_hoc` (Ad Hoc / Charter), `corporate_shuttle`, `airport_transfer`, `disposal`, `school_run` |
| `client_id` | id | Managed Client (required) |
| `client_site_id` | id | Site of the client (when it has sites) |
| `title` | string | Trip Name (optional: empty = the Service For customer when sub-contracted, else the client) |
| `label` | string | Trip Label (sign on the bus) |
| `starts_on` | date | Trip date (first date of a series) |
| `start_time`, `end_time` | HH:MM | Shuttles and School Runs: worked out by the server from their timetable / stops |
| `days` | int[] | Recurring: weekdays, `0` = Sunday … `6` = Saturday. Empty = one-off |
| `end_mode` | string | Recurring: `never`, `date` (`ends_on`), `count` (`occurrence_count`; the server works out `ends_on`) |
| `skip_public_holidays` | bool | `false` = Run on Public Holidays |
| `calendar_id` | id | Calendar the series follows (section 10) |
| `pax` | int | Passengers |
| `luggage_on`, `luggage_cabin`, `luggage_medium`, `luggage_large`, `luggage_extra_large`, `luggage_oversized` | bool / int | Luggage by size |
| `vehicles_count` | int | Vehicles (1–20) |
| `requestor_name`, `requestor_email`, `requestor_phone` | string | Requestor |
| `guest_is_requestor`, `guest_name`, `guest_phone` | bool / string | Guest on the day |
| `notes`, `business_unit`, `project`, `booking_ref` | string | |
| `price` | decimal | Client Price |
| `price_per` | string | `route` (whole route, shared over vehicles) or `vehicle` |
| `price_set` | string | Each Vehicle: `same` or `each` (then `vehicle_slots_attributes[].price`) |
| `price_basis` | string | `trip` (per trip / run), `day`, `month` |
| `hourly_rate` | bool | Disposal: price is per hour |
| `trip_value`, `trip_value_mode`, `trip_value_rounding` | | Driver trip value; mode `trips` / `hours`, rounding `up` / `down` |
| `operator_cost` | decimal | Contractor bus cost per run |
| `operator_cancel_rule` | string | If the client cancels a run: `done` (pay runs done) / `full` |
| `subcontracted` | bool | We Are the Sub-Contractor (default true for a Transport Company client) |
| `client_end_customer_id`, `service_for` | id / string | Service For |
| `contractor_contact_name`, `contractor_contact_phone`, `require_contractor_app` | | Main contractor contact |
| `lock_version` | int | Send back on update |

**Airport Transfer**: `airport_direction` (`arrival` / `departure`), `flight_number`, `flight_time` (HH:MM), `terminal`,
`wait_minutes` (arrival, > 0), `meet_and_greet`, `signboard_name`, `meet_and_greet_fee`.

**Disposal**: `hours` (end time = start + hours), `hourly_rate`.

**Corporate Shuttle**: `shuttle_return` (Direction 2), `shuttle_separate_return` (Different Stops on Return), `price_by`
(`all`, `direction`, `run`), `trip_value_per` (`run` / `day`), `trip_value_return`, `route_tags` (list or "Campus, Staff"),
`color`, `approved_riders_only`, `seat_reservation`, `head_count`, `no_fixed_bus`, `runs_attributes`, `price_table`.

**School Run**: `session` (`am` / `pm`), `paid_months_mode` (`all`, `some`, `part`), `unpaid_months` (int[] 1–12),
`unpaid_month_share` (% for `part`), `charge_no_school_days`. Read only: `school_time_estimated`, `route_list_name`, `route_list_imported_at`.

### 7.4 Nested lists (send the whole list; existing rows with `id`, `_destroy: true` to remove)

| Key | Item fields |
| --- | --- |
| `stops_attributes` | `id, direction (1, or 2 = return stops), position (0..), name, return_name, use (pu / do / both / via), address, lat, lng, driver_note, street_view_url, client_site_id, scheduled_time, _destroy, photos_attributes [{ id, photo, position, _destroy }], students_attributes [{ id, position, name, class_name, parent_name, phone, phone2, note, _destroy }]` |
| `route_vias_attributes` | `id, direction, from_position (the stop before the pin), position, lat, lng, _destroy` |
| `vehicle_requirements_attributes` | `id, vehicle_type_id, count, _destroy` |
| `vehicle_slots_attributes` | `id, slot_no (1..vehicles_count), vehicle_id (empty = unassigned), price (when price_set each), _destroy` |
| `standby_attributes` | `id, location, minutes, lat, lng, address, note, street_view_url, _destroy, photos_attributes [...]` |
| `attachments_attributes` | `id, file, _destroy` (max 10) |
| `runs_attributes` (shuttles) | `id, direction, position, times[], trip_value, standby_needed, _destroy, slots_attributes [{ id, slot_no, vehicle_id, unassigned, group_key, _destroy }]` |
| `price_table` (shuttles) | `[{ row, col, amount }]`, replaces the whole table |

- Stops can be reordered in one save (positions swap freely).
- Shuttle `times`: one per stop **in travel order of the run's direction**: Direction 1 = the direction-1 stops;
  Direction 2 = the direction-2 stops when `shuttle_separate_return`, else the direction-1 stops reversed. `""` = the run does not stop there.
  Errors: "Direction 1, run 1: enter the time at the first stop", "… each stop time must be later than the one before".
- `group_key` on run slots: any text ("am", "g1"); slots sharing a key become one group.
- `price_table` rows: `all`, `d1`, `d2`, or a run key `d1r0`; cols: `all` (whole route) or `"1".."N"` (vehicle).
  Changing Price Is For / Price By while keeping the total is done in the front end before saving.
- School Run stops: AM = pick-ups then the school last; PM = the school first, then drop-offs. Give the school's time if known;
  otherwise the end is estimated (send your road-time estimate as `end_time`, else last pick-up + 10 min).

### 7.5 Attachments

| Action | Call |
| --- | --- |
| Add (saved trip) | `POST /trips/:trip_id/attachments` (multipart `file`) |
| Remove | `DELETE /trips/:trip_id/attachments/:id` |
| On a new trip | `trip[attachments_attributes][0][file]` in the create request |

### 7.6 Prices

| Action | Call |
| --- | --- |
| Revenue by Vehicle / what each run earns on a date | `GET /trips/:id/prices?date=` → `{ data: [{ run, slot_no, amount }], meta: { date, total } }` |
| Corporate Shuttle: Price From Rate Card | `POST /rate_cards/quote` `{ client_id, date, start_time, vehicle_type_id, km, extra_stops }` |

Quote response (`km` = road distance from your route, for distance bands; `extra_stops` = stops between first pick-up and last drop-off):

```json
{ "data": { "card": { "id": 2, "name": "Corporate Contract Rates" }, "amount": "87.0", "missing": null,
            "lines": [ { "text": "One Way, Off Peak", "amount": "73.0" }, { "text": "1 extra stop", "amount": "14.0" } ] } }
```

"Use This Price" fills `price` with `amount` and `price_basis: "trip"`. `missing` explains a zero (no period covers the time, type not on the card).

### 7.7 Client picker and Add New Client

| Action | Call |
| --- | --- |
| Client list / search | `GET /clients?q[name_i_cont]=goo` |
| Client with sites, end customers, saved points | `GET /clients/:id` |
| Add New Client | `POST /clients` `{ "client": { kind: "company" | "individual" | "transport_company", name, contact_name, phone, email } }` |
| Add New Customer (Service For) | `POST /clients/:client_id/end_customers` `{ "client_end_customer": { "name": "Nanyang Polytechnic" } }` |
| Client's saved pick-up points (place search, listed first) | In `GET /clients/:id` → `pickup_points` |

### 7.8 Fill from Message

1. `POST /document_reads` `{ "kind": "trip_message", "input_text": "<pasted message>" }` → poll `GET /document_reads/:id`.
2. `result`:

```json
{ "client_id": 3, "client_name": "DBS Bank", "client_raw": "DBS",
  "contact": { "name": "Daniel Ng", "phone": "98765432", "email": null, "org": "DBS" }, "notes": null,
  "assume": ["tmr read as Tue 3 Nov 2026"], "miss": ["Drop-off time"],
  "trips": [ "one cleaned trip per request found" ],
  "forms": [ { "trip": { "kind": "ad_hoc", "client_id": 3, "starts_on": "2026-11-03", "start_time": "09:00",
                         "stops_attributes": [ { "position": 0, "name": "DBS Asia Central", "use": "pu" }, { "position": 1, "name": "Changi Business Park", "use": "do" } ],
                         "vehicle_requirements_attributes": [ { "vehicle_type_id": 3, "count": 1 } ], "vehicles_count": 1, "pax": 10,
                         "requestor_name": "Daniel Ng", "requestor_phone": "98765432" },
               "return_trip": null, "filled": ["trip_type", "client", "date", "time", "route", "passengers", "vehicles", "requestor"],
               "notes": ["S$900.00 for each vehicle"] } ] }
```

- One pill per `forms[]` item; fill the form from `trip` (and `return_trip` for a two-way trip). `filled` = labels to highlight;
  `notes` = how a quoted price was read; `assume` = Read As; `miss` = Not in the Message; `client_raw` with `client_id: null` = client not on the list.
- `end_time` is not in the message: work it out from the route as usual. Undo Fill is front end only.

### 7.9 School Run: Import Route List

1. `POST /document_reads` (multipart) `kind=route_list`, `file` (PDF, xlsx, csv, photo) → poll.
2. Review: `POST /route_lists/review` `{ document_read_id, joins: [bool per row] (optional), trip_id (when importing onto a saved trip) }`

```json
{ "data": {
  "meta": { "label": "AM 13", "session": "am", "school": "Red Swastika School", "school_address": "350 Bedok North Ave 3 469719",
            "start_date": "2026-11-09", "arrive_by": "07:20", "leave_by": null, "notes": "Attendant alights at Blk 120" },
  "joins": [false, true, false],
  "stops": [ { "name": "Blk 443A Bedok North", "time": "06:40", "address": "Blk 443A Bedok North 461443", "lat": null, "lng": null,
               "driver_note": "Blk 443A Shelter", "pickup_point_id": null, "postal_codes": ["461443", "462443"],
               "rows": [ { "index": 0, "name": "Lim Jia Hui", "class_name": "P3", "postal": "461443", "time": "06:40",
                           "phone": "91234567", "flags": [] } ] } ],
  "flagged": 2,
  "changes": { "added": ["Goh Mei"], "removed": ["Ali Hassan"], "changed": [ { "name": "Lim Jia Hui", "changed": ["time"], "before": { "time": "06:35" }, "after": { "time": "06:40" } } ] },
  "trip_attributes": { "kind": "school_run", "session": "am", "title": "Red Swastika School AM 13", "starts_on": "2026-11-09",
                       "days": [1,2,3,4,5], "end_mode": "never", "notes": "...", "stops_attributes": [ "stops with students_attributes" ] }
} }
```

- `joins[i] = true` = row i is in the same stop as the row above. Join Stop Above / Separate Stop = flip a value and call review again.
- `flags` per row: "No time", "Earlier than the row above", "No parent phone", "No postal code", "Also on <other School Run>".
  Checking postal codes against OneMap is done in the front end.
- Save Pick-up Point on a review stop: `POST /pickup_points` `{ "pickup_point": { name, postal_codes: [...] or "461443, 462443", lat, lng, note } }`;
  list `GET /pickup_points`; delete `DELETE /pickup_points/:id`. Review again to apply it.
3. Add to Trip:
   - New trip: put `trip_attributes` into the form (plus client, vehicles, price) and `POST /trips`.
   - Saved trip with students: `POST /trips/:trip_id/route_list` `{ document_read_id, joins, apply_from: "2026-11-09" }` →
     the current list becomes an Earlier List until the day before; returns the trip.
4. Earlier Lists: `GET /trips/:trip_id/route_list_versions` → `[{ id, name, valid_until, stops, students }]`.
5. Next 12 Months: `GET /trips/:trip_id/school_run_bill?from=` →
   `{ data: [{ month: "2026-11", runs: 13, no_school_days: 1, share: 0.9286, amount: "2228.57" }], meta: { total, empty_months } }`.

---

## 8. Assign page

Opened from Assign Trips (section 2), Save and Assign in the trip form, or Assign in the drawer.

### `GET /trips/:trip_id/assignments?from=`

```json
{ "data": {
  "as_of": "2026-10-30", "operator_cancel_rule": "done",
  "slots": [ { "key": "d1r0|2", "trip_run_id": 1, "run_key": "d1r0", "run_label": "07:45", "slot_no": 2,
               "assignee": "operator", "vehicle_id": 17, "plate": "PC7475L", "operator_id": 5, "operator_name": "Hup Seng Coaches",
               "pay_amount": "4500.0", "pay_basis": "month", "assignment_id": 1, "from": "2026-09-07" } ],
  "history": [ { "id": 1, "effective_from": "2026-09-07", "assignee": "operator", "operator_id": 5, "operator_name": "Hup Seng Coaches",
                 "vehicle_id": 17, "plate": "PC7475L", "pay_amount": "4500.0", "pay_basis": "month",
                 "slots": ["d1r0|2", "d1r1|2"], "by": "SimpleDrive Ops", "at": "..." } ]
} }
```

- `slots`: every run × vehicle slot with who runs it on `as_of` (`run_label`: "07:45" or "Return 17:30"). Non-shuttle trips have one key per vehicle: `trip|1`.
- `assignee`: `own`, `operator` (bus may be empty: operator named, bus not known yet), `none`.

| Action | Call |
| --- | --- |
| Give ticked runs | `POST /trips/:trip_id/assignments` `{ effective_from, slots: ["d1r0|1", ...], assignee: "own" | "operator" | "none", operator_id, vehicle_id, pay_amount, pay_basis: "run" | "day" | "month" }` → `201` `{ data: entry }` (the history entry shape above) |
| Remove a history entry | `DELETE /trips/:trip_id/assignments/:id` → `204` (those runs go back to what was before) |
| If the Client Cancels a Run | `PATCH /trips/:trip_id` `{ "trip": { "operator_cancel_rule": "done" | "full" } }` |

Pay per day is shared over the slots of the entry; per month also over the month's run days (`operator_cost` on each run).
`effective_from` may be past the horizon: the entry is kept and the runs take it when those dates are added.

---

## 9. Replace dialog and Replacements list

### 9.1 Preview (while the dialog is filled in)

`GET /replacements/preview?occurrence_id=490&replacement[kind]=crew&replacement[vehicle_id]=15&replacement[arranged_by]=us`
(for Driver Away / Vehicle Down send `replacement[scope]=range&replacement[original_vehicle_id]=&replacement[starts_on]=&replacement[ends_on]=` instead of `occurrence_id`).

```json
{ "data": { "affected": 1, "runs": [ { "id": 490, "trip_label": "TID103716-1", "date": "2026-11-02", "start_time": "07:45" } ],
            "message": "Convoy update: MBC Campus Shuttle on 02/11/2026. Your bus is now PD4472H, driven by Siti. Sorry for the change.",
            "pay_text": "Trip value goes to the new crew, Siti", "operator": { "id": 5, "name": "Hup Seng" },
            "deduction_default": "120.0", "errors": [] } }
```

- `affected` / `runs`: only runs up to the horizon; a date range past it still applies to later runs when they are added.
- `message`: the text guests / parents will get (Notify box).
- `operator` + `deduction_default`: when the run is an operator's, ask "Who found the replacement: [operator] / Us"; when Us,
  prefill Deduction with `deduction_default` (their pay for the runs covered) and allow a Premium.

### 9.2 Save

`POST /replacements` (new) or `PATCH /replacements/:id`

```json
{ "occurrence_id": 490,
  "replacement": { "kind": "hand", "vehicle_id": 15, "handover_stop": "Clementi", "handover_time": "08:20",
                   "pay_split": "split", "original_share": 60, "eta": "08:30", "reason": "Breakdown" },
  "notify": { "audiences": ["guests"], "channels": ["email"] } }
```

| Field | Description |
| --- | --- |
| `occurrence_id` | Replace from the drawer (one run; the server sets `scope: "run"`). Leave out for Driver Away / Vehicle Down |
| `kind` | `drv` Driver Unavailable, `veh` Vehicle Down, `crew` Crew Swap, `hand` Handover During the Trip. A run with `drv` and no `vehicle_id` is the trip-only driver ("Replace Driver", section 5.2) |
| `scope` | `range` for Driver Away / Vehicle Down (`drv`, `veh` only) with `original_vehicle_id`, `starts_on`, `ends_on` |
| `vehicle_id` | New bus (`veh`, `crew`, `hand`) |
| `driver_id` / `operator_driver_id` / `driver_name` + `driver_phone` | New driver (`drv` required; `crew` / `hand` optional, else the new bus's driver) |
| `handover_stop`, `handover_time` | `hand`: where and when (must be during the run) |
| `pay_split`, `original_share` | `hand`: `original`, `new`, `both`, `split` (+ % for the original crew) |
| `eta`, `reason` | Text |
| `arranged_by` | `operator` (default) or `us` |
| `deduction`, `premium` | `us`: amount taken from the original operator, extra on top |
| `notify.audiences` | `guests`, `parents` (optional; recorded, sending comes later) |
| `notify.channels` | `email`, `push` (push = Convoy App, parents only). WhatsApp / Client Portal not available |

Response: the replacement:

```json
{ "data": { "id": 4, "kind": "drv", "kind_name": "Driver Unavailable", "scope": "run", "trip_id": 8, "school_route_id": null,
            "run_date": "2026-11-04", "trip_run_id": 1, "slot_no": 1, "original_vehicle_id": 14, "original_plate": "PD3318K",
            "starts_on": "2026-11-04", "ends_on": "2026-11-04", "vehicle_id": null, "plate": null, "new_driver": "Ah Kow",
            "driver_name": "Ah Kow", "driver_phone": "+6591112222", "handover_stop": null, "handover_time": null,
            "pay_split": null, "original_share": null, "arranged_by": "operator", "deduction": null, "premium": null,
            "eta": null, "reason": null, "status_label": "Coming Up",
            "summary": "Ah Kow (+6591112222) drives PD3318K. This trip on 04/11/2026.",
            "pay_text": "Trip value goes to Ah Kow, the replacement driver",
            "notifications": [ { "audiences": ["guests"], "channels": ["email"], "message": "...", "at": "...", "by": "..." } ],
            "created_by": "SimpleDrive Ops", "created_at": "..." } }
```

A new replacement on a run replaces the run's earlier one. Messages: "Pick the replacement driver", "Vehicle must be picked",
"Vehicle must be another bus", "The handover time must be during the trip, 08:00 to 09:00".

### 9.3 Replacements list (toolbar) and remove

- `GET /replacements?from=&vehicle_id=&scope=run|range` — from 30 days ago by default; `status_label` Active / Coming Up / Ended;
  `meta.active` = count still running or coming. Clicking one opens its date (`starts_on`) and run.
- `DELETE /replacements/:id` — its runs go back to the regular bus and driver.

In the grid, runs under a replacement have `replacement_id`; Vehicle Down / Crew Swap / Handover set `original_vehicle_id` (ghost).
A handover adds a second run (`part: 2`) on the new bus from the handover time.

---

## 10. Change a Day (calendars)

| Action | Call |
| --- | --- |
| Calendar list | `GET /calendars` |
| One calendar with its days | `GET /calendars/:id?year=` (the days touching that year; every day without `year`) |
| Add a day (Change a Day / Add a Day) | `POST /calendars/:calendar_id/days` `{ "calendar_day": { kind, starts_on, ends_on, label, usual_time, new_time, shift_minutes, in_place_of, notify_drivers } }` |
| Edit / remove a day | `PATCH` / `DELETE /calendars/:calendar_id/days/:id` |
| New calendar | `POST /calendars` `{ "calendar": { name, kind: "school" | "general", observed_holidays, morning_time, afternoon_time }, "start_from": "moe" | "blank" | "<calendar id>" }` |
| Edit / delete calendar | `PATCH` / `DELETE /calendars/:id` → `204`; `422` "This calendar is used by trips, so it can't be deleted" |
| Public holidays | `GET /public_holidays?year=2027`, `POST /public_holidays` `{ public_holiday: { date, name, observed } }`, `PATCH`, `DELETE`, Add MOM [year] Dates: `POST /public_holidays/import` `{ year }` |

Day `kind`: school calendars `hol` School Holiday, `ns` No School, `early` Early Dismissal, `late` Late Arrival
(`usual_time` + `new_time`); general calendars `off` Day Off, `shift` Changed Times (`shift_minutes` ±), `oil` Off in Lieu
(`in_place_of`), `work` Working Holiday. Runs re-sync in the background after a change: reload the grid after a few seconds.
Changing calendars needs the `vehicles` or `finance` permission. The full Calendars page (year view, trips using a calendar,
observed Monday for a Sunday holiday) is in [settings.md § 4](settings.md#4-calendars).

---

## 11. Maintenance dialog and Workshops

| Action | Call |
| --- | --- |
| New visit (toolbar or empty slot) | `GET /maintenance_visits/new?vehicle_id=&date=&start_time=` → defaults (the bus's driver that day, 2 hours, GST 9 %, `tyre_positions`) |
| Open a visit (purple block) | `GET /maintenance_visits/:id` |
| Plan the Visit (save) | `POST /maintenance_visits` (or `PATCH /maintenance_visits/:id`) |
| Record the Work | `PATCH /maintenance_visits/:id` with `status: "completed"` + odometer and lines |
| Read the invoice | `POST /document_reads` `kind=maintenance_invoice`, then save with `document_read_id` |
| Cancel visit | `PATCH /maintenance_visits/:id/cancel` (scheduled visits) |
| Delete ("Delete this maintenance record?") | `DELETE /maintenance_visits/:id` → `204`. Any saved visit (scheduled, completed or cancelled); its line items and invoice files go with it. A completed visit's cost leaves Vehicle Financials, the spend tiles and the Dashboard |
| Fleet > Maintenance tabs | `GET /maintenance_visits?tab=upcoming\|to_record\|completed\|cancelled&q=&vehicle_id=` (with `meta.counts` per tab). Or `GET /maintenance_visits?from=&to=&vehicle_id=` for every visit in the dates, soonest first (no `tab`) |
| Workshops window | `GET /workshops`, `POST /workshops` `{ workshop: { name, address, phone } }`, `PATCH`, `DELETE` (not when used) |

Save body:

```json
{ "maintenance_visit": { "vehicle_id": 6, "driver_id": 4, "date": "2026-11-05", "start_time": "13:00", "end_time": "16:00",
                         "workshop_id": 1, "address": "21 Kaki Bukit Ave 1", "kind": "service", "work_to_do": "40,000 km service",
                         "status": "completed", "odometer": 84210, "gst_on": true, "gst_rate": 9,
                         "lines_attributes": [ { "line_type": "tyre", "description": "Tyre 295/80R22.5", "brand": "Bridgestone",
                                                 "model": "R249", "tyre_position": "Front Left", "quantity": 1, "unit_price": 520 } ] },
  "workshop_name": "New Workshop Pte Ltd", "workshop_address": "...",
  "document_read_id": 12 }
```

- `workshop_name` = New Workshop typed in the form (matched by name or created); otherwise `workshop_id`.
- `invoice` (multipart file) or `document_read_id` attaches the invoice.
- Response `{ data: visit (full), meta: { filled: ["workshop", "odometer", "lines"], warnings: ["The invoice is for PD3318X, not PD3318K"] } }`.
- Visit fields: `kind` (`service`, `repair`, `tyres`, `inspection`, `other`), `status` (`scheduled`, `completed`, `cancelled`),
  `tab`, `subtotal`, `gst`, `total`, `last_odometer`, `driver_notified_at`, `lines` (`line_type` `part` / `tyre` / `labour` / `other`, `amount`),
  `invoices`, `tyre_positions` (valid tyre positions for that bus).
- Recording needs: odometer, at least one line, a description on every non-tyre line, a valid tyre position on every tyre.

---

## 12. Notice form

Send Notice in the drawer opens it prefilled with the trip (or the school) and the run's timing.

| Action | Call |
| --- | --- |
| Templates | `GET /notice_templates` → `[{ id, name, message }]` (`{min}`, `{time}` to fill in) |
| Send | `POST /notices` (body below) |
| Lists (Active, Scheduled, Ended) | `GET /notices?state=active|scheduled|ended&trip_id=` (page and search: [trips.md § Notices](trips.md#2-notices-page)) |
| Edit (scheduled only) | `PATCH /notices/:id` |
| End Now (active only) | `PATCH /notices/:id/end_now` |
| Duplicate | `POST /notices/:id/duplicate` (starts now, same length) |
| Delete (not active) | `DELETE /notices/:id` |

```json
{ "notice": { "audience": "trip", "trip_id": 8, "to_riders": true, "to_parents": false, "banner": true, "push": true, "sms": false,
              "notice_template_id": 1, "message": "The bus is running about 10 minutes late because of heavy traffic." },
  "start": "now", "period_minutes": 15, "run_keys": ["d1r0"] }
```

- Start: `start: "now"` (Immediate) or `start: "at"` with `notice[starts_at]`. End: `period_minutes` (5, 15, 20, 25, 30 or any) or `notice[ends_at]`.
- Trip notices: `run_keys`: `["all"]` or the timings (`d1r0`...). School route notices: `audience: "school"`, `school_id`, `route_ids: ["all"]` or route ids.
- **School route picker**: `GET /schools/:id/routes?date=<the notice's start day>` (default today) → the routes of the plans in
  use that day, AM then PM then CCA, by route number:
  `{ "data": [ { "id": 51, "label": "AM 1", "session": "am", "plan_id": 21, "riders_count": 18, "start_time": "06:35", "end_time": "07:20", "vehicle_plate": "PD6604E" } ] }`.
  Chips = `label`; "All Routes" = `route_ids: ["all"]`; the audience line "N riders on M routes" adds up `riders_count`.
  An empty list = "No routes in use for this school". Schools for the picker: `GET /schools`.
- `route_ids` must be routes of plans in use while the notice runs: else `422` "Pick routes in use at this school".
- Refused: WhatsApp (`notice[whatsapp]`) "WhatsApp is not available yet"; `{min}` / `{time}` left in the message; no audience; no channel; end before start; editing an active or ended notice.
- Push and SMS are recorded in `sent` (sending comes with the apps).

---

## 13. New External Vehicle

`POST /vehicles/external`

```json
{ "plate": "PA1234X", "seats": 45, "driver_name": "Muthu", "driver_phone": "91234567",
  "company": { "name": "Kallang Bus Charter", "phone": "+65 9123 4567", "paynow_uen": "201912345K" },
  "vehicle_id": null }
```

- The company is matched by name (any case) or created. `vehicle_id` edits an existing external vehicle.
- A new one is refused at the company's cap: "All 10 external vehicle slots are used. Remove one in External Vehicles, or ask Convoy to raise the limit".
- Returns the vehicle (same shape as `GET /vehicles/:id`). To put a run on it, call `move` (section 3).

---

## 14. Edit Vehicle

Edit Vehicle (vehicle panel) opens the vehicle form.

### 14.1 Vehicle

| Action | Call |
| --- | --- |
| Open | `GET /vehicles/:id` |
| Save | `PATCH /vehicles/:id` `{ "vehicle": { plate, seats, make, model, year_made, registered_on, chassis_number, engine_number, coe_expires_on, road_tax_expires_on, tags (list or "Coach, VIP"), notes, photo (file), remove_photo, operator_id, vehicle_team_id, driver_name, driver_phone } }` |
| Add | `POST /vehicles` (same body) |
| Remove | `DELETE /vehicles/:id` → `204`; `422` "<plate> still has 2 runs and 1 workshop visit from now on. Move or cancel them first, then delete the vehicle" (refused while it has runs or scheduled visits from now on) |
| Vehicles page list | `GET /vehicles` with the filters of section 1 and `meta.facets` |

Log card details on the form (all optional, send `""` or `null` to clear):

| Field | Form label | Format |
| --- | --- | --- |
| `registered_on` | Registration Date | `YYYY-MM-DD` |
| `chassis_number` | Chassis Number | text, saved trimmed and upper case |
| `engine_number` | Engine Number | text, saved trimmed and upper case |
| `coe_expires_on` | COE Expiry | `YYYY-MM-DD` |
| `road_tax_expires_on` | Road Tax Expiry | `YYYY-MM-DD` |

The same fields come back on `GET /vehicles/:id`. A date that can't be read → 422 `{ details: { coe_expires_on: ["is not a valid date"] } }`.

While `plate_conflict` is true (the log card shows another plate), saving is refused until the plate is picked (14.3).

### 14.2 Default driver (own buses)

| Action | Call |
| --- | --- |
| History with periods | `GET /vehicles/:vehicle_id/driver_schedules` → `[{ id, starts_on, start_time, ends_on, ends_at, driver { id, name, phone } }]` |
| Change Default Driver from a date (may be ahead) | `POST /vehicles/:vehicle_id/driver_schedules` `{ "vehicle_driver_schedule": { driver_id, starts_on, start_time } }` (same date and time replaces) |
| Remove an upcoming change | `DELETE /vehicles/:vehicle_id/driver_schedules/:id` (only ones not started) |
| Driver list | `GET /drivers?status=active` |

`start_time` (optional, "HH:MM", default "00:00" = the whole day): a driver who switches buses during the day (from 06:30 on
PC1234X): runs on the bus starting from that time take the new driver, earlier runs keep the old one (enter the same time
on the other bus with its new driver, or none). A period that ends during a day has `ends_on` = that day and `ends_at` =
the time; otherwise `ends_at` is null. The driver does the handover inspection in the Convoy Driver app (Switch Vehicle).

Managed (operator) buses: the driver is the operator driver on the bus: `PATCH /operator_drivers/:id/assign_vehicle` `{ vehicle_id }`
(swaps with the driver already on it). Runs take the new driver in the background.

### 14.3 Log card

| Action | Call |
| --- | --- |
| Current and past cards | `GET /vehicles/:vehicle_id/log_cards` |
| Upload | `POST /vehicles/:vehicle_id/log_cards` (multipart `file`) or `{ document_read_id }` after a `log_card` read |
| Pick the plate when they differ | `PATCH /vehicles/:vehicle_id/log_cards/:id/resolve_plate` `{ "use": "card" | "vehicle" }` |
| Delete a past card | `DELETE /vehicles/:vehicle_id/log_cards/:id` |

Upload response: `{ data: card { current, plate_on_card, plate_conflict, file, uploaded_by }, meta: { filled: ["make", "chassis_number"] } }` —
empty vehicle fields are filled from what was read; show "Check each one before saving".

### 14.4 Insurance

| Action | Call |
| --- | --- |
| Current and Past Policies | `GET /vehicles/:vehicle_id/insurance_policies` |
| Start a policy by hand | `POST /vehicles/:vehicle_id/insurance_policies` `{ vehicle_insurance_policy: {...} }` |
| Save the current policy | `PATCH /vehicles/:vehicle_id/insurance_policies/:id` |
| Add a file (up to 5) | `POST /vehicles/:vehicle_id/insurance_documents` (multipart `file`, `kind`) or `{ document_read_id }` after an `insurance` read |
| Change a file's kind / remove it | `PATCH /vehicles/:vehicle_id/insurance_documents/:id` `{ vehicle_insurance_document: { kind } }` / `DELETE` |
| Renew Policy | `POST /vehicles/:vehicle_id/insurance_policies/renew` |
| Delete a past policy | `DELETE /vehicles/:vehicle_id/insurance_policies/:id` |

Policy fields: `insurer, policy_number, cover_type, starts_on, ends_on, excess, excess_third_party, hire_purchase_company, agent,
holder, premium (before GST), gst, total, debit_note_number, debit_note_date, paid_on`; read only `current, renewed_at,
expiry_status (expired / due_soon / valid / none), cover_months, documents [{ kind, kind_name, plate_on_document, plate_differs, file }]`.
Adding a file returns `meta: { filled, policy_id }`. `plate_differs: true` = show a warning (not blocking).
Renew moves the policy to Past Policies and starts a new one with insurer, agent, HP company and cover kept, starting the day after.

---

## 15. Lists the forms pick from

| List | Call | Notes |
| --- | --- | --- |
| Vehicle types | `GET /vehicle_types` | `[{ id, key, name, seats, label, enabled }]` — offer only `enabled` |
| Vehicle teams | `GET /vehicle_teams` | Manage Teams: `PUT /vehicle_teams/bulk` ([fleet.md § 1.2](fleet.md#12-manage-teams-put-vehicle_teamsbulk)), or `POST`, `PATCH`, `DELETE /vehicle_teams/:id` |
| Operators | `GET /operators?q[kind_eq]=managed` | `kind` managed / external, payment details, `valid_until` |
| Own drivers | `GET /drivers?status=active` | `meta.counts` per status; the Drivers page is in [fleet.md § 2](fleet.md#2-drivers-and-operator-drivers) |
| Operator drivers | `GET /operator_drivers?status=active` | |
| Attendants | `GET /attendants` | |
| Clients | `GET /clients` | Section 7.7 |
| Client sites | `GET /clients/:client_id/sites` | |
| Calendars | `GET /calendars` | |
| Saved Pick-up Points (company) | `GET /pickup_points` | School Run import |

---

## 16. Public Trip Tracking page

1. Share Tracking Link in the drawer: `POST /occurrences/:id/tracking_link` →
   `{ data: { token: "u8X...", expires_at: "2026-11-04T09:00:00+08:00", api_path: "/api/v1/public/tracking/u8X..." } }`.
   Build the page link (for example `Trip Tracking.dc.html?trk=<token>`) and copy it. Sharing again makes a new token (the old link stops).
2. The public page (no sign-in): `GET /public/tracking/:token`

```json
{ "data": { "company": "SimpleDrive", "trip_label": "TID103716-1", "title": "MBC Campus Shuttle", "kind": "Corporate Shuttle",
            "date": "2026-11-02", "start_time": "07:45", "end_time": "08:00", "starts_at": "...", "ends_at": "...",
            "stops": [ { "name": "Labrador Park MRT Exit A", "time": "07:45", "use": "pu", "lat": 1.2722, "lng": 103.8026 } ],
            "bus": { "plate": "PC8841T", "seats": 23, "picture": "coaster" }, "driver": "Siti",
            "state": "upcoming", "closes_at": "2026-11-03T08:00:00+08:00", "powered_by": "CONVOY" } }
```

`state`: `upcoming`, `live`, `done`. The link closes 24 hours after the run ends (`410 "This tracking link has closed"`).
`picture` is the default illustration key (`assets/fleet/iso/sq/<picture>.png`).

---

## 17. Values reference

| Value | Meaning |
| --- | --- |
| Trip `kind` | `ad_hoc` Ad Hoc / Charter, `corporate_shuttle`, `airport_transfer`, `disposal`, `school_run`; runs also `school_route` |
| Stop `use` | `pu` pick-up, `do` drop-off, `both`, `via` Waypoint Only |
| Run `status` | `scheduled`, `cancelled`, `completed` (ended, not cancelled), `removed` (no longer made by its trip but kept because of an issue or edits; not listed), `skipped` (the calendar skips the date; only in Trip History, never on the grid) |
| Run `grid_status` | `ok`, `live`, `done`, `unassigned`, `cancel`, `cancel_unassigned`, `replacement` |
| Run `overridden_fields` | What a person changed on this run: `vehicle_id`, `operator_cost`, `shift_minutes`, `status` |
| Run `run_key` | `d<direction>r<timing index>`: `d1r0` = Direction 1, first timing; `d2r1` = Return, second timing |
| Slot key | `<run_key>|<slot_no>` (`d1r0|2`), `trip|<slot_no>` for trips that are not shuttles |
| Driver `kind` (in runs) | `own`, `operator`, `external` (typed on the bus), `replacement` (typed in a replacement) |
| Vehicle `ownership` | `own`, `managed`, `external` |
| Vehicle `default_picture` | `sedan-4`, `mpv-6`, `mpv-vip-6`, `hiace-commuter-hr`, `coaster`, `coach-40`, `yutong-zk6117h` |
| Insurance `status` | `expired`, `due_soon` (30 days), `valid`, `none` |
| Replacement `kind` | `drv`, `veh`, `crew`, `hand` |
| Assignment `assignee` | `own`, `operator`, `none` |
| Pay / cost basis | `run`, `day`, `month` (`hour` for Disposal drops) |
| School plan session | `AM`, `PM`, `CCA` (`plan.session` in the route drawer) |
