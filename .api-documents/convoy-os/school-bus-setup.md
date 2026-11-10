# School Bus › Schools & Year Setup — API Guide

This guide covers the first part of the School Bus menu (rail icon `school`):

- the Schools page and the school record, with its Riders, Rider Data and Route Labels tabs;
- these Year Setup steps: School Levels, Terms & Semesters, Bus Sessions and Bus Attendants (Bus Fares, Payment & Refund
  Policy, Payment Methods and Operator Pay are in [school-bus-money.md](school-bus-money.md));
- Holidays & Special Days;
- the setup strip and the Summary.

Conventions are in [README.md](../README.md); paths start with `/api/v1`.

**Permissions**

| What | Who |
| --- | --- |
| Lists, the school record and riders (read) | Any company user, limited to the schools they may open |
| Add a school, Route Labels, upload or delete Rider Data, Add Rider | `schools` |
| Year Setup and Holidays (change) | `plans` or `schools` |
| Delete Year | Admins (`users`) |

A Convoy Admin can see everything but change nothing. "The schools they may open" means every school for Admins and for
users with *All Schools*; everyone else sees only the schools picked for them in Settings › Users.

**Locks.** Most setup steps follow the prototype's Save & Lock pattern:

- **Save** validates the whole step and **locks** it.
- A locked step answers **422** `"<Step> is locked. Unlock to edit"` to any change.
- **Unlock to Edit** asks the user to type the AY key, or `UNLOCK` for school-level steps. That prompt is FE only; then
  call the unlock endpoint.
- **Lock Again** just discards the FE draft: make no call.

## Contents

1. [Schools](#1-schools)
2. [Rider Data and Riders](#2-rider-data-and-riders)
3. [Terms & Semesters (academic years)](#3-terms--semesters-academic-years)
4. [Holidays & Special Days](#4-holidays--special-days)
5. [School Levels](#5-school-levels)
6. [Bus Sessions](#6-bus-sessions)
7. [Bus Attendants](#7-bus-attendants)
8. [Setup strip and Summary](#8-setup-strip-and-summary)
9. [How the Scheduler uses this](#9-how-the-scheduler-uses-this)
10. [Front-end only](#10-front-end-only)

---

## 1. Schools

### 1.1 List

`GET /schools?date=` returns the schools the user may open:

```json
[ { "id": 3, "name": "St. Stephen's School", "short_name": "SSS", "address": "20 Siglap View, Singapore 455789", "postal": "455789",
    "lat": 1.3138, "lng": 103.9283, "client": { "id": 4, "name": "St. Stephen's School" },
    "datasets_count": 1, "rider_data_from": "2026-01-02" } ]
```

`rider_data_from` is the Effective From date of the rider list in use on `date` (default today). Show it as
"From <date>"; `null` shows as "None".

### 1.2 New School

`POST /schools { school: { name, short_name, address, postal } }`

- The postal code must have 6 digits. It is looked up on OneMap on the server.
- When `address` is empty, OneMap's address is used.
- `lat` and `lng` are saved with the school.

| Error (422) | Cause |
| --- | --- |
| "Postal code must be 6 digits" | Postal code is not 6 digits |
| "Postal code not found on OneMap" | OneMap has no match |
| "OneMap cannot be reached. Try again in a moment" | OneMap is down |
| "Name has already been taken" | Duplicate school name |

The prototype has no Edit or Delete School.

### 1.3 School record and Route Labels

`GET /schools/:id` returns the school row plus `route_labels`:

```json
"route_labels": [ { "session": "am", "prefix": "AM ", "start": 1, "digits": 0, "suffix": "", "preview": ["AM 1", "AM 2", "AM 3"] },
                  { "session": "pm", … }, { "session": "asa", "prefix": "CCA ", … } ]
```

Save Labels:

```
PUT /schools/:id/route_labels { labels: { am: { prefix, start, digits, suffix }, pm: {…}, asa: {…} } }
```

- `start` must be 0 or more.
- `digits` (zero padding) must be 0–4.
- Sessions you leave out keep their values.

The response is the school record.

## 2. Rider Data and Riders

A school's riders come from **rider lists** (datasets) uploaded with an *Effective From* date, plus riders **added by
hand**.

- On a date, the list in use is the latest one effective on or before that date (In Use). A later list is Scheduled;
  older lists are Replaced.
- Riders added by hand belong to no list and always count.
- Every rider counts only between its own start and end dates.

### 2.1 Rider Data tab

`GET /schools/:id/rider_datasets?date=` returns the lists (oldest first) in `data`, with `meta.date`:

```json
{ "id": 7, "effective_from": "2026-01-02", "file_name": "SSS riders 2026.csv", "riders_count": 65, "checked_count": 65, "unlocated_count": 0,
  "status": "ready", "state": "in_use", "uploaded_by": "Ops Admin", "created_at": "…",
  "file": { "url": "/api/v1/downloads/<token>", "name": "SSS_riders_2026.csv", "size": 4210, "content_type": "text/csv" } }
```

- `state` is `in_use`, `scheduled` or `replaced`.
- `status` is `locating` while homes are being placed on the map, then `ready`. While locating, poll the list and show
  "Finding addresses on OneMap: `checked_count` of `riders_count`".
- `unlocated_count` is the number of riders OneMap did not find (No Location).

**Check a file before importing:** `POST /schools/:id/rider_datasets/preview` (multipart, `file` = CSV or XLSX).

```json
{ "riders": 3, "problems": 3, "errors": [ { "line": 4, "message": "Row 4: no student name" } ], "sample": [ { "rid": "S-1", "name": "…" } ] }
```

Show "N riders ready to import | M problems (those rows are skipped)" and the first errors.

Columns are found by name, in any order, as in the prototype's template:

| Column | Also accepted |
| --- | --- |
| `student_id` | Student ID / ID |
| `student_name` (required) | Name |
| `gender` | |
| `grade_class` | Grade / Class / Level |
| `address` (required) | |
| `postal_code` (required) | Postal / Postcode |
| `am` | |
| `pm` | |
| `cca_days` | |
| `start_date` | |
| `end_date` | |
| `parent_name` | |
| `parent_contact` | |
| `remarks` | |

Value rules:

- `am` / `pm`: `Y` / `Yes` / `1` / `x`. If the column is missing, everyone rides that session.
- `cca_days`: days such as `Mon;Wed`.
- Dates: `YYYY-MM-DD` or `DD/MM/YYYY`.
- An empty student ID becomes `S-<row number>`.
- A student ID used twice keeps only its first row.
- Postal codes shorter than 6 digits are padded with leading zeros.

**Import:** `POST /schools/:id/rider_datasets` (multipart `file`, `effective_from`).

- The response (201) is the new list (`status: "locating"`), plus `meta.skipped` (up to 50) and `meta.skipped_count`.
- Homes are placed in the background. Poll the list until `status` is `ready`.
- Show "N addresses not found; they show as No Location" from `unlocated_count`.
- Rows with a problem are **skipped** (listed in `meta.skipped`, counted in `meta.skipped_count`); the good rows are
  imported. `422` only when no row can be imported (the message lists the problems), `Choose a CSV or XLSX file` with no
  file, or `Pick the Effective From date` with no date.

**Delete:** `DELETE /schools/:id/rider_datasets/:dataset_id` (`204`). Ask for confirmation first: "Riders from it will no longer
be planned".

The CSV and XLSX templates are built by the FE, as in the prototype.

### 2.2 Riders tab

`GET /schools/:id/riders?date=&filter=all|am|pm|cca|unlocated&q=&page=&limit=` returns a paged list:

```json
{ "data": [ { "id": 41, "rid": "S-1001", "name": "Tan Wei Ling", "first_name": null, "last_name": null, "name_order": "last",
              "gender": "F", "grade": "P3", "address": "…", "postal": "460100", "lat": 1.32, "lng": 103.92, "located": true,
              "am": true, "pm": true, "cca_days": [2, 4], "starts_on": null, "ends_on": null,
              "parent_name": "Tan Ah Kow", "parent_contact": "91234000", "remarks": null, "source": "csv", "rider_dataset_id": 7 } ],
  "meta": { "page": 1, "limit": 20, "count": 65, "pages": 4, "date": "2026-11-02",
            "counts": { "all": 65, "am": 65, "pm": 57, "cca": 13, "unlocated": 0 }, "dataset": { "file_name": "SSS riders 2026.csv", … } } }
```

- `date` is the Plan For date.
- `q` searches name, rider ID, grade, address and postal code.
- `counts` follow `q` but not `filter`; they drive the chips.
- `cca_days` are ISO weekdays (1 = Mon).
- `located: false` means no map location. Show "(no location)" in red.
- The sub-line reads "On <date> | dataset "<file>" effective <date>", or "no dataset in effect on this date" when
  `meta.dataset` is `null`.

**Add Rider:**

```
POST /schools/:id/riders { rider: { first_name, last_name, name_order: first|last, rid, gender, grade, address, postal,
                                    am, pm, cca_days: "Mon;Wed" | [..], starts_on, ends_on, parent_name, parent_contact, remarks } }
```

- `first_name` or `last_name` is required (`422` "Enter a first name or last name").
- The postal code must have 6 digits (`422` "Postal must be 6 digits").
- At least one of AM, PM or CCA is required (`422` "Pick at least one of AM, PM or CCA").
- An empty `rid` becomes `M-0001`, `M-0002`, and so on. The answer is the rider (`201`).
- The home is placed now. When OneMap does not know the postal code, the rider is saved with `located: false`. Show
  "Postal code not found, so they have no map location".

**Export CSV:** `GET /schools/:id/riders/export?date=` returns the template's columns for the riders on that date. The file
name is in `Content-Disposition` (CORS exposes it).

### 2.3 Plan For calendar (rider changes)

`GET /schools/:id/rider_events?date=2026-11-02` (`date` = the Plan For date) feeds the Plan For date picker of the School
Bus header:

```json
{ "data": [ { "date": "2026-10-01", "kind": "list", "rid": null, "name": "SSS riders Oct.csv", "service": null },
            { "date": "2026-11-20", "kind": "leave", "rid": "S-2", "name": "Lim Jia Hui", "service": "AM" },
            { "date": "2027-01-02", "kind": "join", "rid": "S-0002", "name": "New Kid", "service": "AM + PM" } ],
  "meta": { "date": "2026-11-02", "soon": 1 } }
```

- `kind`: `join` (green dot, Joining), `leave` (red, Leaving), `change` (orange, Service change), `list` (teal, New rider
  list: `name` is the file name). By date; one event per date, kind and rider.
- How they are worked out (as the prototype): each rider list starts on its `effective_from` (`list`); against the list
  before it, a rider new to the list joins (on its start date when later), a rider whose service (`service`: "AM + PM +
  CCA" or "No service") changed is a `change`, a rider no longer on it leaves; a rider's end date is a `leave`. Riders
  added by hand join on their start date and leave on their end date.
- `meta.soon` = changes (not lists) in the 30 days after `date`: the badge "N rider changes in the next 30 days".
- Day tip: "<date>: 3 joining, 1 leaving, 2 changing service, 1 new rider list"; This Month groups the names by day
  ("Name (AM + PM), … +k more", 4 names at most).

## 3. Terms & Semesters (academic years)

An academic year runs for 12 months from its start month.

- Its `key` is `"2026"` when it starts in January, otherwise `"2026/27"`.
- Its calendar has operating days and either 2 Semesters or 3–4 Terms.
- Each term has a CCA / ASA period: the term's own dates when `cca_same_as_terms`, otherwise its own dates.
- A **school day** is an operating day, inside a term, and not a holiday.

| Call | What it does |
| --- | --- |
| `GET /schools/:id/academic_years` | The years, oldest first (the year selector) |
| `POST /schools/:id/academic_years { start_year, start_month, copy_from_id }` | New Academic Year (see below): `201` the year |
| `GET /academic_years/:id` | One year with its terms, holidays and special days |
| `PUT /academic_years/:id/calendar` | Save Calendar: validates, saves and **locks**; answers the year |
| `POST /academic_years/:id/unlock { section: "calendar" }` | Unlock to Edit; answers the year |
| `DELETE /academic_years/:id` | Delete Year |

**New Academic Year:**

- With `copy_from_id`, it copies the operating days, structure and CCA setting of that year, but not its dates.
- Otherwise it starts with Mon–Fri and 2 Semesters.
- The empty terms are created.
- 422 "This overlaps AY 2027" when the 12 months overlap another year.

`GET /academic_years/:id`:

```json
{ "id": 5, "key": "2027", "start_year": 2027, "start_month": 1, "starts_on": "2027-01-01", "ends_on": "2027-12-31",
  "structure": "term", "period_count": 4, "period_label": "Term", "operating_days": [1,2,3,4,5], "cca_same_as_terms": true,
  "started": false, "calendar_locked": { "at": "…", "by": "Ops Admin" },
  "terms": [ { "position": 1, "label": "Term 1", "starts_on": "2027-01-04", "ends_on": "2027-03-12", "school_days": 50,
               "cca_starts_on": "2027-01-04", "cca_ends_on": "2027-03-12" } ],
  "school_days": 200,
  "holidays": [ { "id": 1, "name": "Chinese New Year", "starts_on": "2027-02-06", "ends_on": "2027-02-06", "public_holiday": true, "public_holiday_id": 12, "operating_days_off": 0 } ],
  "operating_days_off": 20,
  "special_days": [ { "id": 3, "date": "2027-03-05", "kind": "early_dismissal", "time": "11:30", "description": "Sports Day" } ] }
```

- `school_days` under each term counts operating days in the term that are not holidays.
- `calendar_locked: null` means the step is not done.

**Save Calendar:**

```
PUT /academic_years/:id/calendar { operating_days: [1..7], structure: "semester"|"term", period_count: 2|3|4,
                                   cca_same_as_terms, terms: [{ starts_on, ends_on, cca_starts_on, cca_ends_on }] }
```

Send JSON. Error messages:

| Error (422) | Cause |
| --- | --- |
| "Pick at least one operating day" | No operating days |
| "Period count must be 2" (or "Period count must be 3 or 4") | `period_count` does not fit `structure` |
| "Term 1 needs a start and an end" | Missing date |
| "Term 2 must start after Term 1 ends" | Terms out of order or overlapping |
| "Term 4 must be inside AY 2027 (1 Jan 2027 to 31 Dec 2027)" | Term outside the year |
| "Term 1 CCA / ASA needs a start and an end" | Missing CCA date (when not the same as the terms) |
| "Terms & Semesters is locked. Unlock to edit" | Calendar is locked |

**Delete Year:**

- Only before the year starts (`started: false`), and only for Admins.
- The FE asks the user to type the key first.
- It removes the whole year: calendar, holidays, sessions and locks.
- 422 "AY 2026 has started and cannot be deleted".

The School Bus runs of the school follow the calendar. They are re-synced in the background after any save (see §9).

## 4. Holidays & Special Days

This page is always editable; the calendar lock does not apply. It saves the whole list, like the prototype's Save
Changes.

```
PUT /academic_years/:id/holidays { holidays: [{ name, starts_on, ends_on, public_holiday_id }],
                                   special_days: [{ date, kind, time, description }] }
```

- Send the list back as you got it: each holiday keeps its `public_holiday_id` (null for the school's own).
- Holidays need a `name` and `starts_on`. `ends_on` defaults to `starts_on` and must not be before it.
- Special day `kind` is `early_dismissal`, `late_dismissal`, `early_arrival`, `late_arrival` or `other`. `time` is
  "HH:MM".
- The response is the year (§3), which includes "N operating days off" as `operating_days_off`.
- Errors name the row, e.g. "Holiday 1: Ends on must be on or after the start".

**Import Singapore Public Holidays:** `GET /academic_years/:id/public_holidays` returns the company's public holidays
inside the year (Settings › Calendars) that are not on the list yet:

```json
[ { "public_holiday_id": 12, "name": "Chinese New Year", "starts_on": "2027-02-06", "ends_on": "2027-02-06" } ]
```

Add them to the draft, then save.

## 5. School Levels

Levels are set per school, not per year.

`GET /schools/:id/levels`:

```json
{ "saved": false,
  "levels": [ { "name": "P1", "section": "pri", "final": false, "riders": 0 }, { "name": "P6", "section": "pri", "final": true, "riders": 1 } ],
  "locked": null,
  "unknown": [ { "grade": "Pre-U", "riders": 1 } ],
  "sections": [ { "key": "pri", "name": "Primary", "group": null, "description": "P1 to P6", "levels": ["P1","P2","P3","P4","P5","P6"] } ] }
```

- Before levels are saved (`saved: false`), `levels` are suggestions from rider data. A whole section is suggested when a
  rider's grade matches one of its levels; otherwise the grades found are suggested. The last suggestion is marked final.
- `riders` counts today's riders whose grade matches, ignoring case.
- `unknown` lists grades in rider data that are not levels. Each has a one-click Add.
- `sections` are the "What the School Offers" cards, with their default levels.

**Save & Lock:** `PATCH /schools/:id/levels { levels: [{ name, section, final }] }` (send JSON, in order).

| Error (422) | Cause |
| --- | --- |
| "Add at least one level" | Empty list |
| "Every level needs a name" | A level has no name |
| "P1 is listed twice" | Duplicate name (ignoring case) |

**Unlock:** `POST /schools/:id/unlock { section: "levels" }` returns 204.

## 6. Bus Sessions

Bus Sessions belong to an academic year and need that year's calendar to be locked.

| Call | What it does |
| --- | --- |
| `GET /academic_years/:id/sessions` | `data` = the sessions; `meta.locked` and `meta.calendar_locked` |
| `GET /academic_years/:id/sessions/copy?from_id=` | "Copy AY X Sessions": another year's sessions as a draft (not saved); days that are not operating days are dropped |
| `PUT /academic_years/:id/sessions { sessions: [...] }` | Save & Lock (send JSON); answers the list as `GET` |
| `POST /academic_years/:id/unlock { section: "sessions" }` | Unlock |

```json
{ "position": 2, "name": "PM Departure", "direction": "to_home", "cca": false, "service": "d2d", "max_journey_minutes": 60,
  "days": [1,2,3,4,5], "arrive_from": "14:00", "arrive_to": "15:00", "dismissal": "13:30", "depart": "13:45", "notes": null,
  "variants": [ { "days": [3], "arrive_from": "12:30", "arrive_to": "13:30", "dismissal": "12:00", "depart": "12:15" } ] }
```

The add buttons create these defaults:

| Button | `direction` | `service` | `cca` | Default name |
| --- | --- | --- | --- | --- |
| Add To School | `to_school` | `d2d` | false | "AM Arrival" |
| Add To Home | `to_home` | `d2d` | false | "PM Departure" |
| Add CCA/ASA | `to_home` | `p2p` | true | — |

`max_journey_minutes` defaults to 60.

Rules (422 messages name the session):

| Error (422) | Cause |
| --- | --- |
| "Save and lock the Terms & Semesters first" | The year's calendar is not locked |
| "Add at least one session" | Empty list |
| "Session names must be different" | Duplicate names |
| "pick at least one day" / "pick operating days only" | Bad `days` |
| "set the arrival window" / "the arrival window must end after it starts" | Bad arrival window |
| "set the dismissal and departure times" | To-home session without them |
| "departure must be at or after dismissal" | `depart` before `dismissal` |
| "arrival home cannot start before departure" | `arrive_from` before `depart` |
| "Different Timing N: pick days the session runs" | Variant uses days outside the session |
| "Different Timing N: a day is in two timings" | Two variants share a day |

## 7. Bus Attendants

`GET /schools/:id/bus_attendants`:

```json
{ "needs": "statutory", "sizes": [], "provided_by": "operator", "needed_sizes": ["LARGE_45","LARGE_40"], "saved": true,
  "locked": { "at": "…", "by": "…" },
  "bus_types": [ { "key": "LARGE_45", "label": "45-seater", "seats": 45, "required_by_law": true, "ba_operator": "300.0", "ba_us": "250.0" } ],
  "routes": [ { "id": 41, "label": "AM 1", "session": "am", "bus_type": "LARGE_45" } ] }
```

**Save & Lock:**

```
PATCH /schools/:id/bus_attendants { needs: statutory|all|selected, sizes: [...], provided_by: operator|us }
```

- An empty body is `422` "Send needs, sizes or provided_by" and nothing is saved or locked.
- `routes[].bus_type` is `null` for a route that has none (a hand-made route, old data): it needs no attendant. Routes from the routing engine always have one.
- With `selected`, at least one size is required (`422` "Pick at least one bus size"; `sizes: []` is not filled in with the
  required ones), and the sizes required by law are always included in what is saved.
- The price table (Their BA / Our BA): `bus_types[].ba_operator` / `ba_us` (S$ a month, from Operator Pay,
  [school-bus-money.md](school-bus-money.md); `null` = not priced).
- `routes`: the routes of the plans in use (current and scheduled). Count them against the settings being edited: "x of
  y routes in current plans need a BA with these settings" (a route needs one when its `bus_type` is required by the
  settings); "No routes in current plans yet" when empty.

**Unlock:** `POST /schools/:id/unlock { section: "attendants" }`.

## 8. Setup strip and Summary

`GET /academic_years/:id/setup`, or `GET /schools/:id/setup` when no year is picked yet (it shows the year running today, else the
next one to start, else the latest; `?academic_year_id=` picks one; a school with no year at all answers `"year": null` and the
year steps not done):

```json
{ "year": "2026", "done": 4, "total": 7, "complete": false,
  "steps": [ { "number": 1, "key": "levels", "label": "School Levels", "scope": "school", "available": true, "done": true,
               "detail": "6 levels, P1 to P6", "locked_at": "…", "locked_by": "…" },
             { "number": 4, "key": "fares", "label": "Bus Fares", "scope": "year", "available": true, "done": false,
               "detail": "Not set up yet", "locked_at": null, "locked_by": null },
             { "number": 8, "key": "holidays", "label": "Holidays & Special Days", "scope": "year", "available": true, "done": null,
               "always_editable": true, "detail": "3 holidays, 1 special days" } ] }
```

- `detail` is the strip's sub-line, with the prototype's words: "6 levels, P1 to P6" / "Saved, not locked" / "Not set up yet";
  "Locked 02/11/2026" / "Year setup not saved" / "Not started"; "Needs the calendar first"; "Locked 02/11/2026. Parents pay"
  (also "School pays per bus" / "School pays per rider"); "Version 2 from 01/01/2027"; "Locked …. Statutory only" / "All buses" /
  "3 bus sizes"; "N holidays, M special days". Dates in `detail` are `dd/mm/yyyy`; format `locked_at` yourself if the user picked another format.
- Step 5 (Payment & Refund Policy) is `done` only when a version is **in use today** (`effective_on` today or earlier), the same
  rule Registration uses (prototype `polCur`). A version that starts later does not count yet.

- Show "`done` of `total` done" on the strip.
- Steps 1–7 count in `done` / `total` (7). Holidays & Special Days is step `number: 8` with `done: null` and
  `always_editable: true`: show it on the strip but leave it out of "`done` of `total`".
- Every step is `available: true` now (`available: false` would mark a step still to come).
- The Summary page reads each step's own endpoint: §3, §5, §6 and §7.

## 9. How the Scheduler uses this

School Bus runs on the Scheduler follow the **academic year calendar**, as in the prototype:

- A route runs on its plan's weekdays when the day is a school day of the year that covers it.
- With no academic year covering the date, it runs Monday to Friday, except public holidays.
- Special days do not move the runs, as in the prototype; they are information for planners.
- Settings › Calendars no longer drives School Bus runs; it still drives trips and School Runs.
- After a calendar or holiday change, the school's runs are re-synced in the background.

## 10. Front-end only

The FE handles these without the API:

- How It Works, Year at a Glance, Week at a Glance and the explainers.
- Typing the key or `UNLOCK` before unlocking.
- Rider CSV / XLSX templates.
- The map of riders.
