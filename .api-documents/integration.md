# Integration Guide — start here

**For the AI assistant (and developers) building the Convoy OS front end against the Convoy V3 API.** Building the
**Convoy Driver** phone app? Start at [driver/README.md](driver/README.md) instead (its own sign-in, conventions and
screen map); the shared rules in `README.md` apply to both.
This is the entry point of the API docs: read it fully first. It holds what applies to every screen and tells you which
other file and section to open for each task. It does not repeat them: open them when it points you there.

The API docs in this folder are the source of truth. Do not invent endpoints, params or fields that are not in them.

---

## 1. The files in this folder

| File | What it is | When to open it |
| --- | --- | --- |
| `integration.md` | This guide: the rules and the way around the other files | First, always |
| `README.md` | Conventions for every endpoint: sign-in, response and error format, paging, `lock_version`, files, background reads, runs | Before building the shared API client (section 4) |
| `screen-map.md` | Every screen and button of Convoy OS → API call → doc section | For each screen you build: find it here first |
| `scheduler.md` | Scheduler and everything it opens (drawer, trip form, Edit Vehicle, Replace, Maintenance, Notice, calendars) | When `screen-map.md` links to it |
| `trips.md` | Trips, Trip History, Notices, Bookings, Rate Cards | When `screen-map.md` links to it |
| `fleet.md` | Vehicles, Drivers, Bus Attendants, External Vehicles, Fuel & Energy, Maintenance, Vehicle Types, Transport Operators | When `screen-map.md` links to it |
| `settings.md` | Company Settings, Users, Calendars, the Profile dialog | When `screen-map.md` links to it |
| `clients.md` | Managed Clients (record page, sites, Client Users) and the Client Portal sign-in | When `screen-map.md` links to it |
| `hr.md` | HR: driver pay (rate plans, pay schemes, drivers, earnings, bonuses, points, rewards, simulator, audit log) | When `screen-map.md` links to it |
| `convoy-admin.md` | Convoy Admin: Transport Companies, Message Terms, Discover, Company Leads | When `screen-map.md` links to it |
| `dashboard.md` | Dashboard: widgets, layout, figures | When `screen-map.md` links to it |
| `reports.md` | Reports: the Shuttle Report | When `screen-map.md` links to it |
| `school-bus-setup.md` | School Bus: Schools, Riders, Year Setup (part 1) | When `screen-map.md` links to it |
| `school-bus-money.md` | School Bus: Bus Fares, Extra Charges, Policy, Payment Methods, Operator Pay | When `screen-map.md` links to it |
| `school-bus-stops.md` | School Bus: Stop Library, catchments, Stop Assignment, photo requests | When `screen-map.md` links to it |
| `school-bus-routes.md` | School Bus: Run Routing, plans, hand edits, Adopt, route money, Feasibility Studies | When `screen-map.md` links to it |
| `school-bus-parents.md` | School Bus: Families, Registration, Bus Service Requests (Route Fit, first invoice, plan versions), alerts, CCA Rides | When `screen-map.md` links to it |
| `school-bus-finance.md` | School Bus: Family Bills, Collections, Documents, statements, school operator pay runs; Finance › School Bus Collections | When `screen-map.md` links to it |
| `school-bus-live.md` | School Bus: School Dashboard (Operations, Finance), Live Ops (session, one run) | When `screen-map.md` links to it |
| `ops-control.md` | Ops Control: board, rules, Acknowledge, Alert Log | When `screen-map.md` links to it |
| `live-map.md` | Live Map: board, one bus, Trace, Replay | When `screen-map.md` links to it |
| `finance.md` | Finance: client invoices, documents, operator payments, vehicle financials, finance settings | When `screen-map.md` links to it |
| `convoy-v3-api.openapi.json` | OpenAPI 3.0 of every endpoint with request / response examples recorded from real calls (2.4 MB) | For the exact shape of a request / response (section 1.1) |

UI reference: the prototype `Convoy OS.dc.html` (and its `logic/*.js`). Use it for **layout, labels, flows and behaviour
only**. Its data structures are not the API's (section 5).

### 1.1 How to look something up

| You need | Where |
| --- | --- |
| Which call a button makes | `screen-map.md` → the row of the screen and button |
| Params, which field shows where, when a button is shown, confirm texts, error messages | The doc section the row links to (read the whole section) |
| The exact response / request shape of an endpoint | The doc section if it shows one; otherwise the endpoint's example in `convoy-v3-api.openapi.json` |
| Enum values and their labels | The Values reference sections (section 5.1) |
| How errors, paging, files, auth work | `README.md` (section 4) |

`convoy-v3-api.openapi.json` is large: **do not read it whole**. Search it for the path and read only that operation,
e.g. `"/vehicles/{id}": {` (paths are relative to `/api/v1`, ids written `{id}`, `{vehicle_id}`). Each operation has the
`summary`, a `description` copied from the doc section, `parameters`, `requestBody.example` and the response `example`.
Examples come from test and seed data (names like `user111@example.com`): use them for shape, not for values.

**Worked example: the Vehicles page.**
1. `screen-map.md` → Fleet → Vehicles: "The list, team chips, search, sort" → `GET /vehicles?ownership[]=own` → fleet § 1.1.
2. fleet § 1.1 gives the params (`ownership[]`, `team_id`, `q`, `sort`), the row fields, the insurance text rule and
   `meta.facets.teams` for the chips.
3. For the full row shape, search the OpenAPI file for `"/vehicles": {` → `get` → `responses.200` example.
4. "Manage Teams" → `PUT /vehicle_teams/bulk` → fleet § 1.2 (body, delete confirm text, 422 messages). Build, then check on staging.

---

## 2. Environments and test accounts

| | Base URL |
| --- | --- |
| Staging | `https://convoy-api-staging.convoy.sg/api/v1` |
| Local | `http://localhost:3000/api/v1` |

Put the base URL in environment config, never hard-code it. Staging accepts browser calls from any `localhost` port.

| Account | Password | Role |
| --- | --- | --- |
| `ops@simpledrive.sg` | `Simple123!` | Admin (every permission, company owner) |
| `dispatch@simpledrive.sg` | `Simple123!` | Member (only some permissions: test hidden / disabled actions with it) |
| `finance@simpledrive.sg` | `Simple123!` | Member with finance (HR, but can't Unlock / Reopen Month) |
| `admin@convoy.sg` | `Convoy123!` | Convoy Admin (Convoy staff: picks a company; company data is view only, see [README § Signing in](README.md#signing-in-bearer-token)) |
| `priya.raman@google.com` | `Portal123!` | **Client Portal** only (`/portal/session`): user of two clients (account picker) |

---

## 3. Work order

1. **Build the shared API client first** (section 4). Every screen uses it; no screen calls `fetch` on its own.
2. Then build screens one at a time (section 7).
3. Check every screen against staging with real calls before calling it done.

---

## 4. The shared API client (build once)

Read [README.md](README.md#base-url-and-format) fully, then build one client module that every screen uses. It must do all of this:

| # | The client must | Details |
| --- | --- | --- |
| 1 | Sign in with `POST /session`, keep `data.token` and send `Authorization: Bearer <token>` on every request; on any `401` drop the token and go to sign-in; no cookies | [README § Signing in](README.md#signing-in-bearer-token) |
| 2 | Load `GET /session` on start: user `role` / `permissions` (show or hide menus and buttons), company `date_format` / `time_format` / theme; Convoy Admin picks a company with `PATCH /session` | [README § Signing in](README.md#signing-in-bearer-token) |
| 3 | Unwrap `{ data }` and lists `{ data, meta }`; page with `?page=&limit=`; pass extra `meta` (counts, facets, horizon) to the screen | [README § Responses](README.md#responses) |
| 4 | Turn `{ error: { code, message, details } }` into one error type: show `message` as is, map `details` to form fields on `422`, reload on `409`, wait `Retry-After` seconds on `429` | [README § Errors](README.md#errors), [Rate limits](README.md#rate-limits) |
| 5 | Send back `lock_version` when saving trips and runs | [README § Optimistic locking](README.md#optimistic-locking-lock_version) |
| 6 | Upload with `multipart/form-data`; prefix the API host to file `url` / `thumb_url` (signed, 1 hour, no auth header) | [README § Files](README.md#files-uploads-and-downloads) |
| 7 | One helper for background reads: create, poll every 2–3 s until `done` / `failed`, save with `document_read_id` | [README § Reading documents](README.md#reading-documents-with-claude-background-reads) |
| 8 | Keep the Scheduler within `meta.horizon` (today + 120 days) | [README § Runs](README.md#runs-occurrences) |
| 9 | Parse values by the formats of [README § Base URL and format](README.md#base-url-and-format): money / decimals / coordinates are strings, times "HH:MM" (`ends_next_day`), dates "YYYY-MM-DD" | [README § Base URL and format](README.md#base-url-and-format) |

Keep the token only in the auth module (memory / `localStorage` on web, Keychain / Keystore on mobile).

---

## 5. Mapping the prototype to the API

### 5.1 Map by what the screen shows, not by the prototype's variables

The prototype's JS uses short internal names and display values (`t.stby`, `t.sched`, `t.asg`, `v.vt`, `v.dph`,
`t.kind === 'Disposal'`). The API uses different, explicit names and machine values (`kind: "disposal"`).
**Never translate prototype variables into API fields.** Instead:

1. Look at the **label on the screen** (column header, form label, badge, button) in the prototype.
2. Find that screen in `screen-map.md`, open its doc section.
3. Use the field the doc gives for that label. Field tables to use:

| Screen | Label → field table |
| --- | --- |
| Scheduler grid (runs, vehicles, unassigned tray) | [scheduler § 1](convoy-os/scheduler.md#get-scheduler) |
| Trip drawer | [scheduler § 5.1](convoy-os/scheduler.md#51-open-a-run-get-occurrencesid) |
| Trip form: every field, stops, vehicles, timings | [scheduler § 7.3](convoy-os/scheduler.md#73-trip-fields-trip), [§ 7.4](convoy-os/scheduler.md#74-nested-lists-send-the-whole-list-existing-rows-with-id-_destroy-true-to-remove) |
| Replace dialog fields | [scheduler § 9.2](convoy-os/scheduler.md#92-save) |
| Trips page columns | [trips § 1](convoy-os/trips.md#get-occurrenceslist) |
| Notices page columns and buttons | [trips § 2](convoy-os/trips.md#get-notices) |
| Rate card view / edit | [trips § 3](convoy-os/trips.md#view--edit--get-rate_cardsid) |
| Booking details, approval texts | [trips § 4](convoy-os/trips.md#booking-details--get-bookingsid), [approve / reject](convoy-os/trips.md#approve-reject-and-the-clients-steps) |
| Trip History list and record | [trips § 5](convoy-os/trips.md#list--get-trip_history), [record](convoy-os/trips.md#record--get-trip_historyid) |
| Vehicles list row, vehicle record | [fleet § 1.1](convoy-os/fleet.md#11-list-get-vehicles), [§ 1.3](convoy-os/fleet.md#13-vehicle-record-get-vehiclesid) |
| Drivers tabs and row buttons | [fleet § 2.1](convoy-os/fleet.md#21-tabs-get-driversstatusactive), [§ 2.3](convoy-os/fleet.md#23-row-buttons) |
| Managed Operators row | [fleet § 3.1](convoy-os/fleet.md#31-list-get-operatorsqkind_eqmanaged) |
| External Vehicles columns | [fleet § 4.1](convoy-os/fleet.md#41-list-and-slots) |
| Vehicle Types table | [fleet § 5.1](convoy-os/fleet.md#51-table-get-vehicle_types) |
| Maintenance list row | [fleet § 7.1](convoy-os/fleet.md#71-list-get-maintenance_visitstabupcoming) |
| Fuel log, cards, alerts | [fleet § 8](convoy-os/fleet.md#8-fuel--energy) |

4. Enum values and their screen labels: [scheduler § 17 Values reference](convoy-os/scheduler.md#17-values-reference) and
   [fleet § 9 Values reference](convoy-os/fleet.md#9-values-reference). Labels come from these tables or from the `*_label`,
   `*_name`, `*_text` fields the API already sends. Do not rebuild them from the prototype's code.
5. A label with no field anywhere in the docs: **stop and report it** (section 9). Do not guess a field.

### 5.2 Prototype pages → API

The prototype's page ids (in `logic/mixins/admin.js`, rail and sub-menus) and where their API is. The first column is a
**page id, not a permission** (e.g. `feas` is the Feasibility page; its permission is `plans`; the prototype's `costs`
page always opens the School Dashboard, so Route Costs live on the School Dashboard's Finance tab):

| Prototype page id | Screen | API resource | Doc |
| --- | --- | --- | --- |
| `scheduler` | Scheduler | `/scheduler`, `/occurrences` | [screen-map](convoy-os/screen-map.md#scheduler) |
| `trips` | Trips | `/occurrences/list` | [screen-map](convoy-os/screen-map.md#trips-page) |
| `triphist` | Trip History | `/trip_history` | [screen-map](convoy-os/screen-map.md#trip-history) |
| `notices` | Notices | `/notices`, `/notice_templates` | [screen-map](convoy-os/screen-map.md#notices) |
| `bookings` | Bookings | `/bookings`, `/booking_trips`, `/booking_notifications` | [screen-map](convoy-os/screen-map.md#bookings) |
| `rates` | Rate Cards | `/rate_cards`, `/rate_card_assignments` | [screen-map](convoy-os/screen-map.md#rate-cards) |
| `vehicles` | Vehicles | `/vehicles`, `/vehicle_teams` | [screen-map](convoy-os/screen-map.md#vehicles) |
| `drivers` | Drivers | `/drivers` | [screen-map](convoy-os/screen-map.md#drivers) |
| `attendants` | Bus Attendants | `/attendants` | [screen-map](convoy-os/screen-map.md#bus-attendants) |
| `extveh` | External Vehicles | `/vehicles?ownership[]=external`, `/vehicles/external`, `/external_share_link`, `/external_vehicle_submissions` | [screen-map](convoy-os/screen-map.md#external-vehicles) |
| `fuel` | Fuel & Energy | `/fuel_entries`, `/fuel`, `/fuel_alerts`, `/fuel_companies` | [screen-map](convoy-os/screen-map.md#fuel--energy) |
| `maint` | Maintenance | `/maintenance_visits`, `/workshops` | [screen-map](convoy-os/screen-map.md#maintenance) |
| `vtypes` | Vehicle Types | `/vehicle_types`, `/vehicle_type_requests` | [screen-map](convoy-os/screen-map.md#vehicle-types) |
| `subcons` | Managed Operators | `/operators`, `/banks` | [screen-map](convoy-os/screen-map.md#transport-operators) |
| `opveh` | Operator Vehicles | `/vehicles?ownership[]=managed`, `/operator_drivers/assign_preview` | [screen-map](convoy-os/screen-map.md#transport-operators) |
| `opdrv` | Operator Drivers | `/operator_drivers` | [screen-map](convoy-os/screen-map.md#transport-operators) |
| `clients` | Managed Clients | `/clients`, `/clients/:client_id/sites`, `/clients/:client_id/users`, `/client_users/roles` | [screen-map](convoy-os/screen-map.md#clients) |
| `coset` | Company Settings | `/companies/:id`, `/countries`, `/country_requests` | [screen-map](convoy-os/screen-map.md#company-settings) |
| `users` | Users | `/users` | [screen-map](convoy-os/screen-map.md#users) |
| `phol` | Calendars | `/calendars`, `/public_holidays` | [screen-map](convoy-os/screen-map.md#calendars) |
| Account menu → Profile | Profile dialog | `/profile` | [screen-map](convoy-os/screen-map.md#sign-in-and-app-shell) |
| `paydrv`, `payearn`, `payschemes`, `payrates`, `paybon`, `paypts`, `payrew`, `paysim`, `paylog` | HR pages | `/pay/...` | [screen-map](convoy-os/screen-map.md#hr) |
| `companies`, `terms`, `discover`, `leads` | Convoy Admin pages | `/companies`, `/message_terms`, `/discover/...`, `/leads` | [screen-map](convoy-os/screen-map.md#convoy-admin) |
| `codash` | Dashboard | `/dashboard`, `/dashboard/widgets`, `/dashboard/layout` | [screen-map](convoy-os/screen-map.md#dashboard) |
| `reports` | Reports (Shuttle Report) | `/reports/shuttle/...` | [screen-map](convoy-os/screen-map.md#reports) |
| `schools`, `school`, `levels`, `calendar`, `holidays`, `sessions`, `baset`, `fares`, `policy`, `pay`, `aysum`, `setup` | School Bus: Schools & Year Setup | `/schools`, `/academic_years` (+ `/fares`, `/extra_charges`), `/schools/:id/policy`, `/payment_methods`, `/operator_pay` | [screen-map](convoy-os/screen-map.md#school-bus-schools--year-setup) |
| `plans`, `feas` | School Bus: Route Plans, Feasibility Studies | `/routing/settings`, `/schools/:id/routing_runs`, `/schools/:id/plans`, `/plans/:id`, `/routes/:id`, `/feasibility_studies` | [screen-map](convoy-os/screen-map.md#school-bus-schools--year-setup) |
| `families`, `reg`, `applications`, `cca` | School Bus: Families, Registration, Bus Service Requests, CCA Rides | `/schools/:id/families`, `/families/:id`, `/academic_years/:id/registration`, `/schools/:id/bus_requests`, `/bus_requests/:id`, `/bus_requests/alerts`, `/schools/:id/cca_rides` | [screen-map](convoy-os/screen-map.md#school-bus-schools--year-setup) |
| `library`, `assign` | School Bus: Stop Library, Stop Assignment | `/stops`, `/schools/:id/stops`, `/schools/:id/stop_assignment`, `/stop_photo_requests` | [screen-map](convoy-os/screen-map.md#school-bus-schools--year-setup) |
| `opsctl` | Ops Control | `/ops_control`, `/ops_control/log`, `/ops_control/runs/:id/acknowledge` | [screen-map](convoy-os/screen-map.md#ops-control) |
| `livemap` | Live Map | `/live_map`, `/live_map/vehicles/:id`, `/live_map/runs/:id/track` | [screen-map](convoy-os/screen-map.md#live-map) |
| `cinv`, `cfdocs`, `cfpay`, `vehfin`, `finset` | Finance pages | `/finance/...` | [screen-map](convoy-os/screen-map.md#finance) |
| `cfcol` | Finance › School Bus Collections | `/finance/school_collections` | [school-bus-finance § 6](convoy-os/school-bus-finance.md#6-company-finance-pages) |
| `dashboard`, `liveops` | School Bus: School Dashboard, Live Ops | `/schools/:id/dashboard` (+ `/finance`), `/schools/:id/live`, `/schools/:id/live/runs/:id` | [school-bus-live](convoy-os/school-bus-live.md) |
| `opconn`, `clconn`, and every other page | Connected Operators / Clients | **No API yet** | [screen-map](convoy-os/screen-map.md#not-built-yet) |

### 5.3 Value formats

Keys are `snake_case`; the value formats (strings for money, "HH:MM", dates, timestamps, tags, run `key`) are in
[README § Base URL and format](README.md#base-url-and-format) and section 4 row 9. Display dates and times in the company's
`date_format` / `time_format`; the only server-formatted text is human sentences (warnings, summaries).

---

## 6. TypeScript types

Generate request / response types from `convoy-v3-api.openapi.json` if it helps (the examples are real responses).
When the OpenAPI file and the `.md` docs disagree, **the `.md` docs win** (the OpenAPI schemas are inferred from examples,
so a field that was always empty in the examples may be typed loosely).

---

## 7. For each screen

1. Find the screen and each of its buttons in `screen-map.md`. Open every linked section and read it fully: params,
   response fields, when a button is shown or disabled, confirm texts, error messages. When the section shows no response
   shape, take it from the endpoint's example in the OpenAPI file (section 1.1).
2. Map fields as in section 5. Use the texts the API sends (warnings, labels, summaries, `error.message`) instead of
   writing your own.
3. Wire the calls through the shared client. After a write, use the response (most writes return the updated record) or
   reload the list the doc names.
4. "FE only" in the map = no API call. A screen under [Not built yet](convoy-os/screen-map.md#not-built-yet) has no API: build
   the UI on a mock module named clearly (e.g. `mocks/dashboard.ts`) and say so.
5. Check against staging with real calls. Test as Admin and as Member (hidden / disabled actions), and a write as
   Convoy Admin (must show the `403` message).

---

## 8. Rules that are easy to miss

- Do not let users browse or act past `meta.horizon` on the Scheduler (grey out those days, stop the › button).
- Send `lock_version` when saving trips and runs; handle `409`.
- Never compute prices, statuses, chip counts or labels that the API already returns.
- Lists can be long: always page or filter as the doc says; do not fetch everything with a huge `limit`.
- Signed file links expire after 1 hour: reload the record, do not cache the link.
- Never render user-typed text as HTML.

---

## 9. When the API and the docs disagree

Do not work around it silently. Stop and write a short report for the backend team:

```
Endpoint: PATCH /occurrences/123/time
Sent:     { "scope": "today", "start_time": "08:20" }
Got:      422 { "error": { "message": "..." } }
Doc says: scheduler.md § 5.2 — expected 200 with the run
```

Also report a label on a prototype screen that has no field in the docs, and a screen action missing from `screen-map.md`.

---

## 10. Keeping up to date

This folder comes from the API repo (`kevin-simplelabx/convoy-v3-api`, branch `v3`, folder `.api-documents/`). When the
API changes, the backend updates the `.md` files and regenerates `convoy-v3-api.openapi.json` in the same change.
Replace your copy of the whole folder (do not edit it in the front-end repo), and re-import the OpenAPI file in Apidog
(Overwrite).
