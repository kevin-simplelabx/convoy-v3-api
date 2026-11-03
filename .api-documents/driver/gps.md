# Driver app — GPS, geofence and settings

The phone is the bus's GPS: it sends its position while a trip runs or is coming, and the 30 m geofence of each point
starts the Arrive countdown. The office sees the bus in Live Map, Ops Control and School Live Ops; parents and clients on
tracking links; Trip History keeps the trace.
Conventions: [README.md](README.md). Paths start with `/api/v1`. Needs a picked company.

## Contents

1. [App settings](#1-app-settings-get-driverconfig)
2. [Send positions](#2-send-positions-post-driverpositions)
3. [Geofence alert](#3-geofence-alert-post-driverrunsidgeofence)
4. [How an arrival is confirmed](#4-how-an-arrival-is-confirmed)

---

## 1. App settings: `GET /driver/config`

Read on sign-in and after Switch Company:

```json
{ "data": {
  "gps": { "accuracy": "best", "interval_seconds": 5, "distance_filter_m": 10, "heartbeat_seconds": 300, "geofence_radius_m": 30,
           "arrive_countdown_seconds": 10, "leave_countdown_seconds": 10, "after_trip_minutes": 15, "max_points": 500 },
  "start_early_minutes": 60, "late_warning_minutes": 30,
  "reasons": { "skip_stop": ["No Passengers", "..."], "skip_trip": ["Traffic Congestion", "..."], "force_end": ["Vehicle breakdown", "..."] },
  "date_format": "dmy", "time_format": "24"
} }
```

- `gps` is the same for every company (no per-company settings): best accuracy (iOS `kCLLocationAccuracyBest`, Android
  `PRIORITY_HIGH_ACCURACY`), a point every `interval_seconds` **and** at least `distance_filter_m` moved (nothing while
  stopped at a light), a forced point every `heartbeat_seconds` when not moving, a native geofence of
  `geofence_radius_m` around each point, and positions for `after_trip_minutes` after the trip ends.
- `start_early_minutes` / `late_warning_minutes`: Swipe to start opens 60 minutes before; more than 30 minutes late shows
  the warning. `reasons`: the lists for Skip, Skip Trip and Force End ([driving.md § 12](driving.md#12-errors-and-reasons)).
- `date_format` (`dmy`, `mdy`, `ymd`, `dmon`) and `time_format` (`24`, `12`): the company's defaults for the Configurations
  screen (the driver may change them on the phone).

## 2. Send positions: `POST /driver/positions`

`{ points: [ { at, lat, lng, speed_kmh, heading, accuracy_m, battery_pct, gsm_bars } ] }` → `{ recorded, run_id, vehicle, arrived }`.

```json
{ "data": { "recorded": 12, "run_id": 812, "vehicle": { "id": 7, "plate": "PD997M" }, "arrived": [0] } }
```

- Send in batches (every 15–30 s while driving is fine; up to `max_points` points), oldest first or in any order.
  When offline, keep the points and send them when back: late points go into the trip's trace and do not move the bus
  back on the map.
- `at` ISO 8601 (required), `lat` / `lng` (required), `speed_kmh`, `heading` (degrees), `accuracy_m` (the phone's
  accuracy: shown to the office as GPS Good / Fair / Poor), `battery_pct`, `gsm_bars` (0–4). Points older than 48 hours
  are dropped; times in the future count as now.
- The points go to the trip the driver has on the road (or the bus's run at that time) and to the bus the driver is on
  (`vehicle`). A driver on no bus today: `recorded: 0, vehicle: null` (nothing stored).
- `arrived`: positions of points the server just marked as arrived from these points (§ 4) — refresh Trip Details.
- `422` "Each point needs at (ISO 8601), lat and lng", "Send 500 points at most".

## 3. Geofence alert: `POST /driver/runs/:id/geofence`

`{ position, event: "enter" | "exit", at }` — at once, when the phone's geofence fires for a point of the trip on the road
(also start the app's 10-second Arrive countdown). → `{ position, entered_at, exited_at, arrived_at }`.

- `enter`: the server starts its 15-second clock for the point, and arrives at once when the bus's last report is slow
  (5 km/h or less) — `arrived_at` is then set.
- `exit` before arriving = drove past: the clock is cleared.
- The driver's Arrive ([driving.md § 3](driving.md#3-arrive-at-a-point-post-driverrunsidarrive)) still records the
  arrival; send it after the countdown as usual (the first arrival time is kept).
- `422` code `not_started` when the trip is not on the road; "event must be enter or exit".

## 4. How an arrival is confirmed

Dual trigger (decided 26/10/2026): the phone's geofence gives the fast alert; the server confirms from the GPS. The next
point not reached yet is marked arrived when the bus is inside its 30 m circle **and** either slow (5 km/h or less) or
inside for 15 seconds (from the alert, or the first point inside). A bus driving past in the next lane does neither.
This fills an arrival the driver did not send (the phone in a pocket, the app closed); Leave stays the driver's.
