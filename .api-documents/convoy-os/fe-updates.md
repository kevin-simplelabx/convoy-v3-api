# Convoy OS — changes the front-end must make

Changes to existing Convoy OS endpoints made while building other apps (Convoy Driver) that the OS front-end has to act
on (renamed, removed or changed fields and endpoints). New optional fields are not listed here; they are in the menu
documents. Newest first. Each item: what changed, before → after, and what the front-end has to do.

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
