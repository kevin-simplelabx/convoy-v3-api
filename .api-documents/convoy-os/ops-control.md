# Ops Control — API Guide

Ops Control (rail icon `desktop_windows`) is a control-station view of every trip whose first pick-up is in the next
2 hours. Each run is checked against fixed rules so the duty team can call the driver in time. You need the `vehicles` or
`plans` permission to see it. A Convoy Admin can see it but cannot acknowledge. Conventions are in
[README.md](../README.md); paths start with `/api/v1`.

The prototype ran on a demo clock with sample trips. The API uses **real data at server time**:

- runs that have a bus
- the driver's Convoy Driver app sign-in, and when they tapped Start / End
- the bus's last GPS report (the same data as [Live Map](live-map.md))
- what was recorded at the first pick-up

Alerts are stored. They are raised, cleared and escalated every time the board loads, and by a background job every
minute. **Poll `GET /ops_control` every 10–15 s.** Play the alarm sound on the FE when a new `severity: 2` alert `id`
appears.

> Until the driver app sends sign-ins, Start and GPS, staging uses sample data. `bin/rails live_map:simulate` covers these
> cases: logged in or not, started or not, on the way, running late, and no GPS. The rules only fire while runs are around
> the current time, so run it during the day.

## Contents

1. [The board](#1-the-board)
2. [Rules](#2-rules)
3. [Acknowledge](#3-acknowledge)
4. [Alert Log](#4-alert-log)
5. [Front-end only](#5-front-end-only)

---

## 1. The board

`GET /ops_control?tab=needs_action&client_id=&q=&sort=asc`

| Param | Values |
| --- | --- |
| `tab` | `needs_action` (default), `all`, `not_started`, `running`, `ended` |
| `client_id` | a client from `data.clients` |
| `q` | plate, driver, trip title, TID or client |
| `sort` | `asc` (earliest first pick-up first, default) or `desc` |

```json
{ "data": {
    "kpis": { "next_2_hours": 3, "window_until": "2026-11-02T10:00:00+08:00", "running": 3, "action_now": 3, "unacknowledged": 3,
              "at_risk": 1, "on_time_today": 50, "on_time_count": 1, "started_today": 2, "late_today": 1 },
    "banner": { "count": 3, "more": 0,
                "trips": [ { "occurrence_id": 40, "first_pickup_at": "2026-11-02T07:30:00+08:00", "plate": "SBA0004D",
                             "message": "No GPS for 7 min", "title": "WEN Shuttle", "trip_label": "TID000004", "client": "Google",
                             "route": "Boon Lay MRT to Mapletree Business City", "raised_at": "2026-11-02T08:00:00+08:00",
                             "escalated": false, "driver": { "name": "Tan Wei Ming", "phone": "+6591234471" } } ] },
    "tab": "needs_action",
    "counts": { "needs_action": 4, "all": 5, "not_started": 2, "running": 3, "ended": 0 },
    "clients": [ { "id": 3, "name": "Google" } ],
    "rows": [ {
      "id": 37, "key": "t12|2026-11-02|0|1|1", "date": "2026-11-02", "trip_label": "TID000001", "title": "WEN Shuttle",
      "client": { "id": 3, "name": "Google" }, "route": "Boon Lay MRT to Mapletree Business City",
      "vehicle_id": 48, "plate": "SBA0001A", "driver": { "name": "Tan Wei Ming", "phone": "+6591234471" },
      "first_pickup_at": "2026-11-02T08:10:00+08:00", "ends_at": "2026-11-02T10:00:00+08:00", "timeline_from": "2026-11-02T07:55:00+08:00",
      "state": "action_now", "severity": 2, "arrived_at": null,
      "app": { "status": "not_logged_in", "started_at": null, "ended_at": null, "signed_in_at": null, "last_seen_at": "2026-11-01T18:30:00+08:00" },
      "gps": { "status": "to_first_pickup", "last_ping_at": "2026-11-02T07:59:50+08:00", "distance_m": 300, "stops_reached": 0, "stops": 2 },
      "eta": { "at": null, "late_minutes": null },
      "alerts": [ { "id": 21, "kind": "login", "severity": 2, "message": "Driver not logged in to the Convoy Driver app",
                    "raised_at": "2026-11-02T08:00:00+08:00", "acknowledged_at": null, "acknowledged_by": null, "escalated": false },
                  { "id": 22, "kind": "start", "severity": 1,
                    "message": "Trip not started. First pick-up in 10 min. Driver is 300 m away but has not started", "…": "…" } ],
      "can_acknowledge": true, "acknowledged": null } ] },
  "meta": { "now": "2026-11-02T08:00:00+08:00", "duty": "Nur Aisyah",
            "rules": { "login_minutes": [20, 10], "start_minutes": [15, 5], "eta_late_minutes": [2, 5], "miss_after_minutes": 2,
                       "late_after_minutes": 2, "gps_minutes": [3, 6], "escalate_after_minutes": 3,
                       "window_ahead_minutes": 120, "window_behind_minutes": 15 } } }
```

**Which runs are listed:** runs with a bus, not cancelled, whose first pick-up is up to 2 hours from now and that ended
less than 15 minutes ago. A run without a bus belongs to the Scheduler's Unassigned list.

**KPIs** (cover all runs, not filtered):

| Tile | Field |
| --- | --- |
| Trips in Next 2 Hours | `next_2_hours` ("First pick-up before `window_until`") |
| Running Now | `running` |
| Action Now | `action_now`, with "`unacknowledged` alerts not acknowledged" or "All acknowledged" |
| At Risk | `at_risk` |
| On-Time Starts Today | `on_time_today` % (`null` → N/A); "`on_time_count` of `started_today` at first pick-up on time" |
| Late Starts Today | `late_today`: more than 2 min late, or not at the first pick-up at all |

**Banner:** "`count` trips need action now". It lists `trips` (up to 3) with Call (`tel:` the driver's phone) and
Acknowledge. Add "+`more` more in the table below" when `more` > 0. `escalated: true` means it went to the Ops Manager.

**Tabs:** use `counts`. They follow the client and search filters, as in the prototype.

**Row fields:**

- `state` drives the status chip and row colour:

  | `state` | Chip | Tone |
  | --- | --- | --- |
  | `action_now` | Action Now | danger |
  | `at_risk` | At Risk | warning |
  | `on_route` | On Route | success |
  | `on_the_way` | On the Way | success |
  | `ready` | Ready (logged in, not started) | info |
  | `scheduled` | Scheduled | info |
  | `completed` | Completed (row faded) | neutral |

- Time and countdown:
  - Show `first_pickup_at`.
  - Countdown before the pick-up: "in N min". After it: "N min overdue".
  - Once arrived (`arrived_at` set): "Arrived on time", or "Arrived N min late" when more than 2 min late.
- `app.status` (Driver App column):

  | `app.status` | Label and sub-line |
  | --- | --- |
  | `not_logged_in` | Not Logged In, "Last seen" `last_seen_at`. Red within 20 min of the pick-up. |
  | `not_started` | Not Started |
  | `started` | Started at `started_at` |
  | `running` | Running, "Started" `started_at` |
  | `ended` | Trip Ended |
  | `no_account` | No App: the driver was typed in, with no app account |

- `gps.status` (GPS column):

  | `gps.status` | Label and sub-line |
  | --- | --- |
  | `to_first_pickup` | `distance_m` to the first pick-up (show km above 1000), plus how long ago `last_ping_at` was |
  | `on_route` | Stop `stops_reached` of `stops` |
  | `no_signal` | No signal, "Last ping N min ago" |
  | `at_drop_off` | At drop-off |

- `eta` (ETA column):
  - `eta.at` is set once the driver has started.
  - It is a straight line at 30 km/h from the last position.
  - Show `+late_minutes min` when more than 2, otherwise "On time".
  - Not started shows N/A; arrived shows "At first pick-up".
- Timeline bar:
  - The bar runs from `timeline_from` (15 min before the first pick-up) to `ends_at`.
  - The marker is at `first_pickup_at`.
  - Draw the scale from now − 15 min to now + 2 h; the "now" line uses `meta.now`.
- Issue column:
  - Show `alerts[0].message`, and "(+N more)" when there are more alerts.
  - `alerts` is ordered most severe first. Their messages are live: the minutes update on every load.
- Acknowledge:
  - Show the button when `can_acknowledge` is true.
  - Once every open alert is acknowledged, `acknowledged` = `{ at, by }`. Show "Acknowledged HH:MM by Name".
- Call: `tel:` + `driver.phone`.

## 2. Rules

These are the same as the prototype. They are fixed values returned in `meta.rules`, so the Rules card text can be static.

| Kind | Raised when | Warning | Action |
| --- | --- | --- | --- |
| `login` | Driver not logged in to the app before the first pick-up | 20 min before | 10 min before |
| `start` | Trip not started (the message adds "Driver is N m away" when under 1 km) | 15 min before | 5 min before |
| `eta` | Started; ETA to the first pick-up is late by | more than 2 min | more than 5 min |
| `miss` | Not at the first pick-up 2 min after the scheduled time | — | always |
| `late` | Reached the first pick-up more than 2 min late (shown for 10 min after arriving) | always | — |
| `gps` | Started, and no GPS for | 3 min | 6 min |

- Severity is `1` for Warning (At Risk) and `2` for Action.
- An alert **clears** by itself when its condition stops. For example, the driver logs in, or the warning becomes an
  action, which is a new alert.
- Action alerts not acknowledged within 3 minutes are **escalated** (`escalated: true`) to the Ops Manager. Only the time
  is recorded; no message is sent yet.
- Runs that have ended raise nothing.

## 3. Acknowledge

`POST /ops_control/runs/:id/acknowledge` (`:id` = the row `id` or the banner `occurrence_id`) returns:

```json
{ "acknowledged": 2, "at": "2026-11-02T08:04:00+08:00", "by": "Nur Aisyah" }
```

- It acknowledges every open alert of the run, as the signed-in user (the person on duty, `meta.duty`).
- It stops the alarm and the escalation. The trip **stays flagged** until the problem clears.
- Returns 422 "Nothing to acknowledge on this trip" when nothing is open and unacknowledged.
- Reload the board afterwards.

## 4. Alert Log

`GET /ops_control/log` returns the alerts raised today, newest first (60):

```json
{ "data": [ { "id": 21, "occurrence_id": 37, "kind": "login", "severity": 2, "message": "Driver not logged in to the Convoy Driver app",
              "raised_at": "…", "plate": "SBA0001A", "title": "WEN Shuttle", "trip_label": "TID000001", "client": "Google",
              "status": "acknowledged", "acknowledged_at": "…", "acknowledged_by": "Nur Aisyah", "escalated_at": null, "cleared_at": null } ],
  "meta": { "count": 1 } }
```

- `message` is the text at the time the alert was raised.
- `status` maps to these chips: `open` (danger / warning), `acknowledged` (info), `escalated` (danger), `cleared`
  (success).
- The sub-line is the trip and client, plus "Acknowledged HH:MM by Name".
- The count reads "`meta.count` alerts today".

## 5. Front-end only

The FE handles these without the API:

- The alarm sound on new red alerts: compare alert `id`s between polls.
- Full Screen, How It Works and the ⓘ explainers.
- The clock (`meta.now` plus elapsed time) and the company / date header.

Not built yet: the Convoy OS "Requests" banner above Ops Control (School Bus applications) comes with School Bus.
