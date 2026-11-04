# Client Portal — Approvals: deciding a booking

Bookings that the client's [approval flow](approval-flows.md) sends to people before the transport company sees them.
The route and the people each step asks are kept as they were when the booking was sent (changing the flow later does
not move a waiting booking).

## 1. Who decides

- The current step's people, while still right for it: a group's people while still in the group (and covering the
  booking's site), named people while not removed, the Admins a step fell to while still Admins. Someone no longer right
  shows as `no_longer`; a step with no one left goes to the Admins.
- **Step in**: any Super Admin or Admin may decide any waiting step ("As <role> you can decide for this step.").
- Never the person who booked; nobody twice on one step.
- Same person on two steps: `same_person: "once"` — their approval counts for the later step too (shown `carried`);
  `"other"` — the later step needs someone else, unless no one else is left.
- A step is done when any one approves, or (`need: "all"`) when all its people still right for it have approved (an Admin
  stepping in on such a step adds an approval but does not finish it). The last step done → the trips go to the transport
  company (`sent`). A decline (reason required) declines every trip still waiting (`declined`, `rejection.by_client: true`).

## 2. Approvals page

`GET /portal/approvals` → `{ waiting_for_you: [booking], waiting_for_others: [booking] }` (booking = the [Bookings list
shape](bookings.md#2-list)). Waiting for You: bookings the viewer may decide now. Waiting for Others: other waiting
bookings the viewer may see (Super Admins and Admins: all; others: their sites'). Card: number, site, "By <booker> |
dates", estimate, the first trip, "N trips | types", `approval.name` (the rule), `approval.waiting_text`; buttons View,
Decline (opens the detail with the reason box), Approve (Waiting for You).

The rail item shows when `GET /portal/me` → `menu.approvals` (roles that approve, people named in a flow, people a waiting
booking asks).

## 3. Approve / Decline

| Button | Call |
| --- | --- |
| Approve | `POST /portal/bookings/:id/approve { note }` (note optional) |
| Decline | `POST /portal/bookings/:id/decline { note }` — "Why is it declined?" required: `422` "Say why it is declined, the person who booked sees it" |

Both answer the booking ([detail shape](bookings.md#3-booking-detail)). `403` when the viewer may not decide it now.
Toasts: "<no> approved and sent to <company>" (`approval.status` `ok`), "<no> approved. Waiting for …" (still `wait`),
"<no> declined".

## 4. The approval on a booking

Every booking (list and detail) has `approval` — `null` when the flow was off:

```json
{ "status": "wait", "name": "Otherwise", "flow": "organisation", "same_person": "once", "current_step": 1, "steps_count": 1,
  "sent_at": "2026-11-04T09:04:18+08:00", "decided_at": null,
  "waiting_for": [ { "id": 6, "name": "Daniel Koh" }, { "id": 3, "name": "Mei Ling" } ],
  "waiting_text": "Waiting for Daniel Koh or Mei Ling (step 1 of 1)", "can_decide": true, "stepping_in": false,
  "steps": [ { "position": 1, "label": "Site Admins", "who": ["site"], "need": "any", "fallback": false, "state": "wait",
               "acts": [], "people": [ { "id": 6, "name": "Daniel Koh", "state": "waiting" }, { "id": 3, "name": "Mei Ling", "state": "waiting" } ] } ] }
```

| Field | Use |
| --- | --- |
| `status` | `wait` (a step waits), `ok` (approved, sent), `no` (declined), `none` (the flow was on, no step was needed: "No Approval Needed") |
| `name` | The rule that matched ("<site> flow: <rule>" for a site's own flow; "Otherwise") |
| Stepper | Booking Submitted (`sent_at`) → each step "Approval: <label>" → "Sent to <company>" (or "No Approval Needed") |
| `steps[].state` | `done`, `wait` (current), `no` (declined here), `up` (not reached) |
| `steps[].people[].state` | `approved`, `carried` ("Approved by X (step n)": see the act's `carried_from`), `declined`, `waiting`, `will_be_asked`, `not_asked`, `no_longer` |
| `steps[].acts` | `[{ id, by { id, name }, act: approve \| decline, note, carried_from, at }]` — "Approved on …", notes, "Declined by X: reason" |
| `steps[].need` | `any` "Only one approver is needed", `all` "Everyone on this step must approve" |
| `steps[].fallback` | "No one else is on this step, so it went to the Admins" |
| `can_decide`, `stepping_in` | Show Approve / Decline: "You are on this step." or (stepping in) "As <role> you can decide for this step." |
