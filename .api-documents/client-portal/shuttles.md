# Client Portal — Shuttles (read only)

The rail item shows when `GET /portal/me` → `menu.shuttles`. "To change a timing or a stop, call or email them."

`GET /portal/shuttles` → the client's corporate shuttle routes grouped by site (the sites the person covers; a route
serving several sites shows under each; routes with no site under `site: null` "Other Routes", for people covering every site):

```json
{ "data": [ { "site": { "id": 1, "name": "Mapletree Business City" }, "routes": [ {
  "id": 7, "title": "MBC Shuttle", "label": "MBC", "days": [1, 2, 3, 4, 5], "days_text": "Mon to Fri", "skip_public_holidays": true,
  "starts_on": "2026-10-01", "ends_on": null, "status": "active", "cross_site": false, "tags": ["Staff"],
  "sites": [ { "id": 1, "name": "Mapletree Business City" } ],
  "directions": [ { "direction": 1, "name": "Morning",
                    "stops": [ { "id": 21, "name": "Labrador Park MRT", "site": null }, { "id": 22, "name": "MBC Tower 1", "site": { "id": 1, "name": "Mapletree Business City" } } ],
                    "runs": [ { "id": 51, "start_time": "08:00", "end_time": "08:20", "times": ["08:00", "08:20"] } ] },
                  { "direction": 2, "name": "Evening", "stops": [ … ], "runs": [ … ] } ] } ] } ] }
```

- Card: title, `days_text` + "not on public holidays" (`skip_public_holidays`) or "public holidays too", from / to dates;
  `status` `active` Active, `starts` "Starts <starts_on>", `ended` Ended; chips Cross-site (`cross_site`) and `tags`.
- Morning / Evening: a chip per run "<start_time> to <end_time>"; stops with their site chips.
- **Full Timetable**: per direction, a table of `stops` (rows) × `runs` (columns) from `runs[].times` (`null` = the run skips the stop).
