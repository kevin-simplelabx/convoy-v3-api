# Convoy App — Home, Activity, Alerts, Live Tracking

The four places that pull every service together (Phase 8): **Home** (greeting, invitations, notice banners, Up Next, service
tiles, Get Started), **Activity** (every trip: Now / Upcoming / Past), the **Alerts** tab (the inbox) and **Live Tracking** of a
child's morning bus. Design: `Convoy App.dc.html` (`home` H:102–250, `activity` H:1614–1684, `alerts` H:1579–1612, `live`
H:1370–1577). Paths start with `/api/v1/app`. Every call needs the app token ([auth.md](auth.md)).

1. [Home](#1-home-get-apphome)
2. [Notice banners and Dismiss](#2-notice-banners-and-dismiss)
3. [Activity](#3-activity-get-appactivity)
4. [Alerts tab (inbox)](#4-alerts-tab-inbox)
5. [Which alerts are written, and when](#5-which-alerts-are-written-and-when)
6. [Live Tracking](#6-live-tracking-get-appschoollive)
7. [Errors](#7-errors)

## 1. Home `GET /app/home`

```json
{ "data": {
  "greeting": { "first_name": "Rachel", "part_of_day": "morning", "text": "Good morning, Rachel" },
  "invitations": { "family": [ { "id": 12, "family": "Tan Family", "invited_by": "Rachel Tan", "relationship": "Grandparent", "invited_at": "…" } ],
                   "organisations": [ { "kind": "shuttle", "id": 3, "organisation": "Google Asia Pacific", "matched_email": "…", "…": "as GET /app/organisations" } ] },
  "banners": [ { "id": 41, "kind": "school_notice", "icon": "campaign", "tone": "info", "title": "Notice from SimpleDrive", "body": "Early Dismissal on …",
                 "sender": "SimpleDrive", "at": "…", "until": "…", "action": null } ],
  "up_next": [ { "kind": "school_bus", "icon": "school", "label": "School Bus · SimpleDrive · SSS AM 1", "badge": "Scheduled", "tone": "neutral",
                 "changed": false, "late_minutes": 0,
                 "depart": { "time": "07:20", "text": "Pick-up · Blk 412 Bedok North" }, "arrive": { "time": "07:40", "text": "Arrive · St. Stephen's School" },
                 "who": [ { "name": "Ethan Tan" } ], "foot": "Ethan · SBA3546K", "open": { "kind": "live", "bus": "7-2026-11-03" } } ],
  "tiles": [ { "key": "school_bus", "label": "School Bus", "caption": "1 child", "on": true, "badge": 1 },
             { "key": "shuttles", "label": "Shuttles", "caption": "By employer", "on": false, "badge": null },
             { "key": "bookings", "label": "Bookings", "caption": "2 upcoming", "on": true, "badge": null },
             { "key": "discover", "label": "Discover", "caption": "Coming soon", "on": false, "badge": null } ],
  "get_started": false,
  "badges": { "alerts": 3 }
} }
```

- **greeting**: `text` is "Welcome, <first>" for a person with nothing yet (no Family, no employer, no booking), else "Good
  morning / afternoon / evening, <first>" (Singapore time).
- **invitations**: answer them with the existing calls: Family → `POST /app/household/invitations/:id/accept|decline`
  ([household § 5.5](household.md#55-accept--not-me)); organisations → `POST /app/organisations/:kind/:id/accept|decline`
  ([organisations § 4](organisations.md#4-accept--not-me)). Home looks for new organisation matches each time (as Organisations does).
- **banners**: [§ 2](#2-notice-banners-and-dismiss).
- **up_next**, in the HTML order: the next booking of a school / company account (or "No upcoming bookings" with New Booking
  when the person has such an account and nothing booked) → the Family's **morning buses** (one card per bus, children on it in
  `who`) → if no child rides: the Family's next step (a child waiting for a bus, or "Add your children") → each employer's
  **usual shuttle** ("Pick your usual shuttle" while none) → the next **Personal** booking. Card `kind`:

  | kind | Fields | `open.kind` |
  | --- | --- | --- |
  | `school_bus` | `badge` (Scheduled / On the way / Started / Ended, or the date when the next bus day is not today), `changed` (not the usual bus / driver → orange dot), `late_minutes`, `depart`, `arrive`, `who`, `foot` ("Ethan · SBA3546K · Lucas not required") | `live` (`bus` = the Live key) |
  | `school_message` | `title`, `sub`, `foot` (button label), `badge`/`tone`/`who` for a waiting child | `school`, `add_child`, or the child's action from `GET /app/school` (`request`, `view_request`, `pay_registration`, `first_invoice`) |
  | `shuttle` | `badge` (Cancelled today / Different bus today / Relief driver today / On the way / Completed / Scheduled), `depart` (Board · stop), `arrive` (Alight · last stop), `foot` (Morning · plate) | `shuttle_route` (`employer_id`, `route_id`) |
  | `shuttle_message` | "Pick your usual shuttle" | `shuttle_usual` (`employer_id`) |
  | `booking` | `badge` ("All buses here" / "2 of 3 buses here" on the day, else the booking status), `depart`, `arrive`, `foot` (title · buses · pax · return) | `booking` or `track` (`booking_id`) |
  | `booking_none` | "No upcoming bookings" | `new_booking` (`account`) |

  The School Bus section under Up Next (children's cards, quick actions) is `GET /app/school` ([school § 2](school.md#2-school-bus-page-get-appschool)).
- **tiles**: School Bus caption = riding children, else the Family's children, else "Add children", else "Set up" (no Family:
  open Set Up Your Family); its `badge` = bills to pay, **Billing Contact only**. Shuttles caption = employer marks, off
  ("By employer") without a link (sheet "Shuttles Come From Your Employer"). Bookings caption "n upcoming" / "Book a bus", `badge`
  = bookings with changes to accept. Discover is always "Coming soon".
- **get_started**: `true` for a person with no Family, no employer and no upcoming booking: show the three Get Started rows
  instead of the tiles (Book a Bus → Bookings, School Bus for a Child → Set Up Your Family, Staff Shuttle → Mobile and Emails
  with Add Work Email).
- **badges.alerts**: unread alerts (the Alerts tab badge).

## 2. Notice banners and Dismiss

`banners` are inbox alerts that also show on Home **until** `until` (newest first, at most 10, the newest per run and kind): a
school notice to parents or a shuttle route notice (until the notice ends; ended early in Convoy OS → gone at once), a bus
running late or a different bus today (until the run ends), shuttle changes (until the run ends, a day alert until that day
ends). `action` = `{ label, target, target_id, trip_id }` when the card has a button ("Track the Bus" → Live, "Open" → the
shuttle route or booking), else `null`.

**X** → `POST /app/home/banners/:id/dismiss` → `{ data: { id, dismissed: true } }`. It leaves Home for this person only; the
alert stays in the inbox. Another person's id → `404`.

## 3. Activity `GET /app/activity`

`?service=school|shuttle|booking` narrows the list (the chips; show them only when `services` has more than one).

```json
{ "data": { "services": ["school", "booking"], "service": null,
  "now": [ { "service": "school", "date": "2026-11-03", "time": "07:20", "title": "Pick-up · Ethan", "sub": "Blk 412 Bedok North · SBA3546K",
             "badge": "Started", "tone": "warning", "live": true, "done": false, "open": { "kind": "live", "bus": "7-2026-11-03" } } ],
  "upcoming": [ … ], "past": [ … ] } }
```

- **now** = under way; **upcoming** = not under way and not over (oldest first); **past** = over (newest first, the last 8).
- **School Bus**: each riding child × leg on the days a run exists, 14 days back to 7 days ahead. Pick-up: "Pick-up · <first>",
  "<stop> · <plate>"; Drop-off: "Drop-off · <first>", "Leaves school HH:MM · <plate>". Badge Not required / Cancelled /
  Completed / Started / On the way / Scheduled. `open`: `live` (`bus`) for a morning leg under way, else `bus_info`
  (`dependant_id`, `session`) → `GET /app/school/riders/:dependant_id/bus?session=`.
- **Shuttles**: the usual timing at each employer over the same days ("<route> · Morning", "<stop> · <plates>"); badge
  Cancelled / Different bus / Relief driver / On the way / Started / Completed / Scheduled; `open` = `shuttle_route`.
- **Bookings**: one row per booking trip (declined left out) from 30 days ago: "<title> · <last point>", "<kind> · n buses ·
  <company>", the trip status; `open` = `track` while a bus is on the road, else `booking` (`booking_id`).
- Nothing at all: the HTML's empty state ("No trips yet … Book a Bus").

## 4. Alerts tab (inbox)

One inbox per account across Family, staff and bookings. No push is sent yet; the rows are the same ones a push will carry.

`GET /app/alerts?filter=all|delays|notices&page=` →

```json
{ "data": [ { "id": 41, "kind": "school_late", "icon": "schedule", "tone": "warning", "filter": "delays", "chip": "track_bus",
              "title": "Bus SBA3546K running 6 min late", "body": "New pick-up ETA 07:26 at Blk 412 Bedok North.", "at": "…",
              "group": "today", "read": false, "read_at": null, "company": "SimpleDrive", "dependant_id": 5,
              "target": { "kind": "live", "id": 5, "trip_id": null } } ],
  "meta": { "page": 1, "limit": 30, "count": 9, "pages": 1, "filter": "all", "unread": 4 } }
```

- Header: `meta.unread` → "n unread" / "All read"; **Mark All Read** only when `unread > 0`.
- Pills **All / Delays / Notices** = `filter` (Delays = running late; Notices = school and shuttle notices).
- Groups **Today / Earlier** = `group` (Singapore date). Unread dot = `read: false`.
- `icon` (Material Symbols name) and `tone` (info = teal, warning = orange, success = green, danger = red) per kind.
- `chip`: `track_bus` → show "Track Bus ›"; `school_calendar` → "School Calendar ›" (School Calendar is Phase 4b); `null` → none.
- **Tap**: `POST /app/alerts/:id/read` → `{ data: alert, meta: { unread } }`, then open `target`:

  | target.kind | Opens |
  | --- | --- |
  | `live` | Live Tracking (`GET /app/school/live`; the child is `target.id`) |
  | `school_calendar` | School Calendar (Phase 4b) |
  | `shuttle_route` | Shuttle route: employer `target.id`, route `trip_id` |
  | `booking` | Booking detail `target.id` |
  | `school_request` | Application Status `target.id` |
  | `fee_invoice` | Invoice `target.id` ([fees § 3](fees.md#3-invoice-get-appfeesinvoicesid)) |
  | `household_invitations` | the Family invite on Home |
  | `organisations` | Account › Organisations |
  | `null` | nothing (just marks read) |

- **Mark All Read**: `POST /app/alerts/read_all` → `{ data: { updated, unread: 0 } }`.
- Empty: "Nothing here yet."

## 5. Which alerts are written, and when

School Bus alerts go to **every adult of the Family**; bill alerts to the **Billing Contact** only; the person who did something
in the app (withdrew a request, cancelled a booking) is not told about it. Each alert is written once.

| kind | Title (example) | When |
| --- | --- | --- |
| `school_started` | Morning trip started · "Bus SBA3546K left on SSS AM 1." | the driver starts the morning run |
| `school_near` | Bus SBA3546K is 9 min from Blk 412 Bedok North | the morning bus is 10 min or less from the child's stop (the Live map opens) |
| `school_late` | Bus SBA3546K running 6 min late · "New pick-up ETA 07:26 at …" | 5+ min late before the child's stop, again at each 5 more minutes (10, 15 …); morning and afternoon. Home banner until the run ends |
| `school_bus_change` | Different bus for Ethan today · "Today PC7475L instead of SBA3546K. Pick-up time is the same." | not the route's regular bus that day, from 1 hour before the child's stop. Home banner |
| `school_boarded` / `school_alighted` | Ethan Tan boarded / alighted | the driver or attendant ticks the child (morning: boarded at the stop, arrived at school; afternoon: boarded at school, dropped off at the stop) |
| `school_notice` | Notice from SimpleDrive | a School Bus notice to parents comes into force (school, or the routes picked). Home banner until it ends |
| `shuttle_notice` | Notice · <route> | a shuttle route notice to riders comes into force, for riders whose Alert Settings for the route are on with **Notices** ticked and a ticked timing covered; not while Pause Alerts is set. Home banner |
| `shuttle_bus_change`, `shuttle_cancelled`, `shuttle_service_day` | see [shuttles § 8](shuttles.md#8-alerts-the-app-receives-inbox) | Home banner until the run / day ends. Shuttle alerts and notices only for a live employer (the same rule as `GET /app/shuttles`: not a client the office removed) |
| `bill_issued` | Invoice INV-2026-0901 issued · "Term 4 · S$600.00 · due 17 Nov." | a Family bill is issued (Billing Contact) |
| `request_update` | Ethan Tan · Accepted | a bus request (application, renewal, change, stop, address) changes status |
| `booking_confirmed` | SD26000141 confirmed by SimpleDrive | the company confirms a trip. Booking alerts reach a school link only while it can open the booking (accepted, booking role, work email verified within 12 months) |
| `booking_changed` | Changes to SD26000149 Sports Day | the company changes trips (Accept Changes / Can't Accept) |
| `booking_declined` | SD26000150 declined | the company declines a trip |
| `booking_cancelled` / `booking_cancel_declined` | Cancellation accepted / not accepted | the company answers a cancellation request |
| `invite_employer` / `invite_bookings` | Google Asia Pacific added you to its staff shuttle | a work email matches an employer / a school's client user |
| `invite_family` | Rachel Tan invited you to the Tan Family | an adult invites the person (Manual Invite) |

Not written (not in the HTML or a later phase): Bus Not Required recorded, "asks for your help" (stop photo), Issue reported
(Phase 4b); shuttle Reminder / Running Late (saved settings only, [shuttles § 8](shuttles.md#8-alerts-the-app-receives-inbox)); afternoon "10 min away".

## 6. Live Tracking `GET /app/school/live`

The **morning** bus of the Family's children on their next bus day (afternoon tracking is not designed). Needs a Family
(`404 no_household` otherwise). `?bus=<key>` picks a chip; without it the first bus with a child riding. **Poll** every
`poll_seconds` (15) while the screen is open.

```json
{ "data": {
  "state": "near", "poll_seconds": 15,
  "buses": [ { "key": "7-2026-11-03", "date": "2026-11-03", "names": ["Ethan Tan"], "first_names": ["Ethan"], "plate": "SBA3546K", "warn": false } ],
  "bus": {
    "key": "7-2026-11-03", "date": "2026-11-03", "today": true, "title": "SSS AM 1", "sub": "SBA3546K · SSS AM 1 · Pick-up",
    "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" }, "status": { "label": "Started", "tone": "warning" }, "late_minutes": 0,
    "vehicle": { "plate": "SBA3546K", "seats": 40, "model": "Yutong ZK6107", "size": "LARGE_40" },
    "riders": [ { "dependant_id": 5, "name": "Ethan Tan", "first_name": "Ethan" } ], "not_required": [],
    "eta": { "label": "ETA at Blk 412 Bedok North", "at": "07:20", "scheduled": "07:20", "stops_away": 0, "minutes": 9,
             "text": "Scheduled 07:20 · 0 stops away", "picked_up": false },
    "stops": [ { "name": "Stop 1", "meta": null, "time": "07:00", "state": "departed", "mine": false, "school": false },
               { "name": "Stop 2", "meta": null, "time": "07:08", "state": "departed", "mine": false, "school": false },
               { "name": "Blk 412 Bedok North", "meta": "Ethan boards here", "time": "07:20", "state": "next", "mine": true, "school": false },
               { "name": "St. Stephen's School", "meta": "Arrive", "time": "07:40", "state": "upcoming", "mine": false, "school": true } ],
    "my_stop": { "name": "Blk 412 Bedok North", "note": "At the sheltered drop-off bay", "lat": 1.3236, "lng": 103.93, "photo": { "url": "…", "thumb_url": "…" }, "street_view_url": "…" },
    "crew": [ { "role": "Driver", "name": "Ahmad Ismail", "phone": "+65 …", "relief": false }, { "role": "Bus Attendant", "name": "…", "phone": "…", "relief": false } ],
    "change": null,
    "position": { "lat": 1.329, "lng": 103.926, "speed_kmh": 30, "heading": 90, "recorded_at": "…" },
    "path": [ [1.329, 103.926], [1.3236, 103.93], [1.3138, 103.9283] ]
  } } }
```

- **state**: `none` → "Nothing to track yet" (no child rides in the morning); `far` → the waiting card ("Bus <plate> is on the
  way", ETA, crew, "The map opens 10 minutes before the bus reaches your stop…"); `near` → the map; `ended` → the run is over.
- **The 10-minute rule is server-side**: `position` and `path` are sent **only** in `near` — from 10 minutes before the bus
  reaches the child's stop (ETA = planned time + lateness from the stops reached and the GPS) until the run ends. In `far`
  and `ended` both are `null`. `path` is the line ahead only: bus → the child's stop (until reached) → school; never other
  stops and no trail.
- **Privacy**: `stops` has at most four rows: the 2 stops before the child's as "Stop N" (no name, no time but the planned one,
  no place), the child's stop by name, then the school. Only the Family's own children are in `riders`, `not_required`,
  `names`; other children never appear.
- `buses` = the chips (show when more than one); `warn` = orange dot (not the usual bus or driver). `status`: the date when
  the next bus day is not today, else Scheduled / On the way / Started / Ended.
- `eta`: `at` (big number), `text` ("Scheduled 07:20 · 2 stops away · running 6 min late"), `minutes` to the stop;
  `picked_up: true` once the bus reached the child's stop (`label` "Picked up at <stop>"); `null` in `ended`.
- `change` = `{ title: "Not the usual bus or crew", text: "Today a different bus, PC7475L instead of SBA3546K, and a relief driver, … covering for …. Pick-up time is the same." }` or `null`.
- `crew`: call buttons use `phone` (ask first, as the HTML). `relief: true` → "Relief driver".
- `stops[].state`: `departed` (grey), `at_stop`, `next`, `upcoming`; `mine` = the child's stop (bold, "boards here").
- The help-request banner (stop photo) is Phase 4b; until then it is not shown.

## 7. Errors

| Code | When |
| --- | --- |
| `401` | missing / wrong token |
| `403 profile_required` | Create Your Account not finished |
| `404` | an alert or banner that is not the person's; Live Tracking without a Family (`code: "no_household"`) |
