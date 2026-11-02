# Trips — API Guide

The Trips menu (rail icon `assignment`): **Trips**, **Trip History**, **Notices**, **Bookings** and **Rate Cards**.
Every screen of the menu and what opens from it is covered below; what is not built yet is listed in
[§ 6](#6-not-built-yet).

Conventions (sign-in, errors, paging, files, background reads, runs) are in [README.md](README.md).
All paths below start with `/api/v1`. Screens shared with the Scheduler (trip form, trip drawer, Notice form) are in
[scheduler.md](scheduler.md).

## Contents

1. [Trips page](#1-trips-page)
2. [Notices page](#2-notices-page)
3. [Rate Cards](#3-rate-cards)
4. [Bookings](#4-bookings)
5. [Trip History](#5-trip-history)
6. [Not built yet](#6-not-built-yet)

---

## 1. Trips page

Every run between two dates (one row per run, as on the Scheduler), with search, filters, status chips and paging.

### `GET /occurrences/list`

| Param | Required | Description |
| --- | --- | --- |
| `from` | yes | First date, `YYYY-MM-DD` |
| `to` | yes | Last date. At most 183 days after `from` (else 422 `"Trips show up to 6 months at a time"`) |
| `q` | no | Search: Trip ID, trip name, Service For, client, stop names, plate, driver, operator, school / route label |
| `kind` | no | Trip type: `ad_hoc`, `corporate_shuttle`, `airport_transfer`, `disposal`, `school_run`, `school_route` (School Bus route runs) |
| `operator` | no | `own` (own fleet), `none` (no vehicle) or an operator `id` |
| `status_group` | no | Status chip: `unassigned`, `assigned`, `live`, `completed`, `cancelled` (omit for All) |
| `sort` | no | `date` (oldest first, default) or `date_desc` |
| `page`, `limit` | no | Paging (the page uses 50) |

Presets are dates the FE works out: Today (`from = to = today`), Next 7 Days (today … +6), Next 30 Days (today … +29, the default),
Past 30 Days (−30 … −1).

```json
{
  "data": [
    { "id": 812, "key": "t21|2026-11-02|0|1|1", "date": "2026-11-02", "start_time": "09:00", "end_time": "10:00",
      "ends_next_day": false, "trip_id": 21, "trip_label": "TID104210", "kind": "ad_hoc", "title": "Live run",
      "route_text": "Changi to Marina", "client_id": 3, "client_name": "Google", "customer": "Google",
      "vehicle_id": 7, "plate": "PM2B", "vehicle_seats": 45, "required_vehicle_type": "13-seater",
      "operator": { "id": 2, "name": "Hup Seng", "kind": "managed" },
      "driver": { "kind": "operator", "id": 4, "name": "Rajesh Kumar", "phone": "+6593775502" },
      "pax": 10, "price": "380.0", "status": "scheduled", "grid_status": "live", "status_group": "live",
      "school_route_id": null, "school_name": null, "lock_version": 0 }
  ],
  "meta": {
    "page": 1, "limit": 50, "count": 5, "pages": 1,
    "counts": { "all": 5, "unassigned": 1, "assigned": 2, "live": 1, "completed": 1, "cancelled": 0 },
    "kinds": ["ad_hoc", "corporate_shuttle"],
    "operators": [ { "id": 2, "name": "Hup Seng", "kind": "managed" } ]
  }
}
```

Each row also carries every field of a Scheduler run (see [scheduler.md § Load the grid](scheduler.md#1-load-the-grid)).

| Column | Field |
| --- | --- |
| Date | `date` + `start_time`–`end_time` (`ends_next_day` = ends after midnight) |
| Trip | `trip_label` (Trip ID), `title`, `route_text` (second line) |
| Type | `kind` (labels in [§ Values](scheduler.md#17-values-reference)) |
| Vehicle | `plate` or "No vehicle"; second line `required_vehicle_type` when there is no vehicle, else `vehicle_seats` seats |
| Driver | `driver.name`, else "N/A" |
| Operator | `operator.name`; a vehicle with no operator is "Own fleet"; no vehicle is "N/A" |
| Pax / Price | `pax`, `price` (0 → "N/A") |
| Status | `status_group` — `unassigned` No Vehicle (danger), `assigned` Assigned (info; `grid_status = replacement` → "Replacement"), `live` On the Road (warning), `completed` Completed (success), `cancelled` Cancelled (neutral) |

- `meta.counts` are the chip numbers: every filter applied except `status_group`.
- `meta.kinds` / `meta.operators`: what the Type and Operator menus offer for these dates (add "All" and "No vehicle" yourself).
- Clicking a row opens the Scheduler on `date` (Day view) with the run `key` selected; New Trip opens the trip form.

---

## 2. Notices page

The list of every notice with tabs, search and the templates card. The New Notice / Edit form is the same Notice form as the
Scheduler drawer ([scheduler.md § Notice form](scheduler.md#12-notice-form)); from this page it starts without a trip picked.

### `GET /notices`

| Param | Required | Description |
| --- | --- | --- |
| `state` | no | Tab: `active`, `scheduled`, `ended` (the page opens on `active`). Omit for every notice |
| `q` | no | Search the message and the audience (trip name, client, Service For, school) |
| `trip_id` | no | One trip's notices |
| `page`, `limit` | no | Paging |

Order: Active and Scheduled, soonest start first; Ended, latest end first.

```json
{
  "data": [
    { "id": 4, "state": "scheduled", "audience": "trip", "trip_id": 8, "trip_title": "MBC Campus Shuttle", "client_name": "MBC",
      "service_for": null, "school_id": null, "school_name": null, "all_runs": false, "run_keys": ["d1r0", "d1r1"],
      "run_times": ["07:30", "08:00"], "route_ids": null, "to_riders": true, "to_parents": false,
      "banner": true, "push": true, "sms": false, "starts_at": "2026-11-09T07:00:00.000+08:00", "ends_at": "2026-11-09T09:00:00.000+08:00",
      "notice_template_id": 3, "message": "The bus will take a different route today because of a road closure.",
      "ended_at": null, "ended_by": null, "created_at": "2026-10-30T10:12:00.000+08:00", "created_by": "Ops Admin",
      "sent": [ { "channel": "push", "recipients": 42, "at": "2026-10-30T10:12:00.000+08:00" } ] }
  ],
  "meta": { "page": 1, "limit": 50, "count": 1, "pages": 1, "counts": { "active": 1, "scheduled": 1, "ended": 1 } }
}
```

| On the card | From |
| --- | --- |
| Message | `message` |
| Audience | trip: `client_name` (or `service_for`) \| `trip_title` \| `run_times` joined (empty = "All timings"); school: `school_name` \| "All routes" or N routes (`route_ids`) |
| To | `to_riders` → Riders, `to_parents` → Parents |
| Channel icons | `banner`, `push`, `sms` |
| Window | `starts_at` to `ends_at` |
| By | `created_by`, `created_at` |
| Sent | each `sent[]`: "`recipients` push / SMS sent `at`" |
| Status badge | `state`: `active` Active (success), `scheduled` Scheduled (info), `ended` Ended (neutral) |

`meta.counts` are the tab numbers (the search applies, the tab does not).

| Button | Shown when | Call |
| --- | --- | --- |
| End Now | `active` | `PATCH /notices/:id/end_now` (422 otherwise) |
| Edit | `scheduled` | open the Notice form, save with `PATCH /notices/:id` |
| Duplicate | always | `POST /notices/:id/duplicate` (starts now, same length) — or open the form prefilled and `POST /notices` |
| Delete | not `active` | `DELETE /notices/:id` → 204 (active: 422 `"An active notice can't be deleted. End it first"`) |

### Templates card

| Action | Call |
| --- | --- |
| List | `GET /notice_templates` → `[{ id, name, message }]` |
| Add Template | `POST /notice_templates` (body optional) → `201` a template named "New Template" (then "New Template 2"...) with an empty message |
| Edit name / message | `PATCH /notice_templates/:id` `{ "notice_template": { "name": "Delay", "message": "About {min} minutes late" } }` (save on blur) |
| Remove | `DELETE /notice_templates/:id` → 204 |

- `name` is required, at most 60 characters and unique in the company (422 otherwise). `message` may be empty, at most 300 characters.
- The last template can't be removed: 422 `"Keep at least one template"`.
- Removing a template keeps the notices made from it (their `notice_template_id` becomes `null`, the message stays).
- `{min}` and `{time}` in a message are filled in on the Notice form.

---

## 3. Rate Cards

A rate card prices client bookings: **periods** (days + time ranges) each with a **trip rate** and an **hourly rate** per
vehicle type, plus waiting time, distance, extra stop, disposal and Meet and Greet rules. A client is priced by the card
assigned to it, else by the **default** card. Price From Rate Card in the trip form uses the same cards
(`POST /rate_cards/quote`, see [scheduler.md](scheduler.md)).

### List — `GET /rate_cards`

Every card (no paging): default first, then active, then archived, by name.

```json
{ "data": [
  { "id": 1, "name": "Standard Rates", "description": "Default pricing for client bookings", "default_card": true,
    "archived": false, "archived_at": null, "lock_version": 0, "periods_count": 4, "clients_count": 12,
    "vehicle_types": [ { "id": 3, "name": "13-seater", "seats": 13 }, { "id": 5, "name": "45-seater", "seats": 45 } ] }
] }
```

`clients_count` = clients priced by the card (the default card counts every client with no card). Row text:
"Default, 12 clients" / "3 clients"; `periods_count` periods; `vehicle_types` as chips.

| Row button | Shown when | Call |
| --- | --- | --- |
| View | always | `GET /rate_cards/:id` |
| Edit | always | `GET /rate_cards/:id`, then `PATCH /rate_cards/:id` |
| Duplicate | always | `GET /rate_cards/:id`, rename to "<name> (Copy)", `POST /rate_cards` with the same body |
| Make Default | active, not default | `PATCH /rate_cards/:id/make_default` |
| Archive | not default (and not the last active card) | `PATCH /rate_cards/:id/archive` |
| Unarchive | archived | `PATCH /rate_cards/:id/unarchive` |

Archive is refused (422) for the default card (`"Make another card the default before archiving this one"`), a card clients
are assigned to (`"<name> is assigned to clients. Assign them another card first"`) and the last active card
(`"Keep at least one active card"`). An archived card can't be made the default. Cards are never deleted.

### View / edit — `GET /rate_cards/:id`

The card in the **same shape the create / update body uses**, plus `clients` and `warnings`:

```json
{ "data": {
  "id": 1, "name": "Standard Rates", "description": "Default pricing for client bookings", "default_card": true, "archived": false,
  "lock_version": 3, "vehicle_type_ids": [3, 5],
  "vehicle_types": [ { "id": 3, "name": "13-seater", "seats": 13 }, { "id": 5, "name": "45-seater", "seats": 45 } ],
  "wait_free_minutes": 10, "wait_fee": "15.0", "wait_block_minutes": 15,
  "meet_and_greet": true, "meet_and_greet_fee": "25.0",
  "distance_pricing": true,
  "distance_bands": [
    { "up_to_km": "20.0", "per_km": false, "amounts": [ { "vehicle_type_id": 3, "amount": "0.0" }, { "vehicle_type_id": 5, "amount": "0.0" } ] },
    { "up_to_km": "40.0", "per_km": false, "amounts": [ { "vehicle_type_id": 3, "amount": "25.0" }, { "vehicle_type_id": 5, "amount": "57.0" } ] },
    { "up_to_km": null, "per_km": false, "amounts": [ { "vehicle_type_id": 3, "amount": "50.0" }, { "vehicle_type_id": 5, "amount": "98.0" } ] }
  ],
  "stop_fees": true, "stop_fee_amounts": [ { "vehicle_type_id": 3, "amount": "10.0" }, { "vehicle_type_id": 5, "amount": "23.0" } ],
  "disposal_mode": "hourly", "disposal_free_km": "0.0",
  "disposal_km_amounts": [ { "vehicle_type_id": 3, "amount": "1.0" }, { "vehicle_type_id": 5, "amount": "2.28" } ],
  "periods": [
    { "id": 11, "name": "Off Peak", "days": ["mon", "tue", "wed", "thu", "fri"], "override": false,
      "ranges": [ { "starts_at": "07:00", "ends_at": "19:00" } ],
      "rates": [ { "vehicle_type_id": 3, "trip_rate": "55.0", "hourly_rate": "45.0" }, { "vehicle_type_id": 5, "trip_rate": "135.0", "hourly_rate": "93.0" } ] },
    { "id": 14, "name": "Weekend and PH", "days": ["sat", "sun", "ph"], "override": true,
      "ranges": [ { "starts_at": "00:00", "ends_at": "23:59" } ], "rates": [ "..." ] }
  ],
  "clients": [ { "id": 4, "name": "Ann Tan" } ],
  "clients_count": 12, "periods_count": 4,
  "warnings": { "overlaps": [], "gaps": [] }
} }
```

| Field | Meaning |
| --- | --- |
| `vehicle_type_ids` | The card's columns, in order (company vehicle types switched on) |
| `periods[].days` | `mon` … `sun`, `ph` (public holidays) |
| `periods[].ranges` | `HH:MM`; an end at or before the start runs past midnight ("Runs past midnight") |
| `periods[].override` | Wins over normal periods covering the same time (Weekend and PH) |
| `wait_*` | First `wait_free_minutes` free, then `wait_fee` per `wait_block_minutes` per vehicle (`wait_fee` 0 = "Waiting is not charged") |
| `distance_bands` | On the route km, each one-way leg: band 1 up to `up_to_km`, the next from there... The last band has `up_to_km: null` ("and above"); with `per_km: true` its amounts are S$ per km beyond the band before |
| `stop_fee_amounts` | Per stop between the first pick-up and the final drop-off, when `stop_fees` |
| `disposal_mode` | `hourly` (Hourly Only) or `hourly_distance` (Hourly + Distance: `disposal_km_amounts` per km after `disposal_free_km`) |
| `meet_and_greet_fee` | Added once to an airport arrival with Meet and Greet, when `meet_and_greet` |

View page text the FE builds: days "Mon to Fri, PH" (consecutive days joined with "to"); times "07:00 to 19:00 & ...";
`clients` names or "No clients yet".

**`warnings`** (shown, never blocking):
- `overlaps` — e.g. `"Peak and Night overlap on MON"`, `"Times overlap within Peak on TUE"` (only periods of the same kind: both normal or both override).
- `gaps` — weekday times no period covers, e.g. `"SAT from 00:00"` (first 4); bookings then have no rate.

### New Rate Card — `GET /rate_cards/new`

The starting card, not saved: Off Peak, Peak, Night (Mon to Fri + Sun night) and Weekend and PH (override) for every vehicle
type the company offers, named "New Rate Card", with default bands, stop fees and disposal per km (all switched off).
Same fields as above without `id`, `clients`, counts.

### Save — `POST /rate_cards` · `PATCH /rate_cards/:id`

The whole card every time (periods, bands and amounts are replaced). Send `lock_version` on update (409 if someone saved first).

```json
{ "rate_card": {
    "name": "Standard Rates", "description": "", "vehicle_type_ids": [3, 5],
    "wait_free_minutes": 10, "wait_fee": 15, "wait_block_minutes": 15, "meet_and_greet": false, "meet_and_greet_fee": 0,
    "distance_pricing": false, "distance_bands": [ { "up_to_km": 20, "per_km": false, "amounts": [ { "vehicle_type_id": 3, "amount": 0 } ] } ],
    "stop_fees": false, "stop_fee_amounts": [ { "vehicle_type_id": 3, "amount": 10 } ],
    "disposal_mode": "hourly", "disposal_free_km": 0, "disposal_km_amounts": [ { "vehicle_type_id": 3, "amount": 1 } ],
    "periods": [ { "name": "Off Peak", "days": ["mon"], "override": false, "ranges": [ { "starts_at": "07:00", "ends_at": "19:00" } ],
                   "rates": [ { "vehicle_type_id": 3, "trip_rate": 55, "hourly_rate": 45 } ] } ] },
  "lock_version": 3 }
```

Response: the card as in `GET /rate_cards/:id` (`201` on create). The first active card becomes the default; otherwise a new
card is not the default (use Make Default). A rate or amount left out for a card vehicle type is saved as 0; types not on
the card are ignored.

422 messages (first broken rule): `"Enter the card name"`, `"Another card has this name"` (case-insensitive),
`"Keep at least one vehicle type"`, `"Pick vehicle types the company offers"`, `"Add at least one period"`, `"Name every period"`,
`"Every period needs at least one day"`, `"Every period needs at least one time range"`, `"Enter every time as HH:MM"`,
`"A time range can't start and end at the same time"`, `"Add the distance bands"` (distance pricing on, fewer than 2 bands),
`"Enter the km of every band but the last"`, `"Distance bands must go up in km"`, `"The last distance band has no upper limit"`,
`"Only the last distance band can charge per km"`.

### Live warnings while editing — `POST /rate_cards/check`

Same body as save; nothing is saved. Returns `{ "data": { "overlaps": [...], "gaps": [...], "errors": [...] } }`
(`errors` = the save rules broken so far, in order). Call it after edits (debounced) to show the overlap / gap banners.

### Client Rate Cards — `GET /rate_card_assignments`

Which card prices each client.

| Param | Description |
| --- | --- |
| `q` | Search name, client ID (`code`), email, UEN |
| `kind` | `company`, `individual`, `transport_company` |
| `rate_card_id` | Only clients on this card (the default card includes clients with no card) — the card summary chips |
| `page`, `limit` | Paging |

```json
{ "data": [ { "id": 4, "name": "Google", "code": "CL00004", "kind": "company", "email": "ops@google.com",
              "rate_card_id": 2, "rate_card_name": "Corporate Contract Rates", "on_default": false } ],
  "meta": { "page": 1, "limit": 50, "count": 1, "pages": 1,
            "cards": [ { "id": 1, "name": "Standard Rates", "default_card": true, "clients_count": 11 },
                       { "id": 2, "name": "Corporate Contract Rates", "default_card": false, "clients_count": 1 } ] } }
```

`meta.cards` = active cards for the summary chips and the card select (label the default "(default)"). `on_default` = the
client follows the default card.

**Change a client's card** — `PATCH /rate_card_assignments/:client_id` `{ "rate_card_id": 2 }` → the row. Picking the default
card clears the assignment (the client follows whichever card is default later). Archived cards can't be picked (404).

---

## 4. Bookings

A booking is a client's request for trips: up to **10 days** (no more than 10 days apart), up to **10 trips a day**, up to
**10 vehicles a trip**. Recorded here for a client who asked (later also from the Client Portal and the Convoy App).
Each trip is approved, edited or rejected **on its own** (see [Approve, reject and the client's steps](#approve-reject-and-the-clients-steps)).

### List — `GET /bookings`

| Param | Description |
| --- | --- |
| `tab` | `pending` (default), `approved`, `rejected`, `completed` |
| `q` | Search Booking ID, coordinator name / email / phone, client name |
| `page`, `limit` | Paging. Newest first |

```json
{ "data": [
  { "id": 1, "number": "SD26000001", "source": "console", "created_at": "2026-10-30T09:12:00.000+08:00",
    "client": { "id": 1, "name": "Google Asia Pacific", "code": "CL00001", "kind": "company" }, "client_site": null,
    "coordinator_name": "Jason Lee", "coordinator_org": "Google Asia Pacific", "coordinator_email": "jason.lee@google.example",
    "coordinator_phone": "+65 8789 1011", "tab": "pending", "status_label": "Ready for Approval",
    "kinds": ["Ad Hoc / Charter, Two Way", "Ad Hoc / Charter", "Disposal", "Airport Transfer"],
    "dates": ["2026-11-05", "2026-11-06", "2026-11-07"], "trips_count": 4, "estimate_amount": "766.0" }
],
  "meta": { "page": 1, "limit": 50, "count": 1, "pages": 1, "tab": "pending",
            "counts": { "pending": 3, "approved": 0, "rejected": 1, "completed": 0 } } }
```

- Tab labels: "Pending 3", "Approved 0"... from `meta.counts` (counts ignore `q`).
- Columns: Booking ID `number`, Type `kinds`, Dates `dates`, Client `client.name` (+ `client_site.name`), Requested By
  `coordinator_name` / phone / email, Status `status_label`, Est. Total `estimate_amount`.
- `tab` rules: **pending** — a trip waits (ready for approval, waiting for the client); **rejected** — no trip approved;
  **completed** — every approved trip's date has passed; **approved** — the rest.
- `status_label` → badge tone: Ready for Approval (info), Pending Client Acknowledgement (warning), Awaiting Client Approval
  (neutral), Unassigned (neutral: an approved trip's Scheduler run has no vehicle yet), Assigned (success), Rejected (danger),
  Cancelled (neutral), Completed (success).

### Booking details — `GET /bookings/:id`

The list fields plus:

```json
{ "data": {
  "id": 1, "number": "SD26000001", "lock_version": 0, "client_end_customer_id": null, "service_for": null,
  "po_number": "PO-GA-2026-131", "cost_centre": null, "notes": null, "created_by": "Ops Admin",
  "attachments": [ { "id": 3, "url": "/api/v1/downloads/...", "name": "passengers.xlsx", "size": 10240, "content_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" } ],
  "days": [
    { "id": 1, "date": "2026-11-05", "trips": [
      { "id": 1, "date": "2026-11-05", "position": 0, "kind": "two_way", "kind_name": "Ad Hoc / Charter, Two Way", "status": "pending", "locked": false,
        "label": null, "start_time": "08:00", "return_time": "19:00", "hours": null,
        "airport_direction": null, "flight_number": null, "terminal": null, "wait_minutes": null, "meet_and_greet": false, "signboard_name": null,
        "pax": 30, "luggage_on": false, "luggage_cabin": 0, "luggage_medium": 0, "luggage_large": 0, "luggage_extra_large": 0, "luggage_oversized": 0,
        "contact_name": "Benjamin Loo", "contact_phone": "+65 8789 2212", "note": null, "distance_km": "9.8", "return_distance_km": null,
        "points": [ { "name": "Boon Lay Shopping Centre", "address": null, "lat": "1.3483", "lng": "103.7059", "use": "pu", "note": null },
                    { "name": "Jurong East", "address": null, "lat": "1.3331", "lng": "103.7422", "use": "both", "note": null },
                    { "name": "Jurong West", "address": null, "lat": "1.3404", "lng": "103.709", "use": "do", "note": null } ],
        "back_points": [ { "name": "Jurong West", "use": "pu", "...": "..." }, { "name": "Jurong East", "use": "both" }, { "name": "Boon Lay Shopping Centre", "use": "do" } ],
        "own_way_back": false,
        "standby": { "location": "Boon Lay Bus Interchange", "minutes": 15, "lat": null, "lng": null, "note": null }, "return_standby": null,
        "vehicles": [ { "vehicle_type_id": 3, "name": "13-seater", "seats": 13, "count": 1 }, { "vehicle_type_id": 4, "name": "23-seater", "seats": 23, "count": 1 } ],
        "seats_requested": 36, "seats_warning": null,
        "estimate_amount": "318.0",
        "estimate_lines": [
          { "kind": "vehicles", "text": "1 x 13-seater", "vehicle_type_id": 3, "count": 1, "amount": "130.0",
            "lines": [ { "text": "Out, Off Peak", "amount": "55.0" }, { "text": "Return, Off Peak", "amount": "55.0" },
                       { "text": "1 extra stop, both ways", "amount": "20.0" } ] }
        ] } ] }
  ]
} }
```

| Field | Meaning |
| --- | --- |
| `kind` | `one_way`, `two_way` (a return later the same day; the form shows it as the Two-Way switch on Ad Hoc / Charter), `disposal` (`hours`), `airport` (`airport_direction` `arrival` / `departure`, `flight_number`, `terminal`; arrival: `wait_minutes`, `meet_and_greet`, `signboard_name`) |
| `status` | `pending` (Ready for Approval), `awaiting_ack` (we changed it, waiting for the client to acknowledge), `awaiting_client` (the client's own approval), `approved`, `rejected`, `cancelled` (at the client's request). `status_label` is the badge: "Approved, Unassigned" / "Approved, Assigned" for approved trips. `locked` = approved, rejected or cancelled: shown read-only ("Approved and in the Scheduler. Change it there" / "Rejected") |
| `points` | The way there in order: first = pick-up, last = drop-off (Disposal: drop-off if known), the ones between are stops (max 5). `use`: `pu`, `do`, `both` |
| `back_points` | Two Way: the way back as it runs, starting where the way there ends. `own_way_back: false` = the way there reversed (pick-up and drop-off swapped) |
| `standby` / `return_standby` | Standby area of each way: report `minutes` before the pick-up (FE text "Report at X by HH:MM, N min before the 08:00 pick-up") |
| `seats_warning` | Passengers do not fit the seats requested |
| `estimate_*` | As at the last save, from the client's rate card (else the default). One `vehicles` line per vehicle type (amount × count, its `lines` are the breakdown for one vehicle), plus `meet_and_greet` once for an airport arrival. FE text: "1 x 13-seater: S$128.00" and "Out, Off Peak S$55.00, ... \| Standard Rates" |

### Record Booking / Save Changes — `POST /bookings` · `PATCH /bookings/:id`

The whole booking each time. On update send `lock_version` (409 if someone saved first) and the `id` of every day and
trip that already exists; days and trips left out are removed. Approved and rejected trips keep their values (send them
with their `id`; their fields are ignored) and can't be removed.

```json
{ "booking": {
    "client_id": 1, "client_site_id": null, "client_end_customer_id": null, "service_for": null,
    "coordinator_name": "Jason Lee", "coordinator_org": "Google Asia Pacific", "coordinator_email": "jason.lee@google.example",
    "coordinator_phone": "+65 8789 1011", "po_number": "PO-GA-2026-131", "cost_centre": "", "notes": "",
    "days": [
      { "id": 1, "date": "2026-11-05", "trips": [
        { "id": 1, "kind": "two_way", "label": "", "start_time": "08:00", "return_time": "19:00", "pax": 30,
          "contact_name": "Benjamin Loo", "contact_phone": "+65 8789 2212", "note": "", "distance_km": 9.8, "return_distance_km": null,
          "luggage_on": false, "luggage_cabin": 0, "luggage_medium": 0, "luggage_large": 0, "luggage_extra_large": 0, "luggage_oversized": 0,
          "points": [ { "name": "Boon Lay Shopping Centre", "lat": 1.3483, "lng": 103.7059, "use": "pu", "note": "" },
                      { "name": "Jurong West", "lat": 1.3404, "lng": 103.709, "use": "do" } ],
          "back_points": [],
          "standby": { "location": "Boon Lay Bus Interchange", "minutes": 15, "lat": null, "lng": null, "note": "" },
          "return_standby": null,
          "vehicles": [ { "vehicle_type_id": 3, "count": 1 } ] }
      ] }
    ] },
  "lock_version": 0 }
```

- New booking: `number` is given by the server (company code, 2-digit year, 6 digits: `SD26000001`); every trip starts `pending`.
- `back_points`: send only when the way back was changed (at least 2 points; the first is replaced by the last point of the way there). Empty = the way there reversed.
- `standby` / `return_standby`: `null` when the switch is off.
- `distance_km` / `return_distance_km`: road km from the map (OSRM), each way; used for distance pricing. Leave empty when not known.
- Picking a client: prefill the coordinator from the client (contact, email, phone; individual: the client's name), and the site when the client has only one.
- New trip defaults (FE): One Way, 09:00, return 18:00, 4 hours, terminal T3, wait 60 min, one vehicle of the first type.

422 messages (first broken rule; trip rules start with the day's date `DD/MM/YYYY: `): `"Pick the client"`,
`"Enter the booking coordinator"`, `"Pick a site of this client"`, `"Add at least one day"`, `"No more than 10 days in a booking"`,
`"Pick the date of each day"`, `"Two days have the same date"`, `"Days must be no more than 10 days apart"`,
`"No more than 10 trips a day"`, `"An approved or rejected trip can't be removed"`, and per trip: `add at least one trip`,
`enter the pick-up time`, `enter the pick-up point`, `enter the drop-off point`, `name every stop, or remove it`,
`up to 5 stops`, `each point needs a pick-up, a drop-off or both`, `the return time must be after the pick-up time`,
`enter the drop-off on the way back`, `enter the standby area, or turn it off`,
`enter the standby area for the return, or turn it off`, `enter the disposal hours`, `pick vehicle types the company offers`,
`pick each vehicle type once`, `request at least one vehicle`, `no more than 10 vehicles a trip`.

### Estimate while editing — `POST /bookings/estimate`

`{ "client_id": 1, "date": "2026-11-05", "trip": { ...one trip as in the save body } }` →
`{ "data": { "amount": "318.0", "lines": [...], "without_rate": 0, "card": { "id": 1, "name": "Standard Rates" } } }`.
Nothing is saved. `without_rate` = vehicles with no rate (show "N without a rate"). The booking total in the form is the sum
of the trips' amounts.

Pricing rules: One Way / Airport = the period's trip rate at the pick-up time; Two Way = out (pick-up time) + back
(return time); Disposal = hourly rate × hours (+ per km after the free km on an Hourly + Distance card). Distance and
extra stops are charged on each one-way leg; a Two Way whose way back goes more than 200 m from every point of the way
there is priced as two one-way trips (`"Return, priced as a one-way trip"`, each way its own km and stops).

### Approve, reject and the client's steps

Every call below returns the whole booking (as `GET /bookings/:id`). Trip fields for the buttons and texts:

| Field | Use |
| --- | --- |
| `can_approve` | Show the approve button: "Approve & Convert to Trip" (`pending`) or "Approve Without Waiting" (`awaiting_ack`) |
| `can_reject` | Show Reject (`pending`, `awaiting_ack`, `awaiting_client`) |
| `approval` | `{ at, by, how, note }` → "Approved by X on DD/MM/YYYY. Client approval: Phone, Spoke to Alex" |
| `acknowledgement` | `{ at, by, how }` → "Client acknowledged DD/MM/YYYY (Email)" |
| `rejection` | `{ at, by, by_client, reason }` → "Rejected by X: reason" or "Declined by X in the client's approval flow: reason" |
| `changes` | Newest first `[{ at, by, items: ["Pick-up time: 08:00 to 10:30", ...] }]` — the "What changed" toggle |
| `scheduler_trips` | `[{ id, title, is_return }]`: Open in Scheduler goes to the trip's `date`, Day view |
| `cancelled_at` | When it was cancelled at the client's request |

| Action | Call |
| --- | --- |
| Approve & Convert to Trip | `POST /booking_trips/:id/approve` `{ "trip_value": 1, "return_trip_value": 1 }` (`return_trip_value` for Two Way) |
| Approve Without Waiting (`awaiting_ack`) | same, plus `"how": "Phone"` (`Phone`, `Email`, `WhatsApp`, `In person`) and optional `"note"` |
| Reject | `PATCH /booking_trips/:id/reject` `{ "reason": "No bus that day" }` (the client sees it) |
| Client Acknowledged (stands in for the Client Portal) | `PATCH /booking_trips/:id/acknowledge` `{ "how": "Email", "by_name": "Alex" }` → back to `pending` |
| Client approval done (`awaiting_client`) | `PATCH /booking_trips/:id/client_approve` `{ "by_name": "Priya" }` → `pending` |
| Declined in the client's approval | `PATCH /booking_trips/:id/client_decline` `{ "by_name": "Priya", "reason": "Over budget" }` → `rejected` |

Approving creates the Scheduler trip(s) with **no vehicle** (their runs are in the Unassigned tray):
- Type: One Way / Two Way → Ad Hoc / Charter (Two Way: an outbound and its "(Return)" linked as a pair; return stops = the way back),
  Disposal → Disposal, Airport → Airport Transfer. Date, times (end = start + 1 h; Disposal: + hours), pax, luggage, stops with
  notes and pins, standby, vehicles required, requestor = coordinator, guest = trip contact, `booking_ref` = Booking ID.
- Title: "<org> to <drop-off>", "Changi Arrival SQ321", "Disposal 4 h".
- Price from the estimate (per route): Two Way half each; Meet and Greet as the trip's M&G fee. Trip value as entered.
- Notes: the driver note, "Vehicles requested: 1 x 13-seater", "Trip contact: ...", "PO ...", "Booking SD26000001".

Saving the booking form with changes to a trip that is not locked moves it to `awaiting_ack` and adds a `changes` entry
(date, type, times, hours, pick-up, drop-off, stops, flight, passengers, luggage, vehicles). Saving with no change keeps the status.

422 messages: `"Enter the trip value"`, `"Say how the client agreed to the changes"`, `"Enter the reason, the client sees it"`,
`"This trip is <status> already"`, `"This trip is <status>, so it can't be changed here"`.

### Cancellation requests

A client asks to cancel the booking or one trip (from the Client Portal later; recorded here on their behalf). The booking
shows them in `cancel_requests`:

```json
"cancel_requests": [ { "id": 2, "booking_trip_id": 7, "trip_date": "2026-11-04", "reason": "Event moved", "requested_by_name": "Alex",
                       "requested_at": "...", "status": "open", "resolved_at": null, "resolved_by": null, "resolution_note": null } ]
```

| Action | Call |
| --- | --- |
| Record a request | `POST /bookings/:booking_id/cancel_requests` `{ "booking_trip_id": 7, "reason": "Event moved", "requested_by_name": "Alex" }` (omit `booking_trip_id` for the whole booking; name defaults to the coordinator) → 201 |
| Accept | `PATCH /bookings/:booking_id/cancel_requests/:id` `{ "decision": "accept", "note": "Told Alex" }` |
| Decline | `PATCH /bookings/:booking_id/cancel_requests/:id` `{ "decision": "decline" }` |

Accept cancels the trips (status `cancelled`); for approved trips their Scheduler runs not started yet are cancelled
(they show as Cancelled on the Scheduler), or the Scheduler trip is removed when it has no runs yet. A booking whose
trips are all cancelled shows "Cancelled" (Rejected tab). A resolved request can't be resolved again (422).

### Notifications (the bell)

For coordinators (users who work on trips). Events of the last 14 days, newest first (max 20), only the kinds the user keeps on.

`GET /booking_notifications`

```json
{ "data": [ { "id": 9, "kind": "cancel_request", "message": "Alex asks to cancel the trip on Wed 4/11: Event moved", "actor_name": "Alex",
              "occurred_at": "...", "unseen": true, "booking_id": 5, "booking_trip_id": 7, "booking_number": "SD26000005",
              "client_name": "Google Asia Pacific", "tab": "approved" } ],
  "meta": { "unseen_count": 1, "seen_at": null } }
```

| `kind` | Icon idea | When |
| --- | --- | --- |
| `new_booking` | book_online | A booking from the Client Portal or the Convoy App |
| `client_approved` | how_to_reg | The client's own approval done |
| `client_declined` | block | Declined in the client's approval |
| `acknowledged` | task_alt | The client accepted our changes |
| `cancel_request` | event_busy | A cancellation request |

- Badge = `meta.unseen_count`. Opening the bell: `PATCH /booking_notifications/seen`.
- Clicking an item: open Bookings on `tab`, booking `booking_id`.
- Settings dialog: `GET /booking_notifications/preferences` →
  `{ "data": { "email": true, "user": "Ops Admin", "kinds": [ { "kind": "new_booking", "label": "New booking", "description": "...", "on": true } ] } }`;
  change with `PATCH /booking_notifications/preferences` `{ "cancel_request": false, "email": false }`.
- Email: when on, each event is **recorded** as an email to the user (not sent yet).

### Files — `POST /bookings/:booking_id/attachments` · `DELETE /bookings/:booking_id/attachments/:id`

Multipart `file` (PDF, images, Excel, Word, CSV). Up to 10 a booking. Upload after Record Booking (the form keeps picked
files and sends them once the booking has an id).

---

## 5. Trip History

Every run that has **run, was cancelled or was skipped by the calendar**, up to today (one row per run, as on the Scheduler,
School Bus route runs included). Opens on the past 30 days.

### List — `GET /trip_history`

| Param | Description |
| --- | --- |
| `from`, `to` | Dates (`to` is capped at today). Default: today − 30 … today. At most a year (422 `"Trip History shows up to a year at a time"`) |
| `q` | Search Trip ID, trip, client, plate, driver, operator, school / route |
| `client_id[]`, `vehicle_id[]` | Ids (any picked matches). A corrected vehicle that is not in the fleet is listed by its plate (`value` = the plate) |
| `driver[]` | Driver names as listed in the facets |
| `operator[]` | `own`, `none` (no vehicle) or operator ids |
| `kind[]` | `ad_hoc`, `corporate_shuttle`, `airport_transfer`, `disposal`, `school_run`, `school_route` |
| `outcome[]` | `completed`, `incomplete`, `cancelled_by_client`, `cancelled_by_us`, `skipped` |
| `on_time[]` | `on_time`, `late`, `na` |
| `needs_look` | `true` = Needs a Look: a note, a correction, a replacement, an issue, an Incomplete run, or time above the speed limit |
| `sort` | `new` (date, newest first; default), `old`, `id` (Trip ID), `client` |
| `page`, `limit` | Paging |

```json
{ "data": [
  { "id": 812, "key": "t8|2026-10-27|0|1|1", "date": "2026-10-27", "start_time": "08:00", "end_time": "09:00",
    "trip_label": "TID103716", "title": "Office Shuttle", "kind": "ad_hoc", "trip_id": 8, "school_route_id": null, "status": "completed",
    "client": { "id": 1, "name": "Google" },
    "vehicle": { "id": 14, "plate": "PD1A", "make": "Toyota", "model": "Hiace", "seats": 13 },
    "driver_name": "Eric Tan", "operator": "Own fleet",
    "outcome": "completed", "outcome_label": "Completed", "tone": "success", "on_time": "on_time",
    "distance_km": "13.42", "pax": 12, "needs_look": false, "corrected": false, "skip_reason": null }
],
  "meta": { "page": 1, "limit": 50, "count": 7, "pages": 1, "from": "2026-10-03", "to": "2026-11-02", "on_time_minutes": 5, "speed_limit_kmh": 80,
            "facets": {
              "client_id": [ { "value": "1", "label": "Google", "count": 6 } ],
              "vehicle_id": [ { "value": "14", "label": "PD1A", "count": 5 } ],
              "driver": [ { "value": "Eric Tan", "label": "Eric Tan", "count": 5 } ],
              "operator": [ { "value": "own", "label": "Own fleet", "count": 6 }, { "value": "none", "label": "No vehicle", "count": 1 } ],
              "kind": [ { "value": "ad_hoc", "label": "Ad Hoc / Charter", "count": 7 } ],
              "outcome": [ { "value": "completed", "label": "Completed", "count": 4 }, { "value": "skipped", "label": "Skipped by Calendar", "count": 1 } ],
              "on_time": [ { "value": "na", "label": "N/A", "count": 7 } ] } } }
```

- Filter chips: one per facet; a chip's popover lists its `facets[key]` values with counts. Counts apply every **other**
  filter (a chip's own picks do not shrink its list). Date chip presets (FE): Past 7 Days, Past 30 Days, This Month, Last Month.
- Header: "<company> | Every trip that has run, was cancelled or skipped | `meta.count` trips in this range".
- Table columns: Trip ID, Date, First Pick-up (`start_time`), Trip, Client, Vehicle, Driver, Outcome (`outcome_label`, `tone`),
  On Time, Distance (`distance_km`, "N/A" when null), Pax ("N/A" when null).
- `corrected: true` → "Corrected" badge. Outcome, vehicle, driver and pax show the corrected values (pax = boarded at the
  corrected stops when set), and filters / search use them.
- `on_time`: `late` = a stop was reached more than `meta.on_time_minutes` after its planned time (corrected arrival times
  count); `na` when the run did not run to the end (cancelled, skipped, Incomplete) or no arrival time is known.
  `distance_km` = from the GPS pings, null when there are none. Pax = boarded at the stops when known, else planned pax.

### Record — `GET /trip_history/:id`

`:id` = the run's `id` from the list.

```json
{ "data": {
  "id": 812, "key": "t8|2026-10-27|0|1|1", "date": "2026-10-27", "trip_label": "TID103716", "title": "Office Shuttle",
  "kind": "ad_hoc", "kind_name": "Ad Hoc / Charter", "trip_id": 8, "school_route_id": null, "client": { "id": 1, "name": "Google" },
  "start_time": "08:00", "end_time": "09:00", "outcome": "completed", "outcome_label": "Completed", "tone": "success",
  "on_time": "on_time", "on_time_minutes": 5, "needs_look": false,
  "not_run": null, "corrected": false, "can_correct": true, "correction_lock_version": null, "was": {},
  "vehicle": { "id": 14, "plate": "PD1A", "make": "Toyota", "model": "Hiace", "seats": 13, "ownership": "own",
               "photo": null, "default_picture": "hiace" },
  "original_vehicle": null, "operator": null,
  "crew": { "driver": { "kind": "own", "id": 10, "name": "Eric Tan", "phone": "+6590034455" }, "attendant": null },
  "stops": [ { "position": 0, "name": "Jurong East", "use": "pu", "planned_time": "08:00", "lat": "1.333", "lng": "103.742", "note": null,
               "planned_minute": 480, "arrived_at": "08:03", "departed_at": "08:06", "boarded": 9, "alighted": null,
               "served": true, "skipped": false, "delay_minutes": 3, "late": false, "on_board": 9,
               "was": { "arrived_at": "08:02" } },
             { "position": 1, "name": "MBC", "use": "do", "planned_time": null, "planned_minute": null, "lat": null, "lng": null, "note": null,
               "arrived_at": "08:40", "departed_at": "08:41", "boarded": null, "alighted": 9,
               "served": true, "skipped": false, "delay_minutes": null, "late": false, "on_board": 0, "was": {} } ],
  "stop_summary": { "distance_km": "13.42", "duration_minutes": 40, "started_at": "...", "ended_at": "...", "stops_total": 2,
                    "stops_served": 2, "stops_skipped": 0, "late_stops": [], "boarded": 9 },
  "has_track": true,
  "speed": { "max_kmh": "90.0", "avg_moving_kmh": "41.2", "limit_kmh": 80, "overspeed_seconds": 60 },
  "driving_summary": { "distance_km": "13.42", "duration_minutes": 40, "planned_minutes": 60, "vs_plan_minutes": -20,
                       "odometer_start_km": 48210, "odometer_end_km": 48223, "idle_minutes": 0, "harsh_events": 4,
                       "ping_count": 241, "ping_interval_seconds": 10, "fuel_used": "1.88", "fuel_unit": "L", "fuel_estimated": true },
  "trip_info": { "kind_name": "Ad Hoc / Charter", "label": null, "recurrence": "Mon to Fri", "run": null, "price": "120.0",
                 "trip_value": "1.0", "operator_cost": null, "business_unit": null, "project": null, "booking_ref": null,
                 "notes": null, "pax": 12 },
  "standby": { "location": "Car park B", "minutes": 15, "report_time": "07:45", "note": null },
  "point_of_contact": { "requestor": { "name": "Alex", "email": "alex@google.com", "phone": null }, "guest": null },
  "passengers": null,
  "driver_report": { "driver_name": "Eric Tan", "note": "Smooth run", "submitted_at": "...",
                     "photos": [ { "id": 1, "caption": "Drop-off", "url": "/api/v1/downloads/...", "name": "photo.png", "size": 1024, "content_type": "image/png" } ] },
  "issue": null, "replacement": null,
  "changes": [ { "at": "...", "by": "Ops Admin", "changes": { "shift_minutes": [0, 15] } } ],
  "corrections": [ { "at": "...", "by": "Ops Admin", "reason": "Driver app lost signal, times from the log sheet",
                     "items": [ "Outcome: Completed to Incomplete", "Stop 1 arrival: N/A to 08:03" ] } ],
  "notes": [ { "id": 3, "body": "Driver reminded about the 60 km/h limit", "by": "Ops Admin", "at": "..." } ],
  "log": [ { "at": "...", "text": "Note added", "by": "Ops Admin" }, { "at": "...", "text": "Run completed", "by": null } ]
} }
```

| Section | Field |
| --- | --- |
| Summary strip | `trip_label`, `date`, `start_time` (first pick-up), `outcome_label`, `on_time` |
| Why the trip did not run | `not_run`: `{ kind: "skipped", reason }` (e.g. "Public holiday: Deepavali", a calendar day off) or `{ kind: "cancelled", by_client, by, at }` |
| Vehicle and crew | `vehicle` (`photo` = `{ url, name, size, content_type, thumb_url }`, else the `default_picture` illustration; `id: null` when a corrected plate is not in the fleet), `original_vehicle` (the bus a replacement took over from), `operator`, `crew.driver`, `crew.attendant` (School Bus) |
| Stop record | `stop_summary` (header: Distance, Duration `started_at`–`ended_at`, Stops "`stops_served` of `stops_total` served, `stops_skipped` skipped", Late Stops "stop 2, stop 4", Passengers boarded) and `stops` in travel order (`position` from 0): `planned_time` (the run's timetable; ad hoc trips: the first pick-up only), what happened — `arrived_at`, `departed_at`, `boarded`, `alighted` (corrected first, else recorded; null = N/A), `served` (false → "Not served", or "Not served, trip ended before this stop" when Incomplete), `skipped` ("Passed at `arrived_at`, no passenger to pick up"), `delay_minutes` ("+3 min"), `late` (Late badge), `on_board` |
| Speed history | `speed` (Max, Average while moving, time above `limit_kmh`; null without GPS). The chart and replay use `GET /trip_history/:id/track` when `has_track` |
| Driving summary | `driving_summary` (null without GPS): Distance, Actual Duration (`vs_plan_minutes` "+5 vs plan"), Odometer, Idling Away From Stops, Harsh Braking or Acceleration, GPS Pings ("241 every 10 s"), Fuel or Charge Used ("(est.)" when `fuel_estimated`) |
| Corrected badges | `was` holds the recorded value of each corrected field (record: `outcome_label`, `plate`, `driver_name`; each stop: its fields) — show "Corrected" with `was` as the tooltip |
| Trip information | `trip_info` (`run` = "Direction 1, run 2" for shuttles; `recurrence` "Mon to Fri" / "One-off") |
| Standby area | `standby` (`report_time` = start − minutes) |
| Point of contact | `point_of_contact.requestor`, `.guest` (null when the guest is the requestor) |
| Passenger list | `passengers` (School Run; same shape as `GET /occurrences/:id/passengers`) |
| Driver's report | `driver_report` (note, photos) or null ("No photos taken on this trip") |
| Replacements, changes and corrections | `replacement`, `issue`, `changes` (edits to this run), `corrections` (each Correct Record save: who, when, reason, change lines) |
| Notes / Trip log | `notes` oldest first; `log` newest first |

Not built: Conditions During the Trip (weather / traffic), and in the driving summary Ops on Duty, Linked Incident Report,
Client Feedback.

### GPS track — `GET /trip_history/:id/track`

For the map trail (coloured by speed), the replay bar and the speed chart. Rows, oldest first:

```json
{ "data": { "columns": ["at", "lat", "lng", "speed_kmh", "heading"],
            "points": [ ["2026-10-27T08:00:00+08:00", 1.333, 103.742, 0.0, 90], ["2026-10-27T08:00:10+08:00", 1.333, 103.7425, 40.0, 90] ],
            "interval_seconds": 10, "speed_limit_kmh": 80,
            "stops": [ { "position": 0, "name": "Jurong East", "lat": "1.333", "lng": "103.742", "served": true, "skipped": false, "late": false } ] } }
```

Replay (FE): position at a time = between the two pings around it; On Board = sum of `boarded − alighted` of stops departed
by then (record `stops`). Road names are not stored.

### Add Note — `POST /trip_history/:id/notes`

`{ "body": "..." }` (up to 1000 characters) → 201 with the whole record. Kept with the author and time; the run then counts
as Needs a Look.

### Correct Record — `POST /trip_history/:id/correction`

Only when `can_correct` (the run ran). The dialog opens with the record's current values (outcome, `vehicle.plate`,
`crew.driver.name`, each stop's `arrived_at` / `departed_at` / `boarded` / `alighted`).

```json
{ "lock_version": 0,
  "correction": { "outcome": "incomplete", "vehicle_plate": "PD2B", "driver_name": "Ali Hassan",
                  "stops": [ { "position": 0, "arrived_at": "08:03", "departed_at": "08:06", "boarded": 9, "alighted": "" } ],
                  "reason": "Driver app lost signal, times taken from the driver's log sheet" } }
```

- `outcome`: `completed` | `incomplete`. Vehicle: `vehicle_id` (fleet) or `vehicle_plate` (any plate; matched to the fleet
  when it is one). Driver: `driver_id` or `driver_name` (matched to a driver by name when there is one).
- Send only what the dialog shows; a field left out or blank stays as it is. Times "HH:MM", counts whole numbers ≥ 0.
- `lock_version` = the record's `correction_lock_version` (null / left out the first time); stale → 409.
- → 200 with the whole record. GPS trail, speed and the log stay as recorded; the run itself is not changed. Setting a value
  back to what was recorded removes its badge; the history in `corrections` stays (the run stays Needs a Look).
- 422 messages: "Nothing has changed", "Give the reason for the correction", "Only a run that ran can be corrected",
  "Outcome must be Completed or Incomplete", "Stop 2: departure is before arrival", "Stop 2: boarded must be a whole number",
  "Stop 2: arrival must be a time like 08:05", "Stop 7 isn't on this run".

### Cancelled by Client / by Us

Cancel in the Scheduler drawer takes `by_client` (`PATCH /occurrences/:id/cancel { lock_version, by_client: true }`); a booking
cancellation accepted on the Bookings page cancels its runs as by the client.

---

## 6. Not built yet

| Where | What | For now |
| --- | --- | --- |
| Bookings | Client Portal / Convoy App endpoints (the client records, acknowledges, approves, cancels) | Admin records the client's steps (`acknowledge`, `client_approve`, `client_decline`, cancel requests) |
| Bookings | Multi-step client approval (several approvers) | One client approval step |
| Bookings bell | Sending the emails | Emails are recorded only |
| Trip History | Driver app / telematics ingest (GPS, stop events, driver's report) | Sample data from the seed |
| Trip History | Conditions During the Trip (weather / traffic), road names in the replay, Ops on Duty, Linked Incident Report, Client Feedback | Not in the response |
| Trip History | Correct Record feeding driver pay and invoices | Corrections show in Trip History only |
| Trip History | Passenger list of a School Bus route run (riders are kept as counts per stop until the School menu is built) | `passengers: null`; `pax` = riders count |
| Settings | Editing `on_time_minutes` and `speed_limit_kmh` | Defaults 5 min and 80 km/h (shown in `meta`) |
