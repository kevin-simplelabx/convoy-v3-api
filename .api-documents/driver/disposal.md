# Driver app — Disposal

A disposal is a block of hours with the bus and driver at the client's disposal: one meeting point, then runs as the
coordinator directs. The app records the start and end odometer with photos, the runs, the extensions the client signs
for and who released the bus; the office reads it in Trip History (billing comes later).
Conventions: [README.md](README.md); actions work as in [driving.md § 1](driving.md#1-how-every-action-works)
(`client_id`, `at`, the answer is Trip Details). Send photos and signatures as `multipart/form-data` (image files).

## Contents

1. [The disposal block in Trip Details](#1-the-disposal-block-in-trip-details)
2. [Start the disposal](#2-start-the-disposal-post-driverrunsiddisposal_start)
3. [Runs](#3-runs)
4. [Extend Time](#4-extend-time-post-driverrunsiddisposal_extend)
5. [End the disposal](#5-end-the-disposal-post-driverrunsiddisposal_end)
6. [The block clock](#6-the-block-clock)

The order: Start (swipe) → Arrive at the meeting point → **Start Disposal** → runs, Extend Time → **End Disposal** (ends
the trip). Leave at the meeting point and Complete Trip answer `422` codes `disposal_not_started` / `disposal_end_needed`
on a disposal: use these instead.

---

## 1. The disposal block in Trip Details

`GET /driver/runs/:id` → `disposal`:

```json
{ "hours": 4.0, "suggested_start_odometer": 45252, "record": null }
```

- `suggested_start_odometer`: the reading this bus ended its last disposal on (Day 2 of a multi-day booking starts from
  Day 1's end): pre-fill the Start odometer with it. Null once started, or when unknown.
- `record` once started:

```json
{ "block_starts_at": "2026-11-03T11:40:00+08:00", "started_at": "2026-11-03T11:40:00+08:00", "early_start": true, "late_minutes": 0,
  "start_odometer": 45210, "start_photo": { "url": "...", "thumb_url": "..." }, "extension_minutes": 30,
  "ended_at": null, "end_odometer": null, "end_photo": null, "released_by": null, "release_signature": null, "km": null,
  "clock": { "used_minutes": 220, "booked_minutes": 270, "over_minutes": 0, "overtime_minutes": 0, "standing_by_minutes": 195,
             "block_ends_at": "2026-11-03T16:10:00+08:00", "state": "within" },
  "runs": [ { "id": 1, "started_at": "...", "ended_at": "...", "from_road": "Bayfront Avenue", "to_road": "Nicoll Highway", "pax": 18, "minutes": 25 } ],
  "extensions": [ { "at": "...", "from_minutes": 0, "to_minutes": 30, "signed_by": "Alex Hwang", "operations_told": true,
                    "signature": { "url": "..." } } ] }
```

## 2. Start the disposal: `POST /driver/runs/:id/disposal_start`

`{ client_id, at, start_odometer, start_photo, start }` after arriving at the meeting point.

- `start_odometer` (required, whole number; "45,210" is fine); `start_photo` the dash (file, optional).
- `start`: `agreed` (default) or `now`. **Now** counts only before the agreed time, when the coordinator asked to start
  early: the block then starts now. After the agreed time the block always starts at the agreed time (a late coordinator
  does not move it); `late_minutes` says how late.
- `422` code `not_arrived` before arriving; `started` when already started; `details.start_odometer`.

## 3. Runs

One run at a time; standing by = time not on a run. `from_road` / `to_road`: the road from the phone's reverse geocoding
(OneMap), as text.

### 3.1 Start a run: `POST /driver/runs/:id/disposal_run_start`

`{ client_id, at, from_road, lat, lng }`. `422` "A run is on: end it first".

### 3.2 End a run: `POST /driver/runs/:id/disposal_run_end`

`{ client_id, at, to_road, lat, lng, pax }` — `pax` only when the trip counts (`requires: "count"`). `422` "No run is on".

## 4. Extend Time: `POST /driver/runs/:id/disposal_extend`

`{ client_id, at, minutes, operations_told: true, signed_by, signature }` — step 1 (the driver: +/- 30 minutes, ticks
that operations was told), step 2 (the client signs and types their name). No office approval.

- `minutes`: the **new total** extension (0, 30, 60…; taking time back down is allowed, not below 0).
- `422`: "Extend in steps of 30 minutes"; code `tell_operations` without `operations_told`; `details.signed_by` without the
  client's name (2+ letters); "Add or remove time first" when unchanged.

## 5. End the disposal: `POST /driver/runs/:id/disposal_end`

`{ client_id, at, end_odometer, end_photo, released_by, release_signature, feedback }`.

- `end_odometer` (required, not below the start: `details.end_odometer`); `end_photo` (file, optional).
- `released_by`: who released the bus (optional: "Not recorded"); `release_signature` (file, optional) needs
  `released_by` (`details.released_by`).
- An open run ends; the last point is recorded; the trip ends (`status: "ended"`). The summary ("Disposal 5h 0m, 32 km,
  released by Alex Hwang") goes to the office as the driver's feedback unless `feedback` is sent.

## 6. The block clock

`record.clock`, worked out on every answer (refresh it; the app can also run it locally between calls):

- `booked_minutes` = the booked hours + `extension_minutes`; `block_ends_at` = `block_starts_at` + booked.
- `used_minutes` = from `block_starts_at` to now (or the end). Ending early refunds nothing.
- `over_minutes` = used beyond booked; `overtime_minutes` = what is billed: whole 15-minute blocks (14 minutes over = 0,
  15 = 15, 29 = 15, 30 = 30).
- `state`: `within`, `near_end` (30 minutes or less left: "extend if the client needs more"), `over`.
