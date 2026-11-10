# Client Portal — shell: who am I, what can I do, Role Permissions

The frame around every page: top bar (transport company, client, person, role and sites), the rail, and the Role
Permissions window. Call `GET /portal/me` after sign-in and after the organisation is switched
(`PATCH /portal/session`, see [auth.md](auth.md)); it drives which rail items and buttons show.
Without an organisation picked every call here answers `422` `pick_account` ([auth.md § 3](auth.md#3-after-sign-in-the-account-picked)).

## 1. `GET /portal/me`

```json
{ "data": {
  "account": { "id": 2, "email": "kenneth.ong@google.com", "name": "Kenneth Ong" },
  "client_user": {
    "client_user_id": 2, "name": "Kenneth Ong", "title": "Finance", "role": "fin", "role_label": "Finance Admin", "wide": true,
    "client": { "id": 2, "name": "Google Asia Pacific", "kind": "company",
                "brand": { "logo": { "url": "…", "name": "google-logo.png", "size": 4210, "content_type": "image/png" }, "logo_ratio": 3.2, "color": "#4285F4" } },
    "company": { "id": 1, "name": "SimpleDrive", "display_name": "SimpleDrive", "theme_color": "#0B6E6E", "logo": null } },
  "all_sites": true,
  "sites": [ { "id": 2, "name": "Google Asia Pacific (Pasir Panjang)" }, { "id": 1, "name": "Mapletree Business City" } ],
  "can": { "book": false, "see_all": true, "approve": true, "step_in": false, "users": false, "rules": false, "brand": false, "billing": true },
  "menu": { "approvals": true, "shuttles": true, "school_buses": false, "invoices": true } } }
```

| Field | Use |
| --- | --- |
| `client_user` | Same shape as an account in the session. Top bar: `company` (logo, name) \| client name; person name; "`role_label` \| sites" |
| `all_sites` | `true`: the person covers every site (Super Admin, Admin, Finance Admin, or a client with no sites) → "All sites" |
| `sites` | The sites the person covers, by name (every site when `all_sites`). Empty for a site role whose sites were all removed: they see nothing tied to a site |
| `can` | What the role may do (below). Hide the buttons it does not allow; the API refuses them anyway (`403`) |
| `menu` | Rail items that depend on the person or the client. Home, Bookings, Map, Notices and Settings always show |

`can`:

| Key | Allows | Roles |
| --- | --- | --- |
| `book` | New Booking, Accept Changes | Super Admin, Admin, Site Super Admin, Site Admin, Member |
| `see_all` | Every booking of their sites (otherwise only their own) | all but Member |
| `approve` | Can be asked by an approval flow | all but Member |
| `step_in` | Decide any waiting step | Super Admin, Admin |
| `users` | Settings › Users (add, change, remove people) | Super Admin, Admin, Site Super Admin, Site Admin |
| `rules` | Settings › Approval Flows | Super Admin, Admin, Site Super Admin, Site Admin |
| `brand` | Settings › Logo and Colour, Teams | Super Admin, Admin |
| `billing` | Invoices, Settings › Billing Details | Super Admin, Admin, Finance Admin, Site Finance |

`menu`: `approvals` (roles that approve, or a person named in an approval flow step), `shuttles` (the client has corporate shuttle routes), `school_buses` (the client
is a school, or a site the person covers is one: Home tile School Buses Today and the AM / PM / CCA activities on the Map),
`invoices` (`can.billing`).

Sites and roles: Super Admin, Admin and Finance Admin cover every site, including sites added later. Site roles cover
only the sites picked for them. Something with no site (a booking the transport company made without one) is shown
to the organisation-wide roles only.

## 2. `GET /portal/roles` — Role Permissions

```json
{ "data": {
  "roles": [ { "key": "sa", "label": "Site Admin", "tag": "Like Site Super Admin, cannot remove one", "wide": false, "gives": ["sa", "sfin", "member"] } ],
  "features": [
    { "group": "Bookings", "features": [
      { "name": "Make a booking", "detail": "Request trips priced from your rate card. …", "roles": ["super", "adm", "ssa", "sa", "member"] } ] } ] } }
```

- `roles`: the seven roles in order (`super`, `adm`, `fin`, `ssa`, `sa`, `sfin`, `member`) with the one-line tag and
  `gives` (the roles this role may give in Settings › Users).
- `features`: the window's rows by group, as in the design (columns = `roles`; click a row for `detail`). Some rows
  describe things not built yet (ask to cancel, pay invoices, send a notice): shown as in the design.
