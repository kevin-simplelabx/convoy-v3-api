# Live Map — API Guide

The Live Map menu (rail icon `map`) shows every bus now: on a trip, available or offline. You can open a bus to see its
device and the stops of its run, trace it, or replay a run. You need the `vehicles` or `plans` permission (read only; a
Convoy Admin sees it too). Conventions are in [README.md](README.md); paths start with `/api/v1`.

Positions come from the **last report of each bus's device**: the Convoy Driver app on the driver's phone, or a GPS
tracker fitted to the bus. Progress on a run comes from what was recorded at its stops. The prototype ran on a demo clock
with sample routes. The API has no clock: **"now" is the server time**. Poll `GET /live_map` (every 10–15 s is enough) and
let markers glide between reports on the front end.

> Until the driver app and trackers send real pings, staging has sample data. `bin/rails live_map:simulate` writes "now"
> for the seed company (buses on a run get GPS points and stops passed; others park; two are offline). `LOOP=10` keeps it
> moving. It only produces buses "On Trip" while runs are in progress, so run it during the day.

## Contents

1. [The board](#1-the-board)
2. [One bus](#2-one-bus)
3. [Trace and Replay](#3-trace-and-replay)
4. [Front-end only](#4-front-end-only)

---

## 1. The board

`GET /live_map?q=&state=&team_id=` returns the Fleet panel, the markers and the counts:

```json
{ "data": [
    { "id": 4, "plate": "SBA3546A", "make": "Mitsubishi", "model": "Rosa", "seats": 29, "ownership": "own", "operator": null,
      "team": { "id": 1, "name": "East", "color": "#008C95" },
      "driver": { "name": "Tan Wei Ming", "phone": "+65 9123 4471" },
      "state": "on_trip", "online": true, "on_map": true,
      "position": { "lat": 1.2801, "lng": 103.8102, "speed_kmh": 38, "heading": 90, "recorded_at": "2026-11-02T08:19:55+08:00" },
      "last_reported_at": "2026-11-02T08:19:55+08:00", "road": null,
      "device": { "kind": "gps_tracker", "name": "OTW GPS T-8 tracker" },
      "run": { "id": 492, "trip_label": "TID103716-3", "title": "MBC Campus Shuttle", "client": "Google Asia Pacific",
               "date": "2026-11-02", "key": "t8|2026-11-02|2|1|1", "kind": "corporate_shuttle", "kind_name": "Corporate Shuttle",
               "trip_id": 8, "school_route_id": null,
               "starts_at": "2026-11-02T08:15:00+08:00", "ends_at": "2026-11-02T08:30:00+08:00",
               "points": 3, "points_done": 1,
               "next_stop": { "position": 1, "number": 2, "last": false, "name": "Alexandra Road (Opp Blk 1)",
                              "planned_at": "2026-11-02T08:22:00+08:00", "at_stop": false, "arrived_at": null,
                              "eta_at": "2026-11-02T08:24:00+08:00", "late_minutes": 2 } },
      "next_run": { "id": 494, "trip_label": "TID103716-5", "title": "MBC Campus Shuttle", "client": "Google Asia Pacific",
                    "starts_at": "2026-11-02T08:45:00+08:00" },
      "last_run": null } ],
  "meta": { "counts": { "on_trip": 6, "available": 5, "offline": 2 }, "now": "2026-11-02T08:20:00+08:00",
            "teams": [ { "id": 1, "name": "East", "color": "#008C95" } ], "offline_after_minutes": 15 } }
```

- Every kept bus is listed (own, managed and external), sorted by plate. `q` matches the plate or the driver's name;
  `state` and `team_id` filter. `meta.counts` covers all buses and is not filtered, which suits the On Trip / Available /
  Offline chips. Group by team on the FE with `team` (no team = "No Team", grey).
- `state`:
  - `on_trip`: the bus has a run that has started and not ended.
  - `available`: the device reported in the last `offline_after_minutes`.
  - `offline`: no report for that long, or no device at all.
  
  A bus on a trip whose device went quiet keeps `on_trip` with `online: false`.
- An offline bus stays on the map at its last position (grey marker), however long ago that was. `on_map: false` only
  when the bus has never reported (`position: null`); the row shows "Not on map". `position` is the last report. `speed_kmh` is 0 when offline.
- `driver`: the run's driver, or the bus's default driver today.
- Row text:
  - **On a trip:** `run.client | run.title | to Point {next_stop.number} of {run.points}`. The right side shows
    `ETA {next_stop.eta_at}`, or `Arrived {arrived_at}` when `next_stop.at_stop` is true (the chip then reads "Arrived";
    otherwise "On the way"). "Last Point" when `next_stop.last`.
  - **Available:** "Next trip starts {next_run.starts_at}", or `{last_run.title} | ended {last_run.ended_at}`.
  - **Offline:** "Since {last_reported_at}" plus how long ago.
- `eta_at` is estimated as a straight line at 30 km/h from the last position. It is the planned time when there is no
  fresh position. `late_minutes` = ETA (or arrival) minus the planned time, never below 0.
- `road` is always `null` for now (road names need a map service). Hide the Road line.

## 2. One bus

`GET /live_map/vehicles/:id` is used when a bus is clicked (the Vehicle and Device window and the trip drawer). It
returns the same row plus:

```json
{ "device": { "id": 4, "kind": "gps_tracker", "name": "OTW GPS T-8 tracker", "sharing_enabled": true,
              "report_interval_seconds": 10, "battery_pct": 78, "gps_signal": "good", "gsm_bars": 2 },
  "run": { "…": "as in the board",
           "on_board": 6, "eta_last": "2026-11-02T08:32:00+08:00",
           "stops": [ { "position": 0, "name": "Labrador Park MRT Exit A", "use": "pu", "lat": 1.2722, "lng": 103.8025,
                        "planned_at": "2026-11-02T08:15:00+08:00", "arrived_at": "2026-11-02T08:15:00+08:00",
                        "departed_at": "2026-11-02T08:15:40+08:00", "skipped": false, "state": "done",
                        "students": [ { "key": "…", "name": "Aiden Tan", "class_name": "P3A", "status": "boarded",
                                        "boarded_at": "…", "alighted_at": null } ] } ] } }
```

- Vehicle and Device rows:

  | Row | Source |
  | --- | --- |
  | Vehicle | `plate`, `make` / `model` |
  | Current Driver | `driver.name` |
  | Speed | `position.speed_kmh`; N/A when offline |
  | Current Trip | `run.title`, `run.trip_label`, `run.client` |
  | Timestamp / Last Online | `last_reported_at` |
  | Device | `device.name` |
  | GPS Signal | `device.gps_signal`: good / fair / poor / none ("No fix" when none) |
  | GSM Signal | `device.gsm_bars` of 4 |
  | Battery Level | `device.battery_pct` ("at last report" when offline) |

- Location Sharing is "Enabled" when `device.sharing_enabled` and the bus is online. The note under it reads "GPS tracker
  reporting every {report_interval_seconds} s" for `gps_tracker`, or "Driver app sharing in the background" for
  `driver_app`. The **Check** button has no API yet (it needs the driver app). Hide it, or refetch this endpoint.
- Trip drawer:
  - Points `points_done` of `points`, `on_board` (boarded minus alighted so far), ETA Last `eta_last`.
  - Stops in travel order. `state` is `done` (reached or skipped), `current` (heading there) or `upcoming`. Show
    `arrived_at` for done stops and `planned_at` for the rest.
  - `students` is filled only for School Run trips (matched by stop name). `status` is `boarded` / `alighted` / `absent`
    / `not_marked`. The label depends on the stop:
    - at a pick-up that is done: Picked up / Absent
    - at the current stop: Waiting
    - otherwise: Not yet
    - at the last stop: Dropped off / On board
- Draw the route line through the stops' `lat` / `lng` (the API has no road geometry).
- `run` is `null` when the bus is not on a trip. In that case show "No trip running now" with the available / offline
  text from section 1.

## 3. Trace and Replay

**Trace** (live, only for a bus on a trip): `GET /live_map/runs/:run_id/track` gives the points so far. After that,
`?since={last point's at}` returns only the new ones:

```json
{ "columns": ["at", "lat", "lng", "speed_kmh", "heading"],
  "points": [ ["2026-11-02T08:15:00+08:00", 1.2722, 103.8025, 0.0, 120] ],
  "speed_limit_kmh": 80,
  "stops": [ { "position": 0, "name": "Labrador Park MRT Exit A", "lat": 1.2722, "lng": 103.8025,
               "planned_at": "…", "arrived_at": "…", "departed_at": "…", "skipped": false } ] }
```

Colour each segment by speed on the FE (< 20, < 40, < 60, < 80, < 100, ≥ 100 km/h, as in the prototype).

**Replay**: pick a date and a bus, then load `GET /live_map/vehicles/:id/runs?date=2026-11-02`:

```json
{ "data": [ { "id": 492, "key": "t8|2026-11-02|2|1|1", "trip_label": "TID103716-3", "title": "MBC Campus Shuttle",
              "client": "Google Asia Pacific", "status": "completed", "starts_at": "…", "ends_at": "…",
              "points": 46, "track_from": "…", "track_to": "…" } ],
  "meta": { "date": "2026-11-02" } }
```

Runs with `points: 0` have no GPS and cannot be replayed. Load the chosen run with `GET /live_map/runs/:id/track` and
play it on the FE. The range is `track_from` to `track_to`; speeds are 1×, 10× and 60×. Runs that are over can also be
opened in Trip History (`GET /trip_history/:id`).

## 4. Front-end only

The FE handles these without the API:

- Map themes (Grey, Muted, Standard, Satellite) and the Plates, Drivers and Route Lines toggles.
- Fit, the panel toggle, hover highlight and the clock.
- Replay play / pause and speed.

Not built yet:

- **Rain** (radar plus the NEA 2-hour forecast) and **Traffic** (LTA speed bands): hide these toggles.
- **Road** name.
- The location **Check** button.
