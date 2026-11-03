# Driver app — Account: profile, licences, company, vehicle

Account tab: the profile card and Career Metrics, Personal Details, Complete My Profile, Email (and password),
Driving Credentials, Transport Company, Contact Operations, Company Links, My Vehicle Today.
Conventions: [README.md](README.md). Paths start with `/api/v1`. Files are sent as `multipart/form-data`.

The profile belongs to the driver and travels with them between companies. Every company they work for (active
membership) gets a copy each time it changes (Drivers › View Details in Convoy OS); a company they left keeps the copy as
it was when they left.

## Contents

1. [Profile](#1-the-profile-get-driverprofile)
2. [Personal Details](#2-personal-details-patch-driverprofile)
3. [Email and password](#3-email-and-password-patch-driverprofileemail)
4. [Driving Credentials](#4-driving-credentials)
5. [Transport Company, Contact Operations, Company Links](#5-transport-company-get-drivercompany)
6. [My Vehicle Today](#6-my-vehicle-today)
7. [Values reference](#7-values-reference)

---

## 1. The profile: `GET /driver/profile`

The Account card, Personal Details, Complete My Profile and the Driving Credentials list in one answer:

```json
{ "data": {
  "id": 1, "phone": "+6592104100", "phone_display": "+65 9210 4100", "phone_verified": true,
  "name": "Eric Pang", "email": "eric.pang@gmail.com", "password_set": true,
  "photo": { "url": "/api/v1/downloads/...", "thumb_url": "/api/v1/downloads/...", "name": "drv-2.png", "size": 48211, "content_type": "image/png" },
  "date_of_birth": "1979-06-21", "nationality": "Singaporean", "residential_status": "Singapore Citizen",
  "id_label": "NRIC", "id_number": "S****345D",
  "address": "Blk 120 Jurong West St 52 #03-150", "postal_code": "640120",
  "full_address": "Blk 120 Jurong West St 52 #03-150, Singapore 640120",
  "singpass": { "verified": true, "verified_at": "2026-10-03T10:00:00+08:00",
                "fields": ["name", "id_number", "date_of_birth", "nationality", "residential_status", "address", "postal_code"] },
  "completeness": { "done": 6, "total": 6, "items": [
    { "key": "phone", "done": true }, { "key": "name", "done": true }, { "key": "date_of_birth", "done": true },
    { "key": "email_password", "done": true }, { "key": "licences", "done": true }, { "key": "photo", "done": true } ] },
  "licences": [ { "id": 1, "kind": "dl", "name": "Driving Licence", "classes": "Class 3, 4", "...": "see § 4" } ],
  "metrics": { "this_company": { "trips": 1284, "hours": 1530.5, "km": 31250.2 },
               "all_time": { "trips": 3594, "hours": 4210.0, "km": 88010.7 } }
} }
```

- `id_number` is always masked; the full number is never sent to the app.
- `singpass.fields`: the details verified with Singpass. Show them with the lock and "Verified with Singpass on
  `verified_at`"; they cannot be changed in the app. **Update with Singpass is not available yet** (no Myinfo link): hide
  the button or show it disabled.
- Complete My Profile rows (`completeness.items`, in this order): Verify phone number, Add your name, Add date of birth,
  Add email and password, Add driving credentials (a driving licence **and** a vocational licence, each with classes),
  Add profile photo. "`done` of `total` done".
- Career Metrics: completed trips, hours driven and distance. **This Company** = the company picked for the sign-in
  (zeros when none), **All Time** = every company the driver works or worked for.

## 2. Personal Details: `PATCH /driver/profile`

`{ profile: { name, date_of_birth, nationality, residential_status, id_number, address, postal_code, photo, remove_photo } }`
→ the profile (§ 1). Send only the fields that changed. `photo` is a file (crop it square in the app); `remove_photo: true`
removes it.

- `residential_status`: one of the values in § 7. `postal_code`: 6 digits. `date_of_birth`: `YYYY-MM-DD`, in the past.
- `id_number` (NRIC / FIN) can be added once; after that it is verified: `422` "Your NRIC / FIN is verified, so it cannot be
  changed here". The mobile number cannot be changed here.
- A field verified with Singpass: `422` "Full Name is verified with Singpass and cannot be changed here" (`details.<field>`).
  Sending the same value again is fine.
- Other errors: `422` with `details.<field>`, e.g. `details.postal_code` "Postal code must be 6 digits".

## 3. Email and password: `PATCH /driver/profile/email`

`{ email, password, password_confirmation, current_password }` → the profile. Lets the driver sign in with
[`POST /driver/session/email`](auth.md#2-sign-in-with-email-and-password-post-driversessionemail) when the SMS cannot
reach them.

- The first time no `current_password` is needed; to change them later it is: `422` "Your current password is not right".
- `422` `details.password` "Password needs at least 8 characters", `details.password_confirmation`, `details.email`
  (taken or not an email).
- The email is not verified with a code yet.

## 4. Driving Credentials

| Button | Call |
| --- | --- |
| Tap a licence → Save | `PATCH /driver/licences/:id` |
| Add a Licence → Save | `POST /driver/licences` |
| Delete (in the licence sheet) | `DELETE /driver/licences/:id` → `204` |

The list is `licences` in [`GET /driver/profile`](#1-the-profile-get-driverprofile).

### 4.1 Add a licence: `POST /driver/licences`

`{ licence: { kind, name, classes, number, issued_on, expires_on, card_front, card_back } }` (cards are image files) →
`201` the licence:

```json
{ "data": { "id": 2, "kind": "vl", "name": "Vocational Licence", "classes": "BDVL", "number": "BD107919",
            "issued_on": null, "expires_on": "2027-01-02", "days_left": 60, "expiry_status": "due_soon",
            "card_front": { "url": "...", "thumb_url": "..." }, "card_back": null } }
```

- `kind`: `dl` (driving licence), `vl` (vocational licence, e.g. BDVL) or `other` (Class 4A, Omnibus…). One `dl` and one `vl`
  each: `422` `details.kind` "Kind is already on your list". `name` defaults to "Driving Licence" / "Vocational Licence";
  `other` needs a `name`.
- Badge from `expiry_status`: `valid`; `due_soon` (90 days or less, orange "Expires … · in `days_left` days");
  `urgent` (30 days or less, red); `expired` (red "Expired …"); `missing` (no expiry date: "Add the expiry date").

### 4.2 Update a licence: `PATCH /driver/licences/:id`

Same fields, plus `remove_card_front: true` / `remove_card_back: true`. → the licence. `404` for a licence that is not the
driver's.

### 4.3 Remove a licence: `DELETE /driver/licences/:id`

→ `204`.

## 5. Transport Company: `GET /driver/company`

Account › Transport Company, Contact Operations and Company Links, for the company picked for the sign-in
(`422` "Pick a company first" without one):

```json
{ "data": {
  "membership": { "key": "driver-4", "kind": "own", "status": "active", "company": { "name": "SimpleDrive", "...": "..." },
                  "joined_at": "2026-05-03T09:00:00+08:00", "...": "as in the session" },
  "uen": "201912345K", "vehicles_count": 48, "role": "Driver",
  "operations": { "phone": "+65 6222 1100", "hours": "Mon–Sat 05:30–20:00", "whatsapp": "+65 9222 1100",
                  "email": "ops@simpledrive.sg", "depot_address": "12 Tuas Avenue 8, Singapore 639226" },
  "links": [ { "id": 1, "title": "Depot map", "url": "https://simpledrive.sg/depot", "note": "Bays and the wash bay" } ]
} }
```

- Card rows: company name + "Current", "UEN `uen` · `vehicles_count` vehicles"; Your Role = `role` (a managed driver:
  "Driver, Hup Seng"), "Since" `membership.joined_at`; Operations = `operations.phone` and `hours`; Company Links = the
  count of `links`. Any value may be null (the company has not filled it in): hide that row.
- Contact Operations: hotline `operations.phone`, WhatsApp `operations.whatsapp`, email, depot.
- Switch Company and Disconnect: [auth.md § 4–5](auth.md#4-switch-company-and-sign-out).
- Employment History: [`GET /driver/companies`](auth.md#51-list-companies-get-drivercompanies) (each row has
  `trips_completed` there).

## 6. My Vehicle Today

The bus now, Switch Vehicle (the handover inspection) and Vehicle History: [vehicle.md](vehicle.md).

## 7. Values reference

| Field | Values |
| --- | --- |
| `residential_status` | `Singapore Citizen`, `Permanent Resident`, `Employment Pass`, `S Pass`, `Work Permit`, `Other` |
| `id_label` | `NRIC` (Citizen, PR, Other, none), `FIN` (Employment Pass, S Pass, Work Permit) |
| `licence.kind` | `dl`, `vl`, `other` |
| `licence.expiry_status` | `valid`, `due_soon`, `urgent`, `expired`, `missing` |
| `completeness.items[].key` | `phone`, `name`, `date_of_birth`, `email_password`, `licences`, `photo` |
