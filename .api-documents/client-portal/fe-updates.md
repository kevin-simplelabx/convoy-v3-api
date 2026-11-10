# Client Portal — answers and changes for the front-end

Answers to the front-end's findings (API-ISSUES.md) about the Client Portal, and the changes the Portal front-end has to
make. Newest first. Each row: the claim, the class, the answer and, for a BE bug, what changed.
Class: **BE bug** (fixed), **Doc gap** (documented now), **FE answer** (works as designed), **Not valid**. **B** = breaking.

## 10/11/2026 — Portal Map, Home, Luggage, §21 (phase Q11)

Docs: [map.md](map.md), [home.md](home.md), [bookings.md](bookings.md), [approval-flows.md](approval-flows.md),
[shell.md](shell.md), [settings.md](settings.md). 18 findings (rows 4–21): 9 BE bugs, 5 doc gaps, 3 FE answers, 1 not valid; 2 of the fixes are breaking (rows 1–3).

### What the front-end must change (breaking)

| # | Where | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 **B** | `GET /portal/map/runs/:id` (School Bus run) | `stops[].riders` → `stops[].students` | Read `students` (the list in the doc). Convoy OS Live Ops keeps `riders` |
| 2 **B** | `GET /portal/bookings/:id` trips | `luggage { cabin, medium, large, extra_large, oversized }` → flat `luggage_cabin`, `luggage_medium`, `luggage_large`, `luggage_extra_large`, `luggage_oversized` | Read the flat fields, the same names as the request |
| 3 | `POST /portal/bookings`, `POST /portal/bookings/estimate` | a nested `luggage` object was dropped silently → `422` code `luggage_flat` | Send the flat fields (the booking form of Convoy OS); never a `luggage` object |

### §21 Client Portal (2026-11-04), item by item

| # | FE claim | Class | Answer / what changed |
| --- | --- | --- | --- |
| 4 | Booking detail `own_way_back` is null (trips doc: boolean) | **BE bug** | Not null in Convoy OS (always a boolean), but the Portal detail never sent the field: the trips doc is the Convoy OS one. Now sent on every trip: `true` when the way back has its own points, else `false` (`false` for non-Two-Way trips) |
| 5 | Map: Bookings / Shuttles runs are `ad_hoc` and have no kind label (map.md lists only `corporate_shuttle`) | **BE bug** | Every run has `kind_label` in the prototype's words: "Ad Hoc / Charter", "Ad Hoc / Charter, Two Way", "Two Way, return", "Airport Transfer", "Disposal", "Shuttle, morning", "Shuttle, evening", "School bus, morning / afternoon / CCA". `kind` is any trip kind; map.md updated |
| 6 | Map: Google's runs have `site: null` though the client has 2 sites | **BE bug** | `site` was only the trip's own site. Now the trip's site, else the first stop site the person covers (the site picked wins) |
| 7 | Map: PM activity `on_road: 3` while all 3 runs `scheduled`, `counts.on_the_way` 0, `position` null | **BE bug** | The pill was counted from a clock state (On the way from 30 min before) and the rows from the bus status. Both now come from the same rows. School Bus runs are `scheduled` → `started` → `ended` (no On the way); documented |
| 8 | Map: a run went started → ended with no `arrived_at` / `departed_at` on any stop | **FE answer** | By design: with no Driver app events a run is `started` at its start and `ended` at its planned end by the clock. Stop times are filled only from the Driver app. Documented |
| 9 | Map: Bookings runs are `ended` with `bus: null` | **FE answer** | A run nobody has assigned a bus to still ends by the clock; `bus: null` = "No bus assigned yet. Ask <company>". Same for School Bus runs (`bus: null` without a plate) |
| 10 | School Bus `GET /map/runs/:id` has no `id`, `kind`, `title`, `state`, `state_label` | **BE bug** | Now merged from the list row: `id`, `kind`, `kind_label`, `title`, `school`, `bus`, `state`, `state_label` |
| 11 **B** | Students sit under `stops[].riders` (doc: `students`) | **BE bug** | Renamed to `students` in the Portal answer (row 1) |
| 12 | `position` is sent while the bus is not on the road | **BE bug** | School Bus detail sent the last ping whatever the state. Now only when `state` is `started` (trip runs already did this: `on_the_way` or `started`) |
| 13 | Home: Shuttle Runs Today says "N active routes" but the tile has no count | **BE bug** | The tile is `{ count, on_road, active_routes }`. `active_routes` = shuttle routes on the person's sites that have started and not ended today |
| 14 | Bookings: detail answers nested `luggage`, the request is flat; which does POST take? | **BE bug** | Flat both ways (rows 2, 3) |
| 15 | Bookings: Service For: `client_end_customer_id` only, or `service_for` too? | **Doc gap** | Send `client_end_customer_id`. `service_for` is optional free text; blank with a customer picked → the customer's name is stored. Documented |
| 16 | Bookings: no toast text for Accept Changes | **Doc gap** | The prototype says "Changes accepted". Documented |
| 17 | Flows: `DELETE .../rules/:id`: 200 + flow or 204? | **Doc gap** | `200` + the whole flow (never 204). Documented |
| 18 | Flows: a never-saved Otherwise has `when: null`, `position: 0`, `approved_automatically: true` | **Doc gap** | Correct: it has no rule yet (`id: null`, `steps: []`, nothing to approve). The full shape is in approval-flows.md |
| 19 | Users: `signed_in: true` with `last_sign_in_at: null` | **Not valid** | `signed_in` means "a password is set" (invitation, reset or seed), `last_sign_in_at` is the last real sign-in. Both can hold. Documented; show "Last sign-in" only when set |
| 20 | shell.md `/portal/me` example has no `client.brand` | **Doc gap** | The API sends `client.brand { logo, logo_ratio, color }`; the example now shows it |
| 21 | Billing: required `billing_email` / `attention` come as null on staging | **FE answer** | Required applies on save (PATCH 422). Data from Convoy OS or an import can still have none; show the fields empty. Attention is optional anyway. Documented |
