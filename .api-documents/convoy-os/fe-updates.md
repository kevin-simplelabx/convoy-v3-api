# Convoy OS — changes the front-end must make

Changes to existing Convoy OS endpoints made while building other apps (Convoy Driver) that the OS front-end has to act
on (renamed, removed or changed fields and endpoints). New optional fields are not listed here; they are in the menu
documents. Newest first. Each item: what changed, before → after, and what the front-end has to do.

## 10/11/2026 — Answers to the rest of API-ISSUES (Convoy OS, phase R2)

This section answers every API-ISSUES item not already answered above. Items marked **Open** are not finished (see the end).

| # | Where | Your claim | Answer | Front-end |
| --- | --- | --- | --- | --- |
| 1 | Live Ops › attention kinds (§14) | Only 3 kinds listed | `gps_lost`, `late`, `no_show` (documented). `delay_expected` is not built (see 22) | Nothing |
| 2 | Live Map › offline bus (§16) | Hidden after 3 days; the doc keeps it | Not an API rule: the API returns the bus with its last position, as the prototype. Hiding after 3 days is a front-end choice | Hide offline buses on the front end if you want to |
| 3 | Riders › `meta.dataset.state` (§22) | `null` on the list | **Fixed:** the list now sends the state of its list for the day (`in_use`, `scheduled` or `replaced`) | Read it |
| 4 | Riders › `lat` / `lng` (§22) | Numbers, README says strings | Numbers, as now (README corrected) | Treat as numbers |
| 5 | Riders › `route_labels` `id` (§22) | Undocumented id | Label sets are keyed by `session`; there is no `id` | Use `session` |
| 6 | Year Setup › hand-added level (§22) | Stored as `custom`; doc silent | Documented: `section` is `pre`, `pri`, `sec`, `jc`, `grd`, `yr`, or `custom` (hand-added) | Send only those values |
| 7 | Year Setup › unlock (§22) | Year 200, school 204 | Both `200`; the school unlock answers the school | Parse the body |
| 8 | Year Setup › `session id`, `period_label`, copy (§22) | Undocumented | The session rows have no `id`: each is keyed by `position` (and `name`). `PUT …/sessions` sends the whole list, so no id is needed. `period_label` and the copy (`GET …/sessions/copy`, a draft in `data`, no `meta`) are documented | Key rows by `position` |
| 9 | Stops › candidate `metres` (§22) | `null` when the home has no location | Kept `null` (documented) | Show no distance |
| 10 | Stops › `street_view_url` message (§22) | Raw field name in the message | **Fixed:** "Street View link must be a Google Maps link" (no field prefix) | Show the message |
| 11 | Stops › Needs Attention (§22) | Omits "No catchment" / "No riders" | Kept as the prototype: Needs Attention is the coverage gaps only. Those two texts are row labels | Show them as labels |
| 12 | Stops › delete a stop or a photo request (§22) | No delete | A stop is archived (`DELETE /stops/:id`, the only delete). A closed photo request is removed by `DELETE /stop_photo_requests/:id` (`204`) | Use Archive / Remove |
| 13 | Routing › unassigned reason labels (§23) | Reason is a code | Codes: `RIDER_NO_STOP`, `ADMIN_REMOVED`, `NOT_ROUTED`, and the others in the doc. The FE maps the labels | Map each code |
| 14 | Routing › `summary.riders` (§23) | Does it count no-stop riders? | Yes: `assigned` + `unassigned`, so a no-stop rider counts | Nothing |
| 15 | Routing › low effort time (§23) | 0.2 s against 15 s in the doc | `sec` is the limit; a run ends when its search finishes, so a small run is under a second | Nothing |
| 16 | Routing › `defaults.preset` vs `types` (§23) | Preset FEWEST_BUSES, types Balanced | `defaults` are the prototype defaults (Fewest Buses); `types` now shows the same list. Change in R1 row 4 | Nothing |
| 17 | Routing › engine params keys (§23) | `maxEffort`, `rr*`, `ants`, `effort[].use` undocumented | Documented in `school-bus-routes.md` | Leave them at defaults |
| 18 | Routing › empty route stops (§23) | `422`; doc said the route goes | `422`, use Delete Route (R1 row 13) | Show the message |
| 19 | Routing › answer shapes (§23) | `vehicle` / `prices` / `charges` / comment / delete answers differ from the doc | As implemented: `POST /routes/:id/vehicle` and `/prices` → `{ vehicles, prices }`; `POST /routes/:id/charges` → the list; comment `POST` → `201` + the plan; comment `DELETE` → `204`; route `DELETE` → `200` + the plan | Read these shapes |
| 20 | Routing › adopt cancels the other scheduled plan (§23) | Doc only "after the date" | Same as the prototype (R1 row 14) | Nothing |
| 21 | Feasibility › postal `999999` accepted (§23) | Accepted | **Open:** we cannot reproduce it. Asked of the FE (see the question at the end) | See the question |
| 22 | Families › guardian `name_order` (§24) | Undocumented on create | Documented: `first` or `last`, the order of the guardian's name | Send it |
| 23 | Families › guardian `422`s without `details` (§24) | No field name for the name check | **Fixed** for the name check: `details.first` and `details.last` (both fields in red, as the prototype). Phone and email already come with `details.phone` / `details.email`. Registration and CCA `422`s stay message-only | Mark `first` / `last` / `phone` / `email` in red |
| 24 | Families › unlink / delete (§24) | `200` / `204` undocumented | Unlink a rider `200` + the family; delete a family `204` (documented) | Nothing |
| 25 | Registration › message fields (§24) | `released_at`, `saved_at`, `saved_by` undocumented | Documented: `released_at` (`null` until released; the screen shows "Released by you"), `saved` / `saved_at` / `saved_by` on the registration | Show "Released by you" |
| 26 | Requests › `tabs.open` for New Service (§24) | `null` | `0` (R1 row 6) | Show `0` |
| 27 | Requests › Overdue tile count 0 (§24) | Sent with count 0 | `0` is the true count when nothing is overdue, as sent | Show 0 |
| 28 | Requests › Route Fit `tm` and fields (§24) | Unit unknown; no route / stop fields | `tm` is minutes from midnight of the stop time. Each route has `id`, `label`, `free` (seats), `start` / `end` (minutes), and `stops[]` with `name`, `ll`, `tm`, `n`, `postals` | Read these |
| 29 | Requests › quote with no Bus Fares (§24) | `"0.0"` | `amount` is `null` when there is no estimate (R1 row 20) | Show an empty amount to type |
| 30 | Requests › bulk accept answer (§24) | Undocumented | `POST /schools/:id/bus_requests/accept { ids }` → `200 { data: { updated: n } }` (documented) | Show the count |
| 31 | Requests › change-row fare unit (§24) | No unit | Per term (R1 row 16) | Show "per term" |
| 32 | Bills › statement lines (§24) | `details`, `charge` / `credit` null | Lines keep `details` (R1 row 17) | Read `details` |
| 33 | Bills › `late_waived` (§24) | Money string, doc said boolean | A money string (R1 row 15) | Parse as money |
| 34 | Bills › `payer_key`, history, voucher, payout kind (§24) | Undocumented | Documented: `payer_key` (`school` or `family:<id>`; `family:` with no id = the child is not in a family yet); bill `history` kinds (`payment`, notes, `waiver`); voucher `{ number, on }`; payout `history` kinds (`returned`, `sent`, `approved`, `paid`) | Read these shapes |
| 35 | Bills › `meta.payers` same name twice (§24) | Duplicate names | Two payers with the same name are two families (two keys). By design | Nothing |
| 36 | Live › `position` on arrived runs (§24) | Sent after arrival | Kept: the last known position (R1 row 9) | Nothing |
| 37 | Live › `ahead[]` / `attention[]` `detail` (§24) | Undocumented | `detail` is the line shown under the title, as the prototype (documented) | Show it |
| 38 | Live › utilisation with 0 seats (§24) | `null` with 65 riders | `null` (no seats, no %) | Show "—" |
| 39 | Live › "Delay expected" (§24) | Label missing | **Not built** for now (skipped) | Hide it |
| 40 | Finance › pending stop requests (§24) | No field | **Not built** for now (skipped) | Hide it |
| 41 | Parents › `/api/v1/app/*` (§14) | In OpenAPI only | The parent app (Convoy App) is not final yet (its Phase 1 is in progress). Its markdown doc will come when Phase 1 is done. Until then use the OpenAPI file | Use OpenAPI for now |

**Open (not finished)**
- **21** Postal `999999`: the FE question below.
- **Not built:** Delay expected (39) and pending stop requests on Finance (40), skipped for now.

**Question to the FE (21): postal `999999`.** Please send, for the feasibility study that accepted postal `999999`:
1. the exact request body (name, `school_mode`, `prospect_postal`, and anything else sent),
2. the endpoint (`POST` or `PATCH`) and the response status,
3. the time it happened, and the study id if there is one.
We cannot reproduce it: a postal code OneMap does not know gives `422` "Postal code not found on OneMap", and nothing is saved.
(Postal lookup is skipped only when `school_mode` is `existing`, because the postal code is not used then.)

## 10/11/2026 — Decisions on the remaining API-ISSUES items (Convoy OS, phase R1)

Docs: [school-bus-setup.md § 2.2, 3](school-bus-setup.md), [school-bus-stops.md](school-bus-stops.md), [school-bus-routes.md](school-bus-routes.md),
[school-bus-parents.md](school-bus-parents.md), [school-bus-live.md](school-bus-live.md), [school-bus-finance.md](school-bus-finance.md).
**B** = breaking. 

| # | Where | Change | Front-end |
| --- | --- | --- | --- |
| 1 | Riders: `PATCH /schools/:id/riders/:rid`, `DELETE /schools/:id/riders/:rid` (new) | Edit or remove a rider added by hand. Delete is refused (`422`) while a family, stop, absence, CCA booking, request or bill uses the rider. Riders from an uploaded list answer `422` | Enable Edit / Remove for hand-added riders only |
| 2 | `POST /schools/:id/unlock` (school sections) | **B** `204` → `200` with the school, as the year unlock | Parse the body (the record) |
| 3 | `POST /schools/:id/rider_links/remove` | Accepts `{ rid }` or `{ postal }` per link; a postal link removes the code for every rider of that code at the school | Send `postal` for a whole code |
| 4 | `GET /routing/settings` | `types` is the engine's defaults (the same list as `defaults.types`, Fewest Buses), as the prototype shows them | Show `types` as the defaults |
| 5 | `POST /families` | A typed name is required for `name_mode: custom` (`422` "Family name is required"); an automatic name is worked out from the guardians | Show the message |
| 6 | Requests `tabs` | **B** `New Service` `open` is `0` (was `null`) | Show `0` |
| 7 | Levels | `section` values are listed (`pre`, `pri`, `sec`, `jc`, `grd`, `yr`, `custom`); send only these | Send only listed values |
| 8 | Live Ops `attention` | Three kinds (`gps_lost`, `late`, `no_show`); `delay_expected` is not built | Nothing |
| 9 | Live Ops `position` | Kept after a run arrives (the last known position); `null` before it starts | Nothing |
| 10 | Rider `lat` / `lng` | Numbers (not strings), as now | Treat as numbers |
| 11 | Route summary `riders` | `assigned` + `unassigned`, so riders with no stop count | Map `unassigned[].reason` labels on the front end |
| 12 | Stops › Archive | The only delete for a stop (`DELETE /stops/:id`) | Nothing |
| 13 | Routes › `PUT /routes/:id/stops` | Empty list → `422`; use Delete Route | Show the message |
| 14 | Plans › Adopt | Adopting a plan also cancels the plan scheduled for the same session (as the prototype) | Nothing |
| 15 | Money string `late_waived` | A money string, like `late_fee` (the doc said boolean) | Parse as money |
| 16 | Change-row fare `amount` | Per term | Show "per term" |
| 17 | Statement lines | Lines keep `details` (not `text`) | Read `details` |
| 18 | Families `code` | **B** Codes are numbered per school (`FAM-0001` at each school), unique within the school, not the company. The same code can now exist at two schools | Show the code as is; do not treat it as a company-wide key |
| 20 | Requests `quote_default.amount` | **B** With no Bus Fares table and no parent estimate the amount is `null` (was `"0.0"`). Staff type the fare; Accept without a fare is `422` | Show an empty amount to type; do not show 0 |
| 19 | Families `name` (auto) | Shown as the rule: surname in upper case then " Family" (e.g. `TAN Family`); the doc example was `TAN FAMILY` | Nothing |

Not built: "Delay expected" in Live Ops and pending stop requests on Finance (skipped for now; the FE is told).

## 10/11/2026 — Answers to API-ISSUES §14–§24 with no API change (Convoy OS, phase Q9)

These items are answers, not changes: the API is right as it is (same as the prototype), or the feature is not built yet.
**B** = none. Items that were fixed are in the sections below.

| # | Where | Your claim | Answer | Front-end |
| --- | --- | --- | --- | --- |
| 1 | Dashboard › Export (§14) | No call or doc | Export is a CSV built in the browser from `route_costs.rows` (as the prototype's `costVals.export`). No endpoint | Build the CSV on the client |
| 2 | Dashboard › Overdue Families (§14) | Counts bills, not families | As the prototype: the tile counts overdue bills | Nothing; label it "bills" if you want to be exact |
| 3 | Dashboard › `duty` (§15) | On duty / On leave / On MC / Rest day: no source | No duty roster exists in the system; not built (backlog) | Hide the duty figures or show "—" |
| 4 | Live Map › trip km (§16); Live Ops route km (§24) | No field | The routing engine has no distances; the prototype shows sample data. Not built | Hide the km figures |
| 5 | Live Map › student photo (§16) | No field | Not built (backlog: no photo source for students) | Show initials |
| 6 | Reports › utilisation AM / PM (§16) | Seats per run for AM / PM | Utilisation = riders / (seats × runs a day), as the prototype; the prototype has no AM / PM split | Use the field as it is |
| 7 | Vehicle Financials › loan preview (§20) | No server preview of the auto loan | No endpoint: the prototype computes it in the browser (`logic/vehicle-loan.js`); use the same formula | Compute in the browser as the prototype does |
| 8 | Year Setup › Lock / Unlock (§22) | "Lock Again" cannot relock | Unlock is saved on the call, so send it only from Save (the prototype unlocks on Save) | Unlock on Save, not on the toggle |
| 9 | School Finance › Collections (§24) | No academic-year picker | The server picks the default year (running → next → latest); send `academic_year_id` to choose another | Send `academic_year_id` when a year is picked |

## 10/11/2026 — St. Stephen's seed data (API-ISSUES §14 item 17, §22–§24 "Seed data", phase Q8)

Seed data only, no endpoint or field changes. After a reset + reseed, the St. Stephen's Term 4 plans (AM and PM) have the
data the screens were missing:

| # | Where | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | `GET /schools/:id/plans/:id` routes[].stops[] | no `stop_point_id`, no lat / lng → every stop links its library stop and main PUDO point, with the point's lat / lng | Nothing; the map can draw the stops and a stop can be edited |
| 2 | stops[].riders / `riders_count` | most stops empty → each stop lists the students living at it (65 AM, 57 PM; counts match) | Nothing |
| 3 | routes[].bus_type, `seats`, `student_seats`, `fill` | `bus_type` null (`bus_mix {"": 3}`) → the size of the regular bus (`LARGE_40` / `LARGE_45`), with seats and fill | Nothing |
| 4 | plan `summary` and `params` | null → filled (riders, assigned, byType, avgFill, …; the company's routing parameters with session and attendant) | Nothing |
| 5 | Stop Assignment (`rider_assignments`) | none → the 65 AM riders have their PUDO point | Nothing |

Seed order only: the Client Portal bookings moved from `46_bookings.rb` to `47_portal_bookings.rb` so a clean seed runs in one pass.

## 10/11/2026 — Vehicle Financials Running Total, Live Ops / Dashboard fields (API-ISSUES §20, §24 Live / Dash, phase Q7 Convoy OS)

Docs: [finance.md § Vehicle Financials](finance.md), [school-bus-live.md § 2, § 4](school-bus-live.md).
Class: **BE bug** (fixed), **Doc gap**. **B** = breaking. 8 rows: 7 BE bugs (1 breaking: 5), 1 doc gap. Client Portal items (13, 14) are not in this entry.

| # | Where | Your claim | Class | Answer / what changed | Front-end |
| --- | --- | --- | --- | --- | --- |
| 1 | Vehicle Financials `GET /finance/vehicles/pl`, `GET /finance/vehicles/:id/pl` (16) | No "Running Total" | BE bug | `chart[].running_total` (profit from the first month on record to the end of that month, as the prototype's `vfBody`) and `running_total` (the Month period's card, "Profit to the end of <month>"; `null` for the other periods). Same on a vehicle's view | Draw Running Total as the second line (Monthly Profit / Running Total) and show the Month card |
| 2 | Live Ops run `stops[].riders[].status` (C5) | Runs "arrived" with every stop done but children still `waiting` | BE bug | A child nobody ticked is `waiting` only until the bus has left the stop (or the run is done). After that: morning `on_board` (`at_school` once the run is done), afternoon `dropped_off`, as the prototype's `stu()`. A tick, Bus Not Required or No Show always wins. The board's `counts`, `kpis.riders` and the Live Map / Client Portal run views follow | Nothing (map the statuses as before) |
| 3 | Live Ops run `bus.type`; Dashboard `route_costs.rows[].bus_type`; Operator Payments route rows `bus_type` (C6) | `null` | BE bug | A route made without a bus size shows the size nearest its seats (or its bus's seats). Display only: prices and rates still use the route's own size, so a route with no size stays "unpriced". The seeded St. Stephen's routes already have one | Nothing |
| 4 | Dashboard Finance `month`, `year[].month` (C6) | `"2026-11-01"`, doc says `YYYY-MM` | BE bug **B** | Both are `"YYYY-MM"` now (the query `?month=YYYY-MM` is unchanged). `reference_day`, `ahead[].date` stay dates | Parse `month` as `YYYY-MM` (not as a date) |
| 5 | Dashboard Finance (C6) | No field for the "not a paid month" banner | BE bug | New `paid_month` (`false` when Operator Pay does not pay the month; the costs are 0). Banner text as the prototype: "<Month Year> is not a paid month for this school. Change it in Operator Pay." | Show the banner when `paid_month` is `false` |
| 6 | Live Ops run `crew[]` (C6) | No Bus Attendant photo (driver photo too) | BE bug | `crew[].photo`: signed thumbnail link for the driver and the bus attendant, `null` when none (a replacement driver has none) | Show the photo, else the initials |
| 7 | Live Ops run `stops[].address` (C6) | No stop address under the stop name | BE bug | `address` = the PUDO point's description (`stop_point.description`); `null` when the stop is not linked or the point has none | Show it under the name when set |
| 8 | Dashboard Finance `reference_day` in a month with no school day (C6) | December 2026-12-15 undocumented | Doc gap | By design: today for this month, else the month's first school day, else the 15th. Documented | Nothing |

## 10/11/2026 — Families / Requests / Bills / CCA Rides / Operator Payments (API-ISSUES §24 Q6, §14 items 9, 10a, 10b, 12, 15, C1–C4, phase Q6)

Docs: [school-bus-parents.md § 1, 2, 4, 6](school-bus-parents.md), [school-bus-finance.md](school-bus-finance.md).
Class: **BE bug** (fixed), **Doc gap**, **FE answer**. **B** = breaking. 14 rows: 11 BE bugs (5 breaking: 6, 8, 10, 11, 12), 1 doc gap, 2 FE answers.

| # | Where | Your claim | Class | Answer / what changed | Front-end |
| --- | --- | --- | --- | --- | --- |
| 1 | Families candidates (C1) | The list has riders of other families, no exact "riders without a family" / "Parent matches" | BE bug | `GET /families/:id/candidates` returns only riders of the school who are in no family (as the prototype's pool), parent matches first (`match: "parent"`), then by name; 200 at most. `match: "last_name"` still flags a shared last name but no longer ranks | Nothing; "N riders without a family" can use the list length (up to 200) |
| 2 | Families CSV import (item 9) | One bad phone fails the whole file; rows match families company-wide by name / phone; the file empties other families; default relationship | BE bug | A wrong phone or email is dropped with a warning (`Line 2: 12 doesn't look like a phone number, left out`) and the row imports. Without `family_id`, rows group **inside the file** by `family_name`, else phone; a family already in the company is never matched by name or phone. Only a family that lost riders to the file and is left empty is deleted; one left with guardians only is kept with the first warning "N families lost all their riders but still have guardians…". New guardian `relationship` defaults to `Guardian`. A family with no name is named after its first guardian, else its code (was "New Family"). Skipped rows now carry a warning | Show `warnings` as before |
| 3 | Families CSV import | An unknown student is warned **and** linked (name `null`, `on_list: false`) | FE answer | As the prototype ("not in this school's rider list, linked anyway") | Nothing |
| 4 | Families CSV import | `families_deleted` undocumented | Doc gap | Documented with the other counts (`school-bus-parents.md` § 1) | Nothing |
| 5 | Operator Payments history (10a) | "Approved for S$0.00" when the net is S$87.50 | BE bug | The text prints the **net** (route pay + additions − deductions), as the prototype's `runNet`; it printed the route pay before | Nothing |
| 6 | Operator Payments / CCA / bills money (10b, C2) | `balance`, `kpis.still_to_pay`, CCA `kpis.collected` / `credit_given` are the number `0` when empty or when the net is ≤ 0, else strings | BE bug **B** | Always decimal strings (`"0.0"`). Same fix for other sums that could leak `0`: CCA `off.credit`, bill `amount` of a draft with no lines, Operator Pay `still_to_pay`, Finance Client Invoice `paid` / `credited` / `balance` | Parse these fields as decimal strings only |
| 7 | CCA Rides rows (C2) | Rows have only `bill_id` | BE bug | Rows have `bill_number` (the CCA bill's number, `null` while not billed) | Show it |
| 8 | CCA Rides `no_school` (C2) | `{ run, label }` with a made-up label | BE bug **B** | `{ run: false, kind, label, sub }` as the prototype's `yearDay`: `kind` `public_holiday` \| `no_service` \| `school_holiday` \| `no_cca`; `label` the holiday name, "No Service", "School Holidays" or "No CCA"; `sub` the reason ("Public holiday", "Mon is not an operating day", "Between terms"…). A public holiday now also stops the CCA bus. The special-day `calendar` has `kind: "special_day"` and `sub` (same text as `detail`, which stays) | Show `label` and `sub` |
| 9 | CCA Rides `PUT` (C2) | The answer is the current week, not the one viewed | BE bug | `PUT /schools/:id/cca_rides?week_of=YYYY-MM-DD` answers that week (default week when left out) | Send the viewed `week_of` |
| 10 | Requests `record_payment` (item 12) | An empty method is accepted (saved as "Bank Transfer"); methods undocumented | BE bug **B** | `422` "Pick how it was paid" when `method` is empty or not one of `meta.methods`; `meta.methods` is on the answer and on `GET /bus_requests/:id` (`PayNow`, `Bank Transfer`, `GIRO`, `Cheque`, `Cash`, `Card`) | Add a method picker; send `method` |
| 11 | Bills `GET bill_runs` (item 15) | Before fares are locked it answers `422` "Lock the Bus Fares for a year first" (doc: `on: false` with `error`) | BE bug **B** | `GET …/bill_runs` answers `200 { data: { on: false, error } }` when no year has locked fares (also when `academic_year_id` is left out). `POST` Draft / Issue still answer `422` | Read `on: false`; no `422` handling needed for GET |
| 12 | Requests (C3) | "Not Checked (part)" when every session is Not Checked; rows have no `can`; alert items no academic year; `windows` `[]` with no year; no start date → year start | BE bug (5 fixes) | The route check says "(part)" only when some, not all, sessions are Not Checked. Every row has `can` (same object as the drawer). Alert items have `academic_year_id`. `meta.windows` is `null` (was `[]`) when the school has no academic year **B**. With no start date asked, `quote_default.start_on` and Add Application use the registration's service start (the first school day by default), not the year start | Read `windows` as `null`; use `row.can` for the row buttons |
| 13 | Requests alerts / digest (C3) | "3 changes of address" for 1 address + 1 service + 1 stop | FE answer | As the prototype (`reqAlerts`: `nAdr` counts address, service and stop changes and prints "changes of address") | Nothing |
| 14 | First invoices (C4) | `lines: []`, `children: []`, `bill_to_code: null` | BE bug | The first invoice has one line ("<child> | First month, <period>", amount before GST, `rid`, `child_name`) so `children` fills in. `bill_to_code` and `family_id` are the family's, also for a renewing child already in a family (before: only a new child, and the code stayed `null`). Not in the prototype (its invoice has no lines); added to match period bills | Nothing |

Also found: the Billing Differences list had no order; it is now by bill id.

## 10/11/2026 — Setup / Registration / Policy / Operator Pay (API-ISSUES §22 items A1–A3, A9, A11, §14 item 8 and 11, phase Q5)

Docs: [school-bus-setup.md § 2, 7, 8](school-bus-setup.md#8-setup-strip-and-summary), [school-bus-money.md § 3, 5](school-bus-money.md),
[school-bus-parents.md § 2](school-bus-parents.md#2-bus-service-registration). Class: **BE bug** (fixed), **Doc gap**, **FE answer**.
**B** = breaking. 8 rows: 7 BE bugs (1 breaking: 6), 1 FE answer.

| # | Where | Your claim | Class | Answer / what changed | Front-end |
| --- | --- | --- | --- | --- | --- |
| 1 | Registration (item 8) | Scheduling needs the policy in use, the strip does not agree | BE bug + FE answer | Registration needing the policy **in use today** is as the prototype (`ayReady` / `polCur`): a version that starts later does not count. The strip was the part that differed (any version counted): `GET …/setup` step 5 `done` now uses the same rule (`SchoolPolicyVersion.current_for`) | Nothing |
| 2 | Strip sub-lines (item 8) | No "6 levels, P1 to P6", "Version N published" | BE bug | Every step has `detail` with the prototype's words (e.g. "Version 2 from 01/01/2027", "Locked 02/11/2026. Parents pay"); step 8 too ("N holidays, M special days") | Show `detail` under each step |
| 3 | Period count (A1) | "must be 3 and 4" | BE bug | "Period count must be 3 or 4" (semester: "must be 2") | Nothing |
| 4 | Bus Attendants (A2) | `selected` with `sizes: []` accepted | BE bug | `422` "Pick at least one bus size", nothing saved or locked. Before, the sizes the law requires were filled in and the empty pick passed | Show the message |
| 5 | Setup without a year (A3) | No setup endpoint without a year | BE bug (new endpoint) | `GET /schools/:id/setup` (optional `?academic_year_id=`): the running, next or latest year; `year: null` and the year steps not done for a school with no year | Use it when no year is picked |
| 6 | Operator Pay calculator (A9) | `rate` is the number `0` for an unpaid month; notes differ from the prototype | BE bug **B** | `rate` / `earned` are always decimal strings (`"0.0"`). Notes as the prototype: "Not a paid month under the Pay Scheme", "Route not started yet" (both `pct: 0`, `amount: "0.0"`), grace-period and "less N days" notes. `400` without `start_date` stays (a required field) | Parse `rate` as a decimal string |
| 7 | Policy `collection` (A11) | `null` when no year covers the current calendar year | BE bug | Falls back: running year, else the next to start, else the latest year. `null` only when the school has no year or that year has no fares | Nothing |
| 8 | Release Now / Unschedule (11) | Release works on a draft, a message sent by date, or twice; Unschedule works on a draft | BE bug | `release` is `422` when the registration is not scheduled, the message is sent automatically by date (`scheduled: true`) or was already released. `unschedule` is `422` "Registration is already a draft" on a draft | Show Release Now only for a manual message with `scheduled: false` and no `released_at`, in a scheduled registration; show Unschedule only when `status` is `scheduled` |

## 10/11/2026 — Feasibility Studies (API-ISSUES §23 Feasibility, items B6–B8, phase Q4)

Doc: [school-bus-routes.md § 7](school-bus-routes.md#7-feasibility-studies). Class: **BE bug** (fixed), **Doc gap**, **FE answer**,
**Not valid**. **B** = breaking. 17 rows: 15 BE bugs (4 breaking: 3, 4, 5, 6), 1 doc gap / FE answer, 1 not reproducible.

| # | Where | Your claim | Class | Answer / what changed | Front-end |
| --- | --- | --- | --- | --- | --- |
| 1 | `place` | `{name, short, lat, lng}`, no address | BE bug | `place.address` added: the school's address, or the address OneMap found for a prospect's postal code (kept in `prospect_address`; filled for old studies) | Show it under the school |
| 2 | `unassigned` | One entry per rider, no rider list | BE bug | Every entry has `riders: [id]` (the prototype's `un[].riders`) next to `n`, `reason`, `label`. The same student has the same id in AM and PM: count different ids per reason (prototype `unS`). Students with no postal code found stay one entry each (`RIDER_NO_STOP`) | Group by `reason`, count ids |
| 3 | Scenario `PATCH` | `sizes: []`, `hard_cap: "abc"` stored as `[]` / 0 | BE bug **B** | `hard_cap`, `target_cap` must be whole numbers above 0 (`422` `details.hard_cap`), `margin_pct` 0–90, unknown bus sizes `422`. `sizes: []` stays allowed (the prototype lets you untick every size and Run says "Pick at least one bus size") | Show `details` under the field; do not send text in number fields |
| 4 | Scenario `params` | (new) | BE bug **B** | Only the prototype's Routing Parameters keys are accepted: `amTarget`, `pmTarget` (`"HH:MM"`), `baseDwell`, `perStudent`, `amTraffic`, `pmTraffic`, `headroom` (fraction 0–0.9), `effort`; numbers sent as text become numbers. Any other key or a bad value is `422`. Empty values = company setting | Send only the card's fields |
| 5 | `POST …/run` | Run with no students → `202`, then `failed` | BE bug **B** | Checked before the `202`: `422` "Set the school location first" / "Add student postal codes first" / "Pick at least one bus size" and no run starts. `failed` remains for what only the run can know (OneMap or the routing service down) | Show the `422` message; keep polling `status` after `202` |
| 6 | Study `POST` / `PATCH` | Empty name + bad postal reports only the postal; OneMap is asked first | BE bug **B** | The whole study is validated first: `422` lists every wrong field (`name`, `prospect_postal` not 6 digits, `walk_m` below 0), then OneMap is asked. Clearing the postal code clears the place | Show every `details` entry |
| 7 | Study `POST` | postal `999999` accepted | Not valid (not reproducible) | In the specs a postal code OneMap does not know (`999999`) gives `422` "Postal code not found on OneMap" and no study is saved. It is only skipped when `school_mode` is `existing` (the postal code is not used then). If it still happens, send the exact request body | Re-test |
| 8 | `stale` | Only new students set it; a scenario `PATCH` clears it | BE bug | As the prototype: students added / removed / cleared, `school_mode`, school, prospect place, `pickup`, `walk_m`, and a scenario's `sizes`, `attendant`, `hard_cap`, `target_cap`, `params` set it. Prices, fare tiers, `margin_pct`, `extra_buses` and `name` do not (they only change the cost). A scenario edit no longer clears it: only a new run does | Show "Run Again" from `stale` |
| 9 | Scenario | No "Run at" time | BE bug | `ran_at` on each scenario (when its result was planned) and on the study (the latest). `null` before a run; a copied study starts with `null` | Show "Run <time>" |
| 10 | Rows | No per-row geocode status / address (no Address column) | BE bug | Each row has `status` (`found` / `not_found` / `pending`), `address`, `lat`, `lng`; the study has `geocode: { postals, pending, not_found }`. Adding students looks the codes up on OneMap in the background (prototype `fzGeo`): poll the study until `pending` is 0 | Address column, red for `not_found` |
| 11 | No Check Again | — | BE bug (new endpoint) | `POST /feasibility_studies/:id/geocode` → `202` + the study: asks OneMap again for the `pending` codes only (not for `found` / `not_found`) | Show **Check Again** while `geocode.pending > 0` after the first poll |
| 12 | Default bus cost (new study) | A new study has no bus prices, so every cost shows "No monthly price" | BE bug | A new study starts with default `bus_prices` for all five sizes (placeholder numbers; type the operator's own with `PATCH`) | Show them as editable defaults |
| 12b | Default bus types | The run read the engine's bus types (fixed cost per type) from `meta.types`, not `meta.defaults.types` as the prototype (`RE.DEFAULTS.types`) | BE bug | When the company has no saved bus types the run uses `defaults.types` of `GET /routing/settings` (same values today; they follow the engine's defaults if those change) | Nothing |
| 13 | Seat Buffer | The scenario's `headroom` had no effect | BE bug | `params.headroom` now replaces the buffer of every bus size in the run (prototype `fzRun`: `hr`), a fraction (send `0.1` for 10%) | Convert % ↔ fraction |
| 14 | AM Arrival / PM Dismissal | The scenario's `amTarget` / `pmTarget` did not move the planning window | BE bug | The window follows the target as in the prototype `fzPar`: AM `target − 5 … + 10 min`, PM `− 15 … target` | Nothing |
| 15 | `road` flag | Not in the result | BE bug | `result.AM.road` / `result.PM.road` (`false` = straight-line times: show "straight-line times") | Show it next to the session line |
| 16 | `summary`, `cost.by_session`, `fares.exact`, open tier, answers of `PATCH` / `rows` / `DELETE rows` / `run` | Undocumented or unexplained; `DELETE rows` is 200 not 204 | Doc gap + FE answer | Documented in § 7 ("Other fields", "Answers"). `DELETE …/rows` is `200` + the study on purpose (the screen redraws from it); only deleting a study or scenario is `204` | Nothing |

New (not in your list): the OneMap search now answers errors (a missing API token) as `200` with `error`. It used to look like
"postal code not found" and was kept for a week; now it is "OneMap cannot be reached" and nothing is kept.

## 10/11/2026 — Route Plans and routing (API-ISSUES §23 Run Routing / Plans / Adopt / Charges, items 4, 5a–c, 6, phase Q3)

Doc: [school-bus-routes.md § 2–6](school-bus-routes.md#2-run-routing). Class: **BE bug** (fixed), **Doc gap**, **FE answer**,
**Not valid**. **B** = breaking. 11 items, all BE bugs (5c and 6b also doc gaps); 5 breaking.

| # | Where | Your claim | Class | Answer / what changed | Front-end |
| --- | --- | --- | --- | --- | --- |
| 4 | Adopt › Cancel adoption | Cancel leaves the PUDO assignments the scheduled AM adoption made | BE bug | As the prototype (`promotePlan` writes them, `schedAdopt` does not): an AM plan writes its riders' PUDO points **when it starts**: at once when adopted from today or earlier, else on its start day (daily job, about 01:30; once per plan). Scheduling writes nothing, so Cancel has nothing to undo. Moving a scheduled plan's start to today (`PATCH /plans/:id`) writes them at once. Points written by a scheduled adoption **before this fix** stay: re-check Stop Assignment for that school | None. Stop Assignment changes on the start day, not when scheduling |
| 5a | Plans › Route Again | Every route gets a new id; old `summary` values | BE bug **B** | Routes are matched by number and **updated in place**: same `id` (bus history, prices, charges, attendant stay; hand edits, via points, Hide cleared); leftover unlocked routes are deleted with everything on them (no more FK error); new numbers are added. Locked routes keep their engine version (Reset Route still works). **New:** `422` "Make a new plan to route again" on an adopted plan; a run whose plan is adopted meanwhile ends `failed` with that message | Keep the selected route by `id` after Route Again; disable Route Again on scheduled / current / replaced plans |
| 5b | Plans › `summary` | After Route Again `summary.fixed / run / total` keep the old values | BE bug | `summary` is rebuilt from the routes with every key of the engine's `summarize` after hand edits, Route Again and Draw Routes: `riders, assigned, unassigned, routes, byType, avgJourney, maxJourney, avgFill, fixed, run, overtime, floor, stability, total, slots`. Nothing is kept from an older summary | Read the "Optimisation score" line and slots from `summary` |
| 5c | Plans › Reset Route | Reset keeps `locked` and reverts the bus size (undocumented) | BE bug + Doc gap | As the prototype (`setBusType` edits the result, `resetRoute` only clears edits): Reset Route and Reset All keep the bus size picked with Bus Type; stops and times go back to the engine's. `locked` is not changed by a reset (documented) | None |
| 6a | Route Charges | `route_charges` with `per_bus: false` still lists runs and takes charges | BE bug **B** | Billed per bus = the year covering the date has **locked** Bus Fares with `payer: "bus"` (prototype `F.locked && payer === 'bus'`). Then `per_bus: true` (even with no rates: `rate: null`). Otherwise `{ per_bus: false, runs: [], unmatched: [], to_check: 0 }`. `POST /routes/:id/charges` and `PATCH /route_charges/:id` → `422` "The school is not billed per bus"; POST only on a route of an AM / PM plan in use (`422` "Route Charges are for runs of an AM or PM plan in use") | Hide the Route Charges card when `per_bus` is false |
| 6b | Route Charges › PATCH | `school_route_id` (route id?) undocumented | Doc gap + BE bug | It is the **route id** (`runs[].route_id`). Now checked: a route of an AM / PM plan in use (`422` "Pick a run of an AM or PM plan in use"), same session as the charge's run (`422` "Pick a run of the AM plan"). `status: "ok"` can go in the same call | Send `runs[].route_id` from the Move to run picker (same session only) |
| B1 | Run Routing | `routing_blocked` when no rider has a stop | BE bug **B** | The prototype runs anyway, so the guard is gone: the run goes, the plan has no routes and every rider is in `unassigned`. `422 routing_blocked` is no longer sent | Drop the `routing_blocked` handling |
| B2 | Run Routing | `routing_blocked` details are counts; engine `unassigned[]` has no label and `riders: [null]` for no-stop riders | BE bug **B** | `no_stop` / `conflicts` on the run (`GET /routing_runs/:id`) and on the plan (`routing_run`) are `[{ rid, name }]` (were rid strings). Rails sent the engine bare rids, so its no-stop / conflict entries had `riders: [null]` and no label: now `riders: [rid]`, `label` = name. `reason` stays a code (`RIDER_NO_STOP` …): label it with the prototype's `REASONS` (listed in the doc) | Read `{ rid, name }`; map `reason` codes to labels |
| B3 | Plans › hand edits | Hand edits send text in `unassigned` ("Removed by hand", one entry for several riders) | BE bug **B** | As the prototype: one entry per rider taken off (edit, route deleted, Reset Route): `{ gid: "rm:<rid>", riders: [rid], n: 1, reason: "ADMIN_REMOVED", label: <name> }` | Label `ADMIN_REMOVED` "Removed by admin" |
| B4 | Plans › New Route | `manual: true` but no "Manual" badge | BE bug | A route drawn by hand leads `badges` with `Manual` instead of `Edited` (prototype `res()`) | Show the chip from `badges` |
| B5 | Plans › Draw Routes | Drawn plan: `summary` / `params` null, `unassigned` does not list undrawn riders | BE bug | As `createManualPlan`: `POST /schools/:id/plans { session, date }` sets `effective_from` = Plan For `date` (default today); `unassigned` = riders by stop (`NOT_ROUTED`, label = stop code) + no-stop / conflict riders (`RIDER_NO_STOP` / `RIDER_IN_CONFLICT`, label = name); `summary` of no routes; `params` = engine defaults + company's + session. `422` "Date must look like 2026-11-02" | Send `date` (Plan For); show the Unassigned list right away |

## 10/11/2026 — Stops and assignments (API-ISSUES §22 Stops, phase Q2)

Doc: [school-bus-stops.md](school-bus-stops.md). **B** = breaking.

| # | Where | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | Stops › Unlink (`DELETE /schools/:id/stops/:stop_id`) | **B** `204` → `200 { data: { unassigned: n } }`; riders assigned to the stop's points are unassigned in the same transaction | Parse the body; show "n riders unassigned" |
| 2 | Stop Library › Archive (`DELETE /stops/:id`) | **B** `204` → `200 { data: { unassigned: n } }`; assignments left on its points (old unlinks) are removed | Parse the body |
| 3 | Select Links › Remove (`POST /schools/:id/rider_links/remove`) | **B** `204` → `200 { data: { unassigned: n } }`; a rider assigned to a removed point is unassigned (prototype `removeLinks`) | Parse the body; "n riders unassigned" |
| 4 | `GET /schools/:id/stops`, `PUT …/stops/:id` | `stop.subzone { code, name, planning_area }` added (same as `GET /stops`) | Read it from there |
| 5 | Ask for Photos (`POST /stop_photo_requests`) | `rid` accepted for `audience: parent` (`school_rider_id` still works) | Send `rid` from Stop Assignment |
| 6 | CSV exports | `Content-Disposition` is exposed to the browser (CORS) | Read the file name from the header |

## 10/11/2026 — Bus Fares and Extra Charges (API-ISSUES §22 Fares, phase Q1)

Doc: [school-bus-money.md § 1–3](school-bus-money.md#1-bus-fares). **B** = breaking.

| # | Where | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | Bus Fares › zones, surcharges | **B** `area` (one polygon, kept only as a JSON string) → `areas: [{ latlngs: [[lat, lng], …], exclude }]` on each tier and surcharge, in and out; several outlines and cut-outs (`exclude: true`), like a stop's catchment. Sending `area` → 422 | Send and read `areas`; Draw Area edits the list (add / cut-out) |
| 2 | Bus Fares › Save & Lock | **B** Tiers / zones and surcharges are kept by `id`: send back each row's `id` from `GET` (new rows without one). Before, every save gave new ids, so Extra Charges lost their tiers. Surcharges now carry `id` too. A tier an Extra Charge targets cannot be removed (422 "Tier 2 is used by the Extra Charge "Toll". Keep it, or remove it from that charge first") | Keep `id` in the wizard draft; "Copy AY X Fares" comes without ids (new rows) |
| 3 | Bus Fares › 422 | `error.details: { step, step_name }` on the wizard checks (0 Who Pays, 1 Billing, 2 Fares / Bus Rates, 3 Services, 4 CCA / ASA) | Jump to that step on Save & Lock |
| 4 | Bus Fares | New `POST /academic_years/:id/fares/preview` (draft, nothing saved): `periods` with school days from the calendar now, `fares`, `problem` (first failing check with its step or `null`) | Use it for each step's numbers before Save & Lock (school days per bill, the fare table) |
| 5 | Bus Fares › Bus Rates | New `plan_runs: { "<bus_type>": n }` (runs in the AM and PM route plans in use) and `bus_types[].student_seats`; Operator Pay `rates[].student_seats` too | "3 runs in the route plans" / "Not in the route plans", "45 seats, 44 for students", price per student seat |
| 6 | Bus Fares | Money in `fares` and the table's fares now has 2 decimals ("420.00", was "420.0") | None if parsed as numbers |
| 7 | Extra Charges | **B** `targets` (strings: tier ids, `"bus:<type>"`) → `tier_ids: [int]` and `bus_types: [string]`, in the body and the row. Sending `targets` → 422 | Send / read `tier_ids` (riders pay) or `bus_types` (school pays per bus) |
| 8 | Extra Charges › preview | The preview now uses the first picked tier / bus size (it used the first tier when the id was a number). Adds `meta.example` ("0 to 3 km, 2-way rider"); amounts with 2 decimals | Show `meta.example` above the table |
| 9 | Extra Charges › checks | **B** (wording) Messages follow the form: "Give the charge a name", "Enter an amount above 0", "Percentage must be 100 or less" (a 150% charge was accepted), "Pick the start month" (was "Pick the first month"), "Bills before this month are already raised. Pick this month or later" (was "The first month cannot be in the past"), "No bill is raised in that month" (one-off in a month with no bill: was saved with a warning, now 422), "End month must be on or after the start month". `meta.warning` for a charge over months with no bill reads "No AY 2027 bills fall between February 2027 and May 2027" | Show the message as is |
| 10 | Extra Charges | `value` has 2 decimals ("5.00") | None |

## 10/11/2026 — Answers to API-ISSUES §25 (Route Plans, Dashboard, Finance, Year Setup, Stops)

Every §25 item is answered below: **BE bug** (fixed), **Doc gap** (API right, doc fixed), **FE answer**, **Not valid**.
**B** = breaking (a value or shape the front end may read differently). 7 BE bugs, 6 doc gaps, 3 FE answers, 2 not valid.

| # | Where | Your claim | Class | Answer / what changed | Front-end |
| --- | --- | --- | --- | --- | --- |
| 1 | Route Plans › Optimise | `POST /routes/:id/optimise`, `/plans/:id/optimise` → 422 "no /optimise" | Not valid | The route exists in the routing service (`routing-service/server.js`, added with the 04/11 commit; covered by its tests). Your routing container runs an older image | Deploy the routing service (`bin/routing-image && bin/kamal accessory reboot routing`); nothing to change in the app |
| 2 | Run Routing | `progress` null while running | FE answer | `null` while `running` means the routing service has no entry yet (just started or restarted); documented in school-bus-routes.md. Small runs end in about 0.2 s | Keep polling; show "Estimating…" while `null` |
| 3 | Route Plans › Estimate | `margin_pct` is a string | BE bug **B** | Now a number with 1 decimal (`null` when revenue is 0), as the doc said. Same for School Dashboard › Finance `kpis.margin_pct` | Stop parsing it as a string |
| 4 | Route Plans › Replacement Buses | Own regular bus → 201 with an empty list | Doc gap | By design, as the prototype ("Back on its regular bus"): the dates are cut out of replacements and nothing is added | An empty list is not an error; show "Back on its regular bus" |
| 5 | Dashboard | `PATCH /dashboard/layout` sets `saved: true` | Doc gap | `saved` = a layout is stored for the user; the first PATCH stores the default pages with the period / page. Only `DELETE` resets. `page` is an index | None; documented |
| 6 | Dashboard › Clients at Risk | Reasons lose the sign | BE bug | Reasons read "On time 91.0% (+0.7 pts)" / "(-2.1 pts)" | Show as is |
| 7 | Live Map | `last_run.school` undocumented | Doc gap | `last_run` carries `school` like `next_run` (`null` unless a School Bus route) | Optional "School Route \| <school>" |
| 8 | Finance › Operator Payments | Total -30.0, left 0, status paid | BE bug **B** | Batch operator `status` is `nothing_to_pay` when its total is 0 or less (deductions only) and nothing was paid; `paid` only for a positive total fully paid. `total` / `paid` / `left` are always decimals (were Integer 0 when empty) | Add the chip "Nothing to Pay"; no Pay / Mark Paid for it |
| 9 | Vehicle Financials | `due_this_month` "0.0" vs number 0 | BE bug | A vehicle with no loan details now answers "0.0" like the others | Parse as the other money values |
| 10 | Client Invoices | `cancelled_hours_before` 0 after the start | FE answer | Never below 0, as the prototype (`Math.max(0, …)`) | Show "cancelled 0 h before" |
| 11 | Vehicle Financials | No "create vehicle" from a loan schedule | Doc gap | The pieces exist: read `result` has plate / make / model / chassis / engine / registered_on. Recipe added to finance.md | `POST /vehicles` (Edit Vehicle pre-filled), then `PATCH /finance/vehicles/:id { document_read_id }` |
| 12 | Operator Payments › Requests | Items have no id | BE bug | Items add `item_id` (manual items, `source: item`; else `null`); `ref` stays opaque | `DELETE /finance/operator_pay/items/:item_id`, do not parse `ref` |
| 13 | Year Setup › Bus Attendants | `PATCH {}` saves and locks | BE bug **B** | An empty body is `422` "Send needs, sizes or provided_by"; nothing is saved or locked | Send the form values on Save & Lock |
| 14 | Stop Library | `GET /stops` has no `meta.subzones` | Doc gap | Each row carries `subzone { code, name, planning_area }`; the doc line is fixed | Read `data[].subzone` |
| 15 | Stops › Import | Answer `state` null | Not valid | The answer is `{ data: { added } }`; there is no `state` field and the doc matches | If another field was meant, tell us which call |
| 16 | Year Setup › Bus Attendants | `routes[].bus_type` null on St. Stephen's | BE bug (seed) | The seeded routes now get a type from the regular bus seats (re-run `bin/rails db:seed`); engine routes always have one. A hand-made route may still be `null`: it needs no attendant (documented) | Count `null` as "no BA needed" |
| 17 | Stops › Photo Requests | Is To Review part of Open? | FE answer | Yes, as the prototype: To Review = open requests with a photo waiting, so the Open count includes them | Keep both counts from `meta.counts` |
| 18 | Stops › Photo Requests | Ask for photos on an archived stop's point → 404 | Doc gap | By design: an archived stop is out of the library, so its points are not found | Hide Request Photo for archived stops |

## 10/11/2026 — Scheduler (API-ISSUES §26)

No breaking changes (**B** = none).

| # | Where | API | Front-end |
| --- | --- | --- | --- |
| 1 | Scheduler grid, drawer | `driver.photo` (thumb link or `null`) on `vehicles[].driver` and run `driver` | Show the photo on each row and in the drawer; stop reading `GET /drivers` for it |
| 2 | Scheduler grid | `client_name` on every run (was only in the Trips list) | Card line "TID \| client"; stop looking it up in `GET /clients` |
| 3 | Trip form | `GET /trips/next_number` → `{ data: { trip_id } }`, reserves nothing | New Trip header; informational, use the create answer's `trip_id` |
| 4 | Drawer "Replace Driver" / "Use Regular Driver" | No API change: `POST /replacements` kind `drv`, scope `run` (`trip_id`, `run_date`, `slot_no`, `driver_name`, `driver_phone`); delete it to use the regular driver | Post the run-scope replacement from the drawer. A run replacement has no dates; "Temporary driver dd/mm to dd/mm" is a range replacement on the bus |
| 5 | Scheduler grid | `route_stops: [{ name, address }]` on every run, in travel order (`[]` for School Bus route runs); `route_text` unchanged | Build "A > +N > B" with `routeSum` / `street(name, address)`; the BE has no street field |

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
