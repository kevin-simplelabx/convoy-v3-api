# Convoy App — Shuttles (staff who ride a company shuttle)

The **Shuttles** service tile, the employer's route list, **My Usual Shuttle**, a **route** (14-day strip, timings, buses,
changes, stops with the bell), **View Schedule**, **Alert Settings** per route and **Pause Alerts**. Design:
`Convoy App.dc.html` screens `shuttle`, `shRoute`, `shSched` and the sheets `usual`, `alr`, `pause`. Conventions:
[README.md](README.md); how a person gets an employer: [organisations.md](organisations.md). Paths start with `/api/v1/app`.
Times are `"HH:MM"` in the transport company's time zone (Singapore); `*_at` fields are ISO timestamps; dates `YYYY-MM-DD`.

## Contents

1. [Who sees what](#1-who-sees-what)
2. [Route list: `GET /app/shuttles`](#2-route-list-get-appshuttles)
3. [My Usual Shuttle](#3-my-usual-shuttle)
4. [Pin and bell](#4-pin-and-bell)
5. [Route page: `GET /app/shuttles/:employer_id/routes/:id`](#5-route-page)
6. [View Schedule](#6-view-schedule)
7. [Alert Settings and Pause Alerts](#7-alert-settings-and-pause-alerts)
8. [Alerts the app receives (inbox)](#8-alerts-the-app-receives-inbox)
9. [Errors](#9-errors)

---

## 1. Who sees what

- A person sees an employer only through a **live staff link**: they accepted it ([organisations.md](organisations.md)), the
  office has not removed it, and the **work email that matched is still verified** (12 months; past that the link is *paused*).
  A paused or removed link, an invited (not yet accepted) link and an employer of someone else give **nothing**: the list says
  `employers: []` and every `/shuttles/:employer_id/…` call is `404`.
- `:employer_id` is the `id` of an employer in `GET /app/shuttles` (the link id), not the client id. All of an employer's data
  is read in its transport company; "today" is that company's today.
- A route = a corporate shuttle of the employer (Convoy OS › Trips). **Tags** (the chips) = the employer's site names on the
  route's stops + the route's own tags. Routes that ended are not listed.
- **Dates.** Real runs exist from today to 120 days ahead (no virtual runs). The route page takes a date from today to today + 92
  days; past days and days beyond that are `422`. Changes (another bus, relief driver, cancelled) show for **any** day in range,
  not only today.
- No staff link yet: the Shuttles tile opens "Shuttles Come From Your Employer" (Suggest Convoy). `GET /app/shuttles` →
  `employers: []` tells the FE to show it; invitations are on `GET /app/organisations`.

## 2. Route list: `GET /app/shuttles`

Query: `employer_id` (default: the first employer), `tag` (`All` default, `Pinned`, or any chip; case-insensitive; an unknown
tag gives an empty list).

```json
{ "data": {
  "employers": [ { "id": 1, "name": "Google Asia Pacific", "mark": "GA", "by": "SimpleDrive", "company_id": 1 } ],
  "employer": { "id": 1, "name": "Google Asia Pacific", "mark": "GA", "by": "SimpleDrive", "company_id": 1 },
  "usual": { "trip_id": 8, "route": "MBC Campus Shuttle", "direction": 1, "run_id": 1, "stop_id": 15, "time": "07:45", "stop": "Alexandra Road" },
  "tags": ["All", "Pinned", "Campus", "Mapletree Business City", "Staff"], "tag": "All",
  "routes": [ { "id": 8, "name": "MBC Campus Shuttle", "label": "mbc", "tags": ["Mapletree Business City", "Campus", "Staff"],
                "pinned": true, "no_fixed_bus": false,
                "directions": [ { "direction": 1, "name": "Morning", "timings": 3, "first": "07:45", "last": "08:45" },
                                { "direction": 2, "name": "Evening", "timings": 2, "first": "17:30", "last": "18:15" } ],
                "now": { "state": "next", "time": "08:15" },
                "usual": { "time": "07:45", "stop": "Alexandra Road" } } ] } }
```

- Header: `employer.name` "· by `employer.by`". **Employer switch** shows when `employers.size > 1` (it resets the tag to All).
- **My Usual Shuttle** card: `usual` (`"07:45 · MBC Campus Shuttle"`) or "Choose My Usual Shuttle"; Change opens the sheet (§3).
- Chips = `tags`. Routes come **pinned first**, then by name. Empty list: "No routes with this tag."
- Card: `name`, `tags`, a line per `directions[]` ("Morning 07:45 to 08:45 · 3 timings"; the app has no "every N min"),
  the pin, and `now`: `{ state: "now", time }` a run is on the road ("Now 07:45"), `next` ("Next 08:15"), `done` ("Done for
  today": all ended or cancelled), `none` (nothing runs today). `usual` on the card (only the usual route): "Your usual: 07:45
  from Alexandra Road". Tap → the route page.
- More: Alert Settings (§7 list), Report a Lost Item / Contact Transport Desk (the shared contact page, Phase 4b), Send Feedback
  is Coming Soon (not built).

## 3. My Usual Shuttle

One per employer: the route, the **timing** (required) and **where you board** (the alighting stop is the last stop).

- `GET /app/shuttles/:employer_id/usual` → `{ employer, usual: { trip_id, run_id, stop_id, direction } | null, routes: [ { id, name,
  directions: [ { direction, name, timings: [ { run_id, time } ], stops: [ { id, name } ] } ] } ] }`. `stops` are the stops where
  riders **board** in that direction (the evening list starts from the other end and swaps pick-up and drop-off). Changing the
  route or the direction resets the timing and the stop in the FE.
- `PUT /app/shuttles/:employer_id/usual { trip_id, run_id, stop_id? }` (**Save as My Usual**) → the same body as GET. `stop_id`
  missing = the first boarding stop. `422 "Pick your usual timing"` (no `run_id`), `422 "Pick where you board"` (not a boarding
  stop). Saving again replaces the usual of that employer.
- `DELETE /app/shuttles/:employer_id/usual` (**Clear**) → the same body (`usual: null`).
- If the office deletes the run or the stop in Convoy OS the usual disappears (`usual: null`): show "Choose My Usual Shuttle".

## 4. Pin and bell

Both are set **to a value**, so repeating a tap never flips it back.

- `PUT /app/shuttles/:employer_id/routes/:id/pin { pinned: true|false }` → `{ data: { pinned } }`.
- `PUT /app/shuttles/:employer_id/routes/:id/stops/:stop_id/bell { direction: 1|2, on: true|false }` → `{ data: { on } }`. A bell is
  per stop and direction (all timings). With no saved choice the **usual boarding stop** of the usual direction is on; the route
  page returns the effective `bell`. (The bell is stored; stop reminders are not sent yet, see §8.)

## 5. Route page

`GET /app/shuttles/:employer_id/routes/:id` — query `date` (default today), `direction` (`1` Morning, `2` Evening; default the
usual's direction, else the first), `run_id` (the timing; default **the run on the road, else the next, else the first**).
One call gives the whole page; calling it again with another `date` / `direction` / `run_id` is the date strip, the swap
button and the timing pills.

```json
{ "data": {
  "employer": { "id": 1, "name": "Google Asia Pacific", "mark": "GA", "by": "SimpleDrive", "company_id": 1 },
  "route": { "id": 8, "name": "MBC Campus Shuttle", "label": "mbc", "tags": ["Campus", "Staff"], "no_fixed_bus": false, "pinned": true,
             "usual": true, "directions": [ { "direction": 1, "name": "Morning" }, { "direction": 2, "name": "Evening" } ] },
  "today": "2026-11-16", "date": "2026-11-17", "direction": 1, "direction_name": "Morning",
  "day": { "state": "service", "reason": null, "resumes_on": null, "shifts": [] },
  "strip": [ { "date": "2026-11-16", "weekday": 1, "state": "service", "reason": null, "resumes_on": null, "shifts": [], "changes": [] },
             { "date": "2026-11-17", "weekday": 2, "state": "service", "changes": ["driver", "bus"], "…": "" },
             { "date": "2026-11-21", "weekday": 6, "state": "no_service", "reason": "Weekend", "resumes_on": "2026-11-23", "changes": [], "shifts": [] } ],
  "next_change": { "date": "2026-11-21", "state": "no_service", "reason": "Weekend", "resumes_on": "2026-11-23", "shifts": [] },
  "usual": { "run_id": 1, "direction": 1, "time": "07:45", "stop": { "id": 15, "name": "Alexandra Road" } },
  "timings": [ { "run_id": 1, "time": "07:45", "shift_minutes": 0, "state": "scheduled", "state_label": "Scheduled", "live": false, "past": false,
                 "usual": true, "change": "driver", "buses": 2 } ],
  "selected_run_id": 1,
  "timing": { "…": "see below" },
  "stops": null } }
```

**Day and strip.** `state`: `service`, `changed` (the day's times moved: `shifts: [ { direction, name, minutes } ]`, minutes
negative = earlier: "Evening 120 min earlier. Timings below are for <date>") or `no_service` (`reason`: a public holiday or
the client's day off by its name, `"Weekend"`, `"Not a service day"`, `"Not running yet"`, `"Service ended"`; `resumes_on` =
"Service resumes <date>", the next day with a run within 14 days or `null`). Dot colours: grey `no_service`, orange `changed`.
`strip[].changes` lists what happened on runs that day: `cancelled`, `bus`, `driver` (use them for a red / orange dot).
`next_change` = the next day within the next 7 days that is not plain `service` (the "Next change" banner; tap → that date) or
`null`. On a `no_service` day `timings` is `[]`, `timing` is `null` and `stops` lists the stops with `time: null` ("—").

**Timing pills** (`timings`, one per run of the direction, in time order): `time` (already moved by `shift_minutes`),
`state` `scheduled | on_the_way | started | ended | cancelled`, `live` (on the road → teal-100), `past` (ended → grey),
`usual` (outlined), `change` `cancelled | bus | driver | null` (red / orange change dot), `buses` (how many vehicles run the
timing: 1 or more; **every vehicle is shown**), `occurrence_ids` (its runs, for the WebSocket). Past days are not offered (the strip starts today).

**`timing`** (the selected pill):

```json
{ "run_id": 1, "occurrence_id": 600, "time": "07:45", "state": "scheduled", "state_label": "Scheduled", "late_minutes": null,
  "status": { "key": "scheduled", "departs_at": "2026-11-17T07:45:00+08:00",
              "next_stop": { "name": "Alexandra Road", "planned_at": "…", "eta_at": "…" },
              "arrived": { "stop": "Mapletree Business City", "at": "…" },
              "next_bus": { "run_id": 2, "time": "08:15", "from": "Labrador Park MRT" } },
  "buses": [ { "occurrence_id": 600, "slot_no": 1, "part": 1, "plate": "PD5126A", "description": "Toyota Coaster", "seats": 23, "photo": { "…": "" },
               "no_fixed_bus": false,
               "driver": { "name": "Daniel Wong", "photo": { "…": "" }, "relief": false, "regular_name": null },
               "change": { "kind": "bus", "set_at": "…", "usual_bus": { "plate": "PC8841T", "description": "Mitsubishi Rosa", "seats": 23 },
                           "alert": { "stop": "Alexandra Road", "alert_at": "2026-11-17T06:40:00+08:00", "alerted_at": null } } } ],
  "stops": [ { "position": 0, "stop_id": 14, "name": "Labrador Park MRT", "address": "Exit A", "planned_time": "07:45", "planned_at": "…",
               "boarding": true, "alighting": false, "my_stop": false, "bell": false, "done": false, "next": false, "arrived_at": null,
               "street_view_url": null, "lat": 1.2722, "lng": 103.8026 } ],
  "line": [ [1.2722, 103.8026], [1.2779, 103.8009] ],
  "position": { "lat": 1.27, "lng": 103.80, "speed_kmh": 28, "heading": 90, "recorded_at": "…" } }
```

- **Status line** from `status.key`: `scheduled` "Trip has not started · Departs <first stop> at `departs_at`" (plus "usually
  HH:MM" from the usual when different); `on_the_way` / `started` "Driver is on the way" + `next_stop` ETA; `ended` "Trip
  completed · Arrived at `arrived`"; `cancelled` "Cancelled today" + `next_bus` ("Next bus 08:15 from Labrador Park MRT") or, when
  `next_bus` is `null`, "No more buses this morning / evening". `late_minutes` > 0 while on the road: "<route> Bus <plate> is
  running N min late on this timing" (the FE may show it from a few minutes). `position` and `line` feed the map (the bus only
  while the run is on the road); Centre on bus / Fit route are FE. `occurrence_id` = the lead bus (the one `position` is of).
- **Live**: `TrackChannel` `screen: "shuttle_route"` with `employer_id`, `route_id` and the picked `date`, `direction`,
  `run_id` ([../websocket.md § 4](../websocket.md#4-convoy-app-screens-trackchannel)): `position` moves the bus (`run_id` =
  `occurrence_id`), `run_changed` (any run of the day's timings, `timings[].occurrence_ids`) → fetch again. No polling.
- **Crew row** per `buses[]` (several rows for a timing with two vehicles): `driver.name` / `photo`, "<description> · <company>",
  the `plate` chip, "Relief Driver" badge when `driver.relief`. No phone number, no attendant. `plate: null` = no bus assigned
  yet (show nothing for the bus). `no_fixed_bus: true` → autorenew icon: "Bus changes daily on this route. Check the plate before
  you board: on this timing today it is <plate>." (never a change card, never an alert).
- **Change card** per bus (`change`, not shown on a past run):
  - `cancelled` (`at`, `by` = the transport company): "<by> cancelled it at <at>. Next bus: <status.next_bus>." + button "See the 08:40" (→ `run_id`).
  - `driver`: "<driver.name> is driving instead of <driver.regular_name>. Same bus, <plate>." + Relief Driver badge. No push for it.
  - `bus`: **Look For** box (photo, `plate`, "<description> · <seats> seats", "Usual bus: <usual_bus.plate>, <usual_bus.description>"). Sub text
    from `alert` (the stop riders are told about: the usual boarding stop of the usual direction, else the first belled stop, else the
    first boarding stop): `alerted_at` set → "You were alerted at <alerted_at>, 1 hour before the bus reaches <alert.stop>."; else
    "Set by <company> at <set_at> and may still change. You will be alerted at <alert_at>, 1 hour before the bus reaches <alert.stop>.";
    no `alert` → "Riders are alerted 1 hour before the bus reaches their stop."
- **Stops**: number, `planned_time` (already shifted), `boarding` (orange up) / `alighting` (green down), `my_stop` badge (the
  usual boarding stop on the usual timing), `bell`, `done` (grey strike-through), `next` (filled), `arrived_at`, `street_view_url`
  (opens Google Maps), `address`. On the evening direction pick-up and drop-off are already swapped. The office's driver notes are
  **not** shown to riders.
- Header actions: bell → Alert Settings (§7); swap_vert → the same call with the other `direction`; menu: Set as My Usual (§3),
  View Schedule (§6), Legends / Alert Settings (FE).

## 6. View Schedule

`GET /app/shuttles/:employer_id/routes/:id/schedule` — query `direction` (default the first), `month` (`YYYY-MM`, default the month
of `date`), `date` (the picked day, default today).

```json
{ "data": { "employer": { "…": "" }, "route": { "…": "" }, "direction": 1, "direction_name": "Morning",
  "month": "2026-11", "first_month": "2026-11", "last_month": "2027-02", "today": "2026-11-16", "date": "2026-11-16",
  "days": [ { "date": "2026-11-15", "weekday": 0, "state": "no_service", "reason": "Weekend", "changes": [], "past": true, "beyond": false, "shifts": [] } ],
  "timetable": { "day": { "state": "service", "reason": null },
                 "stops": [ { "stop_id": 14, "name": "Labrador Park MRT" } ],
                 "timings": [ { "run_id": 1, "time": "07:45", "state": "scheduled", "usual": true, "change": null, "times": ["07:45", "07:52", "08:00"] } ] } } }
```

- Month grid: Monday first (`weekday` 0 = Sunday); `past` days disabled; `beyond` days (after today + 92) disabled; previous / next
  month between `first_month` and `last_month` (anything else is `422`). Dots: grey `no_service` (public holiday / day off /
  not a run day), orange `changed`. Footer: "<date> · <label>" or "No shuttle this day".
- **Timetable** of the picked day: header = `stops` (size the columns by stop count: routes differ), a row per timing with the
  time at each stop in `times` (`null` = that run skips the stop). `usual` row, `change` dot as on the route page. On a day with no
  service `timings` is `[]`. Footer text: "Times are planned. Public holidays and the client's calendar days off are skipped …".
- Tapping a timing = go back to the route page with `date`, `direction`, `run_id`.

## 7. Alert Settings and Pause Alerts

**Per route** (the `alr` sheet from the route's bell or from Account › Notifications › Shuttle Alerts).

- `GET /app/shuttles/:employer_id/routes/:id/alerts` →

```json
{ "data": { "route": { "id": 8, "name": "MBC Campus Shuttle", "tags": ["…"] }, "employer": { "…": "" },
  "timings": [ { "run_id": 1, "direction": 1, "name": "Morning", "time": "07:45" }, { "run_id": 4, "direction": 2, "name": "Evening", "time": "17:30" } ],
  "setting": { "enabled": true, "run_ids": [1], "weekdays": [1, 2, 3, 4, 5], "lead_minutes": 5,
               "notify": { "bus_change": true, "service_days": true, "late": true, "notices": true }, "saved": false },
  "paused_until": null } }
```

- `setting` is what applies. `saved: false` = never saved: the **usual route** is on with the usual timing, Mon–Fri, 5 minutes and all
  four changes on; every other route is off. `weekdays`: **0 Sunday … 6 Saturday** (the same as a route's days).
- `PUT …/alerts { enabled, run_ids: [..], weekdays: [..], lead_minutes: 5|10|15, bus_change, service_days, late, notices }` → the same body as GET.
  A field that is missing keeps what the sheet showed: the saved value, or on a route never saved (`saved: false`) the
  default above, so the list switch `{ enabled }` keeps the usual timing; switching on a route that has no default timing that
  way ticks **every** timing of the route. `run_ids` replaces the ticked timings. The HTML's messages (422): on with no timing
  and no change type → "Pick a timing to be reminded for, or a change to hear about, or turn alerts off"; timings but no day →
  "Pick at least one day"; a timing of another route → "Pick a timing of this route"; `lead_minutes` other than 5 / 10 / 15 → 422.
  Turning alerts off is always allowed ("Nothing for this route. Safety notices from <company> still come").
- Screen wording: **Alerts for This Route** = `enabled`; **Remind Me for These Timings** = `run_ids` (Morning and Evening pills from
  `timings`); **On These Days** = `weekdays`; **How Early** = `lead_minutes`; **Tell Me About** = `notify` (Bus or Driver Change,
  No or Changed Service "the day before at 12:00", Running Late, Notices).

**List** (Account › Notifications › Shuttle Alerts): `GET /app/shuttles/alerts` →
`{ paused_until, routes: [ { employer, route: { id, name }, enabled, run_ids, weekdays, lead_minutes, notify, saved, timings } ] }`
(every route of every live employer; row = route name, "<timings> timings · <lead_minutes> min before · <days>" or "Off · <employer>";
the switch = `PUT …/alerts { enabled }`; a tap opens the sheet; `employer.id` builds the path).

**Pause Alerts** (all employers and routes; safety notices still come):
`PUT /app/shuttles/pause { until: "2026-12-01" }` → `{ data: { paused_until } }` (`422 "Pick a date after today"`; the quick
1 week / 2 weeks / 1 month buttons are FE dates); `DELETE /app/shuttles/pause` (Resume) → `{ paused_until: null }`.
`paused_until` is `null` again once the date has come.

## 8. Alerts the app receives (inbox)

A background job (every 5 minutes) writes rows into the account's **inbox** (the Alerts tab, [home.md § 4](home.md#4-alerts-tab-inbox);
no push is sent yet); they also show on Home as banners until the run (or day) ends. Only the change alerts of the HTML and route
**notices** exist; **Remind Me (5 / 10 / 15 min before the stop) and Running Late are saved settings only** for now. A notice Convoy
OS sends to the route's riders comes as `shuttle_notice` while **Notices** is ticked ([home.md § 5](home.md#5-which-alerts-are-written-and-when)).

| Alert | When | Text |
| --- | --- | --- |
| `shuttle_bus_change` "Different bus" | 1 hour before the bus reaches the rider's stop (see `alert` in §5), once; **again at once** when the bus changes again; a change made later than that alerts at once. Today and tomorrow's runs | "Look for PD5126A on the 07:30 <route> shuttle today instead of PC8841T. It reaches <stop> at 07:40." |
| `shuttle_cancelled` "Shuttle cancelled" | at once, for runs in the next 14 days (every vehicle of the timing cancelled) | "<route> 07:30 on tomorrow was cancelled by <company>. Next bus 08:30 from <stop>." |
| `shuttle_service_day` "No service tomorrow" / "Changed times tomorrow" | the day before from 12:00 (public holiday, the client's day off, a calendar shift), once per change | "No shuttle on <route> tomorrow (<reason>). Service resumes Mon 23 Nov." |

Sent only for the timings and weekdays ticked in the route's Alert Settings, while the route's alerts are on and not paused
(Pause Alerts), for a live link, and never for runs that have ended. **Never** for a relief driver alone, never on a No Fixed Bus
route. In the inbox a shuttle alert's `target` is `{ kind: "shuttle_route", id: <employer_id>, trip_id: <route id> }`.

## 9. Errors

| Code | When |
| --- | --- |
| `401` | missing / wrong token |
| `403 profile_required` | Create Your Account not finished |
| `404` | an employer or route that is not the person's (no live link, paused link, another person's `employer_id`, an ended route, another employer's route) |
| `422` | the messages above (usual, alert settings, pause), a date outside today … today + 92 days (`"Pick a day from today to 2027-02-16"`), a month outside `first_month … last_month`, a direction the route does not run |
