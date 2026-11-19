# Convoy Driver app — notes for the front-end

Things the app does by itself (no server field or call) and changes the app has to act on. Newest first.

## 19/11/2026 — Answers to API-ISSUES (**breaking**: #10, #11)

Every item of API-ISSUES.md (last re-checked 19/11 at 4b79fc4) has its answer here: one row per open item (#1–#6, #8,
#10–#13); #7 and #9 were answered earlier (last row). This file is the place to check; we do not edit API-ISSUES.md.
"act on it" = not breaking, but the app should use it.

**Live on staging** (deployed `bd3f3d6` and re-seeded 19/11). Checked there: #12 frame, #2 `invited_at`, #5 runs, #6 point
`note`.

| # | Breaking | Change / answer | Doc |
| --- | --- | --- | --- |
| 13 | no (new field; act on it) | Bell lines now carry `run.open` (`run: { id, date, open }`): `true` → Trip Details opens (the run is still the driver's, Replaced or Cancelled); `false` → it went to another driver or is no longer planned: open nothing, toast "This trip is no longer assigned to you". Every tap still marks the line read. You can drop the newest-line rule; keep the `404` as a safety net. Worked out on each fetch: if the run comes back, its old lines open again. Optional: dim `open: false` lines. | [notifications § 1](notifications.md#1-the-bell-get-drivernotifications) |
| 12 | no | Staging ran an older build. Checked on staging after the 19/11 deploy: `?ticket=bogus` and a missing ticket both get `{"type":"disconnect","reason":"unauthorized","reconnect":false}`, then the socket closes (1000). Your fallback is right either way, and it is now in the doc: a close before `welcome` without that frame = get a new ticket (`401` on the ticket call → Sign In). | [websocket § 1](../websocket.md#1-connect) |
| 11 | **yes** (behaviour) | Fixed. A run whose end time passed without a Start now answers `422` code `ended` to every action (Start, points, attendance, Skip / Force End, `disposal_*`; `disposal_start` used to say `not_started`) and never shows in `on_going`. A run the driver **started** keeps `on_the_way` / `started`, stays in `on_going` and stays drivable past its end time until Complete / Force End (it used to flip to `ended` while still on the road). | [driving § 1](driving.md#1-how-every-action-works), [§ 12](driving.md#12-errors-and-reasons), [runs § 3](runs.md#3-the-on-going-trip-get-driverrunson_going) |
| 10 | **yes** (behaviour) | Fixed. `count` before Start now answers `422` code `not_started` (it used to store the count on a point the bus had not reached). Arriving at the point first is still not needed. | [driving § 7](driving.md#7-count-passengers-post-driverrunsidcount), [§ 12](driving.md#12-errors-and-reasons) |
| 8 | no | Doc only. `account.name` is `null` until the driver fills in Personal Details: fall back to `current.name_on_record` (or the first membership's), then `phone_display`. | [auth § 3](auth.md#3-the-session-get-driversession) |
| 6 | no | `points[].note` fixed: School Bus points now always send `note` (`null`: School Bus stops have no driver note; the key used to be missing). `passengers[].parent_phone2` is now in the doc: a second parent phone (School Run, from the route list) or `null` (always on School Bus). Already there before (e815362, your list is stale): `driver_end`, `driver_feedback`, contact roles `attendant` / `school_office`, `contacts[].note`. | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| 5 | no | Seed fixed (no API change). Every sample account now has runs from today, from recurring trips and routes, so they keep coming on later days (up to 120 days ahead): Eric Pang a disposal every day 08:00–11:30 (try `disposal_*` end to end) and the bus swap tomorrow 12:00 (both drivers go back to their own bus the day after); Ah Beng St. Stephen's AM 2 / PM 2 (bus PE1290S); Kumar his next run Replaced; Lee Kok Wah School Run + the Cross-site Shuttle 12:00 return; Siti Nurhaliza keeps AM 1 with Ethan Tan's photo. The swap, Kumar's replacement and Siti's ended runs are made for the day the seed runs. Lee's runs "stopping" after 20/11 are the MOE Year-End Holidays (21/11–31/12): school runs are `skipped` / absent on holidays, so try School Bus / School Run on a school day (from 04/01/2027). **Staging re-seeded 19/11.** There, 20/11 is the last school day before the holidays: Ah Beng SSS AM 2 / PM 2, Siti SSS AM 1 (Ethan Tan's photo), Lee Red Swastika AM 13 + Cross-site Shuttle, Kumar's Jurong East Staff Pick-up `replaced`, and Eric's bus swap at 12:00 (then Frankie's 14:00 transfer). Eric's disposal is there every day. The swap and Kumar's replacement are one-off rows, so ask us to re-seed staging when you want them again. | [README § Sample accounts](README.md#sample-accounts-staging-and-local-seed) |
| 4 | no | Answer: no new status. `status: "ended"` with `started_at: null` = the run was not driven in the app (end time passed without a Start, or the office ended it). Show it as Ended with no times. | [runs § 6](runs.md#6-values-reference) |
| 3 | no (text only; act on it) | accept / decline / disconnect on a row in the wrong status now answer the app's own message (still `422` code `invalid`), named as on the card (`employer_name`): accept / decline on an `active` row "You already work with SimpleDrive"; on a `past` row "This invitation from SimpleDrive is no longer open"; disconnect on a `pending` row "You have not joined Hup Seng yet"; on a `past` row "You no longer work with SimpleDrive". A declined invitation answers `404` (it is no longer listed). Show `error.message` as is. | [auth § 5](auth.md#5-companies-invitations-employment-history) |
| 2 | no | Seed fixed (no API change). Seeded drivers were invited when the seed ran but joined months earlier; now `invited_at` = `joined_at` (never after it) for every seeded row (staging re-seeded 19/11; Eric's SimpleDrive row checked). The API was right: an invite always resets `joined_at`. | [auth § 3](auth.md#3-the-session-get-driversession) |
| 1 | no | Doc only. `account.photo` (`GET` / `POST /driver/session`) = `{ url, thumb_url, name, size, content_type }` signed links, or `null`. | [auth § 3](auth.md#3-the-session-get-driversession) |
| 7, 9 | no | Answered earlier (e815362; your file already says so): #7 `driver_end`, `driver_feedback`, contact roles and `contacts[].note` documented; #9 point record fields documented, `left_early { missing, until }`. See the section "New fields for the design's records" below. | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |

## 19/11/2026 — Live updates over a WebSocket (**breaking**: stop polling)

The app no longer polls. Guide: [../websocket.md](../websocket.md).

| # | What to change | Doc |
| --- | --- | --- |
| 1 | New: `POST /driver/cable_ticket` → open `wss://<host>/cable?ticket=…` (subprotocol `actioncable-v1-json`), subscribe `{"channel":"DriverChannel"}` | [websocket § 1–3](../websocket.md#1-connect) |
| 2 | `runs_changed { run_ids, dates }` → fetch `GET /driver/runs` (a shown date) and the open Trip Details (its id) again | [websocket § 3](../websocket.md#3-channels-and-messages) |
| 3 | `notifications_changed` → fetch `GET /driver/notifications` again (red dot) | [websocket § 3](../websocket.md#3-channels-and-messages) |
| 4 | Remove the timers that polled runs and the bell; fetch once on start, on each (re)connect and when the app comes to the front | [websocket § 5](../websocket.md#5-reconnecting-and-the-app-in-the-background) |
| 5 | `disconnect` with `reconnect: false` = signed out / signed in on another phone: new ticket, and on `401` the sign-in screen | [websocket § 5](../websocket.md#5-reconnecting-and-the-app-in-the-background) |

Try it: sign in as Siti Nurhaliza `+65 9003 4455`; an office user (`ops@simpledrive.sg`) cancels and restores one of her
runs today in the Scheduler → `runs_changed` + `notifications_changed` arrive.

## 19/11/2026 — Child photo (no breaking change)

The child photo view (tap a child in Attendance / All Passengers, with Call Parent) can show the real photo.

| # | Screen / item in the design | Field | Doc |
| --- | --- | --- | --- |
| 1 | Child photo view + list avatar (the design draws initials) | `passengers[].photo` `{ url, thumb_url, ... }` or `null` → keep the initials | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |

Sample: sign in as Siti Nurhaliza `+65 9003 4455`, St. Stephen's AM 1 on a school day: Ethan Tan has a photo (from Rachel
Tan's Convoy App Household); the other children have none.

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
Vehicle Today has a highlight photo; Siti's AM 1 has the attendant with the office's note and the school office (item 6;
Ah Beng's AM 2 / PM 2 have an attendant without a note).

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
