# Client Portal — Bookings, New Booking, Accept Changes

Bookings the client asks the transport company for (Ad Hoc / Charter one way or two way, Disposal, Airport Transfer).
Who sees what: everyone sees the bookings they made; every role but Member also sees the bookings for the sites they
cover (a booking with no site — made by the transport company — only for Super Admin, Admin, Finance Admin). Bookings
cannot be edited, given a title or cancelled in the portal (not in the design).

## 1. Statuses

| Trip `status` | `status_label` | Means |
| --- | --- | --- |
| `awaiting_approval` | Awaiting Approval | Waiting for the client's own approval flow ([approvals](approval-flows.md)) |
| `sent` | Sent to Transport | With the transport company, not confirmed yet |
| `changed` | Changes to Review | The transport company changed it: Accept Changes (§ 5) |
| `confirmed` | Confirmed | In their Scheduler; `buses` once a bus is on |
| `declined` | Declined | By the transport company, or in the client's approval flow (`rejection.by_client`) |
| `cancelled` | Cancelled | |

Booking `status`: any trip `changed` → `changed`; else any `awaiting_approval`; else every trip declined / cancelled →
`declined` (`cancelled` when all cancelled); else any `sent` → `sent`; else `confirmed`. Use the same badge words.

## 2. List

`GET /portal/bookings?tab=upcoming|awaiting|past&page=&limit=` — newest first, 50 a page by default. `meta.counts { upcoming, awaiting, past }`
for the tab labels ("Awaiting Approval 2").

- **Upcoming**: a day today or later (bookings waiting for approval included). **Awaiting Approval**: a trip waiting for
  the client's approval. **Past**: every day before today.

```json
{ "id": 9, "number": "SD26000008", "status": "sent", "status_label": "Sent to Transport", "service_for": null,
  "coordinator_name": "Priya Raman", "estimate_amount": "1240.0", "created_at": "2026-11-04T10:00:00+08:00",
  "site": { "id": 1, "name": "Mapletree Business City" },
  "booked_by": { "name": "Priya Raman", "in_portal": true, "me": true },
  "dates": [ "2026-11-13" ],
  "billed_to": { "name": "Google Asia Pacific Pte. Ltd.", "uen": "200817984R", "own": false },
  "trips": [ { "id": 21, "date": "2026-11-13", "kind": "two_way", "kind_name": "Ad Hoc / Charter, Two Way", "label": null,
               "start_time": "08:30", "return_time": "14:00", "hours": null, "pax": 38, "from": "St. Stephen's School",
               "to": "Sentosa, Siloso Beach", "stops": 0, "status": "sent", "status_label": "Sent to Transport",
               "estimate_amount": "1240.0", "buses": [], "changes": null } ] }
```

Card: number, site chip, "By <coordinator_name> | <first date> to <last date>", estimate (S$, 2 dp), status badge, a row
per trip ("<start>, back <return>" / "<start>, <hours> h"; "<from> to <to>" or "Disposal from <from>"; Disposal note
"Estimate charged first, extra hours or km billed after the trip"; `changes` → "Changed by <transport company>: …"),
footer "Billed to <name> | UEN …" (`own`: the site's own entity).

## 3. Booking detail

`GET /portal/bookings/:id` → the list fields plus `coordinator_org`, `coordinator_email`, `coordinator_phone`,
`po_number`, `cost_centre`, `notes`, `attachments [{ id, url, name, size, content_type }]` (signed links), and each trip
in full:

| Trip field | Shown as |
| --- | --- |
| `airport_direction`, `flight_number`, `terminal`, `wait_minutes`, `meet_and_greet`, `signboard_name` | Airport: Arrival / Departure, Flight, Terminal, Free Waiting (min after landing), Meet and Greet (+ signboard) |
| `luggage_on`, `luggage_cabin`, `luggage_medium`, `luggage_large`, `luggage_extra_large`, `luggage_oversized` | Luggage by size. **Flat**, the same names as the request and Convoy OS (no nested `luggage`) |
| `own_way_back` | Two Way: `true` when the way back has its own points, `false` when it is the way there reversed; always a boolean (`false` for other kinds) |
| `contact_name`, `contact_phone`, `note` | Contact on the Day (else "The coordinator"), Note to the Driver |
| `points`, `back_points` (`[{ name, address, lat, lng, use, note }]`) | Route: Pick-up, Stop n, Drop-off (way back for Two Way) |
| `vehicles [{ vehicle_type_id, name, seats, count }]`, `seats_requested` | "2 x 13-seater", "26 seats for 20 passengers" |
| `estimate_lines`, `estimate_amount` | Estimate lines and total |
| `buses` | Bus Assigned: plates; empty and `confirmed` → "Not yet. <company> assigns it after confirming" |
| `acknowledgement { at, by, how }` | "Changes accepted by <by> (<how>)" |
| `rejection { at, by, by_client, reason }` | "Declined by <by>: <reason>" (`by_client`: in your approval flow) |
| `can_accept_changes` | Show **Accept Changes** |

Each booking also has `approval` (the client's own approval: progress, who it waits for, Approve / Decline):
[approvals.md § 4](approvals.md#4-the-approval-on-a-booking); `null` when the flow was off.

## 4. New Booking

| Step | Call |
| --- | --- |
| Open the form | `GET /portal/bookings/form` |
| Live estimate and approval preview (on every change, debounced) | `POST /portal/bookings/estimate { booking }` (nothing saved) |
| Service For › Add New Customer (main contractors) | `POST /portal/end_customers { name }` → `{ id, name }` (the same name, any case, is reused) |
| Submit for Approval / Send to <company> | `POST /portal/bookings { booking }` → `201`, the booking (§ 3) + `approval` |

Only `can.book` roles (not Finance roles). `GET /portal/bookings/form`:

```json
{ "coordinator": { "name": "Priya Raman", "email": "priya.raman@google.com" }, "site_required": true,
  "sites": [ { "id": 1, "name": "Mapletree Business City", "address": "…", "lat": 1.2747, "lng": 103.7993,
               "billed_to": { "name": "Google Asia Pacific Pte. Ltd.", "uen": "200817984R", "own": false } } ],
  "main_contractor": false, "end_customers": [],
  "vehicle_types": [ { "id": 3, "name": "13-seater", "seats": 13 } ],
  "rate_card": { "id": 1, "name": "Standard Rates" }, "company": { "name": "SimpleDrive", "country": "SG" },
  "limits": { "days": 10, "span_days": 10, "trips_a_day": 10, "vehicles_a_trip": 10, "stops": 5, "files": 10, "file_mb": 5 } }
```

- Site: only `sites` (pre-pick when there is one); hint "Billed to <name> | UEN". Required when `site_required`.
- Changi terminals T1–T4 only when `company.country` is `SG`. Vehicle sizes: only `vehicle_types` (the client's
  Bookable Vehicles). `rate_card: null` → "No rate card yet. <company> prices this booking."

`booking` (same trip fields as Convoy OS, [trips § Bookings](../convoy-os/trips.md); no `client_id`, no standby):

```json
{ "client_site_id": 1, "client_end_customer_id": null, "service_for": null, "coordinator_name": "Priya Raman",
  "coordinator_email": "…", "coordinator_phone": "…", "po_number": "PO-1", "cost_centre": null, "notes": null,
  "days": [ { "date": "2026-11-13", "trips": [
    { "kind": "one_way", "label": "WEN", "start_time": "09:00", "pax": 10,
      "points": [ { "name": "Changi Airport T3", "use": "pu", "lat": 1.355, "lng": 103.987, "note": "Wait at Gate B" },
                  { "name": "Marina Bay Sands", "use": "do" } ],
      "vehicles": [ { "vehicle_type_id": 3, "count": 1 } ], "contact_name": null, "contact_phone": null, "note": null } ] } ] }
```

Trip luggage is **flat**, as in Convoy OS: `luggage_on`, `luggage_cabin`, `luggage_medium`, `luggage_large`, `luggage_extra_large`,
`luggage_oversized` (integers). A trip with a nested `luggage { cabin, … }` object is refused with `422` code `luggage_flat`
(on both `estimate` and Submit), never silently dropped.

Service For: send `client_end_customer_id` (a customer from the form's `end_customers` or `POST /portal/end_customers`). `service_for`
is optional free text; when it is blank and a customer is picked, the customer's name is stored in it.

With files: send multipart, `booking` = that JSON as a string, `files[]` = up to 10 files of 5 MB each.

Estimate answer: `{ trips: [{ date, kind, amount, lines, without_rate }], total, rate_card, billed_to, approval }`;
`approval` is the [Try a Booking](approval-flows.md#3-try-a-booking) shape for this booking (site, the person, trip types,
total, days ahead): `need: true` → "Rule: <name>", the steps with names ("No one else is on this step, so it goes to the
Admins" when `fallback`), "Then it goes to <company>", button **Submit for Approval**; `need: false` → "Goes straight to
<company>", button **Send to <company>**.

Rules (`422`, as in Convoy OS plus the portal's): "Pick the site this booking is for", "Pick one of your sites", "The first
day can't be in the past", "Days must be no more than 10 days apart", "No more than 10 trips a day", "<date>: enter the number
of passengers", "<date>: 20 passengers but 13 seats. Add a vehicle or pick a bigger one", "<date>: pick vehicle types the
company offers", "<date>: up to 5 stops", "<date>: no more than 10 vehicles a trip", "<file> is over 5 MB".

On Submit the booking gets its number (e.g. `SD26000008`) and its `approval` ([approvals § 4](approvals.md#4-the-approval-on-a-booking)). Needs approval → its trips are `awaiting_approval` (toast
"Booking <no> submitted. <first step names> approves it first", open the Awaiting Approval tab); else `sent` (toast
"Booking <no> sent to <company>") and the transport company is told.

## 5. Accept Changes

`PATCH /portal/booking_trips/:id/accept_changes` (a `changed` trip; `can_accept_changes`) → the booking (§ 3). The trip goes
back to `sent` for the transport company to confirm; `acknowledgement` = `{ by: <you>, how: "Client Portal" }`. Toast: "Changes accepted".
