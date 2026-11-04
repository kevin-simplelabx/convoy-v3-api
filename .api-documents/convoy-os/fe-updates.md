# Convoy OS — changes the front-end must make

Changes to existing Convoy OS endpoints made while building other apps (Convoy Driver) that the OS front-end has to act
on (renamed, removed or changed fields and endpoints). New optional fields are not listed here; they are in the menu
documents. Newest first. Each item: what changed, before → after, and what the front-end has to do.

## 04/11/2026 — Discover: empty fields in the placement / advertiser form (multipart)

Sending `""` for an empty field used to fail (`422` "Commission pct is not a number", or `500` for `listing_fee`).

| # | Endpoint / field | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | `POST` / `PATCH /discover/placements` `listing_fee`, `commission_pct` | `""` → error → `""` = not given: from the advertiser on a new placement or a new advertiser, else unchanged | Nothing; send `""` or leave the field out. Send `0` to set 0 |
| 2 | `POST` / `PATCH /discover/advertisers` same fields | `""` → error → 0 on create, unchanged on edit | Nothing |
| 3 | Placement `cta`, `starts_on`, `ends_on` | `""` → `500` → "Book Now" / `422` "Pick the start and end dates" | Show the message |
| 4 | Error message for a bad commission / fee | "Commission pct must be in 0..100" → "Commission must be between 0 and 100%", "Listing fee must be 0 or more" | Nothing if `message` is shown as is |
| 5 | Any endpoint: an empty required column no validation catches | `500` → `422` `{ code: "invalid", details: { <field>: ["can't be empty"] } }` | Nothing |

Details: [convoy-admin.md § 3](convoy-admin.md#3-discover), [README § Files](../README.md#files-uploads-and-downloads).

## 04/11/2026 — Client Portal, phase 5 (approvals): the client's own approval is decided only in the Client Portal

Bookings waiting for the client's approval flow (`awaiting_client`) are decided by the client in the Client Portal. Convoy OS
only shows them, as the Convoy OS design does ("<client> approves it in the Client Portal first", no buttons).

| # | Endpoint / field | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | `PATCH /booking_trips/:id/client_approve`, `PATCH /booking_trips/:id/client_decline` | removed (`404`) | Remove "Client approval done" / "Declined in the client's approval" if built |
| 2 | Booking trip `can_reject` | `true` for `awaiting_client` → `false` | Nothing if the button follows the flag |
| 3 | Booking `can_edit` (new), `PATCH /bookings/:id` | edit any time → `can_edit: false` and `422` while the client's approval waits | Hide Edit Booking when `can_edit` is `false` |
| 4 | Booking `client_approval` (new) | — → `{ status, name, waiting_text, … }` | Show `waiting_text` under trips waiting for the client's approval |

Details: [trips.md § Bookings](trips.md).

## 03/11/2026 — Convoy Driver app, phase 4 (driving): one attendance for School Run and School Bus

School Run attendance (the Scheduler drawer's Passenger List) and the Driver app's attendance are now the same record,
with the School Bus words. The values changed:

| # | Endpoint / field | Before → after | Front-end |
| --- | --- | --- | --- |
| 1 | `PATCH /occurrences/:id/passengers/:key` body `mark` | `boarded` \| `alighted` \| `absent` \| `clear` → `boarded` \| `alighted` \| `not_boarded` \| `expected` | Send `not_boarded` for the Absent button and `expected` to clear a mark |
| 2 | `GET /occurrences/:id/passengers` (and the answer of 1) `stops[].students[].status` | `not_marked`, `boarded`, `alighted`, `absent` → `expected`, `boarded`, `alighted`, `not_boarded`, `not_boarding` | Map `expected` to "Not marked" and `not_boarded` / `not_boarding` to "Absent" |
| 3 | `GET /live_map/vehicles/:id` run detail `students[].status` (School Run) | same change as 2 | Same mapping as 2 |
| 4 | `stops[].students[].by` | the user's name → the name of whoever marked (a user, or the driver in the Driver app) | Nothing (still a name) |

Details: [scheduler.md § 5.3](scheduler.md#53-passenger-list-school-run), [live-map.md](live-map.md).
