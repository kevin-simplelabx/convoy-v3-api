# Convoy Driver app — notes for the front-end

Things the app does by itself (no server field or call) and changes the app has to act on. Newest first.

## 19/11/2026 — New fields for the design's records (no breaking change)

Fields the design draws that the API now sends. Nothing existing changed meaning; show each line when its field is set.

| # | Screen / item in the design | Field | Doc |
| --- | --- | --- | --- |
| 1 | Stop list: "Passenger Count" under a point | `points[].record.on_board` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| 2 | Stop list: "left before 07:12, 2 not boarded" | `points[].record.left_early { missing, until }` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| 3 | Stop list: "Skipped: 07:41" and the reason | `points[].record.skipped_at`, `skip_reason` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| 4 | Trip Details bar and Plan row: "Force ended at 14:05 after Point 3 · Accident · 4 still on board", "Skipped at 07:20" + reason | card `driver_end { kind, at, reason, on_board }` (Drive, Plan, on-going, Trip Details) | [runs § 1](runs.md#1-drive-the-days-runs-get-driverruns) |
| 5 | Driver's Feedback on an ended trip | `driver_feedback { note, at }` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| 6 | Point of Contact on School Bus: School Attendant (with the office's note) and School Office | `contacts[]` roles `attendant`, `school_office`; every contact now has `note` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| 7 | Switch Vehicle › Anything to Highlight? (extra photos, each marked up) | request `highlights[i][photo]`, `[marked]`, `[marks]`; response `highlights[]` (`photos` keeps the six sides only) | [vehicle § 3](vehicle.md#3-handover-inspection-post-drivervehiclehandovers) |
| 8 | On Route: "Wait for N children · you may leave at 07:12 · 2 min after the scheduled time" | `GET /driver/config` → `pickup_grace_minutes` | [gps § 1](gps.md#1-app-settings-get-driverconfig) |
| 9 | Airport block: "From Sydney" / "Flight to London" | `airport.flight_city` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |

Sample: sign in as Siti Nurhaliza `+65 9003 4455` and open yesterday in Plan (items 1–5); Eric Pang's handover in My
Vehicle Today has a highlight photo; Ah Beng's School Bus runs have the attendant and school office (item 6).

## 19/11/2026 — Parts of `Convoy Driver.dc.html` the app works out itself (no API change)

The design was compared screen by screen with the API. These items are drawn in the design but have no field on the
server on purpose: the app works them out from data it already has.

| # | Screen / item in the design | How the app does it |
| --- | --- | --- |
| 1 | On Route and the floating bar: distance to the next point, ETA, "On Time / Early / Behind Schedule", traffic bar, bus position | From the phone's GPS (or the navigation SDK) and the next point's `lat` / `lng` in [`GET /driver/runs/:id`](runs.md#4-trip-details-get-driverrunsid) → `points`; compare with the point's `planned_time` |
| 2 | Force-ended banner: "… after Point N" | The last point with `record.departed_at` (or `record.arrived_at`) in `points` |
| 3 | Plan: "Completed x / y" for a day | Count the day's runs by `status` |
| 4 | Skip button on a point (`stop.skippable` in the design) | Show it on every point except the first, the last and waypoints; the server answers 422 when a skip is not allowed |
| 5 | Disposal On Route: "Directed by …" | The `requestor` (or `guest`) in `contacts`; hide the line when there is none |
| 6 | End Disposal: quick-pick chips for "Released by" | Build them from `contacts` (name + role); `released_by` stays free text |
| 7 | Driving Credentials: "the app reminds you before anything expires" | Local phone reminders from each licence's `expiry` / `days_left` (90 and 30 days before); the server sends no reminder |
| 8 | App Language 中文 / 繁體中文 | Server text (status labels, reasons, error messages, notification titles) is English. Translate by value in the app (status codes, reason values from [`GET /driver/config`](gps.md#1-app-settings-get-driverconfig)); show the English text when there is no translation |
| 9 | Driving Credentials: Delete only on "Other" licences | A UI rule: the API lets any licence be deleted, so hide Delete on driving / vocational licences in the app |
| 10 | All Passengers "Name list from the school, no attendance" (`approved_rider_required` off) | Not needed: every run with `passengers` takes attendance (`requires: "attendance"`), so this variant never happens |
| 11 | Disposal standing-by toggle (`toggleWait`) | Not wired in the design; standing-by time comes from `disposal.record.clock.standing_by_minutes` |
| 12 | Point of Contact: Second Guest, Teacher in Charge, Site Contact, and a note under each contact | Not on the server (Convoy OS does not record them). Show only the roles in `contacts`; a note is shown only when `note` is set (School Bus attendant) |
| 13 | Child age ("9 y/o • P3") on Attendance, the child card, All Passengers and Edit Route | Not on the server (no birth date is kept). Show the `level` only ("P3") |
| 14 | Via points: "Via {name}" and its address in the stop list and On Route | Vias are `{ lat, lng }` only. Show "Via" + the road name from reverse geocoding on the phone (OneMap) |

Already decided earlier (no server part): live flight status, main contractor app hand-off ("Continue on … app" / Stay
shows nothing extra), Fuel row, child photo, Update with Singpass, Trip Alerts / Arrival Sounds (device settings),
Help / Terms / Privacy / Permissions / About (static), GPS strip and Internet / GPS dots.

The server parts the design also needs were added the same day: see the section above.
