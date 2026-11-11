# Client Portal — Map (today)

Only the client's own runs today, on the sites the person covers ("today only for now"). Positions come from the
Driver app / trackers, and a bus shows only while it is **On the way** or **Started** on this client's run (the same bus
may run for other clients the rest of the day). Poll every 20–30 s while the page is open.

## 1. `GET /portal/map?activity=&site_id=`

```json
{ "data": {
  "date": "2026-11-04", "now": "2026-11-04T07:20:00+08:00", "site": null,
  "sites": [ { "id": 1, "name": "Punggol", "lat": 1.4043, "lng": 103.902 } ],
  "activities": [ { "key": "am", "label": "AM", "count": 3, "on_road": 1 }, { "key": "shuttles", "label": "Shuttles", "count": 13, "on_road": 2 } ],
  "activity": "am",
  "schools": [ { "id": 2, "name": "Bright Steps (Punggol)", "lat": 1.4043, "lng": 103.902 } ],
  "counts": { "scheduled": 7, "on_the_way": 1, "started": 1, "ended": 4 },
  "runs": [ … ] } }
```

- **Site** pills (when `sites` has more than one): All Sites, or `site_id` = one site (its trips, its school).
- **Activities** pills (when more than one): `am` AM, `pm` PM, `asa` CCA (school bus sessions of the schools linked to the
  client or the person's sites), `bookings` Bookings (the client's one-off trips made from a Portal booking, so `booking` is always set; Members see only trips from their own
  bookings), `shuttles` Shuttles. Without `activity`: the one with buses on the road, else the next to start, else the first.
- `count` / `on_road` of an activity are counted from the same runs the list shows (`state` of each run), so a pill and its
  list always agree. **School Bus runs have no On the way**: they are `scheduled` until the bus starts, `started` while
  on the road, `ended` once arrived. Bookings and Shuttles also use `on_the_way` (the driver started, or 30 minutes before
  the start when there is no Driver app).
- **Trip States** counters filter the list: Started, On the way, Scheduled, Ended (`state` of each run).
- A run with no Driver app events (no `arrived_at` / `departed_at` on its stops) goes `started` at its start and `ended`
  at its planned end by the clock.

A run (Bookings, Shuttles):

```json
{ "id": 901, "date": "2026-11-04", "kind": "corporate_shuttle", "kind_label": "Shuttle, morning", "title": "Staff Shuttle", "label": "S-08", "site": { "id": 1, "name": "Punggol" },
  "starts_at": "…", "ends_at": "…", "state": "on_the_way", "state_label": "On the way",
  "booking": null, "bus": { "plate": "PD6604E", "model": "Yutong ZK6107", "seats": 40 }, "driver": { "name": "Kumar" },
  "next_stop": { "name": "Blk 101 Punggol Field", "planned_at": "…", "eta_at": "…" },
  "position": { "lat": 1.3984, "lng": 103.9072, "speed_kmh": 25, "heading": 90, "recorded_at": "…" },
  "line": [ [1.3984, 103.9072], [1.4043, 103.902] ] }
```

`kind` is the trip kind (`ad_hoc`, `airport_transfer`, `disposal`, `corporate_shuttle`) and `kind_label` the text for the
row ("Ad Hoc / Charter", "Ad Hoc / Charter, Two Way", "Two Way, return", "Airport Transfer", "Disposal", "Shuttle, morning",
"Shuttle, evening"). `site` is the trip's own site, else the first stop site the person covers (a site picked in
`site_id` wins); `null` only when no site of the run is in view (no stop has a client site either, e.g. a trip made in Convoy OS with free-text stops).

A School Bus run: the [School Live Ops row](../convoy-os/school-bus-live.md) (`occurrence_id`, `label`, `plate`,
`driver`, `status`, `late_minutes`, `points`, `points_done`, `counts` of children, `next_stop { name, at_stop, expected_at }`,
`end_at`, `line`, `position` while on the road) plus `id`, `kind: "school_bus"`, `kind_label` ("School bus, morning" /
"School bus, afternoon" / "School bus, CCA"), `title`, `school`, `bus { plate }` (`null` without a bus), `state`, `state_label`.

Row text: time range, state badge, title, "site | kind | booking number | plate | N students", then "Next: <stop>,
<eta_at>" / "Heading to <stop>, due <planned_at>" / "On the map from <starts_at − 30 min>" / "Ended <ends_at>" / "No bus
assigned yet. Ask <company>" (`bus: null`). `booking` → **Open Booking <number>** (`GET /portal/bookings/:id`).

## 2. `GET /portal/map/runs/:id` — the trip card

- Bookings / Shuttles: the run fields plus `stops [{ position, name, use, planned_at, lat, lng, arrived_at, departed_at, skipped }]`.
- School Bus: the [School Live Ops run detail](../convoy-os/school-bus-live.md) — bus, crew (driver, bus attendant), the
  next stop, counts (total, on board, waiting, at school / dropped off, absent, Bus Not Required) and each stop with its
  **`students`** and their status (Convoy OS calls the same list `riders`). The run row's fields are merged in: `id`,
  `kind`, `kind_label`, `title`, `school`, `bus`, `state`, `state_label`. `position` is `null` unless `state` is `started`.

`404` for a run that is not the client's, not today, or not on the person's sites.

## 3. `GET /portal/map/students?q=` — find a student

At least 2 characters (name, level or rider id); up to 6 legs from today's School Bus runs:

```json
[ { "rid": "K-1", "name": "Aisha Tan", "level": "K2", "school": "Bright Steps (Punggol)", "session": "am", "session_label": "AM",
    "run_id": 77, "route": "AM 1", "plate": "PD6604E", "stop": "Blk 101 Punggol Field", "planned_at": "…",
    "status": "waiting", "boarded_at": null, "alighted_at": null } ]
```

"Picked up / Dropped off HH:MM at <stop>"; click → the run (`run_id`) with the student highlighted. `status`: `waiting`,
`on_board`, `at_school`, `dropped_off`, `not_required` (Bus Not Required), `no_show`.
