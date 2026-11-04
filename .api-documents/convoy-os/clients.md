# Clients — API Guide

The Clients menu (rail icon `corporate_fare`): **Managed Clients** (list and the client record page) and **Connected
Clients** (Coming Soon). This file also covers the **Client Portal sign-in** (§ 5), since client users are added here.
What is not built yet is listed in [§ 7](#7-not-built-yet).

Conventions (sign-in, errors, paging, files, background reads) are in [README.md](../README.md).
All paths below start with `/api/v1`. Any company user can add and change clients (the trip form adds them too);
a Convoy Admin can only read.

## Contents

1. [Managed Clients](#1-managed-clients)
2. [Sites, customers, vehicles and pick-up points](#2-sites-customers-vehicles-and-pick-up-points)
3. [Client Users](#3-client-users)
4. [Values reference](#4-values-reference)
5. [Client Portal sign-in](#5-client-portal-sign-in)
6. [Changes to existing endpoints (02/11/2026)](#6-changes-to-existing-endpoints-02112026)
7. [Not built yet](#7-not-built-yet)

---

## 1. Managed Clients

### 1.1 List: `GET /clients`

| Param | Description |
| --- | --- |
| `q[name_i_cont]` | Search by name (also `q[code_eq]`, `q[kind_eq]`, `q[email_i_cont]`, `q[uen_i_cont]`) |
| `page`, `limit` | Paging |

Row: `id, code, kind, name, uen, contact_name, phone, email, billing_address, on_time_allowance`.
Badges: `kind` `individual` → "Individual", `transport_company` → "Main Contractor".

### 1.2 Add / Edit Details

Add: `POST /clients`. Edit: `PATCH /clients/:id`.

```json
{ "client": { "kind": "company", "name": "St. Stephen's School", "uen": "T08GB0047K", "contact_name": "Mrs Lee",
              "billing_address": "20 Siglap View", "phone": "+65 6241 1243", "email": "transport@ststephens.edu.sg",
              "school_id": 3, "school_calendar_id": 7 } }
```

- `kind`: `company`, `individual` (name label "Full Name"; no UEN / contact), `transport_company` (Main Contractor).
- `uen` is upper-cased; `422` "Uen looks wrong. Examples: 53012345A, 201912345K, T09LL1234A".
- An individual needs a phone or an email.
- **This Client Is a School** (only `company`, shown when School Bus has schools): `school_id` links the school to this client
  (`null` / empty unlinks it). `422` "<school> is already linked to <client>".
- **School Calendar** (only with a school): `school_calendar_id`, a calendar with `kind: school` (`422` "Pick a school calendar").
  It is the school's calendar: its holidays stop the school's buses (they re-sync in the background).
- Changing `kind` away from `company` unlinks the school.
- Response: the record (§ 1.3), `201` when added.

### 1.3 Record page: `GET /clients/:id`

The row fields plus `school { id, name }`, `school_calendar { id, name }`, `sites`, `end_customers`, `pickup_points`
(§ 2). Details card: Client Is, Client Code (`code`), UEN, Contact Person, Phone, Email, Billing Address, School, School Calendar
(show only those with a value).

**On-Time Allowance** (−1 / +1, 0–15 minutes): `PATCH /clients/:id { client: { on_time_allowance: 4 } }`. Text: "Within 4 min".

### 1.4 Delete Client: `DELETE /clients/:id`

`204`, the client is removed from the list and pickers; past trips keep its name. Refused (`422`) while the client
has trips still running (not deleted, last date not passed) or open bookings (waiting or approved):
"Google has 2 trips still running and 1 open booking. End or delete them first".

## 2. Sites, customers, vehicles and pick-up points

### 2.1 Sites

| Action | Call |
| --- | --- |
| List (also in the record) | `GET /clients/:client_id/sites` |
| Add Site | `POST /clients/:client_id/sites { client_site: { name, address, lat, lng } }` |
| Edit Site (dialog) | `PATCH /clients/:client_id/sites/:id` |
| Remove | `DELETE /clients/:client_id/sites/:id` |

The address and pin come from OneMap on the front end (search the typed address or postal code, send `address`, `lat`, `lng`;
no pin found → send the typed text only: "No pin found; stops are matched by name").

Site: `{ id, client_id, name, address, lat, lng, school { id, name }, own_billing, billing_name, billing_uen, billing_address,
billing_contacts [{ id, name, email, send_as, attention }], shuttle_trips_count, created_at }`.
Row text: "Billed to <billing_name> | UEN <billing_uen>" when `own_billing`, else "Billed to <client name>";
sub line "On 2 shuttle trips" (`shuttle_trips_count`), else "Pin set" / "No pin".

Edit Site body:

```json
{ "client_site": { "school_id": 4, "own_billing": true, "billing_name": "Bright Steps (Punggol) Pte Ltd",
                   "billing_uen": "201912345K", "billing_address": "1 Punggol Field",
                   "billing_contacts": [ { "name": "Accounts", "email": "ap@bs.sg", "send_as": "to", "attention": false },
                                         { "name": "Mr Lim", "email": "", "send_as": "to", "attention": true } ] } }
```

- **This Site Is a School**: `school_id` (or `null`). One school per client or site: `422` "School is already linked to <client>".
- **Billed as its own legal entity**: `own_billing: true` needs `billing_name`. `own_billing: false` clears the billing fields and people.
- **Send Invoices To**: send the whole list (up to 6, empty rows are dropped). Each person needs an email unless ticked under
  Attention; an Attention person needs a name; when anyone has an email, at least one must be `to`
  (`422` "Send the invoice To at least one person, not only CC").
- Remove is refused while a trip (not deleted) is for the site or has a stop marked as the site:
  "HQ is on 2 shuttle trips. Unmark it in Stop Details first".
- `422` "Name is already a site of this client" (any case).

### 2.2 Their Customers (Main Contractor)

`POST /clients/:client_id/end_customers { client_end_customer: { name } }`, `DELETE /clients/:client_id/end_customers/:id`.
`422` "Name is already on the list" (any case); a customer used by trips or bookings can't be removed.

### 2.3 Bookable Vehicles: `PUT /clients/:id/bookable_vehicle_types`

`{ "vehicle_type_ids": [3, 5] }`; `[]` = **All Vehicle Types**. Only types the company offers (`422` "Pick vehicle types you offer").
Response: the record; `bookable_vehicle_type_ids` (`[]` = all). Pills: "All Vehicle Types" + one per offered type (`GET /vehicle_types`).
Text: none picked → "The client sees every vehicle type you offer…", some → "The client books only these in the Client Portal…".

### 2.4 Saved Pick-up Points

`POST /clients/:client_id/pickup_points { client_pickup_point: { name, address, postal_code, lat, lng, note } }`,
`DELETE /clients/:client_id/pickup_points/:id`. Each point has `created_by { id, name }` and `created_at`:
"Added by Rachel Tan on 2 Nov 2026"; `note` → "Note for the driver: …".

## 3. Client Users

People at the client who sign in to the Client Portal. The same email can be a user of several clients (one Portal
account, an account picker at sign-in).

| Action | Call |
| --- | --- |
| List | `GET /clients/:client_id/users` |
| Add User | `POST /clients/:client_id/users { client_user: { name, title, email, role, site_ids: [] } }` |
| Edit (dialog: title, role, site access) | `PATCH /clients/:client_id/users/:id { client_user: { title, role, site_ids: [] } }` |
| Remove | `DELETE /clients/:client_id/users/:id` (confirm "Remove <name>?") |
| Role select, Role Permissions window | `GET /client_users/roles` |

User: `{ id, client_id, name, title, email, role, role_label, wide, sites [{ id, name }], team { id, name }, manager { id, name },
created_by { id, name, in_portal }, created_at, portal { password_set, last_sign_in_at } }`. Sub line: "Added <created_at> by
<created_by.name>" (`in_portal: true`: added by a client user in the Client Portal → "… in the Client Portal"); sites text:
`wide` or no sites → "All sites", else the site names. `team` / `manager` (or `null`) are set by the client in the Client
Portal (Settings › Users), shown read-only here. The list's Users column: `users_count` on `GET /clients`.

- **Site Access**: `wide` roles (Super Admin, Admin, Finance Admin) cover every site: hide the pills, `site_ids` is ignored.
  Site roles need at least one site when the client has sites (`422` "Pick at least one site for a Site Admin").
  Hint: no sites → "This client has no sites, so access covers everything".
- On edit, leave `site_ids` out to keep the sites. Name and email are not changed after adding.
- `422`: "Email is already a user of this client", "<email> belongs to a Convoy OS user of your company",
  "Keep at least one Super Admin for <client>" (changing or removing the last one), "Some sites are not sites of <client>".
- After adding: "They sign in to the Client Portal with this email, get a one-time code the first time and set their own password."

## 4. Values reference

Client Portal roles (`GET /client_users/roles`):

| `role` | Label | Line | Sites |
| --- | --- | --- | --- |
| `super` | Super Admin | Everything, every site | Every site |
| `adm` | Admin | Everything except removing a Super Admin | Every site |
| `fin` | Finance Admin | Bookings, invoices and billing, every site | Every site |
| `ssa` | Site Super Admin | Runs their sites: people, bookings, approvals | Picked sites |
| `sa` | Site Admin | Like Site Super Admin, cannot remove one | Picked sites |
| `sfin` | Site Finance | Bookings, invoices and billing for their sites | Picked sites |
| `member` | Member | Books trips for their sites | Picked sites |

The feature rows of the Role Permissions window (what each role may do in the Portal) are fixed text on the front end
(`ROLE_FEAT` in the prototype's `logic/app-feed.js`). Client `kind`: `company`, `individual`, `transport_company`.

## 5. Client Portal sign-in

Moved to the Client Portal documents: [client-portal/auth.md](../client-portal/auth.md) (sign-in, account picker, session).
Client users added here (§ 3) sign in there.

## 6. Changes to existing endpoints (02/11/2026)

| Endpoint | Before | Now |
| --- | --- | --- |
| `POST` / `PATCH /clients` | Saved any UEN | UEN checked (`422`); new fields `school_id`, `school_calendar_id` |
| `GET /clients/:id` | Sites, customers, points | Also `school`, `school_calendar`, `bookable_vehicle_type_ids`; sites have school / billing fields; points have `created_by` |
| `POST` / `PATCH /clients/:client_id/sites` | name, address, pin | Also school and billing (§ 2.1); `DELETE` refused while trips use the site |
| `POST /clients/:client_id/end_customers` | Case-sensitive duplicate check | Any case: "Name is already on the list" |
| `GET /clients` | Client fields | Also `users_count` |
| `DELETE /clients/:id` | Always deleted | Refused while trips run or bookings are open |

## 7. Not built yet

- Connected Clients (Coming Soon in the prototype).
- Everything inside the Client Portal after sign-in (bookings, approvals, invoices, live map) and managing users from the Portal.
- Real email sending (the sign-in code is only shown on dev / staging, see § 5).
- Portal API after sign-in (no Portal data endpoints yet besides the session).
