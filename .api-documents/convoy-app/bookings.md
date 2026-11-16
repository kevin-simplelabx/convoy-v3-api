# Convoy App — Bookings (book a bus: school / company, or personally)

The **Bookings** list, a **booking**, **New Booking** (3 steps), **Pick a Point**, **Accept Changes / Can't Accept**,
**Cancel**, **Book Again** and **Track Buses**. Design: `Convoy App.dc.html` screens `bookings`, `bkDetail`, `bkNew`, `bkPt`,
`bkTrack` and the sheets `acc`, `cx`, `reply`, `dup`, `link`. Conventions: [README.md](README.md); how a teacher / booker gets a
school account: [organisations.md](organisations.md). Paths start with `/api/v1/app`. Times are `"HH:MM"` in the transport
company's time zone (Singapore); dates `YYYY-MM-DD`; money is a decimal string (`"123.0"`), show it as `S$123.00`.

## Contents

1. [Booking accounts](#1-booking-accounts)
2. [List: `GET /app/bookings`](#2-list-get-appbookings)
3. [A booking: `GET /app/bookings/:id`](#3-a-booking-get-appbookingsid)
4. [New Booking](#4-new-booking)
5. [Pick a Point](#5-pick-a-point)
6. [Accept Changes / Can't Accept](#6-accept-changes--cant-accept)
7. [Cancel](#7-cancel)
8. [Book Again](#8-book-again)
9. [Track Buses](#9-track-buses)
10. [Money: what is paid and when](#10-money-what-is-paid-and-when)
11. [Errors](#11-errors)

---

## 1. Booking accounts

`GET /app/bookings/accounts` → `{ accounts: [account], work_hint }`

```json
{ "data": {
  "accounts": [
    { "key": "personal-1", "kind": "personal", "org": "Personal", "role": "Personal", "client": null, "terms": "prepaid",
      "company": { "id": 1, "name": "SimpleDrive", "ops_phone": "+65 6123 4567" } },
    { "key": "link-10", "kind": "link", "org": "St. Stephen's School", "role": "Member", "terms": "credit",
      "client": { "id": 4, "name": "St. Stephen's School" }, "company": { "id": 1, "name": "SimpleDrive", "ops_phone": "+65 6123 4567" } } ],
  "work_hint": false } }
```

- **Personal**: one per transport company that takes personal bookings (today SimpleDrive). Everyone has it. Personal
  bookings are **paid when sent** (simulated), no approval.
- **link**: each school / company booking link the person accepted ([organisations.md](organisations.md)) whose role may book
  (Finance roles do not get one), while the work email is verified (a paused link is left out). Bookings are **invoiced to the
  organisation after the trip** (`terms: "credit"`), through its approval flow. There is no prepay.
- Every other call takes **`account` = `key`** (list, form, estimate, create, points). A booking id needs no account: it is
  found among the person's own bookings only.
- Header: one account → "`org` · by `company.name`"; several → the switch sheet `acc` (title `company.name` for Personal,
  sub "With SimpleDrive · pay by card or PayNow" / "`org` · `role`"). Foot: "Missing one? Your company adds you with the
  transport company, using your work email."
- `work_hint: true` (no school / company link): show **Bill to Your Company?** → the `link` sheet (Add Work Email /
  Suggest Convoy, [account.md](account.md)).

## 2. List: `GET /app/bookings`

Query: `account` (required), `tab` = `current` (default) | `pending` | `past` | `all`, `page`. Page size 20.
`meta: { page, limit, count, pages, tab, account }`.

| Tab | Statuses | Order |
| --- | --- | --- |
| Current | `confirmed`, `ongoing`, `approved` | in progress first, then first day |
| Pending | `pending`, `changed`, `cxreq` | first day |
| Past | `completed`, `cancelled`, `rejected` | newest first day first |
| All | open ones (as above), then past | |

Card:

```json
{ "id": 12, "number": "SD26000012", "title": "P5 Zoo Excursion", "first_date": "2026-11-22", "days_count": 1, "trips_count": 1,
  "buses_count": 1, "pax": 40, "start_time": "08:00", "return_time": "12:30", "status": "confirmed", "status_label": "Confirmed",
  "tone": "success", "tab": "current", "payer": "client", "amount": "276.0", "note": null, "warm": false }
```

- Date block from `first_date` (orange when `warm`, grey on Past); meta "`number` · N days · N trips · N buses"; "`pax` pax ·
  `start_time` to `return_time`"; chip `status_label` / `tone`; `amount`; `note` under the card when set (orange when `warm` or
  in progress). Notes: "Under way today · 1 of 2 buses at the pick-up", "Changes from SimpleDrive waiting for your acceptance" /
  "You replied. SimpleDrive is sending another option", "With Lim Hui Ling for approval", "S$114.07 paid by Card · SimpleDrive to
  confirm", "Cancellation sent · SimpleDrive confirms it", "2 trips cancelled", "Paid personally".
- Statuses: `pending` (with the approver, or sent and waiting for the company), `approved` (approver signed off, company to
  confirm), `confirmed`, `ongoing` ("In Progress": a bus on the road today), `changed` (the company changed it: accept or
  reply), `cxreq` (a cancellation of the whole booking waits for the company), `completed`, `cancelled`, `rejected`.
- Empty: "No current bookings with SimpleDrive." Foot text: Personal "Personal bookings are paid when you book. SimpleDrive
  confirms within 1 working day; if it can't, you are refunded in full."; link "School bookings are invoiced by SimpleDrive to
  St. Stephen's School after the trip. Trips you pay for yourself skip approval."
- **Pay Myself** bookings made from a school account are listed on that school account (not on Personal).

## 3. A booking: `GET /app/bookings/:id`

The card fields plus:

```json
{ "company": { "name": "SimpleDrive", "ops_phone": "+65 6123 4567" }, "account": "link-10", "short_notice": false,
  "banner": { "title": "Changes from SimpleDrive", "text": "SimpleDrive changed the booking. Wed 25 Nov: Pick-up time: 07:15 to 07:45.",
              "icon": "edit_note", "tone": "warning", "accept_changes": true, "reply": true, "reply_label": "Can't Accept" },
  "days": [ { "id": 31, "date": "2026-11-25", "cancelled": false } ],
  "trips": [ { "id": 40, "day_id": 31, "date": "2026-11-25", "kind": "two_way", "kind_label": "Ad Hoc / Charter, Two Way", "icon": "sync_alt",
               "start_time": "08:00", "return_time": "12:30", "hours": null, "pax": 40, "adults": 3, "flight_number": null, "terminal": null,
               "airport_direction": null, "vehicles": [ { "vehicle_type_id": 2, "name": "40-seater", "seats": 40, "count": 1 } ],
               "vehicles_text": "1 × 40-seater", "note": null, "contact": { "name": "Priya Nair", "phone": "+65 9166 7720" },
               "status": "confirmed", "status_label": "Confirmed", "tone": "success",
               "points": [ { "name": "St. Stephen's School", "address": "20 Siglap View", "lat": 1.3156, "lng": 103.9262, "note": "Bus bay", "time": "08:00" },
                           { "name": "Singapore Zoo", "address": null, "lat": 1.4043, "lng": 103.793, "note": null, "time": null } ],
               "back_points": null, "return_text": "Return leaves Singapore Zoo at 12:30", "estimate": "276.0",
               "buses": [ { "n": 1, "occurrence_id": 900, "plate": "PC7475L", "desc": "Scania · 40 seats",
                            "driver": { "name": "Eric Pang", "photo": null }, "state": "here", "state_text": "At pick-up since 07:44",
                            "since": "…", "eta_at": null, "km": null } ],
               "no_bus_text": null, "track": false } ],
  "rows": [ { "key": "requested_by", "label": "Requested by", "value": "Priya Nair" },
            { "key": "contact", "label": "Contact on the day", "value": "Priya Nair · +65 9166 7720" },
            { "key": "approver", "label": "Approver", "value": "Lim Hui Ling" },
            { "key": "bill_to", "label": "Bill to", "value": "St. Stephen's School · Parents Support Group" },
            { "key": "payment", "label": "Payment", "value": "Invoiced after the trip" },
            { "key": "po", "label": "PO", "value": "SSS-P5-ZOO" }, { "key": "vehicles", "label": "Vehicles", "value": "1" } ],
  "total": { "label": "Confirmed price", "amount": "276.0" },
  "timeline": [ { "name": "Requested", "meta": "Sent Mon 16 Nov by Priya Nair", "state": "done" },
                { "name": "School approval", "meta": "Lim Hui Ling approved", "state": "done" },
                { "name": "Provider confirmation", "meta": "SimpleDrive confirmed the buses", "state": "done" },
                { "name": "On the day", "meta": "Plates and drivers shared the day before · live tracking", "state": "current" },
                { "name": "Invoiced", "meta": "After the trip, to the school's finance office", "state": "todo" } ],
  "actions": { "cancel": true, "cancel_label": "Request Cancellation", "book_again": true, "call_ops": false, "track": false },
  "payments": [], "cancel_parts": [], "replies": [], "receipt": null }
```

- **Banner** (`null` = none): title, text, icon, tone. `accept_changes` / `reply` show the two buttons (§6).
- **Day pills** when `days.length > 1` (" · Cancelled" when `cancelled`); the trips of the picked day = `trips` with that `day_id`.
- **Trip card**: icon, "`kind_label` · `start_time` to `return_time`", "date · pax pax · `vehicles_text`", chip `status_label`
  (`pending`, `approved`, `changed`, `confirmed`, `live` "On the way", `done` "Completed", `declined`, `cancelled`,
  `cancel_requested`); points with "Note for the driver: …"; `return_text`; "Times are for the convoy; each bus shows its own
  below" when `buses.length > 1`.
- **Buses**: shown from the **day before** the trip once confirmed: avatar `driver.photo` / `driver.name`, `desc`, plate chip,
  `state_text` on the day (`here` green, `on_the_way` orange). No driver phone here (only in Track Buses, on the day). No bus:
  `no_bus_text` ("Buses are assigned once approved and confirmed." / "SimpleDrive shares the plates and drivers the day before.").
  `track: true` → **Track Buses** (§9).
- **Rows** as given (label / value). Personal: Requested by "· personal", Payment; school: Approver, Bill to, Payment. Each
  cancellation part: "Cancelled" / "Cancel requested" · "Day … · S$x charge / no charge". **Total** `label` / `amount`.
- **Timeline** state `done` (green), `current` (teal ring), `todo` (grey). Personal: Requested, Paid, Provider confirmation,
  On the day, Receipt.
- **Actions**: `cancel` → the Cancel sheet (§7) with `cancel_label`; `call_ops` → "A trip under way can't be cancelled in the
  app. Call the provider for changes on the day." + Call `company.ops_phone`; `book_again` → §8.
- `payments` (Personal / Pay Myself): `{ kind: payment|refund, method: card|paynow, method_label, amount, card_fee, charged,
  reference, paid_at, note }`. `replies`: your Can't Accept replies. `receipt`: the company name on the receipt (Personal).
- The invoice / receipt itself is not shown (text only), as in the design.

## 4. New Booking

### 4.1 Form: `GET /app/bookings/form?account=`

```json
{ "data": {
  "account": { "key": "link-10", "…": "" },
  "booker": { "name": "Priya Nair", "role": "Teacher", "phone": "+65 9166 7720", "email": "priya_nair@moe.edu.sg" },
  "payers": [
    { "key": "client", "label": "St. Stephen's School", "sub": "Invoiced after the trip · approver signs off", "prepaid": false,
      "vehicle_types": [ { "id": 2, "name": "40-seater", "seats": 40 } ], "funds": [ { "id": 1, "name": "Admin Fund" } ],
      "fund_required": true, "sites": [], "site_required": false, "default_po": null, "methods": [] },
    { "key": "self", "label": "Pay Myself", "sub": "Pay now by card or PayNow · no approval", "prepaid": true,
      "vehicle_types": [ "…" ], "funds": [], "fund_required": false, "sites": [], "site_required": false,
      "methods": [ { "key": "card", "label": "Card", "icon": "credit_card", "fee_kind": "pct", "fee": "3.7", "fee_text": "+3.7% card fee" },
                   { "key": "paynow", "label": "PayNow", "icon": "qr_code_2", "fee_kind": "none", "fee": "0.0", "fee_text": "No fee" } ],
      "note": "For trips the school does not fund. You pay when you book. …" } ],
  "default_payer": "client", "receipt_allowed": false,
  "waiting": { "free_minutes": 10, "fee": "15.0", "block_minutes": 15, "text": "First 10 min free, then S$15.00 per 15 min per bus" },
  "limits": { "days": 10, "span_days": 10, "trips_a_day": 10, "vehicles_a_trip": 10, "stops": 5, "short_notice_days": 3 },
  "kinds": [ { "key": "one_way", "label": "Ad Hoc / Charter" }, "…" ], "disposal_hours": [3, 4, 5, 6, 8, 10, 12],
  "contact_phone_format": "8 digits starting with 8 or 9" } }
```

- **Who Pays**: a school account offers `client` (the organisation) and `self` (**Pay Myself**); Personal offers `self` only
  (the design's "Bill to My Company" opens the `link` sheet, not a payer). Each payer has its own `vehicle_types`.
- **Bill To** = `funds` (required when `fund_required`). **Approver**: no picker. The client's Approval Flow decides; the
  estimate shows who (§4.2), read only. **PO**: free text (prefill `default_po`).
- **Site**: only when `site_required` (the organisation has sites, as in the Client Portal): pick one of `sites` (one = preselect it).
- Pay Myself: `methods` (no saved cards: "Add card" stays Coming Soon). Personal: **Receipt in My Company's Name** when
  `receipt_allowed` (company name*, UEN ≤ 10 upper case, billing address*).
- Passengers: **Students** + **Teachers and Adults** (school), **Adults** + **Children** (Personal). Send `pax` = the total and
  `adults` = the teachers / adults among them.
- Step 1 checks in the FE as the design (date and time, every point, return time and way back, passengers, at least one
  vehicle). The server checks them again (and enough seats for the passengers).

### 4.2 Estimate: `POST /app/bookings/estimate`

Body: `{ account, payer, method (self), booking }` (the booking as in §4.3). Nothing is saved.

- Organisation: `{ trips: [ { date, kind, amount, lines, without_rate, rate } ], total, rate_card, billed_to, approval, payer, short_notice }`.
  `approval` = `{ need, name, steps: [ { position, label, people: [ { id, name } ], need } ] }`: "Lim Hui Ling approves in the app or
  by email" → show the step people; `need: false` → "Goes straight to SimpleDrive".
- Pay Myself: same `trips` / `total` + `method`, `card_fee`, `charged` (Total = charged; rows "Estimate", "Card fee 3.7%").
- `rate` = the rate period at the pick-up ("Peak", "Off Peak", "Weekend / PH"): "… rate". `short_notice: true` (first day less
  than 3 days away): "Short notice: SimpleDrive first checks it has buses and drivers free."

### 4.3 Send: `POST /app/bookings`

```json
{ "account": "link-10", "payer": "client", "agree": true, "contact": { "me": true },
  "booking": { "title": "P4 Learning Journey", "client_bill_fund_id": 1, "po_number": "PO-1", "notes": "…", "client_site_id": null,
               "days": [ { "date": "2026-11-20", "trips": [
                 { "kind": "two_way", "start_time": "08:30", "return_time": "13:30", "pax": 82, "adults": 4, "note": "…",
                   "distance_km": 18.2, "return_distance_km": 18.2,
                   "points": [ { "name": "St. Stephen's School", "address": "20 Siglap View", "lat": 1.3156, "lng": 103.9262, "use": "pu", "note": "Bus bay" },
                               { "name": "Science Centre Singapore", "lat": 1.3329, "lng": 103.7356, "use": "do" } ],
                   "back_points": [],
                   "vehicles": [ { "vehicle_type_id": 2, "count": 2 } ] } ] } ] } }
```

- Trips are grouped by date (`days`), as the Client Portal. Kinds: `one_way` (Ad Hoc / Charter), `two_way` (return later the
  same day; `back_points` only when the way back was edited), `disposal` (`hours`, the first point only), `airport`
  (`airport_direction` arrival | departure, `flight_number`, `terminal`). Up to 5 stops between pick-up and drop-off.
  `distance_km` comes from the FE's road route (OSRM), as in the Portal.
- `contact`: `{ "me": true }` (the booker) or `{ "name", "phone" }` (SG mobile, 8 digits starting with 8 / 9). It is written on
  every trip as the contact on the day.
- `agree: true` is required (charter terms + cancellation policy).
- Pay Myself: `"payer": "self", "method": "card" | "paynow"`; Personal may add `"receipt": { "name", "uen", "address" }`.
- Book Again: add `"copied_from_id": <booking id>` (§8).
- Answer: `201` + the booking (§3). Organisation: `pending` with the approver (or straight to the company when no flow
  applies); Pay Myself / Personal: paid at once (simulated), `pending` until the company confirms.
- The submit button reads **Send for Approval** (organisation) or **Pay** (Pay Myself).

## 5. Pick a Point

Search (OneMap, ≥ 3 characters), the map with a fixed pin, and the address under the pin are **FE** (no API). The lists:

`GET /app/bookings/points?account=` →

```json
{ "data": { "org_name": "St. Stephen's School", "can_save_org": false,
  "org": [ { "id": 3, "kind": "org", "name": "School Gate (Siglap View)", "address": "20 Siglap View, Singapore 455789", "lat": 1.3156, "lng": 103.9262,
             "note": "Bus bay beside the guardhouse", "by": "Ops Manager" } ],
  "mine": [ { "id": "home", "kind": "home", "name": "Home", "address": "Blk 123 Tampines St 11, Singapore 521123", "lat": 1.35, "lng": 103.95, "note": null, "by": null } ],
  "recent": [ { "id": null, "kind": "recent", "name": "Science Centre Singapore", "address": null, "lat": 1.33, "lng": 103.74, "note": null, "by": null } ] } }
```

- **`org`** ("St. Stephen's School Points", sub "Saved by St. Stephen's School's booking admins"): school accounts only.
- **`mine`** (My Points): the person's own, on every account; Personal also has **Home** (the Family's address).
- **`recent`**: the last 5 different points of this account's bookings that are not saved already. Filter the lists by the
  search text in the FE.
- Save This Point: `POST /app/bookings/points { account, to: "me" | "org", name, address, lat, lng, note }` → `201` the point.
  `to: "org"` only when `can_save_org` (the school's booking admins), else `403`. Same name twice → `422`. Editing a saved
  point's note on the confirm screen changes **this booking only** (send it as the point's `note`).

## 6. Accept Changes / Can't Accept

Status `changed` (the company changed a trip). The banner text lists the changes.

- **Accept Changes**: `POST /app/bookings/:id/accept_changes` → the booking. Every changed trip goes back to the company
  (flash "Changes accepted. SimpleDrive is notified").
- **Can't Accept / Reply Again** (sheet `reply`): `POST /app/bookings/:id/reply { reason, message }` → the booking. `reason`
  one of "The new time does not work", "We need the buses we asked for", "The price is more than approved", "Something else".
  The booking stays as it is; the note becomes "You replied. SimpleDrive is sending another option" and the button "Reply
  Again". The company sees the reply in Convoy OS.
- No changes waiting: `422 no_changes`.

## 7. Cancel

`GET /app/bookings/:id/cancel` → the choices with the charge **before** sending:

```json
{ "data": { "reasons": ["Trip postponed", "Trip called off", "Booked by mistake", "Booking again with changes", "Other reason"],
  "scopes": [
    { "key": "booking", "label": "Whole Booking", "trip_ids": [40, 41], "fee": "276.0", "confirmed": true, "late_cancel_hours": 24,
      "fee_text": "Per trip: full charge within 24 hours of the start, free before that",
      "note": "SimpleDrive confirms the cancellation and the charge. The buses stay booked until then." },
    { "key": "day-31", "label": "Day 1 · Tue 17 Nov", "trip_ids": [40], "fee": "276.0", "confirmed": true,
      "fee_text": "Full charge: less than 24 hours before the trip", "note": "…" },
    { "key": "day-32", "label": "Day 2 · Wed 25 Nov", "trip_ids": [41], "fee": "0.0", "confirmed": true,
      "fee_text": "No charge: more than 24 hours before the trip", "note": "…" } ] } }
```

- Scopes: **Whole Booking** ("Rest of the Booking" once part has gone), each **Day** (several days), each **Trip** (a day with
  several trips). Only trips not cancelled, declined or already asked about, from tomorrow on, or today before the pick-up and
  not under way. `scopes: []` → no Cancel button (and a trip under way: `actions.call_ops`).
- **Charge** (the transport company's rule, Convoy OS › client `late_cancel_hours`, 24 by default): a trip the company has not
  confirmed is free; a confirmed trip starting within that many hours is charged in full, free before that. Fee box: red with
  `fee` when > 0, green otherwise; `fee_text`; `note`.
- Send: `POST /app/bookings/:id/cancel { scope: key, reason, note }` → the booking + `meta: { cancelled_trip_ids, request_id }`.
  - Trips not confirmed yet are **cancelled at once** (free; a Personal booking is refunded for them; flash "Booking cancelled" /
    "Day cancelled").
  - Confirmed trips become a **request** the company accepts or declines in Convoy OS (flash "Cancellation request sent to
    SimpleDrive"); the booking shows Cancel Requested / `cxreq`. If accepted, the charge is what was quoted here.
  - Button label: "Cancel Booking / Day / Trip" (nothing confirmed) or "Send Request"; second button "Keep Booking".
- `422`: "Pick a reason"; `not_cancellable` (the scope is gone: e.g. the trip started meanwhile).

## 8. Book Again

Sheet `dup`: `GET /app/bookings/:id/copy?first_day=YYYY-MM-DD` (call it again when the date changes; without `first_day` the
new dates are `null`).

```json
{ "data": { "from": { "id": 12, "number": "SD26000012", "title": "P5 Zoo Excursion" }, "first_day": "2026-12-24", "shift_days": 32,
  "days": [ { "was": "2026-11-22", "date": "2026-12-24", "trips_count": 1, "flag": null },
            { "was": "2026-11-23", "date": "2026-12-25", "trips_count": 1, "flag": "Christmas Day" } ],
  "payer": "client", "account": "link-10",
  "booking": { "title": "P5 Zoo Excursion", "notes": null, "client_bill_fund_id": 3, "client_site_id": null, "days": [ "… §4.3 shape" ] } } }
```

- Rows: "Was Sun 22 Nov" → `date`, `flag` (orange: "Weekend" or the public holiday's name). `first_day` before today → `422
  "Pick a date from today"`.
- Continue opens New Booking prefilled with `booking` (trips, points, driver notes, buses, passengers, notes; **not** the PO,
  flights or approval) and `payer`; the price is estimated again. Send it with `copied_from_id` → the new booking's rows show
  "Copied from SD26000012".

## 9. Track Buses

`GET /app/bookings/:id/track` (only when `actions.track`; else `404`):

```json
{ "data": { "id": 12, "number": "SD26000012", "title": "P5 Zoo Excursion", "company": { "name": "SimpleDrive", "ops_phone": "+65 6123 4567" },
  "trips": [ { "booking_trip_id": 40, "kind_label": "Ad Hoc / Charter, Two Way", "live": true,
               "depart": { "time": "08:00", "name": "St. Stephen's School" }, "arrive": { "name": "Singapore Zoo" },
               "return_text": "Return leaves Singapore Zoo at 12:30", "badge": "1 of 2 here",
               "route": [ [1.3156, 103.9262], [1.4043, 103.793] ],
               "buses": [ { "n": 1, "occurrence_id": 900, "way": "there", "plate": "PC7475L", "desc": "Scania",
                            "driver": { "name": "Eric Pang", "photo": null, "phone": "+6592104100" },
                            "state": "on_the_way", "state_text": "On the way · 1.8 km · about 07:56", "eta_at": "…", "km": 1.8, "since": null,
                            "position": { "lat": 1.32, "lng": 103.92, "heading": 90, "recorded_at": "…" } } ] } ] } }
```

- Header "`number` · `company.name`", badge `badge`; caption / times from `depart`, `arrive`, `return_text`. Map: `route`,
  numbered markers from `buses[].position` (only while on the road), Fit buses / Fit route are FE. Poll every ~15 s.
- Bus row: number, avatar, name, plate, `desc`, `state_text` (`here` green, `on_the_way` orange), **Call driver** with
  `driver.phone` (on the day only). `way: "back"` = a bus of the return. Foot: "Driver numbers show on the day of the trip only.
  For changes, call the provider." + call `company.ops_phone`.

## 10. Money: what is paid and when

- **School / company** (`payer: "client"`): nothing is paid in the app. Amount = the estimate, or the confirmed price once
  every trip left is confirmed; a cancellation charge is added to the organisation's invoice. "Invoiced after the trip".
- **Personal / Pay Myself** (`payer: "self"`): paid **when sent** (simulated: card or PayNow is "collected" at once; card fee from
  the company's Finance Settings). Amount = what you paid less refunds. Refunds happen at once when unconfirmed trips are
  cancelled, when the company declines a trip, and when it accepts a cancellation (less the charge quoted). These bookings
  are settled in the app; the company does not invoice them again. If the company confirms at a different price, what you paid
  does not change.

## 11. Errors

| Code / HTTP | When |
| --- | --- |
| `404` | not one of your accounts / bookings; Track Buses with nothing on the road |
| `422 terms` | "Agree to the charter terms to continue" |
| `422` | "Pick the fund to bill", "Pick who pays", "Personal bookings are paid by you", "Pick how to pay", "Enter the contact name and an 8-digit mobile number", "Enter the company name and billing address for the receipt", "Add a mobile or email to your account first", the booking rules of §4.1 (date from today, seats, …), "Pick a date from today" |
| `422 no_changes` | Accept / reply with nothing changed |
| `422 not_cancellable` | the scope can't be cancelled any more |
| `403` | saving an organisation point without being its booking admin |
