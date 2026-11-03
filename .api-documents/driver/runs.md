# Driver app — Drive, Plan and Trip Details

Drive (Today / Tomorrow trip cards), Plan (the month and a day), the floating on-going trip, Trip Details (route,
contacts, map and stop list, names, Before You Go) and the New badge. Driving actions (On the way, Arrive, Leave,
attendance…): [driving.md](driving.md).
Conventions: [README.md](README.md). Paths start with `/api/v1`. Every call here needs a picked company
(`422` "Pick a company first").

A run is one trip (or School Bus route) on one day, as the company's Scheduler planned it: the driver's runs are the
runs of the bus they drive that day, plus runs a replacement took from them (shown as **Replaced**). Runs exist up to
120 days ahead; days further out have none yet.

## Contents

1. [Drive: the day's runs](#1-drive-the-days-runs-get-driverruns)
2. [Plan: days with runs](#2-plan-days-with-runs-get-driverrunsschedule)
3. [The on-going trip](#3-the-on-going-trip-get-driverrunson_going)
4. [Trip Details](#4-trip-details-get-driverrunsid)
5. [Mark as seen](#5-mark-as-seen-post-driverrunsidseen)
6. [Values reference](#6-values-reference)

---

## 1. Drive: the day's runs: `GET /driver/runs`

| Screen | Call |
| --- | --- |
| Drive › Today | `GET /driver/runs` (today) |
| Drive › Tomorrow | `GET /driver/runs?date=YYYY-MM-DD` |
| Plan › a day | `GET /driver/runs?date=YYYY-MM-DD` |
| Plan › week strip | `GET /driver/runs?from=YYYY-MM-DD&to=YYYY-MM-DD` (31 days at most) |

→ `{ data: [card], meta: { from, to, vehicle_switches } }`, in start time order (`vehicle_switches`: the Switch Vehicle
cards, [vehicle.md § 2](vehicle.md#2-the-switch-vehicle-card-on-drive)). A card:

```json
{ "id": 812, "date": "2026-11-03", "start_time": "06:30", "end_time": "07:20",
  "starts_at": "2026-11-03T06:30:00+08:00", "ends_at": "2026-11-03T07:20:00+08:00",
  "trip_label": "TID260921", "title": "SSS AM 1", "label": "AM 1",
  "kind": "school", "kind_label": "School Bus", "direction": "To School",
  "client": { "name": "St. Stephen's School", "via": null },
  "status": "scheduled", "status_label": "Scheduled", "seen": false, "started_at": null, "ended_at": null,
  "points_count": 4, "first_point": "Blk 123 Tampines St 11", "last_point": "St. Stephen's School",
  "expected_pax": 13, "requires": "attendance", "vehicle": { "id": 7, "plate": "PD997M" }, "replaced_by": null }
```

- `seen: false` → the New badge (until Trip Details is opened, § 5; it comes back when the run's time, bus or driver changes).
- `client.via`: on a sub-contracted trip, the main contractor ("Google Asia Pacific · via ABC Transport").
- `expected_pax`: School Bus = children on the route less Bus Not Required; others = the planned passengers.
- `requires`: `attendance` (School Bus, School Run: tick names), `count` (shuttles with head count), or null.
- `status: "replaced"` → `replaced_by: { driver_name, vehicle_plate }` ("Replaced by Siti · PD4472H"); the run is read-only.
- `422` "Ask for 31 days at most", "to must be on or after from", "Dates are YYYY-MM-DD, months YYYY-MM".

## 2. Plan: days with runs: `GET /driver/runs/schedule`

`?month=YYYY-MM` (default this month) → the dots on the month calendar:

```json
{ "data": { "month": "2026-11", "days": [ { "date": "2026-11-03", "runs": 9 }, { "date": "2026-11-04", "runs": 8 } ] } }
```

## 3. The on-going trip: `GET /driver/runs/on_going`

→ the card (§ 1) of the run the driver has started and not ended (the floating bar on every tab), or `data: null`.
Ask on app start and after each driving action.

## 4. Trip Details: `GET /driver/runs/:id`

The card fields plus:

```json
{ "data": {
  "...": "the card fields",
  "trip_value": "1.5",
  "notes": "Wait at the lobby",
  "airport": { "direction": "arrival", "flight_number": "SQ 231", "flight_time": "20:40", "terminal": "T3", "wait_minutes": 60,
               "meet_and_greet": true, "signboard_name": "GOOGLE · MS CHEN",
               "luggage": { "cabin": 2, "medium": 0, "large": 4, "extra_large": 0, "oversized": 0 } },
  "disposal": { "hours": 4.0, "suggested_start_odometer": 45252, "record": null },
  "series": { "day": 2, "of": 3, "title": "SD26000123" },
  "standby": { "location": "Expo loading bay", "address": "10 Bayfront Ave", "lat": 1.284, "lng": 103.8607, "minutes": 15,
               "report_time": "11:45", "note": "Report to the coordinator", "street_view_url": null, "photos": [] },
  "attachments": [ { "url": "/api/v1/downloads/...", "name": "Route 3 rider list.pdf", "size": 48211, "content_type": "application/pdf" } ],
  "contacts": [ { "role": "requestor", "name": "Priya", "phone": "+6591110000" }, { "role": "guest", "name": "Mr Chen", "phone": "+6592220000" } ],
  "contractor": { "name": "ABC Transport", "requires_app": true },
  "replacement": null,
  "points": [
    { "position": 0, "number": 1, "name": "Jurong East MRT", "address": "10 Jurong East St 12", "lat": 1.333, "lng": 103.742,
      "planned_time": "08:00", "note": "Point B", "pickup": true, "dropoff": false, "waypoint": false, "school": false,
      "photos": [ { "url": "...", "thumb_url": "..." } ], "street_view_url": null, "vias": [ { "lat": 1.32, "lng": 103.75 } ],
      "pickups": 0, "dropoffs": 0,
      "record": { "arrived_at": "2026-11-03T07:58:00+08:00", "departed_at": "2026-11-03T08:02:00+08:00", "skipped": false, "boarded": 7, "alighted": 0 } }
  ],
  "passengers": [
    { "id": "S-1", "name": "Aaron Lee", "gender": "M", "level": "P3", "address": "Blk 123 Tampines St 11 #08-21",
      "parent_name": "Jason Lee", "parent_phone": "+6598224417", "note": "Allergic to peanuts",
      "pickup_position": 0, "dropoff_position": 5, "state": "expected", "reason": null, "qr_code": "CVR1-S-1-3f9a0c1b2d4e",
      "boarded_at": null, "board_method": null, "alighted_at": null, "alight_method": null, "marked_by": null }
  ],
  "before_you_go": { "not_riding": [ { "id": "S-2", "name": "Emma Lim", "point": "Blk 201 Tampines St 21", "state": "bus_not_required",
                                       "reason": "Unwell. Fever" } ], "skipped_points": [] }
} }
```

- `trip_value`: the driver pay multiplier, shown for **own drivers only**; null for managed drivers, disposals and replaced runs.
- `airport`, `disposal`, `series` (Day `day` of `of` for a booking over several days), `standby`, `contractor`, `replacement`:
  null when they do not apply. `disposal.record` and the actions: [disposal.md](disposal.md).
- `contractor.requires_app: true` = the main contractor wants this run done in its own driver app ("Continue on
  `name`'s app"); the trip form has no app name yet. The handover flow in the app is not built on the server yet.
- `contacts` = Point of Contact; the company's Operations line is on [`GET /driver/company`](profile.md#5-transport-company-get-drivercompany).
- `replacement` (when this run's driver or bus was replaced): `{ kind, reason, driver_name, vehicle_plate, original_vehicle_plate }`.

**Points** (map pins and the stop stepper), in driving order:

- `number` 1, 2, 3… for the stepper; `position` names the point in the [driving actions](driving.md).
- `pickup` / `dropoff`: the arrow; `waypoint: true` = a "Via" row (drive through, nobody boards; no number pin needed);
  `vias` = road pins set between this point and the next (diamonds on the route line).
- `school: true` (School Bus): the school, last in the morning and first in the afternoon.
- `planned_time` may be null for middle points of a trip without stop times.
- `pickups` / `dropoffs`: how many names board / alight here (before the trip: "pick-up 2 children").
- `record`: what was recorded (null before the bus gets there): arrival, departure, skipped, boarded and alighted counts.

**Passengers** (School Bus and School Run only; `[]` for other runs): every name with their pick-up and drop-off point
(`position`), `state` (§ 6) and, on School Bus, `qr_code` = the child's boarding pass (match a scanned code with it;
"Not on this trip" otherwise). `reason`: why Bus Not Required. `parent_phone` for Call Parent. `boarded_at`, `board_method`,
`alighted_at`, `alight_method`, `marked_by`: what was recorded (All Passengers).

**Before You Go**: `not_riding` = children not riding today (Bus Not Required from the parent, or marked not boarding) at
their own stop; `skipped_points` = points that will be skipped ([Edit Route](driving.md#8-edit-route-patch-driverrunsidroute)).

## 5. Mark as seen: `POST /driver/runs/:id/seen`

Send when Trip Details opens → the card with `seen: true`.

## 6. Values reference

| Field | Values |
| --- | --- |
| `kind` / `kind_label` | `school` School Bus, `school_run` School Run, `shuttle` Shuttle, `disposal` Disposal, `airport` Airport Transfer, `adhoc` Ad Hoc |
| `status` / `status_label` | `scheduled` Scheduled, `on_the_way` On the Way (started, first point not left yet), `started` Started, `ended` Ended, `skipped` Skipped (the driver skipped the trip), `replaced` Replaced, `cancelled` Cancelled |
| `direction` | `To School`, `To Home` (School Bus, School Run), `Outbound`, `Return` (shuttle, ad hoc return), `One Way`, `Arrival`, `Departure`, `As Directed` |
| `requires` | `attendance`, `count`, null |
| `passenger.state` | `expected`, `bus_not_required` (from the parent), `not_boarding` (marked before the trip), `boarded`, `not_boarded` (ticked as not there), `alighted` |
| `contact.role` | `requestor`, `guest`, `main_contractor` |
| `airport.direction` | `arrival`, `departure` |

Sample drivers to try each kind of trip: [README.md § Sample accounts](README.md#sample-accounts-staging-and-local-seed).
