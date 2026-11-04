# Client Portal — Settings › Approval Flows

Who must approve a booking before the transport company sees it. Super Admins and Admins set the **organisation's flow**;
Site Super Admins and Site Admins (and organisation-wide managers) set a **site's own flow** (`can.rules` in
[`/portal/me`](shell.md#1-get-portalme)). A booking for a site whose own flow is on follows only that flow; every other
booking follows the organisation's. Flow off = no approval: bookings go straight to the transport company.

How a booking is routed: the rules are checked from the top; the first whose conditions **all** match decides; none
matching → **Otherwise**. Each step asks groups of people (any one of them, or everyone); steps run in order. A rule
with no steps = "Approved automatically".

## 1. The flows

`GET /portal/approval_flows` → the Flow For pills, in order: "Whole Organisation" (organisation-wide roles only) then each
site the person covers ("<site> (own flow)" when `on`).

```json
{ "data": [ {
  "for": "organisation", "site": null, "on": true,
  "rules": [
    { "id": 2, "name": "Large bookings", "position": 1, "same_person": "other", "approved_automatically": false,
      "when": { "site_ids": [], "booker_ids": [], "team_ids": [], "kinds": [], "over": 2000.0, "lead_days": null },
      "when_text": ["Estimate over S$2,000"],
      "steps": [ { "id": 1, "who": ["fin"], "need": "any", "people": [], "text": "Finance, any one" },
                 { "id": 2, "who": ["admins"], "need": "any", "people": [], "text": "Admins, any one" } ] } ],
  "otherwise": { "id": 1, "name": "Otherwise", "same_person": "once", "approved_automatically": false,
                 "when_text": ["Every other booking"],
                 "steps": [ { "id": 4, "who": ["site"], "need": "any", "people": [], "text": "Site Admins, any one" } ] } } ] }
```

- `for`: `"organisation"` or the site id: use it in every call below (`/portal/approval_flows/:for/...`).
- Drawing: Start "Booking Submitted" → each rule "Checked 1st / 2nd…" (`name`, When = `when_text` lines, Then = each step's
  `text`, or "Approved automatically") → "Otherwise / Every other booking" → End "Sent to <transport company> — They
  confirm, change or decline each trip".
- `same_person` (shown under the steps): `once` "If the same person is on two steps, their approval counts for both",
  `other` "… the later step needs someone else".
- A rule that names a site, person or team removed since shows "a removed site" / "a removed person or team" in
  `when_text` and matches no booking until it is edited.
- A flow never saved shows `on: false`, no rules and an empty Otherwise (`id: null`).

## 2. Change a flow

| Action | Call |
| --- | --- |
| Approvals On / Own Flow for <site> | `PATCH /portal/approval_flows/:for { on: true \| false }` |
| Add Rule (turns the flow on) | `POST /portal/approval_flows/:for/rules { rule }` → `201` |
| Edit Rule | `PATCH /portal/approval_flows/:for/rules/:id { rule }` |
| Delete Rule (confirm) | `DELETE /portal/approval_flows/:for/rules/:id` |
| Move up / down | `POST /portal/approval_flows/:for/rules/:id/move { direction: "up" \| "down" }` |
| Edit Otherwise (steps and same person only) | `PATCH /portal/approval_flows/:for/otherwise { rule: { steps, same_person } }` |

Every call answers the whole flow (§ 1 shape).

`rule`:

```json
{ "name": "Large bookings",
  "when": { "site_ids": [1], "booker_ids": [12], "team_ids": [2], "kinds": ["airport"], "over": 2000, "lead_days": 3 },
  "steps": [ { "who": ["site", "fin"], "need": "all" }, { "who": ["people"], "people_ids": [14], "need": "any" } ],
  "same_person": "once" }
```

| Field | Rule editor |
| --- | --- |
| `name` | Rule Name (required: "Name the rule, e.g. Large bookings") |
| `when.site_ids` | Site Is (organisation's flow only; ignored on a site's own flow) |
| `when.booker_ids`, `when.team_ids` | Booked By: these people **or** anyone in these teams (`GET /portal/users`, `GET /portal/teams`) |
| `when.kinds` | Includes a Trip Type: `one_way` Ad Hoc / Charter, `two_way` … Two Way, `disposal`, `airport` |
| `when.over` | Estimate Over S$ (optional, > 0) |
| `when.lead_days` | Booked Less Than N days ahead (optional, whole days > 0) |
| `steps` | Up to 5. `who`: one or more of `mgr` Their Manager, `site` Site Admins, `fin` Finance, `admins` Admins, `people` Named People (keep at least one). `people_ids` with `people`: users covering the flow's site (any user for the organisation's flow). `need`: `any` "Any one can approve", `all` "Everyone must approve" |
| `same_person` | When the Same Person Is on Two Steps: `once` Approves Both (default), `other` Needs Someone Else |

Who each group is, for a booking: Their Manager = the booker's own manager, else their team's manager; Site Admins = Site
Super Admins and Site Admins covering the booking's site; Finance = Finance Admins and Site Finance covering the site;
Admins = Super Admins and Admins. The person who booked is never asked; a step left with no one goes to the Admins.

`422`: "Name is needed: …", "Up to 5 steps", "Pick at least one person for each step with Named People", "Pick people who
cover <site>", "Some sites / people / teams are not … of <client>". `403`: the organisation's flow for a site role, or a
site the person does not cover.

## 3. Try a Booking

`POST /portal/approval_flows/try { site_id, booked_by_id, kind, estimate, lead_days }` (nothing saved; all optional:
Site, Booked By — Anyone or a person, Trip Type, Estimate S$ (default 500), Days Ahead (default 7)) →

```json
{ "data": { "need": true, "flow": "organisation", "rule_id": 2, "name": "Large bookings", "same_person": "other",
  "steps": [ { "position": 1, "who": ["fin"], "need": "any", "label": "Finance", "fallback": false,
               "people": [ { "id": 2, "name": "Kenneth Ong" } ] },
             { "position": 2, "who": ["admins"], "need": "any", "label": "Admins", "fallback": false,
               "people": [ { "id": 5, "name": "Linh Tran" }, { "id": 1, "name": "Priya Raman" } ] } ] } }
```

Highlight the rule `rule_id` in the drawing (`name` "Otherwise" → the Otherwise box; a site's own flow → "<site> flow: <rule>").
`need: false` → "No approval needed (<name>). Goes straight to <transport company>." (or "Goes straight to …" when the
flow is off: `name` null). `fallback: true` → "No one else is on this step, so it goes to the Admins". The same answer
is the approval preview on New Booking.
