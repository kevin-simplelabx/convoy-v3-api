# Client Portal — Notices (read only)

`GET /portal/notices` → notices to riders of the client's trips that are in force or scheduled, for the trips the
person covers. Sending your own is not built ("Sending your own comes in the next phase").

```json
{ "data": [ { "id": 4, "message": "From Monday the 18:00 run leaves from Tower 2 lobby", "starts_at": "2026-11-03T00:00:00+08:00",
              "ends_at": "2026-11-11T23:59:59+08:00", "state": "in_force", "channels": { "banner": true, "push": true, "sms": false },
              "trip": { "id": 7, "title": "MBC Shuttle" } } ] }
```

Row: message, "<starts_at> to <ends_at> | In-app banner, Push, SMS" (the channels that are `true`), badge `in_force` "In
force" / `scheduled` "Scheduled".
