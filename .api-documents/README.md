# Convoy API — Front-end Guide

One API serves every Convoy app. This file and [integration.md](integration.md) are shared; each app has its own
folder with one document per menu, listing the screen actions and the API call behind each one.

| App | Folder |
| --- | --- |
| Convoy OS (operator web app) | [`convoy-os/`](convoy-os/) — menus below, screen map in [convoy-os/screen-map.md](convoy-os/screen-map.md) |

## Convoy OS

| Menu | Document |
| --- | --- |
| Scheduler (rail icon `calendar_view_week`) and everything it opens | [scheduler.md](convoy-os/scheduler.md) |
| Trips (rail icon `assignment`): Trips, Trip History, Notices, Bookings, Rate Cards | [trips.md](convoy-os/trips.md) |
| Fleet (rail icon `directions_bus`): Vehicles, Drivers, Bus Attendants, External Vehicles, Fuel & Energy, Maintenance, Vehicle Types, and Transport Operators (Managed Operators, Operator Vehicles, Operator Drivers) | [fleet.md](convoy-os/fleet.md) |
| Settings (rail footer icon `settings`): Company Settings, Users, Calendars, and the Profile dialog | [settings.md](convoy-os/settings.md) |
| Clients (rail icon `corporate_fare`): Managed Clients, Client Users, and the Client Portal sign-in | [clients.md](convoy-os/clients.md) |
| HR (rail icon `badge`): Drivers, Earnings, Pay Schemes, Rate Plans, Bonuses, Points, Rewards, Salary Simulator, Audit Log | [hr.md](convoy-os/hr.md) |
| Convoy Admin (Convoy staff only): Transport Companies, Message Terms, Discover, Company Leads | [convoy-admin.md](convoy-os/convoy-admin.md) |
| Dashboard (rail icon `dashboard`): the Company Dashboard (widgets, layout per user) | [dashboard.md](convoy-os/dashboard.md) |
| Reports (rail icon `insert_chart`): the Shuttle Report for clients | [reports.md](convoy-os/reports.md) |
| School Bus › Schools & Year Setup (rail icon `school`): schools, riders, academic years, holidays, levels, sessions, bus attendants | [school-bus-setup.md](convoy-os/school-bus-setup.md) |
| School Bus › Fares, Policy, Payment Methods, Operator Pay (Year Setup money steps) | [school-bus-money.md](convoy-os/school-bus-money.md) |
| School Bus › Stop Library & Stop Assignment | [school-bus-stops.md](convoy-os/school-bus-stops.md) |
| School Bus › Route Plans & Feasibility Studies | [school-bus-routes.md](convoy-os/school-bus-routes.md) |
| School Bus › Families & Riders, Bus Service Registration, Bus Service Requests, CCA Rides | [school-bus-parents.md](convoy-os/school-bus-parents.md) |
| School Bus › School Finance: Collections (Family Bills), Documents, Operator Payments (school pay runs) | [school-bus-finance.md](convoy-os/school-bus-finance.md) |
| School Bus › School Dashboard and Live Ops | [school-bus-live.md](convoy-os/school-bus-live.md) |
| Ops Control (rail icon `desktop_windows`): runs in the next 2 hours checked against rules, alerts, Acknowledge, Alert Log | [ops-control.md](convoy-os/ops-control.md) |
| Live Map (rail icon `map`): every bus now, its device, the run it is on, Trace and Replay | [live-map.md](convoy-os/live-map.md) |
| Finance (rail icon `account_balance`): Client Invoices, Documents, Operator Payments, Vehicle Financials, Finance Settings | [finance.md](convoy-os/finance.md) |

**Integrating the API (or asking an AI assistant to)?** Start with [integration.md](integration.md): it is the one
file to read first, and it points to everything else.

**Building a screen?** [screen-map.md](convoy-os/screen-map.md) maps every screen and button of the Convoy OS prototype to its
API call and the section that explains it.

Read the conventions below first; the menu documents do not repeat them.

**Apidog / OpenAPI:** [`convoy-v3-api.openapi.json`](convoy-v3-api.openapi.json) lists every endpoint (OpenAPI 3.0), one
folder per resource inside its menu, with the description of the section here that names it and request / response
examples recorded from the specs and the seed data. Import it in Apidog (Import → OpenAPI). It is generated, do not edit
it by hand: after an API change run `bin/rails api_docs:all` (specs + seed probe + build), or `bin/rails api_docs:openapi`
to rebuild from the last recorded examples.

---

## Base URL and format

- All endpoints live under `/api/v1`, for example `GET /api/v1/scheduler`.
- Request and response bodies are JSON (`Content-Type: application/json`), except file uploads (multipart, see below).
- Keys are **snake_case**: `start_time`, `vehicle_id`, `trip_label`.
- Dates are ISO `YYYY-MM-DD`. Times of day are `"HH:MM"` (24-hour) in requests and responses. A trip that ends after
  midnight still returns its end as `"HH:MM"` and sets `ends_next_day: true`.
- Timestamps (`starts_at`, `created_at`...) are ISO 8601 with the company's offset, for example `2026-11-02T07:45:00+08:00`.
- **Money, decimals and coordinates come back as strings**: `"price": "76.19"`, `"lat": "1.2722"`. Send them as numbers or strings.
- Display formats (company Date Format / Time Format) are the front end's job. The only server-formatted text is human
  sentences such as warnings and summaries, which already follow the company's formats.

## Signing in (Bearer token)

`POST /session` returns a token (JWT). Send it on **every** other request:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

- The token lasts **30 days** (`expires_at`); after that, or after sign-out, calls answer `401` and the app signs in again.
- Each sign-in is its own token (one per device or browser). Signing out ends only that token.
- No cookies are used. Web apps keep the token in memory or `localStorage` (never put user-typed HTML in the page);
  mobile apps keep it in the Keychain / Keystore.
- Cross-origin web front ends must be allowed by the server (`CORS_ORIGINS`; staging accepts any `localhost` port).

| Action | Call |
| --- | --- |
| Sign in | `POST /session` `{ "email": "...", "password": "...", "device_name": "iPhone 16" }` (`device_name` optional) |
| Who am I (on page load) | `GET /session` |
| Sign out (this token) | `DELETE /session` → `204` |
| Convoy Admin picks the company to view (for this token) | `PATCH /session` `{ "company_id": 1 }` |

`POST /session` response = the `GET /session` response below plus the token:

```json
{ "data": { "token": "eyJhbGciOiJIUzI1NiJ9...", "token_type": "Bearer", "expires_at": "2026-12-02T09:00:00+08:00",
            "user": { "...": "..." }, "company": { "...": "..." } } }
```

`GET /session` response:

```json
{
  "data": {
    "user": { "id": 2, "name": "SimpleDrive Ops", "display_name": null, "shown_name": "SimpleDrive Ops", "email": "ops@simpledrive.sg",
              "mobile": null, "mobile_display": null, "role": "admin", "role_label": "Super Admin", "owner": true,
              "permissions": ["users", "vehicles", "finance", "..."], "initials": "SO", "avatar": null, "status": "active", "company_id": 1 },
    "company": { "id": 1, "name": "SimpleDrive", "display_name": "SimpleDrive", "code": "SD", "country": "SG", "timezone": "Asia/Singapore",
                 "date_format": "dmy", "time_format": "24", "theme_color": "#0B6E6E", "logo": null, "observed_holidays": "off",
                 "business_units_enabled": false, "status": "active" }
  }
}
```

- `role`: `convoy_admin` (Convoy staff, **view only**: every write returns `403`), `admin` (every permission), `member` (only `permissions`).
  `owner` = Super Admin. Show `shown_name` (display name or name) in the top bar. Users and the Profile: [settings.md](convoy-os/settings.md).
- `company` is `null` for a Convoy Admin until `PATCH /session` picks one (per token: a new sign-in starts with none);
  company data then answers `422 "Pick a company first"`.
- Sample accounts (seed): `ops@simpledrive.sg` / `Simple123!` (Admin), `dispatch@simpledrive.sg` / `Simple123!` (Member, vehicles),
  `admin@convoy.sg` / `Convoy123!` (Convoy Admin).

## Responses

Success:

```json
{ "data": { "...": "..." } }
```

Lists are paged:

```json
{ "data": [ "..." ], "meta": { "page": 1, "limit": 50, "count": 132, "pages": 3 } }
```

- Paging: `?page=2&limit=100` (default limit 50, max 500).
- Some lists add more to `meta` (counts for filter chips and so on); each endpoint says so.
- Small lists (vehicle types, teams, holidays...) return every row without paging: `{ "data": [...], "meta": {} }`.
- Text filters on lists use ransack keys: `?q[name_i_cont]=goo` (case-insensitive "contains"). Each endpoint lists its filters.

## Errors

```json
{ "error": { "code": "invalid", "message": "Enter the drop-off point", "details": { "base": ["Enter the drop-off point"] } } }
```

| Status | `code` | When |
| --- | --- | --- |
| 400 | `bad_request` | A required parameter is missing (`message` names it) |
| 401 | `unauthorized` | No / bad / expired / signed-out token (`"Sign in to continue"`), or wrong email / password |
| 403 | `forbidden` | Not allowed. Convoy Admin gets `"View only. Convoy Admin cannot change company data"` |
| 404 | `not_found` | The record does not exist or belongs to another company |
| 409 | `conflict` | Someone else changed the record (see `lock_version`) |
| 410 | `gone` | A public tracking link has closed |
| 422 | `invalid` / `unprocessable_content` | Validation failed or a business rule was broken; `message` is a sentence to show the user as is; `details` lists field errors |
| 429 | `too_many_requests` | Too many requests from one IP (or for one email on sign-in). See Rate limits below |

Show `error.message` in the toast. It is written for end users and matches the wording of the Convoy OS prototype.

### Rate limits

A refused request answers `429` with a `Retry-After` header (seconds) and the usual error object:

```json
{ "error": { "code": "too_many_requests", "message": "Too many tries. Try again in 42 seconds", "details": { "retry_after": 42 } } }
```

Show the message, and keep the button disabled for `retry_after` seconds (counting down if you like).

| What | Limit |
| --- | --- |
| Staff sign-in `POST /session` | 10 a minute per IP, 5 a minute per email |
| Client Portal email step: `POST /portal/session/lookup`, `POST /portal/session/code` | 30 a minute per IP (and 5 codes an hour per account, a `422`) |
| Client Portal password step: `POST /portal/session`, `POST /portal/session/verify`, `POST /portal/password` | 10 a minute per IP, 5 a minute per email (not for `/portal/password`) |
| Share Form answers `POST /public/share_forms/:token` | 10 an hour per IP |
| Everything else under `/api` | 300 a minute per IP |

The limits count fixed one-minute (or one-hour) windows, so the wait is at most the length of the window.

## Optimistic locking (`lock_version`)

Trips and runs carry `lock_version`. Send back the value you loaded when saving (`PATCH /trips/:id`, run actions);
if someone else saved in between, the API answers `409` and the screen should reload. Leaving it out skips the check.

## Files (uploads and downloads)

- Upload with `multipart/form-data`. Nested fields use bracket names, for example `vehicle[photo]`,
  `trip[stops_attributes][0][photos_attributes][0][photo]`.
- Files are private. Any file in a response looks like:

```json
{ "url": "/api/v1/downloads/eyJfcmFpbHMi...", "thumb_url": "/api/v1/downloads/...", "name": "hiace.png", "size": 9273, "content_type": "image/png" }
```

- `url` / `thumb_url` are signed links valid for **1 hour** that open the file on their own (no `Authorization` header,
  like a pre-signed URL); use them directly in `<img src>` or open them in a new tab. They are paths: put the API host
  in front (`https://convoy-api-staging.convoy.sg` + `url`). Reload the record to get fresh links. Do not share them.
- Images are resized to 1280 px; `thumb_url` is a 320 px square. Documents accept PDF, images, xlsx / xls, csv, doc / docx, txt (10 MB max).

## Reading documents with Claude (background reads)

Log cards, insurance papers, workshop invoices, route lists and pasted trip messages are read by Claude in the background:

1. `POST /document_reads` with `kind` and a `file` (multipart) or `input_text` → **202** `{ "data": { "id": 7, "status": "pending", ... } }`.
2. Poll `GET /document_reads/:id` every 2–3 s until `status` is `done` (use `result`) or `failed` (show `error`).
3. When saving the form, send `document_read_id` so the server attaches the same file; there is no second upload.

| `kind` | Used by |
| --- | --- |
| `log_card` | Edit Vehicle > Log Card |
| `insurance` | Edit Vehicle > Insurance |
| `maintenance_invoice` | Maintenance > Record the Work |
| `route_list` | Trip form (School Run) > Import Route List |
| `trip_message` | Trip form > Fill from Message (`input_text`) |

```json
{ "data": { "id": 7, "kind": "log_card", "status": "done", "error": null, "result": { "plate": "PD3318K", "make": "Toyota" },
            "file": { "url": "...", "name": "card.pdf" }, "created_at": "...", "finished_at": "..." } }
```

Only the user who started a read can see it. Without an Anthropic key on the server, reads end `failed` with
`"Reading with Claude is not set up (API key missing or not allowed)"`.

## Runs ("occurrences")

The Scheduler works on **runs**: one row per trip (or School Bus route) per date, per shuttle timing, per vehicle slot.
They are already resolved (times, bus, driver, price), so the screens only display them.

- Runs exist up to **`meta.horizon` = today + 120 days**. Later dates have no runs yet: the server adds one date each night.
  Do not let users browse or act past the horizon (grey out those days, stop the › button there).
- Changes made for the future are rules, not runs, so they reach later dates on their own as the horizon moves:
  an assignment From This Date On, Driver Away / Vehicle Down on a date range, Every Run From Today, Change a Day,
  public holidays, default driver changes, trip edits. Their date pickers may go past the horizon.
- `id` identifies a run; `key` is a stable name for the same run across re-syncs:
  `t<trip_id>|<date>|<trip_run_id or 0>|<slot_no>|<part>` or `r<school_route_id>|<date>|0|1|1`.
