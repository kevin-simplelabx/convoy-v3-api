# Fleet — API Guide

The Fleet menu (rail icon `directions_bus`) with its two groups:
**Fleet**: Vehicles, Drivers, Bus Attendants, External Vehicles, Fuel & Energy, Maintenance, Vehicle Types ·
**Transport Operators**: Managed Operators, Operator Vehicles, Operator Drivers, Connected Operators.
What is not built yet is listed in [§ 10](#10-not-built-yet).

Conventions (sign-in, errors, paging, files, background reads) are in [README.md](../README.md).
All paths below start with `/api/v1`. The vehicle form (log card, insurance, default driver) is the Edit Vehicle screen of
the Scheduler: see [scheduler.md § 14](scheduler.md#14-edit-vehicle). It is not repeated here.

Writing needs the `vehicles` permission (Admin and owner always have it); a Convoy Admin can only read.

## Contents

1. [Vehicles and Operator Vehicles](#1-vehicles-and-operator-vehicles)
2. [Drivers and Operator Drivers](#2-drivers-and-operator-drivers)
3. [Managed Operators](#3-managed-operators)
4. [External Vehicles and the Share Form](#4-external-vehicles-and-the-share-form)
5. [Vehicle Types](#5-vehicle-types)
6. [Bus Attendants](#6-bus-attendants)
7. [Maintenance](#7-maintenance)
8. [Fuel & Energy](#8-fuel--energy)
9. [Values reference](#9-values-reference)
10. [Not built yet](#10-not-built-yet)

---

## 1. Vehicles and Operator Vehicles

The same list on two pages:

| Page | Call |
| --- | --- |
| Fleet > Vehicles (own buses) | `GET /vehicles?ownership[]=own&sort=smallest` |
| Transport Operators > Operator Vehicles | `GET /vehicles?ownership[]=managed` |

### 1.1 List: `GET /vehicles`

| Param | Description |
| --- | --- |
| `ownership[]` | `own`, `managed`, `external` |
| `team_id` | A team id, or `none` for vehicles with no team (the No Team chip) |
| `q` | Search: plate, make, model, team, operator, today's default driver (own), operator driver on the bus, typed driver (external) |
| `sort` | `type` (default), `smallest`, `largest`. The pages sort by plate on the front end if they want |
| `page`, `limit` | Paging |

Each row has `plate, seats, make, model, tags, ownership, size_name, default_picture, photo, driver { id, kind, name, phone },
operator, vehicle_team { id, name, color }, insurance { insurer, ends_on, status }`.
The insurance text of a row: `status` `expired` → "Insurance expired", `due_soon` → "Insurance ends <ends_on>", `valid` → "Insured to <ends_on>",
`none` → no insurance line. `insurance` is always an object: with no current policy it is `{ "insurer": null, "ends_on": null, "status": "none" }`.

`meta.facets.teams` gives the team chips for the `ownership[]` picked (the team filter is not applied to it):

```json
"teams": { "all": 13, "none": 2,
           "list": [ { "id": 1, "name": "East", "color": "#004F59", "count": 6 }, { "id": 2, "name": "West", "color": "#2F7FA8", "count": 0 } ] }
```

Show a chip per team (with its colour dot), then **No Team** when `none > 0`. With no teams at all, show one chip "All Vehicles".

### 1.2 Manage Teams: `PUT /vehicle_teams/bulk`

The whole window is saved at once:

```json
{ "teams": [ { "id": 1, "name": "East Depot", "color": "#004F59" }, { "name": "Coaches", "color": "#1E5631" } ] }
```

- A row with `id` renames or recolours that team; its vehicles move with it. A row without `id` adds a team.
- A team left out is deleted and its vehicles are left with no team. Ask first: "Delete East? Its 6 vehicles are left with no team".
- Two teams may swap names in one save.
- Errors (422): `"Give every team a name"`, `"Two teams have the same name"`.
- Response: the teams `[{ id, name, color }]`.

Colour swatches (front end): Teal `#004F59`, Sky `#2F7FA8`, Navy `#1F3A68`, Plum `#5B2A6E`, Rose `#B0306A`, Maroon `#8A1C2B`,
Amber `#B35C00`, Olive `#8C6D1F`, Forest `#1E5631`, Graphite `#33373D`.

### 1.3 Vehicle record: `GET /vehicles/:id`

The row fields plus:

| Field | Description |
| --- | --- |
| `registered_on`, `chassis_number`, `engine_number`, `coe_expires_on`, `road_tax_expires_on` | Log card details (editable on the vehicle form, [scheduler.md § 14.1](scheduler.md#141-vehicle)) |
| `upcoming_drivers` | Default driver changes still to come (own buses): `[{ starts_on, start_time, driver: { id, name } \| null }]`. "Starts on" text (add the time when not "00:00") |
| `fuel` | Fuel & Energy summary (section 8.5) |
| `financials` | Vehicle Financials summary for users with `vehicle financials` (`vehfin`) permission, else `null` (hide the section). See [finance § 6](finance.md#6-vehicle-financials-purchase-and-loan) |

Record sections and their calls:

| Section | Call |
| --- | --- |
| Default Driver (own) | [scheduler.md § 14.2](scheduler.md#142-default-driver-own-buses) |
| Usual Driver, Change Driver (managed) | 1.5 below |
| Log Card | `GET /vehicles/:vehicle_id/log_cards` |
| Insurance (status badge, current and past policies) | `GET /vehicles/:vehicle_id/insurance_policies` |
| Edit | The vehicle form ([scheduler.md § 14](scheduler.md#14-edit-vehicle)) |

### 1.4 Delete Vehicle: `DELETE /vehicles/:id`

The bus is kept for history (soft delete) and leaves every list. Refused (422) while it still has runs or a planned workshop
visit from now on:

`"PD1A still has 3 runs and 1 workshop visit from now on. Move or cancel them first, then delete the vehicle"`

The operator driver on the bus (if any) is taken off it.

### 1.5 Operator Vehicles: Change Driver / Operator Drivers: Assign Bus

The dialog lists the choices from lists the page already has:

- From a bus: active drivers of its operator, `GET /operator_drivers?status=active&q[operator_id_eq]=<operator_id>`,
  each with "On this bus" / "Now on <vehicle_plate>" / "Not on a bus", plus "No driver" when the bus has one.
- From a driver: buses of their operator, `GET /vehicles?ownership[]=managed` filtered by `operator.id`, each with
  "Driven by <driver.name>" / "No driver", plus "Not on a bus" when the driver has one.

When a choice is picked, show what will happen: `GET /operator_drivers/assign_preview`

| Picked | Params |
| --- | --- |
| Driver D for bus V (either dialog) | `driver_id=D&vehicle_id=V` |
| "No driver" on bus V | `vehicle_id=V` |
| "Not on a bus" for driver D | `driver_id=D` |

```json
{ "data": { "effects": [ "Ali moves from PC1X to PC2Y", "Bala moves to PC1X" ], "swap": true, "changed": true,
            "ok_label": "Swap Drivers", "apply": { "driver_id": 4, "vehicle_id": 9 } } }
```

`changed: false` (picked what is there now): disable the button. Confirm with
`PATCH /operator_drivers/:apply.driver_id/assign_vehicle { "vehicle_id": apply.vehicle_id }`.
422: `"PX9 is not a bus of Hup Seng"`, `"Chen has not accepted the invite yet"`.

---

## 2. Drivers and Operator Drivers

Both pages work the same way; operator drivers also have an operator, notes and a bus of that operator.

| Page | Base path | Body key |
| --- | --- | --- |
| Fleet > Drivers (own drivers) | `/drivers` | `driver` |
| Transport Operators > Operator Drivers | `/operator_drivers` | `operator_driver` |

### 2.1 Tabs: `GET /drivers?status=active`

| Param | Description |
| --- | --- |
| `status` | Tab: `active` (default), `pending` (Pending Invites), `declined` (Declined), `past` (Past Drivers) |
| `q` | Name, or 3+ digits of the mobile |
| `operator_id` | Operator drivers only |
| `page`, `limit` | Paging |

`meta.counts` = `{ "pending": 1, "active": 8, "declined": 1, "past": 1 }` for the tab labels (search applied, tab not).

Row (both pages):

```json
{ "id": 7, "name": "Eric Pang", "phone": "+6592104100", "phone_display": "+65 9210 4100", "status": "active",
  "invited_at": "...", "responded_at": "...", "joined_at": "...", "left_at": null, "status_on": "...",
  "photo": { "url": "/api/v1/downloads/...", "thumb_url": "..." },
  "display": { "name": "Eric", "photo": null, "set_by": "Ops Admin", "set_at": "..." },
  "kyc_shared": true, "last_vehicle": null }
```

Own drivers add `vehicle { id, plate, since }` (default driver today, "Default driver since <since>"; null = "Not on a bus") and
`upcoming [{ vehicle_id, plate, starts_on, start_time }]` ("Starts on PD1A from 7 Nov", "from 7 Nov 06:30" when the time is not "00:00").
Operator drivers add `operator_id, operator_name, notes, vehicle_id, vehicle_plate`.

Third column per tab: Active = bus; Pending = "Invited <status_on>"; Declined = "Declined <status_on>"; Past = "Left <status_on>" and
"Last drove <last_vehicle.plate>".
`joined_at` = accepted the invitation, `left_at` = removed or disconnected (null otherwise). Drivers answer invitations and
disconnect themselves in the Convoy Driver app ([driver/auth.md](../driver/auth.md)); the row buttons still work for the office.

### 2.2 Invite and edit

| Action | Call |
| --- | --- |
| Invite Driver | `POST /drivers` `{ "driver": { name, phone, photo (file) } }` |
| Invite Operator Driver | `POST /operator_drivers` `{ "operator_driver": { name, phone, operator_id, notes, photo } }` |
| Edit | `PATCH /drivers/:id` (same fields; `remove_photo: true` clears the photo) |

- The mobile may be typed as `9123 4567`; it is stored as `+6591234567` (no country code = Singapore). 422 when it is not a phone number.
- 422 `details.phone: ["Phone is already used by Eric Pang"]` when an invited or active driver has it.
- Once the driver has accepted, the mobile cannot change: `"Phone can only be changed by the driver in the Convoy Driver app"`
  (disable the field when `status != "pending"`).
- The invite is recorded (not sent yet). `POST` returns `meta.message`, the SMS text, for example
  `"Invited to connect with Hup Seng Coaches, managed by SimpleDrive. Download Convoy Driver to accept"`. Show it under the form
  before sending: own drivers `"<Company> invited you to drive with them on Convoy. Download Convoy Driver to accept"`.
- Operator drivers: changing the operator takes the driver off a bus of the old operator.

### 2.3 Row buttons

All are `PATCH /drivers/:id/<action>` (or `/operator_drivers/:id/<action>`) and return the driver.

| Tab | Button | Action |
| --- | --- | --- |
| Pending | Resend | `resend` |
| Pending | Mark Accepted / Mark Declined | `accept` / `decline` (until the Driver app answers, an admin records it) |
| Pending | Cancel invite | `DELETE /drivers/:id` |
| Active | View Details | 2.4 |
| Active | Assign Bus / Swap Bus (operator drivers) | Section 1.5 |
| Active | Remove driver | `remove` → Past Drivers |
| Declined, Past | Invite Again | `reinvite` (back to Pending, invite recorded again) |
| Declined, Past | Delete | `DELETE /drivers/:id` |

- **Remove** (own driver): the bus they drive today has no default driver from today, and any change that would have made them
  a default driver later is cleared too. Their bus is kept as `last_vehicle`. Confirm first: "Remove Tan? They lose access to your
  company in the Convoy Driver app and move to Past Drivers. PD1A will have no driver".
- **Remove** (operator driver): they leave their bus (`last_vehicle` keeps it).
- **Delete** keeps the record for history (runs they drove still show their name) but it leaves every list; the mobile can be
  invited again. Active drivers: 422 `"Remove Tan first. Active drivers move to Past Drivers"`.
- A button not allowed in the current state: 422 `"Tan is past, so this can't be done"`.

### 2.4 View Details: `GET /drivers/:id/details`

```json
{ "data": {
    "driver": { "...": "the row" },
    "kyc": { "email": "eric.pang@gmail.com", "address": "Blk 120 Jurong West St 52, #03-150, Singapore 640000",
             "date_of_birth": "1968-01-01", "age": 58, "nationality": "Singaporean", "residential_status": "Singapore Citizen",
             "id_label": "NRIC", "id_number": "S****567A", "id_revealed": false,
             "licence_class": "Class 4", "licence_qualified_on": "1993-01-01",
             "vocational_licence_number": "BD100000", "vocational_licence_expires_on": "2026-12-16", "vocational_status": "due_soon",
             "licences": [ { "kind": "dl", "name": "Driving Licence", "classes": "Class 4", "number": null, "issued_on": "1993-01-01", "expires_on": "2033-01-01" },
                           { "kind": "vl", "name": "Vocational Licence", "classes": "BDVL", "number": "BD100000", "issued_on": null, "expires_on": "2026-12-16" } ],
             "shared_at": "..." } } }
```

- `kyc: null` = the driver has not shared yet ("Shared from the Convoy Driver app once the driver accepts").
- `kyc` is the company's copy of the driver's profile from the Convoy Driver app: updated whenever the driver changes it while
  working for the company, kept as it was after they leave. `licences` = every licence the driver listed (Driving
  Credentials); the single `licence_class` / `vocational_*` fields come from the driving and vocational licence.
- The eye button: `GET /drivers/:id/details?reveal_id=true` returns the full `id_number` (`id_revealed: true`). Each reveal is logged.
- `vocational_status`: `expired` (red "Expired"), `due_soon` (orange "in N days", 90 days), `valid`.
- Only the driver can change these details (Driver app); there is no endpoint to edit them.

### 2.5 Shown to Your Customers: `PATCH /drivers/:id/display`

Multipart: `display_name`, `display_photo` (file, square crop done on the front end), `remove_display_photo=true`.
Sending an empty name with no photo clears it (`display: null`, "Not set. Customers see the name and photo the driver shared").
Response: the driver with `display { name, photo, set_by, set_at }` ("Set by <set_by> on <set_at>").

---

## 3. Managed Operators

Operators kept on file (no Convoy account of their own). External operators (companies external vehicles are hired from)
use the same endpoints with `kind: "external"`; see section 4.

### 3.1 List: `GET /operators?q[kind_eq]=managed`

Row: `id, name, kind, uen, contact_name, phone, email, payment_method, paynow_uen, bank_id, bank_code, bank_name, branch_code,
branch_name, account_number, account_number_sent, account_name, valid_until, cost_per_trip, cost_per_day,
pays_by { method, to, warn }, routes_count, vehicles_count`.

- **Pays By** column: `pays_by.method` ("PayNow UEN", "Bank Transfer", "Not set") over `pays_by.to`; orange when `warn`.
- **Routes**: School Bus routes of running plans whose regular bus today belongs to the operator.
- `q[name_cont]=hup` searches the name.

### 3.2 Add / Edit

`POST /operators` / `PATCH /operators/:id`:

```json
{ "operator": { "name": "Hup Seng Coaches", "kind": "managed", "uen": "199801234D", "contact_name": "Mr Lim",
                "phone": "+65 6123 4567", "email": "ops@hupseng.sg",
                "payment_method": "bank", "paynow_uen": "199801234D",
                "bank_id": 1, "account_number": "0721234567", "account_name": "HUP SENG COACHES PTE LTD", "branch_code": null } }
```

- `payment_method` is the default: `paynow` (PayNow UEN card) or `bank` (Bank Transfer card). Both can be saved.
- PayNow UEN left empty uses the UEN. UENs are checked: `"Uen looks wrong. Examples: 53012345A, 201912345K, T09LL1234A"`.
- Bank details (when `payment_method` is `bank` or any bank field is given): bank, 6 to 14 digit account number, account name.
- The branch code is worked out from the account number; send `branch_code` only for banks with `pick_branch` / `enter_branch`
  (3.3). Errors: `details.branch_code: ["Branch code must be picked"]`, `["Branch code must be 3 digits"]`,
  `details.account_number: ["Account number matches no UOB branch (check the first 3 digits)"]`.
- Changing the bank clears the old branch code.
- External operators: `paynow_uen` (free text), `cost_per_trip`, `cost_per_day`, `valid_until`; no payment checks.

Delete: `DELETE /operators/:id`. Refused while it has buses: `"Remove the 2 vehicles of Hup Seng Coaches first"`.
Ask first when `routes_count > 0`: "Hup Seng runs 3 routes. Delete anyway?".

### 3.3 Banks

`GET /banks` (no paging, platform list):

```json
{ "data": [ { "id": 1, "key": "7171D", "code": "7171", "name": "DBS Bank Ltd", "short_name": "DBS",
              "label": "DBS | DBS Bank Ltd (7171)", "branch_rule": "pre3",
              "rule_text": "Branch code is the first 3 digits of the account number",
              "pick_branch": false, "enter_branch": false, "branches": [] } ] }
```

- `pick_branch: true`: show the Branch select from `branches [{ code, name }]`.
- `enter_branch: true`: show a 3-digit Branch Code input.
- Otherwise the branch comes from the account number. While it is typed, show the info line from
  `GET /banks/:id/branch?account_number=0721234567` →
  `{ "data": { "code": "072", "name": "DBS Tampines", "send": "0721234567", "note": null, "rule": "Branch code is the first 3 digits of the account number" } }`
  ("Branch code 072, DBS Tampines. <note or rule>"). When it can't be worked out: `{ code: null, error: "No UOB branch matches the first 3 digits of this account number" }`.
- `send` / `account_number_sent`: the number as payment files carry it (HSBC and OCBC drop the 3 branch digits).

---

## 4. External Vehicles and the Share Form

Buses hired one-off or short-term from companies the company does not manage.

### 4.1 List and slots

`GET /vehicles?ownership[]=external` (rows as in 1.1, sort by plate on the front end).

- Columns: Plate (+ "Filled in by driver" when `source == "share_form"`), Seats, Driver (`driver_name`, `driver_phone`),
  Company (`operator.name`, `operator.phone`), PayNow / UEN (`operator.paynow_uen`, else "Not given").
- `meta.external_cap` = `{ "used": 3, "limit": 10, "left": 7 }` → "3 of 10 external vehicles", "7 slots left".
  When `left` is 0, disable Add External Vehicle and Review and Add: "All 10 slots are used. Remove an external vehicle you no
  longer need, or contact Convoy to raise the limit".

### 4.2 Add / Edit / Remove

| Action | Call |
| --- | --- |
| Add External Vehicle | `POST /vehicles/external` (also from the Scheduler, [scheduler.md § 13](scheduler.md#13-new-external-vehicle)) |
| Edit | `POST /vehicles/external` with `vehicle_id` |
| Remove | `DELETE /vehicles/:id` (section 1.4: refused while it has runs from now on) |

```json
{ "plate": "PA1234X", "seats": 45, "driver_name": "Muthu", "driver_phone": "+65 9123 4567", "vehicle_id": null,
  "submission_id": null,
  "company": { "name": "Kallang Bus Charter", "phone": "+65 9123 4567", "paynow_uen": "201912345K",
               "cost_per_trip": 180, "cost_per_day": 650, "valid_until": "2026-12-31" } }
```

The company is matched by name (case-insensitive) or created. Its phone, PayNow, costs and Valid Until apply to all its buses
("Kallang Bus Charter is on file with 2 other buses. Its details were filled in. Changes here apply to all its buses").
For the company field, offer the names of `GET /operators?q[kind_eq]=external` and fill the fields from the picked one.

### 4.3 Share Form link

| Action | Call |
| --- | --- |
| The link (made on first use) | `GET /external_share_link` → `{ token, created_at, api_path }` |
| New link (old one stops working) | `POST /external_share_link/reset` → the new link. Confirm: "Make a new link? The old link stops working. Answers already sent are kept" |

Build the page link from the token (for example `Convoy OS.dc.html?xform=<token>`). Copy Link, WhatsApp
(`https://wa.me/?text=Hi, please fill in your bus and driver details for <company>: <link>`) and Preview are front-end only.

### 4.4 The public Share Form page (no sign-in)

| Step | Call |
| --- | --- |
| Open | `GET /public/share_forms/:token` → `{ "data": { "company": "SimpleDrive" } }` |
| Send | `POST /public/share_forms/:token` |

```json
{ "submission": { "plate": "PB 4417 R", "seats": 45, "driver_name": "Mohd Hafiz", "driver_phone": "9345 1122",
                  "company_name": "Kallang Bus Charter", "company_phone": "+65 9123 4567", "paynow": "201912345K" } }
```

- 201 `{ "data": { "id": 12, "received": true } }` → thank-you screen ("Send another" clears the form).
- 422 with the first thing to fix as `message` and each field in `details`: "Enter the licence plate", "Enter your name",
  "Enter your mobile number", "Enter the company you drive for".
- 404 `"This link no longer works. Ask for a new one"` (revoked or unknown token).
- At most 10 answers per hour from one address: `429` `too_many_requests` "Too many tries. Try again in N seconds", with
  `Retry-After` ([README § Rate limits](../README.md#rate-limits)).

### 4.5 Answers waiting

| Action | Call |
| --- | --- |
| List ("2 answers waiting") | `GET /external_vehicle_submissions` (pending, newest first; `?status=added` / `dismissed` for the rest) |
| Review and Add | Open the External Vehicle form filled from the answer (plate, seats, driver, mobile, company, company phone, PayNow), then `POST /vehicles/external` with `submission_id` |
| Dismiss | `PATCH /external_vehicle_submissions/:id/dismiss`. Confirm "Dismiss the answer for PB4417R?" |

Row: `id, plate, seats, driver_name, driver_phone, company_name, company_phone, paynow, status, vehicle_id, decided_at, created_at`
→ "PB4417R | Mohd Hafiz" over "Kallang Bus Charter | +65 9345 1122 | 45 seats | Sent <created_at>".

---

## 5. Vehicle Types

### 5.1 Table: `GET /vehicle_types`

```json
{ "data": [ { "id": 3, "key": "minibus_13", "name": "Minibus", "seats": 13, "label": "Minibus | 13 seats",
              "tyre_layout": "1-1", "tyre_text": "2 axles, 1 tyre each side (4 tyres)", "position": 2, "custom": false,
              "enabled": true, "own_count": 6, "operator_count": 1 } ],
  "meta": { "tyre_layouts": { "1-1": "2 axles, 1 tyre each side (4 tyres)", "1-2": "..." } } }
```

| Column | Field / call |
| --- | --- |
| Offered (switch) | `enabled`; `PATCH /vehicle_types/:id/toggle { "enabled": false }` (company Admin) |
| Type, Seats | `name`, `seats` |
| Own Fleet / Operators | `own_count` / `operator_count`: the company's buses with exactly these seats (grey when 0 or the type is off) |
| Tyres | `tyre_text`. Convoy Admin: a select of `meta.tyre_layouts` → `PATCH /vehicle_types/:id { "vehicle_type": { "tyre_layout": "1-2" } }` |
| Remove (Convoy Admin, `custom` only) | `DELETE /vehicle_types/:id`. 422: `"Built-in types can't be removed. Companies turn them off instead"`, `"This type is used by trips"` |

Convoy Admin's Add row: `POST /vehicle_types { "vehicle_type": { key, name, seats, tyre_layout } }` (added as `custom`).

### 5.2 Request a New Type

| Who | Action | Call |
| --- | --- | --- |
| Company | Send Request | `POST /vehicle_type_requests { "vehicle_type_request": { name, seats, reason } }` |
| Company | Your Requests | `GET /vehicle_type_requests` (own company, newest first) |
| Convoy Admin | Requests From Companies | `GET /vehicle_type_requests` (every company; `?status=pending`) |
| Convoy Admin | Add Type | `PATCH /vehicle_type_requests/:id/approve { "tyre_layout": "1-2" }` (optional; by seats otherwise) |
| Convoy Admin | Decline | `PATCH /vehicle_type_requests/:id/decline` |

Row: `id, name, seats, reason, status, status_label, vehicle_type_id, decided_at, created_at, company { id, name }, requested_by`
→ "Luxury Coach | 27 seats" over "SimpleDrive | Requested <created_at> by <requested_by> | <reason>" with a badge
`status_label` ("Waiting for Convoy" warning, "Added" success, "Declined" neutral).

- 422 when the type already exists: `details.name: ["Name Luxury Coach 27 seats is already listed. Turn it on above"]`;
  `"Enter the type name"`, `"Enter the number of seats"`.
- Add Type uses an existing type with the same name and seats, else makes a custom type for every company.

---

## 6. Bus Attendants

| Action | Call |
| --- | --- |
| List | `GET /attendants` (`q[name_cont]=` to search) |
| Add Attendant | `POST /attendants { "attendant": { name, phone, notes, photo } }` |
| Edit | `PATCH /attendants/:id` |
| Delete | `DELETE /attendants/:id` (kept for history; routes keep their name) |

Columns: Name, Contact (`phone`), Notes. Routes pick an attendant in the School Bus route panel.

---

## 7. Maintenance

Every workshop visit of own buses. The Maintenance dialog (plan a visit, record the work, invoice reading, workshops) is the
Scheduler's: see [scheduler.md § 11](scheduler.md#11-maintenance-dialog-and-workshops). Schedule Maintenance opens it with
`GET /maintenance_visits/new?vehicle_id=`; Workshops opens the Workshops window. Delete in the dialog
("Delete this maintenance record?") is `DELETE /maintenance_visits/:id` → `204` for any saved visit (scheduled, completed or
cancelled); a completed visit's cost leaves the spend tiles below and Vehicle Financials.

### 7.1 List: `GET /maintenance_visits?tab=upcoming`

| Param | Description |
| --- | --- |
| `tab` | `upcoming` (default: scheduled, today on), `to_record` (scheduled, before today), `completed`, `cancelled` |
| `q` | Plate, workshop, work to do, or a type name ("tyres", "service") |
| `vehicle_id` | The vehicle select ("All vehicles" = omit) |
| `page`, `limit` | Paging |

Upcoming and To Record are soonest first; Completed and Cancelled newest first. `meta.counts` =
`{ "upcoming": 2, "to_record": 1, "completed": 4, "cancelled": 1 }` (search and vehicle applied) for the tab labels.

Row: `id, date, start_time, end_time, plate, kind, kind_name, workshop_name, address, work_to_do, driver_name, status, odometer,
subtotal, gst, total, items_count, has_invoice`. Button: "Record" on To Record rows, else "Open" → `GET /maintenance_visits/:id`.
Show `total` and "N items" only for completed visits; "Workshop not set", "No driver set" when empty.

### 7.2 KPI tiles, spend and tyre changes: `GET /maintenance_visits/summary?vehicle_id=`

```json
{ "data": {
    "kpis": { "next_30_days": 2, "to_record": 1, "spend_this_month": "0.0", "last_12_months": "2745.71", "last_12_months_visits": 4 },
    "spend": {
      "total": "2745.71",
      "by_type": [ { "name": "Tyres", "amount": "1439.1", "pct": 52 } ],
      "by_vehicle": [ { "name": "PC8841T", "amount": "1526.3", "pct": 56 } ],
      "by_workshop": [ { "name": "Ah Huat Motor Works", "amount": "1219.41", "pct": 44 } ],
      "by_month": { "2025-12": "0.0", "2026-01": "177.0", "...": "...", "2026-11": "0.0" },
      "tyres": [ { "date": "2026-07-20", "plate": "PC8841T", "position": "Rear Left Outer", "tyre": "Michelin XZE",
                   "size": "Tyre 215/75R17.5", "odometer": 98300, "quantity": "2.0", "cost_each": "337.9", "workshop": "Tyre Pro Ubi" } ] } } }
```

- KPIs: Next 30 Days (visits scheduled), To Record (orange when > 0: "Past visits without the invoice"), Spend this month
  (completed visits), Last 12 Months (amount and visits). KPIs ignore `vehicle_id`; spend uses it.
- Amounts include GST when the visit has it. `by_type` names: Parts, Tyres, Labour, Other. Each list has at most 8 rows,
  biggest first; `pct` is of `spend.total`. Draw bars relative to the first row.
- `by_month`: the last 12 months, oldest first, every month present.
- Tyre Changes: "<cost_each> each x <quantity>" when quantity > 1; "Brand not recorded" when `tyre` is null.

---

## 8. Fuel & Energy

Every refuel (diesel, petrol, AdBlue) and charge (electricity) of own buses, with the odometer and the driver of the day.
How It Works is static front-end text.

### 8.1 The month's log: `GET /fuel_entries?month=2026-11`

| Param | Description |
| --- | --- |
| `month` | `YYYY-MM` (default this month). `meta.next_month: false` disables the › button |
| `kind` | `all` (default), `fuel` (diesel and petrol), `elec`, `def` |
| `vehicle_id` | One bus (also set by clicking its card) |

All entries of the month, newest first (no paging):

```json
{ "id": 41, "vehicle_id": 7, "plate": "PD997M", "date": "2026-11-09", "time": "07:42", "kind": "diesel", "kind_name": "Diesel",
  "unit": "L", "quantity": "45.2", "cost": "119.78", "unit_price": "2.65", "odometer": 10600, "full": true,
  "fuel_company_id": 1, "fuel_company_name": "Esso", "station": "Jurong West Ave 2", "note": null,
  "km_since": 400, "efficiency": "10.0", "odometer_back": null,
  "driver_id": 3, "driver_name": "Eric Pang", "created_by": "Ops Admin", "document_read_id": null,
  "receipt": { "url": "/api/v1/downloads/...", "name": "receipt.jpg", "size": 81234, "content_type": "image/jpeg" } }
```

Row text:
- Quantity `45.2 L` with `unit_price` per unit ("S$2.65/L"); Odometer with "+400 km" (`km_since`).
- Efficiency: `efficiency` + " km/L" (fuel) or " kWh/100km" (elec); none: AdBlue = empty, `full` = "First full fill",
  else "Partial fill". Full / Partial label from `full`.
- `odometer_back` set: the reading is lower than the one before (shown in orange, and in Needs a Look).
- Station: "<fuel_company_name> <station> | <note>"; By: "<driver_name> | By <created_by>". Receipt button when `receipt`.

How the server works out the numbers (for the How It Works text): efficiency is measured from one full fill to the next of
the same energy: km between the two readings divided by everything added since (partial fills in between included).
`driver_id` is the bus's default driver that day and follows changes to the default driver schedule.

### 8.2 Add / Edit / Delete an entry

| Action | Call |
| --- | --- |
| Blank form | `GET /fuel_entries/new?vehicle_id=` → `{ vehicle_id, date, time, kind (of the bus's last entry), full, last_odometer }` |
| Add Entry | `POST /fuel_entries` |
| Save Entry | `PATCH /fuel_entries/:id` |
| Delete | `DELETE /fuel_entries/:id`. Confirm "Delete this diesel entry of 9 Nov?" |

```json
{ "fuel_entry": { "vehicle_id": 7, "date": "2026-11-09", "time": "07:42", "kind": "diesel", "quantity": 45.2, "cost": 119.78,
                  "odometer": 10600, "full": true, "fuel_company_id": 1, "station": "Jurong West Ave 2", "note": "Card 4471" },
  "document_read_id": 88 }
```

- Receipt: multipart `receipt` (PDF, JPG, PNG, WebP), or `document_read_id` of a finished `fuel_receipt` read (8.3).
- `kind`: `diesel`, `petrol`, `def` (AdBlue), `elec`. AdBlue is never a full fill (`full` saved false).
- Odometer hint: "+N km since the last entry (last_odometer km)", orange when lower.
- 422: `vehicle` ("must be one of your own buses"), `date`, `quantity` (> 0), `cost` (≥ 0).
- Response `meta: { filled: ["kind", "date", "quantity", "cost", "station", "fuel_company", "vehicle"], warnings: [...] }`:
  "Receipt read: … Check each one before saving". Warnings: "The receipt shows PD777Z, but the vehicle picked is PD1A",
  "The company on the receipt, Cnergy, is not in the list. Add it in Fuel Companies",
  "The odometer is lower than the last reading of 10650 km. Check the number".

### 8.3 Reading a receipt

As every Claude read ([README](../README.md)): `POST /document_reads { kind: "fuel_receipt", file }` → poll
`GET /document_reads/:id` until `done`. `result`: `{ kind, brand, station, date, time, quantity, cost, plate, odometer }`
(missing keys were not on the receipt). Then save the entry with `document_read_id`: empty fields are filled, the company is
matched in Fuel Companies, the bus is picked by plate when none is picked, and the receipt file is attached.
"Drop a Receipt" on the page = open a blank form, then do the same.

### 8.4 Vehicle cards: `GET /fuel_entries/vehicles?month=2026-11`

One card per own bus:

```json
{ "vehicle_id": 7, "plate": "PD997M", "sub": "Toyota HiAce Commuter", "entries": 23, "month_cost": "1029.91",
  "fuel_efficiency": "9.0", "elec_efficiency": null, "cost_per_km": "0.31", "km": 9623,
  "last": { "date": "2026-11-18", "kind": "diesel", "kind_name": "Diesel", "quantity": "38.5", "unit": "L", "odometer": 49623 } }
```

Efficiency: `fuel_efficiency` km/L or `elec_efficiency` kWh/100km ("No measure yet" when both null); cost per km over the
bus's whole log; "Last <date> | <kind_name>" or "No entries". Clicking a card sets `vehicle_id` on the log.

### 8.5 Fuel summary on the vehicle record

`GET /vehicles/:id` → `fuel` (own buses; null otherwise) has the card fields without `vehicle_id, plate, sub`:
Last Entry "<date> | <kind_name> <quantity> <unit> | <odometer> km", This Month (`month_cost`), Average, Cost per km.
`entries: 0` → "No refuels or charges recorded yet". Add Entry / Open Fuel & Energy go to the page with the bus picked.

### 8.6 Fuel Companies window

| Action | Call |
| --- | --- |
| List | `GET /fuel_companies` → `[{ id, name, kind: fuel \| elec \| both, position, entries_count }]` (Singapore defaults on first use) |
| Save | `PUT /fuel_companies/bulk { "companies": [{ "id": 1, "name": "Esso", "kind": "fuel" }, { "name": "Cnergy", "kind": "elec" }] }` |

Rows in the order shown; a row without `id` is added, one left out is deleted. Disable delete when `entries_count > 0`
("In use, so it cannot be deleted"); the server refuses it too: `"Esso is used by 12 entries, so it can't be deleted"`.
Also 422 `"Give every company a name"`, `"Two companies have the same name"`. The entry form's company select offers
companies whose `kind` matches (fuel / both for fuel and AdBlue, elec / both for charging).

### 8.7 KPI row: `GET /fuel/kpis?month=2026-11&vehicle_id=`

```json
{ "data": { "month": "2026-11", "spend": "18098.98", "spend_before": "17234.87", "spend_change_pct": 5,
            "fuel_litres": "6435.9", "kwh": "772.46", "fills": 75,
            "fuel_efficiency": "7.5", "elec_efficiency": "22.0", "measured": 84,
            "km": 40667, "cost_per_km": "0.45", "needs_a_look": 5 } }
```

| Tile | Fields |
| --- | --- |
| Spend <month> | `spend`; "+5% vs Oct 2026" from `spend_change_pct` (null: "No entries in <month before>") |
| Fuel | `fuel_litres` L; under it "<kwh> kWh charged" when kWh > 0, else "<fills> fills" |
| Efficiency | `fuel_efficiency` km/L, else `elec_efficiency` kWh/100km, else "N/A"; "Measured over <measured> full fills" or "Needs two full fills with odometer readings" |
| Cost per km | `cost_per_km` and "<km> km driven", or "N/A" / "Enter the odometer at each fill" |
| Needs a Look | `needs_a_look` (orange when > 0): "Unusual fills in the last 90 days" / "Nothing unusual" |

### 8.8 Needs a Look

| Action | Call |
| --- | --- |
| List | `GET /fuel_alerts?status=open` (or `checked`; `vehicle_id`), newest first; `meta.counts { open, checked }` for the tabs |
| Mark Checked | `PATCH /fuel_alerts/:id/check` |
| Undo | `PATCH /fuel_alerts/:id/reopen` |
| Look | Front end: open the Usage card on the alert's bus (`view=vehicle&key=<vehicle_id>`), `metric` as the measure, the bucket holding `date` marked |

```json
{ "id": 9, "vehicle_id": 7, "plate": "PD997M", "fuel_entry_id": 412, "kind": "dbl", "tone": "warn", "metric": "fuel",
  "message": "Two fills 30 km apart (50 L, then 20 L)", "date": "2026-11-10", "status": "open",
  "checked_by": null, "checked_at": null,
  "entry": { "kind_name": "Diesel", "quantity": "20.0", "unit": "L", "time": "10:00", "driver_name": "Eric Pang", "place": "Esso Jurong West Ave 2" } }
```

Row: "<plate> | <date> <entry.time>" over `message` and `entry.place`; checked rows add "Checked by <checked_by> on <checked_at>".
`metric` → Usage measure: `eff` → `eff`, `elec` → `elec`, `fuel` → `fuel`, `km` → `km`, `spend` → `spend`.
`tone: info` (grey) is a better-than-usual efficiency ("A fill may not have been recorded").

What is checked (fills of the last 90 days; the list is refreshed after every save and daily):

| `kind` | Finding |
| --- | --- |
| `eff` | Efficiency more than 30% off the bus's usual (median of 3+ measures) |
| `odo` | Odometer lower than the reading before |
| `dbl` | Two fills of the same energy less than 60 km or 6 hours apart |
| `big` | A fill more than 1.6 × the bus's usual fill (4+ fills) |
| `price` | Price per unit more than 15% above the fleet's usual for that kind |
| `trend` | Fuel (or energy) per km in the last 30 days more than 18% above the 30 days before |

### 8.9 Usage card: `GET /fuel/usage`

| Param | Values |
| --- | --- |
| `view` | `all` (default), `vehicle`, `driver`, `company` (By Vehicle / By Driver / By Company) |
| `key` | With a view: the vehicle, driver or fuel company id picked from the breakdown; `none` = no driver / company set |
| `measure` | `spend` (default), `fuel` (L), `elec` (kWh), `def` (AdBlue L), `km`, `eff` (km/L), `cpk` (cost per km) |
| `range` | `30d` (by day), `12w` (by week, from Monday), `12m` (default, by month) |
| `zoom_from`, `zoom_to` | Clicking a week or month bar: its first and last day (by day). "Back to 12 Months" drops them |

```json
{ "data": {
    "view": "vehicle", "key": null, "measure": "eff", "range": "12m", "zoomed": false, "by": "month",
    "period": { "from": "2025-12-01", "to": "2026-11-20" }, "before": { "from": "2024-12-01", "to": "2025-11-30" },
    "buckets": [ { "from": "2025-12-01", "current": null, "before": null }, { "from": "2026-11-01", "current": "8.2", "before": "8.4" } ],
    "total": "8.2", "total_before": "8.4", "change_pct": -2, "better": "higher",
    "rows": [ { "key": "7", "name": "PD997M", "current": "8.2", "before": "8.4", "change_pct": -2, "alerts": 2 } ],
    "drivers": [],
    "summary": { "title": "Worth a Look", "worth_a_look": true,
                 "text": "Spend is S$3975.00, up 12% on the period before. Fuel use is 8.2 km/L, steady against 8.4 before. 2 fills need a look, ..." } } }
```

- Chart: `spend`, `fuel`, `elec`, `def`, `km` as bars (this period beside the period before); `eff` and `cpk` as lines.
  `current` / `before` null = nothing measured in that bucket (gap in the line). The last bucket is the period so far.
- Totals: "<period> <total>", "<before label> <total_before>", change `change_pct`% coloured by `better`
  (`higher`: up is green; `lower`: down is green; null: neutral).
- The period before: 30 days / 12 weeks / 12 months earlier; a zoomed month against the month before; a zoomed week against
  the week before.
- `rows` (views other than all): every vehicle / driver / company with entries in either period, biggest first; `alerts` =
  open Needs a Look on it ("2 to check"). Clicking a row sets `key`.
- `drivers` (By Driver): `[{ driver_id, name, excess_pct, excess_pct_before, km, vehicles: ["PD1A"] }]`: fuel per km against the
  usual for the buses driven (each fill against that bus with other drivers, else buses of its size). Orange when
  `excess_pct > 10`. Fuel counts for the bus's default driver that day.
- `summary`: the card beside the chart (`title` "Worth a Look" / "All Normal", `text`).

---

## 9. Values reference

| Value | Meaning |
| --- | --- |
| Vehicle `ownership` | `own`, `managed` (managed operator), `external` |
| Vehicle `source` | `console` (added by a user), `share_form` (from a hired driver's answer: "Filled in by driver") |
| Driver `status` | `pending` (Pending Invites), `active`, `declined`, `past` (Past Drivers) |
| KYC `vocational_status` | `expired`, `due_soon` (90 days), `valid` |
| Operator `kind` | `managed`, `external` |
| Operator `payment_method` | `paynow`, `bank` (the default way to pay) |
| Bank `branch_rule` | `pre3`, `pre3drop`, `posb`, `sc`, `uob`, `list` (only `list` needs a branch picked or typed) |
| Share Form answer `status` | `pending`, `added`, `dismissed` |
| Vehicle type `tyre_layout` | `1-1`, `1-2`, `1-1-2`, `1-2-2` (text in `meta.tyre_layouts`) |
| Type request `status` | `pending` ("Waiting for Convoy"), `added`, `declined` |
| Maintenance `tab` | `upcoming`, `to_record`, `completed`, `cancelled` |
| Maintenance `kind` | `service`, `repair`, `tyres`, `inspection`, `other` |
| Maintenance line type | `part`, `tyre`, `labour`, `other` (spend names Parts, Tyres, Labour, Other) |
| Fuel `kind` | `diesel`, `petrol` (L), `def` (AdBlue, L), `elec` (kWh) |
| Fuel company `kind` | `fuel`, `elec` (charging), `both` |
| Fuel alert `kind` | `eff`, `odo`, `dbl`, `big`, `price`, `trend` |
| Fuel alert `status` | `open`, `checked` |
| Usage `measure` | `spend`, `fuel`, `elec`, `def`, `km`, `eff`, `cpk` |

---

## 10. Not built yet

| Screen / action | Why |
| --- | --- |
| Connected Operators | "Coming Soon" in the design. Keep the placeholder page |
| Vehicle Financials (the Financials section of the vehicle record, Add Financials, Open Vehicle Financials) | Built in the Finance menu: [finance § 6](finance.md#6-vehicle-financials-purchase-and-loan) |
| Log card "Get from Corppass" | "Coming soon" in the design |
| Invite SMS really sent; drivers answering and sharing details in the Convoy Driver app | No SMS sender / Driver app yet. Invites are recorded; Mark Accepted / Mark Declined stand in |
| How It Works (Fuel, Maintenance) | Static text on the front end |
