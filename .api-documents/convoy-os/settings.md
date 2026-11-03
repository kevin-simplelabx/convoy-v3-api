# Settings — API Guide

The Settings menu (rail footer icon `settings`): **Company Settings**, **Users**, **Calendars**, plus the **Profile**
dialog of the account menu in the top bar. What is not built yet is listed in [§ 5](#5-not-built-yet).

Conventions (sign-in, errors, paging, files, background reads) are in [README.md](../README.md).
All paths below start with `/api/v1`. A Convoy Admin can only read.

## Contents

1. [Users](#1-users)
2. [Profile](#2-profile)
3. [Company Settings](#3-company-settings)
4. [Calendars](#4-calendars)
5. [Not built yet](#5-not-built-yet)
6. [Changes to existing endpoints (02/11/2026)](#6-changes-to-existing-endpoints-02112026)

---

## 1. Users

Needs the `users` permission (to see the page and to change anything). Without it every call below is `403`.

### 1.1 Roles and permissions: `GET /users/roles`

The **Start From a Role** pills, the permission switches and the **View Role Permissions** table.

```json
{ "data": {
  "permissions": [ { "id": "users", "label": "Users" }, { "id": "schools", "label": "Schools & Riders" }, "..." ],
  "roles": [
    { "id": "owner", "name": "Super Admin", "tag": "Owns the account. Manages Admins", "permissions": ["users", "..."], "owner": true, "all_permissions": true },
    { "id": "planner", "name": "Planner", "tag": "Plans and edits routes", "permissions": ["schools", "plans", "planview"], "owner": false, "all_permissions": false }
  ] } }
```

- Picking a role fills the permission switches with its `permissions` (and sets `owner` for Super Admin). Show the
  Super Admin pill only when the signed-in user is a Super Admin (`session.user.owner`).
- The feature rows of the View Role Permissions table (what each permission lets you do) are fixed text on the front end:
  a feature is ticked for a role when the role has the feature's permission.

### 1.2 List: `GET /users`

| Param | Description |
| --- | --- |
| `status` | `active` or `suspended` (no value: both) |
| `q[name_or_email_i_cont]` | Search by name or email |
| `page`, `limit` | Paging |

Deleted users are never listed. `meta.counts` = `{ all, active, suspended }`. `meta.maker_checker_warning` = Maker-checker
is on for operator pay runs but fewer than two users are active: show "Maker-checker is on for operator pay runs, but only 1
active user is left. No one can approve. Change Pay Run Approval to One Person in Finance Settings, or add another user"
with a **Finance Settings** button. Each row:

| Field | Description |
| --- | --- |
| `name`, `email`, `created_at` | "Added <created_at>" |
| `role_label` | Role column: `Super Admin`, `Admin`, a preset name when the permissions match one exactly, else `Custom` |
| `permissions` | Permission ids (Show Permissions: map to labels; empty = "No permissions. Can sign in and view the Stop Library") |
| `owner`, `role` | `role` is `admin` for a Super Admin or a user with every permission, else `member` |
| `all_schools`, `every_school`, `schools` | Schools column: `every_school` → "All schools"; else the `schools` names (`[{ id, name }]`), or "No schools yet" when empty |
| `status` | `active` / `suspended` (badge) |
| `can_edit` | Show the Edit button (a Super Admin row only for a Super Admin) |
| `can_act` | Show Suspend / Delete (never on your own row) |
| `created_by` | `{ id, name }` |

### 1.3 Add User / Edit

Add: `POST /users`. Edit: `PATCH /users/:id`.

```json
{ "user": { "name": "Paula Planner", "email": "paula@example.com", "password": "secret123",
            "permissions": ["schools", "plans", "planview"], "owner": false,
            "all_schools": false, "school_ids": [12] } }
```

- `name`, `email`, `password` (at least 8 characters) only when adding. On edit they are ignored: the name and email are
  set when the user is added.
- `permissions`: every permission (or `owner: true`) makes the user an Admin: all permissions, every school.
- `all_schools: true` = every school, including new ones. `false` = only `school_ids` (may be empty: the user opens no school).
  Leave both out on edit to keep the schools as they are.
- Response: the row (§ 1.2), `201` when added.
- `422` messages: `Email is already used by another user`, `Password is too short (minimum is 8 characters)`,
  `Only a Super Admin can make a Super Admin`, `Only a Super Admin can change a Super Admin`,
  `You can't remove your own Users permission`, `There must always be at least one active Super Admin`.

### 1.4 Row buttons

| Button | Call | Result |
| --- | --- | --- |
| Suspend | `POST /users/:id/suspend` | Row with `status: suspended`. The user is signed out on every device and cannot sign in |
| Turn back on | `POST /users/:id/activate` | Row with `status: active` |
| Delete | `DELETE /users/:id` | `204`. The user is signed out and gone from the list; their name stays on past records, and the email can be used for a new user |

Confirm before Suspend and Delete (texts in the prototype). `422`: `You can't suspend yourself`, `You can't delete yourself`,
`Only a Super Admin can change a Super Admin`, `There must always be at least one active Super Admin`.

---

## 2. Profile

The account menu's **Profile** dialog. Every signed-in user (Convoy Admin too) edits only their own profile.

| Action | Call |
| --- | --- |
| Open | `GET /profile` |
| Save Profile | `PATCH /profile` (multipart when a picture is sent) |

```
profile[display_name]   optional; empty = use the name
profile[mobile]         optional; "9123 4567" or "+65 9123 4567", saved as +6591234567
profile[avatar]         image file (JPG, PNG, WebP)
profile[remove_avatar]  true to remove the picture
```

The response (also `data.user` of `GET /session`) has `name`, `email` (read only: "set by an Admin in Users"),
`display_name`, `shown_name` (display name or name: use it in the top bar), `initials`, `mobile`, `mobile_display`,
`avatar { url, thumb_url }`, `role_label` (the line under the title, for example "Planner"). `422` when the mobile is not a
possible phone number.

## 3. Company Settings

### 3.1 Open and save

Open: `GET /companies/:id`. Save: `PATCH /companies/:id`. Use the company id from `GET /session` (`data.company.id`). The response (Company Settings view) has:

| Field | Card |
| --- | --- |
| `can_edit` | `false` → show the "View only. Users with the Users permission can change company settings" banner and disable the inputs |
| `name` | Company Name > Full Name (read only: set when Convoy opens the account) |
| `short_name` | Short Name (max 12) |
| `logo` | `{ url, thumb_url }` or `null` |
| `theme_color` | `#RRGGBB` or `null` (the default theme) |
| `timezone` | IANA name, for example `Asia/Singapore` |
| `date_format` | `dmy` (16/10/2026), `mdy` (10/16/2026), `ymd` (2026-10-16), `dmon` (16 Oct 2026) |
| `time_format` | `24` or `12` |
| `business_units_enabled` | Business Units and Projects switch |
| `country`, `country_locked`, `country_set_at`, `country_set_by { id, name }` | Country card: "Set on <date> by <name>" |
| `country_request` | The pending Request a Country Change (§ 3.3) or `null` |
| `ops_phone`, `ops_hours`, `ops_whatsapp`, `ops_email`, `depot_address` | Operations contacts drivers see in the Convoy Driver app (Contact Operations): phones in E.164, hours as text ("Mon–Sat 05:30–20:00"). No card in the prototype yet; send them like the other fields when one is added |

Save sends only what changed (Save Changes / Discard are front end):

```
PATCH /companies/:id   (multipart when a logo is sent)
company[short_name], company[theme_color], company[timezone], company[date_format], company[time_format],
company[business_units_enabled], company[logo] (PNG, JPG, SVG, WebP), company[remove_logo]=true,
company[country] (only while country_locked is false),
company[ops_phone], company[ops_hours], company[ops_whatsapp], company[ops_email], company[depot_address]
```

Needs the `users` permission (`403` otherwise). `name` is ignored for company users. `422` details per field
(for example `theme_color: ["Theme color is invalid"]`).

### 3.2 Countries: `GET /countries`

`[{ code, name, live, timezone, currency, phone_prefix, map, weather, traffic }]` for SG, TW, MY, TH, HK.
Only `live: true` can be picked (the others show "Coming soon"). Country card info line:
"Base map <map>, weather from <weather>, traffic from <traffic>".

While `country_locked` is `false` the cards can be picked: `PATCH /companies/:id { company: { country } }` sets it once
(and stamps `country_set_at` / `country_set_by`). Then it is locked: changes go through a request.

### 3.3 Request a Country Change

| Button | Call |
| --- | --- |
| Request a Change → Send Request | `POST /country_requests { country_request: { to_country, reason } }` |
| Withdraw | `POST /country_requests/:id/withdraw` |
| History | `GET /country_requests?status=` (own company, newest first) |

A request: `{ id, company_id, company_name, from_country, to_country, to_country_name, reason, status, requested_by { id, name },
decided_by, created_at, decided_at }`, `status` = `pending` / `approved` / `declined` / `withdrawn`.
Banner text: "Change to <to_country_name> requested by <requested_by.name> on <created_at>. Waiting for Convoy: <reason>".
When no other country is live, show "No other country is open yet…" instead of the picker.
`422`: `To country is not open yet`, `To country is where the company is already (Singapore)`, `Reason can't be blank`,
`A change is already waiting for Convoy` (one pending request per company).

Convoy Admin (any company): `GET /country_requests?status=pending&company_id=`, `POST /country_requests/:id/approve`
(the company's country changes, `country_set_by` = the Convoy Admin), `POST /country_requests/:id/decline`.

## 4. Calendars

Everyone in the company can read calendars; adding, changing or removing needs the `vehicles` or `finance` permission
(`403` otherwise). The day forms (Add a Day) are the same as Change a Day: see [scheduler.md § 10](scheduler.md#10-change-a-day-calendars).
After any change the runs re-sync in the background.

### 4.1 Tabs: `GET /calendars`

The first tab is always **Public Holidays** (built in, not in this list). Then one tab per calendar:
`{ id, name, kind: school | general, observed_holidays: off | work, morning_time, afternoon_time, trips_count }`.
Sub line: "School calendar | 2 trips use it" / "No trips use it yet".

| Action | Call |
| --- | --- |
| Add Calendar | `POST /calendars { calendar: { name, kind }, start_from: moe \| blank \| <calendar id> }` (MOE only for school) |
| Rename (pencil) | `PATCH /calendars/:id { calendar: { name } }` (the type can't be changed) |
| Delete | `DELETE /calendars/:id` (`422` "This calendar is used by trips, so it can't be deleted") |
| Observed Holidays (this calendar) | `PATCH /calendars/:id { calendar: { observed_holidays: off \| work } }` |
| Observed Holidays for trips without a calendar | `PATCH /companies/:id { company: { observed_holidays } }` (needs the `users` permission) |
| Regular Sessions (school) | `PATCH /calendars/:id { calendar: { morning_time: "07:30", afternoon_time: "13:30" } }` |

`422` on the name: `Name is already used by another calendar`, `Name is the built-in calendar's name` ("Public Holidays").

### 4.2 Public Holidays tab: `GET /public_holidays?year=2026`

Rows `{ id, date, name, observed, saturday }` (badges Observed and Saturday). `meta`:

```json
{ "year": 2026, "count": 11, "weekdays": 9, "preset_available": true, "preset_missing": 0 }
```

- Card title: "2026 | 11 holidays, 9 on weekdays".
- Empty year: "No public holidays for 2026 yet…" and, when `preset_available`, the **Add MOM 2026 Dates** button:
  `POST /public_holidays/import { year }` → `meta.added` (0 = "Every MOM date for 2026 is already in").
- Observed card text: list the `observed` dates of the year.

Add a Holiday: `POST /public_holidays { public_holiday: { date, name } }`. A holiday on a Sunday also adds the Monday after
as the observed holiday ("<name> Holiday"), returned in `meta.observed` (`null` when not added):
"Added National Day, plus Mon 10 Aug as the observed holiday". `422`: `Date is already a public holiday`.
Remove: `DELETE /public_holidays/:id`.

### 4.3 A calendar's days: `GET /calendars/:id?year=2026`

The calendar with `days` touching that year (every day without `year`), sorted by date. Each day:
`{ id, kind, kind_name, starts_on, ends_on, label, usual_time, new_time, shift_minutes, in_place_of, notify_drivers, time_change }`.

### 4.4 Trips Using This Calendar: `GET /calendars/:id/trips?year=2026`

```json
{ "data": [ { "id": 41, "title": "Office Shuttle", "kind": "shuttle", "kind_name": "Shuttle", "client_name": "Google",
              "repeat_text": "Every weekday", "start_time": "08:00", "starts_on": "2026-09-01", "ends_on": null,
              "runs_skipped": 1, "skipped": [ { "date": "2026-12-25", "reason": "Public holiday: Christmas Day" } ] } ],
  "meta": { "year": 2026 } }
```

Card title "Trips Using This Calendar | <count>"; each row: title, "kind | repeat_text | start_time", and
"1 run skipped in 2026" / "None skipped in 2026". Recurring trips only.

## 5. Not built yet

- Change password, forgot password, signed-in devices, refresh tokens: the prototype has no screen for them.
- On Time and Speed Limit settings (Trip History uses the defaults: 5 minutes, 80 km/h).
- School access (`all_schools`, `schools`) is saved and returned, but School Bus pages do not limit by it yet.

## 6. Changes to existing endpoints (02/11/2026)

Endpoints that existed before the Settings menu and now behave differently. Check the screens that use them.

| Endpoint | Before | Now |
| --- | --- | --- |
| `PATCH /companies/:id` | Admin / Super Admin could save | Needs the `users` permission (`403` otherwise). `company[name]` is ignored for company users. `country` only while `country_locked` is `false`. New: `remove_logo` |
| `GET /companies/:id`, `GET /companies` | Company fields | Also `can_edit`, `country_locked`, `country_set_at`, `country_set_by`, `country_request` |
| `POST`, `PATCH`, `DELETE` on `/calendars`, `/calendars/:id/days`, `/public_holidays` (incl. `import`) | Any company user | Needs the `vehicles` or `finance` permission (`403` otherwise). Reading is unchanged. Change a Day on the Scheduler is affected too |
| `POST /public_holidays` | Added one holiday | A Sunday holiday also adds the Monday after as observed; the response has `meta.observed` (or `null`). Duplicate date message: `Date is already a public holiday` |
| `GET /public_holidays?year=` | `meta: {}` | `meta: { year, count, weekdays, preset_available, preset_missing }` |
| `GET /calendars` | Calendar fields | Also `trips_count` |
| `GET /calendars/:id` | Every day | `?year=` keeps only the days touching that year (no `year` = every day, as before) |
| `POST` / `PATCH /calendars` | | `422` for a duplicate name (any case), the name "Public Holidays", or a changed `kind` |
| `GET /session` (`data.user`) | User fields | Also `display_name`, `shown_name`, `mobile_display`, `role_label`; `initials` come from `shown_name` |
| `POST /session` | | A deleted user cannot sign in |
| Passwords | At least 6 characters | At least 8 characters |

