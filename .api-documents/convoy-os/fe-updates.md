# Convoy OS — changes the front-end must make

Changes to existing Convoy OS endpoints made while building other apps (Convoy Driver) that the OS front-end has to act
on (renamed, removed or changed fields and endpoints). New optional fields are not listed here; they are in the menu
documents. Newest first. Each item: what changed, before → after, and what the front-end has to do.

## 04/11/2026 — Prototype features added to the API (phase 5)

Features the prototype has that the API did not. One **breaking change**: #4 `DELETE /stop_photo_requests/:id`.

| # | Where | API | Front-end |
| --- | --- | --- | --- |
| 1 | Finance › Operator Payments | `DELETE /finance/operator_pay/batches/:id/operators/:batch_operator_id`; batch operators add `can_remove` | "Take out of batch" (confirm first); `204` = the batch is gone |
| 2 | Finance › Client Invoices | `PATCH /finance/invoices/:id { invoice: { lines: [{ id, ref, description, details, period_text, quantity, amount }] } }`; lines add `amount_overridden`, `runs_amount` | Every line of a draft is editable; `amount: ""` = back to the runs; late cancellation amount stays "From runs" |
| 3 | Vehicle Financials | vehicle P&L `categories[].children` (2 levels); fleet `vehicles[].categories`; new "School Bus (auto)" revenue | Dive into a vehicle; stacked bars |
| 4 | Stop Library › Photo Requests | `POST …/:id/close`, `POST …/:id/reopen`, **`DELETE …/:id` now Removes** (was Close), `POST …/:id/submissions` (Add Received Photos); `?status=review`, `meta.counts` | Use `/close` for Close Request; Remove / Reopen on closed requests; the upload form |
| 5 | Route Plans | `POST /routes/:id/optimise`, `POST /plans/:plan_id/optimise`, `POST /plans/:plan_id/reset` → the plan + `meta.message` | Optimise, Optimise All, Reset All (toast = `meta.message`); no Undo yet |
| 6 | Route Plans › price card | `PATCH /routes/:id/pay_setup`; routes add `pay_setup` | Bus Attendant Required / BA Provided By / BA Price; Paid To for a route with no bus |
| 7 | Route Plans › Replacement Buses | `GET` / `POST /routes/:id/replacements`, `DELETE /route_replacements/:id` | The list, Add Replacement (incl. "Bus not in our list"), remove. The Scheduler drag error for a missing cost per day is now "Enter the cost per day" |
| 8 | Route Plans | `GET /plans/:id/estimate?month=` (finance / finview) | Plan card Est. Revenue / Operator Cost / Gross Profit and the Details dialog |
| 9 | School Bus header | `GET /schools/:id/rider_events?date=` | Plan For calendar dots, This Month list, "N rider changes in the next 30 days" |
| 10 | Run Routing | `GET /routing_runs/:id` adds `progress` | The loader: steps, bar, time left, "Route options checked", phase log |

## 04/11/2026 — API-ISSUES.md fixes, phase 4 (School Bus)

All additive; nothing renamed. Details in each doc.

| # | Where | Change | Front-end |
| --- | --- | --- | --- |
| 1 | Stop Assignment | `POST /schools/:id/rider_assignments/remove { rids }` → `{ removed }` | Unassign |
| 2 | Stop Assignment | rider `cut_point_ids` (points cut off; `POST …/rider_links` brings one back) | Show the hidden points |
| 3 | Route drawer | `DELETE /routes/:route_id/vehicle_changes/:id`, `DELETE /routes/:route_id/prices/:id`; `vehicles[]` / `prices[]` add `id`, `by` | Bus History "Remove this change", remove a price, "Set by …" |
| 4 | Feasibility | `POST /feasibility_studies/:id/copy`, `DELETE /feasibility_studies/:id/rows/:row_id` | Copy Study, remove one line |
| 5 | Rider import | list `checked_count` | "Finding addresses on OneMap: i of t" |
| 6 | Bus Attendants | `routes [{ id, label, session, bus_type }]` | "x of y routes in current plans need a BA" |
| 7 | Families | rider `unpaid { request_id, bill_number, overdue }`, `leave { request_id, button, label, text, ends_on }` | Unpaid line; leave line + End Rider in the family |
| 8 | Requests | rows `lat`, `lng`, `located`; `meta.service_check { none, plan }` | Applicant homes map; "Service check uses …" |
| 9 | School Dashboard › Finance | `collections.billable`; `route_costs { rows, by_operator, … }` | "Expected bills: … Not raised yet"; Route Costs + By Transport Operator |

## 04/11/2026 — API-ISSUES.md fixes, phase 3 (Dashboard, Reports, Ops Control, Live Map)

All additive (new fields, one new call); nothing renamed. Details in each doc.

| # | Where | Change | Front-end |
| --- | --- | --- | --- |
| 1 | Dashboard `alerts` | `period { raised, escalated, avg_ack_seconds }` | "In the Period" block |
| 2 | Dashboard `today` | `running`, `still_to_run`, `average_a_day`, `busiest`, `by_client`, `series` | Right Now / Summary / By Client / sparkline |
| 3 | Dashboard `late` | `series [{ date, count }]` | sparkline |
| 4 | Dashboard `unas` | `title`, `missing: bus \| driver \| both`; also own buses with no driver | "No bus / No driver" |
| 5 | Dashboard `off` | `kind`, `back_on` | Repair / Inspection badge, "Back dd/mm" |
| 6 | Dashboard `clotp` / `clrisk` | `change` per client; `clrisk` also lists clients falling 1 pt or more, `badge` | "+N pts on …", Below Target / Falling |
| 7 | Dashboard `profit` / `topbot` | `change`, `ytd`, `vehicles`; `topbot` top 5 / bottom 5 | Year to date, By Vehicle, Top 5 / Bottom 5 |
| 8 | Dashboard `rev` | `month { revenue, cost, profit }` (with `vehfin`) | Costs / Profit rows |
| 9 | Dashboard `opp` | `waiting_operators`, `approved_unpaid_batches` | "from N operators", "N batch" |
| 10 | Dashboard layout | `period` (default `d7`), `page`; `PATCH /dashboard/layout { period, page }` | Open with the saved period / page; PATCH on change |
| 11 | Reports | `kpis.*_change_ly`, `late`, `left_early`, `runs_a_day`; `trip.days_text`, `trip.plate`; `period.last_year` | "vs same period last year", sub-lines, Days / Bus chips |
| 12 | Ops Control | `gps.speed_kmh`, `gps.moving` | "Moving / Not moving" |
| 13 | Live Map | runs (`run`, `next_run`, `last_run`) add `school`; the drawer lists the children of **School Bus routes** too (`class_name` = level, `address`) | "School Route \| <school>", students on School Bus runs |

## 04/11/2026 — API-ISSUES.md fixes, phase 2 (Finance fields and calls)

| # | Change | Front-end |
| --- | --- | --- |
| 1 | `GET /finance/invoices/clients` rows add `overdue` (count); summary adds `owed_count`, `overdue_count` | "N overdue" on the Clients card; "N unpaid invoices", "N past the due date" |
| 2 | Manual line takes `ref` (Trip ID); late cancellation `runs[]` add `cancelled_hours_before` | Send `ref`; "cancelled 3 h before" |
| 3 | `POST …/batches/:id/mark_paid { paid_on, reference }` — **`paid_on` is now required** (`422` "Pick the date paid"); reference saved as "PN … <reference>" | Send the Date Paid and Bank Reference of the dialog |
| 4 | Batch adds `created_by`, `bank_file_by` (`{ id, name }`); batch payments add `by` | "Created by … / Bank file by …" |
| 5 | `PUT /finance/operator_pay/costs` with an empty `amount` removes the cost set by hand | Send `""` when the box is cleared |
| 6 | Vehicle Financials rows add `next_due { n, due_on, amount, of }`; schedule `rows[]` add `paid_by`; P&L `entries[]` add `by` | Next Due column; "<date> \| <by>" |
| 7 | Fleet P&L `vehicles[]` add `break_even` (as on one vehicle); `runs_needed` never below 0 | Break-even table (Runs Done / Runs Needed) |
| 8 | Instalments without `paid_on`: each paid on its due date (today when not due yet) | Mark Overdue Paid needs no date |
| 9 | `PATCH /finance/vehicles/:id { financial: { remove_schedule_file: true } }` | Remove File |
| 10 | School payouts `routes[]` add `attendant { amount, by }`; a school with Bus Attendants "selected sizes" now gets the BA price on those sizes (was left out: bug) | "Incl. S$x BA (ours / theirs)"; payout amounts of such schools can go up |

## 04/11/2026 — API-ISSUES.md fixes, phase 1 (small API changes)

| # | Change | Front-end |
| --- | --- | --- |
| 1 | Dashboard `coll` now `available: true` with the School Bus Collections totals (`bills, billed, collected, outstanding, not_paid, overdue, overdue_bills`); `noshow` reason "No-shows are not recorded yet" | Fill the Collections widget ([dashboard.md](dashboard.md)) |
| 2 | Finance Documents: `type` takes several types (`invoice,school_invoice`); `q` also matches reason, payment reference, batch number, school | Invoices / Credit Notes chips send both types |
| 3 | Statement rows: every row has `text` ("Invoice INV-…", "Payment for INV-…, <ref>", "Credit note CN-…"), `charge` / `credit` always strings; payments add `method`, credit notes `reason` | Show `text`; payment `text` no longer holds the method |
| 4 | Client invoice list: credit notes carry `invoice_number` | "For INV-…" |
| 5 | Payment notice before the bank file: `number: null`, `pays_by` = operator's details. Bank CSV: only operators with something left, Payment Type `PayNow` | — |
| 6 | Adopt Plan: `from` may be the day the current plan started (that plan goes back to `draft`); error text "<plan> was only adopted on <date>. Pick that day or later" | Allow the same day |
| 7 | Route `fill` is a number (0–1), not a string | `Number()` no longer needed |
| 8 | Year holidays return `public_holiday_id` | Send the list back as is |
| 9 | Feasibility Studies: reading needs `plans` (403 otherwise) | Hide the menu without `plans` |
| 10 | `PATCH /finance/vehicles/:id` with `document_read_id`: only the user's own read, kind `vehicle_loan_schedule`, finished (`404` / `422` "That read was for a …" / "The schedule is still being read") | Send the read only when `status: done`; `financial` may be left out (Upload from the list) |
| 11 | `PATCH /discover/advertisers/:id` returns the real `live_count` | — |

## 04/11/2026 — Answers to API-ISSUES.md (12–17, 20): documentation only, no API change

The docs now describe fields the API already returned. Nothing was renamed or removed. Front-end actions:

| # | Topic | Front-end |
| --- | --- | --- |
| 1 | Convoy Admin rights ([README § Signing in](../README.md#signing-in-bearer-token)) | Company data is view only (`403`); the Convoy Admin pages, Vehicle Types, approving requests and **Company Settings of any company** are writable (`can_edit: true`) |
| 2 | PATCH / PUT ([README § Base URL](../README.md#base-url-and-format)) | Docs now say `PATCH` for updates (fares, levels, bus attendants, payment methods, operator pay, school stops, CCA rides, registration); `PUT` still works there |
| 3 | Families, Requests, Registration, Feasibility, Route, Stop Assignment, School Bus Collections, Finance shapes | Read the new JSON examples; e.g. "Registered in the Convoy App by …", Sample, guardian Joined by invite / Name Shown As are already in `GET /families/:id` |
| 4 | Stop Library search | `q` = name, Stop ID, PUDO ID, old ID (no postal codes, as in the prototype) |
| 5 | "Approve (Early) and Send to Finance" (school Payouts) | = `POST /schools/:id/payouts/:op/send` |
| 6 | No School credit (CCA Rides) | `POST …/cca_rides/not_running { date, reason: "no_school" }` |
| 7 | Not in the prototype: React "Reported Issues", Add Application CCA / fixed-start / form answers, Route Costs page, Discover reach | Remove or hide them |
| 8 | 08:00 digest | Show the fixed "Sent · Today 08:00" text |
| 9 | Coordinates | Live GPS returns numbers, other places strings: read both with `Number()` |

## 04/11/2026 — Discover: empty fields in the placement / advertiser form (multipart)

Sending `""` for an empty field used to fail (`422` "Commission pct is not a number", or `500` for `listing_fee`).

| # | Endpoint / field | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | `POST` / `PATCH /discover/placements` `listing_fee`, `commission_pct` | `""` → error → `""` = not given: from the advertiser on a new placement or a new advertiser, else unchanged | Nothing; send `""` or leave the field out. Send `0` to set 0 |
| 2 | `POST` / `PATCH /discover/advertisers` same fields | `""` → error → 0 on create, unchanged on edit | Nothing |
| 3 | Placement `cta`, `starts_on`, `ends_on` | `""` → `500` → "Book Now" / `422` "Pick the start and end dates" | Show the message |
| 4 | Error message for a bad commission / fee | "Commission pct must be in 0..100" → "Commission must be between 0 and 100%", "Listing fee must be 0 or more" | Nothing if `message` is shown as is |
| 5 | Any endpoint: an empty required column no validation catches | `500` → `422` `{ code: "invalid", details: { <field>: ["can't be empty"] } }` | Nothing |

Details: [convoy-admin.md § 3](convoy-admin.md#3-discover), [README § Files](../README.md#files-uploads-and-downloads).

## 04/11/2026 — Client Portal, phase 5 (approvals): the client's own approval is decided only in the Client Portal

Bookings waiting for the client's approval flow (`awaiting_client`) are decided by the client in the Client Portal. Convoy OS
only shows them, as the Convoy OS design does ("<client> approves it in the Client Portal first", no buttons).

| # | Endpoint / field | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | `PATCH /booking_trips/:id/client_approve`, `PATCH /booking_trips/:id/client_decline` | removed (`404`) | Remove "Client approval done" / "Declined in the client's approval" if built |
| 2 | Booking trip `can_reject` | `true` for `awaiting_client` → `false` | Nothing if the button follows the flag |
| 3 | Booking `can_edit` (new), `PATCH /bookings/:id` | edit any time → `can_edit: false` and `422` while the client's approval waits | Hide Edit Booking when `can_edit` is `false` |
| 4 | Booking `client_approval` (new) | — → `{ status, name, waiting_text, … }` | Show `waiting_text` under trips waiting for the client's approval |

Details: [trips.md § Bookings](trips.md).

## 03/11/2026 — Convoy Driver app, phase 4 (driving): one attendance for School Run and School Bus

School Run attendance (the Scheduler drawer's Passenger List) and the Driver app's attendance are now the same record,
with the School Bus words. The values changed:

| # | Endpoint / field | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | `PATCH /occurrences/:id/passengers/:key` body `mark` | `boarded` \| `alighted` \| `absent` \| `clear` → `boarded` \| `alighted` \| `not_boarded` \| `expected` | Send `not_boarded` for the Absent button and `expected` to clear a mark |
| 2 | `GET /occurrences/:id/passengers` (and the answer of 1) `stops[].students[].status` | `not_marked`, `boarded`, `alighted`, `absent` → `expected`, `boarded`, `alighted`, `not_boarded`, `not_boarding` | Map `expected` to "Not marked" and `not_boarded` / `not_boarding` to "Absent" |
| 3 | `GET /live_map/vehicles/:id` run detail `students[].status` (School Run) | same change as 2 | Same mapping as 2 |
| 4 | `stops[].students[].by` | the user's name → the name of whoever marked (a user, or the driver in the Driver app) | Nothing (still a name) |

Details: [scheduler.md § 5.3](scheduler.md#53-passenger-list-school-run), [live-map.md](live-map.md).
