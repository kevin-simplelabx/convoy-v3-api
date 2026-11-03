# Driver app — Driving a trip

On Route: Swipe to start (On the Way), Arrive and Leave (by hand or after the geofence countdown), Skip a point,
Take Attendance (tick or QR scan), Count passengers, Edit Route, Complete Trip, Force End Trip, Skip Trip.
Conventions: [README.md](README.md). Paths start with `/api/v1`. The trip and its points: [runs.md](runs.md).

## Contents

1. [How every action works](#1-how-every-action-works)
2. [Start the trip](#2-start-the-trip-post-driverrunsidstart)
3. [Arrive at a point](#3-arrive-at-a-point-post-driverrunsidarrive)
4. [Leave a point](#4-leave-a-point-post-driverrunsidleave)
5. [Skip a point](#5-skip-a-point-post-driverrunsidskip_stop)
6. [Take attendance](#6-take-attendance-post-driverrunsidattendance)
7. [Count passengers](#7-count-passengers-post-driverrunsidcount)
8. [Edit Route](#8-edit-route-patch-driverrunsidroute)
9. [Complete the trip](#9-complete-the-trip-post-driverrunsidcomplete)
10. [Force End Trip](#10-force-end-trip-post-driverrunsidforce_end)
11. [Skip the whole trip](#11-skip-the-whole-trip-post-driverrunsidskip)
12. [Errors and reasons](#12-errors-and-reasons)

---

## 1. How every action works

Every action is `POST /driver/runs/:id/<action>` (Edit Route: `PATCH /driver/runs/:id/route`) with at least:

```json
{ "client_id": "6b1f0c2e-7d7a-4f53-9b0e-1f2a3c4d5e6f", "at": "2026-11-03T07:58:12+08:00" }
```

- `client_id`: a new UUID made by the app **for each action** (keep it with the action until the server answers).
  Sending the same `client_id` again does nothing the second time and answers `meta.replayed: true`. So when there is no
  signal, queue the actions with their `client_id` and `at`, and send them in order when back online ("You're offline,
  actions will be sent later").
- `at`: when it happened on the phone (ISO 8601). Times in the future count as now. Optional (now).
- The answer is the trip as in [`GET /driver/runs/:id`](runs.md#4-trip-details-get-driverrunsid) after the action, plus
  `meta: { replayed }`. Refresh the screen from it (points `record`, passengers `state`, `status`).
- `position` names a point: the `position` of `points` in Trip Details (not the number shown).
- Only the run's driver can act: a replaced trip answers `422` code `replaced`; cancelled `cancelled`; after the end
  `ended` (attendance can still be corrected).

The usual order for each point: arrive → (attendance or count) → leave. At the last point: arrive → complete.

## 2. Start the trip: `POST /driver/runs/:id/start`

Swipe to start (On the Way). `{ client_id, at }`.

- Allowed from 60 minutes before the start: `422` code `too_early` "You can start this trip from 07:00" (show the
  countdown until then). Starting more than 30 minutes late is allowed (the app shows its warning from `starts_at`).
- One trip on the road at a time: `422` code `busy` with `details.run_id` (show the other trip as Busy).
- `422` code `started` if it was started already.
- After it: `status: "on_the_way"`; `"started"` once the first point is left.

## 3. Arrive at a point: `POST /driver/runs/:id/arrive`

`{ client_id, at, position }`. Arrive by hand, or when the 10-second countdown after the geofence ends.

- `422` code `not_started` before Start; "… is a waypoint: drive through it" for a `waypoint` point.
- Arriving again keeps the first arrival time.

## 4. Leave a point: `POST /driver/runs/:id/leave`

`{ client_id, at, position, boarded, alighted, on_board, force }`.

- `422` code `not_arrived` "Arrive at … first".
- **Names (School Bus, School Run)**: every child who should board here (or alight, except at the school) must be ticked
  first: `422` code `attendance_needed` with `details: { missing: 2, names: ["Aaron Lee", "Megan Lee"] }` → show the
  Leave without attendance warning. `force: true` leaves anyway and records "left early, 2 not there". `boarded` /
  `alighted` are counted from the names; do not send them.
- **Count (`requires: "count"`)**: count first with § 7, or send `boarded` / `alighted` here. Without a count:
  `422` code `count_needed`; `force: true` leaves without one.
- `on_board`: passengers on the bus after the point; optional (worked out from the counts).
- Leaving the last point does not end the trip: use Complete (§ 9).

## 5. Skip a point: `POST /driver/runs/:id/skip_stop`

`{ client_id, at, position, reason, auto }`.

- `reason`: one of § 12 (or any short text). `auto: true` = the app skips a point where nobody rides today (everyone Bus
  Not Required or not boarding, or skipped in Edit Route) — no reason needed ("No one boarding today").
- `422` "… was already reached" after leaving it.

## 6. Take attendance: `POST /driver/runs/:id/attendance`

`{ client_id, at, marks: [ { id, state, method, lat, lng } ] }` — one or many children at once (Confirm on the sheet,
each QR scan, a correction in All Passengers).

- `id`: the passenger `id` in Trip Details. A QR scan: match the scanned code with the passengers' `qr_code` in the app
  (no call needed to check it); unknown code → "Not on this trip".
- `state`: `boarded`, `not_boarded` (Not Boarded: not at the stop), `alighted`, or `expected` to undo a tick.
- `method`: `tick` (default), `qr`, `card`, `palm`. `lat` / `lng`: where the phone was (optional; shown to the school).
- `422` code `not_on_trip` "S-9 is not on this trip".
- Allowed after the end too, to correct a mark.

## 7. Count passengers: `POST /driver/runs/:id/count`

`{ client_id, at, position, boarded, alighted }` (0 or more each). Runs without names; then leave (§ 4).

## 8. Edit Route: `PATCH /driver/runs/:id/route`

`{ client_id, at, skip: [positions], not_boarding: [passenger ids] }` — the **whole set** each time (what the sheet shows
when Done is tapped): points skipped today and children not riding today. Before the trip or on the way.

- A skipped point shows `record.skipped: true` (skip it on the road with § 5 `auto: true`, or just drive on); points
  already reached are not changed.
- Children listed get `state: "not_boarding"` (Before You Go); children taken off the list go back to `expected`.
  Bus Not Required from the parents is not changed here.

## 9. Complete the trip: `POST /driver/runs/:id/complete`

`{ client_id, at, feedback }` at the last point (Complete Trip sheet: "you arrived with N passengers, check everyone
alighted"; Driver's Feedback, optional).

- Everyone still on the bus alights (names: `state` → `alighted`); the last point gets its arrival and departure if not
  sent; the trip ends (`status: "ended"`). `feedback` goes to the office (Trip History › driver report).
- `422` code `not_started` before Start.

## 10. Force End Trip: `POST /driver/runs/:id/force_end`

`{ client_id, at, reason, called_operations: true, feedback }` (the warning: call operations, pick a reason, tick that
operations was called).

- `reason`: one of § 12. Without `called_operations: true`: `422` code `call_operations`.
- The trip ends where it is: points not reached are recorded as skipped ("Trip force ended"); who is still on the bus is
  recorded for the office. Trip History shows "Force ended: <reason>".

## 11. Skip the whole trip: `POST /driver/runs/:id/skip`

`{ client_id, at, reason }`, before leaving the first point. `reason`: one of § 12.

- The trip is not run: `status: "skipped"` ("Skipped"); Trip History shows Skipped by Driver; the client is not charged
  and the driver is not paid for it (as a trip cancelled by the company).
- After the first point is left: `422` code `started` "This trip has started. Use Force End Trip".

## 12. Errors and reasons

| `error.code` | When | App |
| --- | --- | --- |
| `too_early` | Start more than 60 min before | countdown |
| `busy` | another trip is on the road (`details.run_id`) | Busy |
| `started` | Start twice; Skip Trip after leaving a point | — / Force End instead |
| `not_started` | arrive, leave, skip a point, complete, force end before Start | Swipe first |
| `not_arrived` | leave before arriving | arrive first |
| `attendance_needed` | leave with names not ticked (`details.missing`, `names`) | Leave without attendance warning → `force: true` |
| `count_needed` | leave a counted run without a count | Count sheet, or `force: true` |
| `not_on_trip` | attendance for a child not on the list | Not on this trip |
| `call_operations` | force end without `called_operations` | tick the box |
| `replaced`, `cancelled`, `ended` | the trip is no longer the driver's to drive | refresh |
| `disposal_not_started`, `disposal_end_needed`, `not_disposal`, `tell_operations` | disposal actions ([disposal.md](disposal.md)) | — |
| `invalid` | a missing or wrong field (`details.<field>`): no `client_id` (UUID), unknown `position`, reason not on the list | — |

Reasons:

| Action | `reason` values |
| --- | --- |
| Skip a point | `No Passengers`, `Passengers are late`, `Traffic Congestion`, `Instruction given by supervisor/client` |
| Skip Trip | `Traffic Congestion`, `Permission granted by Supervisor/Manager` |
| Force End Trip | `Vehicle breakdown`, `Accident`, `Road closed`, `Medical emergency`, `Instructed by operations`, `Other` |
