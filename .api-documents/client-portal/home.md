# Client Portal — Home

`GET /portal/home` — everything on Home, limited to what the person may see ("today" is the transport company's day).

```json
{ "data": {
  "tiles": {
    "upcoming_trips": { "count": 6, "next": { "date": "2026-11-05", "time": "08:00" } },
    "changes_to_review": 1,
    "waiting_for_you": 1,
    "shuttle_runs_today": { "count": 13, "on_road": 2 },
    "school_buses_today": null,
    "sites": { "count": 2, "own_entity": 1 } },
  "upcoming": [ { "id": 31, "booking_id": 12, "booking_number": "SD26000010", "site": "Mapletree Business City", "date": "2026-11-05",
                  "kind": "one_way", "kind_name": "Ad Hoc / Charter", "start_time": "08:00", "return_time": null, "hours": null, "pax": 12,
                  "from": "Mapletree Business City", "to": "Gardens by the Bay", "status": "awaiting_approval", "status_label": "Awaiting Approval" } ],
  "shuttles_today": [ { "id": 901, "date": "2026-11-04", "trip_id": 7, "title": "MBC Shuttle", "label": "MBC-1", "starts_at": "…", "ends_at": "…",
                        "site": "Mapletree Business City", "state": "started", "state_label": "Started" } ],
  "notices": [ { "id": 4, "message": "From Monday the 18:00 run leaves from Tower 2 lobby", "starts_at": "…", "ends_at": "…",
                 "state": "in_force", "channels": { "banner": true, "push": true, "sms": false }, "trip": { "id": 7, "title": "MBC Shuttle" } } ] } }
```

| Tile | Shown when | Value / sub line | Click |
| --- | --- | --- | --- |
| Upcoming Trips | always | trips of the bookings the person sees, today to 30 days ahead (not declined / cancelled); "Next: <day>, <time>" | Bookings › Upcoming |
| Changes to Review | always | those trips with changes to review ("Made by <company>") | Bookings |
| Waiting for You | not `null` (roles that approve, or someone asked) | bookings the person may decide now | Approvals |
| Shuttle Runs Today | not `null` (the client has shuttles) | "N on the road now" (`on_road`) or "N active routes" | Shuttles |
| School Buses Today | not `null` (the client, or a site the person covers, is a school) | runs today, `on_road` | Map |
| Sites | not `null` | "N billed as their own entity" or "Billed to <client>" | Settings › Sites |

- **Upcoming Trips** panel: `upcoming` (the first 6), each row as on the Bookings list; "All Bookings".
- **Today's Shuttles** (`shuttles_today`, `[]` or `null` when no shuttles): "<start> to <end>", title, site, state badge.
  `state`: `scheduled`, `on_the_way` (the driver has started, or 30 minutes before the start), `started` (left the first
  stop, or the planned start), `ended`.
- **Notices to Riders**: `notices` in force: message, "Until <ends_at> | Sent by <company>". Full list: [notices.md](notices.md).
