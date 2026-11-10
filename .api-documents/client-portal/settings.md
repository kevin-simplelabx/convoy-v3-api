# Client Portal — Settings: Users, Teams, Logo and Colour, Sites, Billing Details

Settings sits in the rail footer. Tabs by role (`can` from [`GET /portal/me`](shell.md#1-get-portalme)):
**Logo and Colour** (`can.brand`), **Users** (everyone: people who manage users see more), **Sites and Billing**
(everyone sees Sites; `can.billing` also edits Billing Details; label "Billing" when the client has no sites, "Sites" for
roles without billing), **Approval Flows** (`can.rules`: [approval-flows.md](approval-flows.md)).

## 1. Users

| Action | Call |
| --- | --- |
| List | `GET /portal/users` |
| Add User | `POST /portal/users { user: { name, email, role, site_ids: [], team_id, manager_id } }` → `201` |
| Edit (name and email stay) | `PATCH /portal/users/:id { user: { role, site_ids: [], team_id, manager_id } }` |
| Remove from Portal | `DELETE /portal/users/:id` → `204` |
| Role pills, "See what each role can do" | [`GET /portal/roles`](shell.md#2-get-portalroles--role-permissions) (`gives` of the viewer's role) |

User:

```json
{ "id": 12, "name": "Mei Ling", "email": "meiling@google.com", "role": "sa", "role_label": "Site Admin", "wide": false,
  "sites": [ { "id": 1, "name": "Mapletree Business City" } ], "team": { "id": 1, "name": "Workplace" }, "manager": null,
  "signed_in": false, "last_sign_in_at": null, "me": false, "can_edit": true, "can_remove": true }
```

- **Who is listed**: people who cannot manage users see only themselves. Super Admins and Admins see everyone; Site Super
  Admins and Site Admins see people who share one of their sites (not the organisation-wide roles).
- `can_edit` / `can_remove`: show the Edit icon and Remove from Portal. An Admin cannot change or remove a Super Admin; a site
  manager changes only people whose sites are all theirs and whose role they may give; nobody removes themselves.
- `signed_in: false` → "Not signed in yet" (they get a one-time code at first sign-in; no password is set here). `signed_in`
  means "a password is set", not "has signed in": `signed_in: true` with `last_sign_in_at: null` is valid (the password came
  from an invitation, a reset or the seed and the person has not signed in since). Show "Last sign-in" only when it is set.
- `wide: true` → "All sites" and hide Site Access ("covers every site, including sites added later"). Site roles need at
  least one site, and only the editor's own sites can be given (organisation-wide editors: any site).
- Role pills: only the roles in the viewer's `gives` (default Member).
- Team and Manager are optional. Manager: anyone listed but the person (label the empty choice "Team manager (<name>)"
  when their team has one). A manager is the Their Manager step in approval flows: their own manager, else the team's.
- Removing someone takes them off as manager of others and of teams.

`422` messages: "You cannot give this role", "You can only give your own sites", "Pick at least one site for a <role>",
"Keep at least one Super Admin for <client>", "<email> belongs to a Convoy OS user of your company", "Email is already a
user of this client", "Manager can't be themselves"; `403` for people the viewer does not manage.

## 2. Teams

| Action | Call |
| --- | --- |
| List (everyone) | `GET /portal/teams` → `[{ id, name, manager { id, name } \| null, people }]` ("Manager: X \| N people") |
| Add / Edit (Super Admin, Admin: `can.brand`) | `POST /portal/teams`, `PATCH /portal/teams/:id` `{ team: { name, manager_id } }` |
| Delete Team (confirm) | `DELETE /portal/teams/:id` → its people have no team |

Name is required and unique (`422` `details.name` "Name Ops is already a team"). Note under the manager: "A Their Manager
approval step goes to this person for everyone in the team, unless someone has their own manager set."

## 3. Logo and Colour

`PATCH /portal/settings/brand` (multipart; Super Admin, Admin) with any of `logo` (file), `remove_logo: true`,
`color` (`#RRGGBB`, `""` = No Colour) → `{ logo, logo_ratio, color }`.

- Logo: PNG, JPG or WebP, up to 1 MB (SVG is not taken). `logo` is `{ url, name, size, content_type }` (a signed link,
  like every file) or `null`; `logo_ratio` = width / height: the strip shows it 28 px high and `28 × logo_ratio` wide
  (clamp 28–140 px).
- Colour: `422` "Enter the colour as a hex code like #004F59"; saved upper case.
- Keep the draft in the page until **Save Changes** (Undo resets), then send once.
- Everyone sees it in `GET /portal/me` → `client_user.client.brand` (same shape), also on each account in the session.

## 4. Sites (read only)

`GET /portal/settings/sites` → the sites the person covers:

```json
[ { "id": 1, "name": "Mapletree Business City", "address": "70 Pasir Panjang Road, Singapore 117371", "lat": 1.2747, "lng": 103.7993,
    "billed_to": { "name": "Google Asia Pacific Pte. Ltd.", "uen": "200817984R", "own": false }, "shuttle_routes": 2 } ]
```

"Kept by <transport company>. Ask them to add or change a site." `billed_to.own: false` → "Billed to <name> | UEN …
(the organisation)". `shuttle_routes`: corporate shuttle routes serving the site (shown when the client has shuttles).

## 5. Billing Details (`can.billing`)

`GET /portal/settings/billing` → the entities the person may edit: **the organisation** (organisation-wide roles only)
and each **site billed as its own entity** they cover ("<site>, its own entity"). Sites are made their own entity by the
transport company.

```json
[ { "kind": "organisation", "site_id": null, "site_name": null, "legal_name": "Google Asia Pacific Pte. Ltd.", "uen": "200817984R",
    "billing_address": "70 Pasir Panjang Road, Singapore 117371", "billing_email": "ap@google.com", "attention": "Priya Raman",
    "changed": { "by": "Kenneth Ong", "at": "2026-11-04T10:00:00+08:00", "in_portal": true } } ]
```

| Save | Call |
| --- | --- |
| The organisation | `PATCH /portal/settings/billing/organisation { billing: { legal_name, uen, billing_email, attention, billing_address } }` |
| A site | `PATCH /portal/settings/billing/sites/:site_id { billing: { … same } }` |

- Answer: the entity again. `changed` → "Changed by <by> in the portal, <date>" (`in_portal: false`: by the transport company).
- Legal Name, Billing Email and Billing Address are required **when saving**; the GET can still answer `billing_email` / `attention`
  as `null` (data entered in Convoy OS or imported has none): show the fields empty.
- UEN optional (Singapore format, saved upper case); Attention
  optional. `422`: "Enter the legal name", "Enter the billing email", "Check the billing email", "Enter the billing address",
  "Check the UEN".
- The transport company keeps a list of people who get the invoices; Billing Email is the first one invoices go To and
  Attention the person named under Attention. Changing them here changes only those two; anyone else on the list stays.
- "<transport company> sees the change at once and uses it on the next invoice."
