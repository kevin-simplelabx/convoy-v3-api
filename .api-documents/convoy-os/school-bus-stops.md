# School Bus › Stop Library & Stop Assignment — API Guide

In Convoy OS the Stop Library (company), Stop Assignment (per school) and Route Plans are one map screen with three
modes. This guide covers the first two; Route Plans comes later. Conventions are in [README.md](../README.md); paths start
with `/api/v1`.

**Permissions**

| What | Who |
| --- | --- |
| Read stops and assignments | Every company user (only the schools they may open) |
| Change stops, catchments, rider links and photo requests | `plans` |
| Answer library requests (Approve / Keep for School) | `library` |

A Convoy Admin can read but change nothing.

**Stop IDs.**

- A new stop is named `<URA subzone code>-NNNN` after the subzone of its primary point, for example `BDSZ03-0001`.
- PUDO points add a letter A–P: `BDSZ03-0001A`.
- The subzone is worked out on the server from the URA Master Plan 2019 subzones.
- A stop keeps its ID when its points move.
- A removed point's letter is never used again on that stop.

## Contents

1. [Stops (Stop Library)](#1-stops-stop-library)
2. [Library membership and requests](#2-library-membership-and-requests)
3. [A school's stops and catchments](#3-a-schools-stops-and-catchments)
4. [Stop Assignment](#4-stop-assignment)
5. [Photos and photo requests](#5-photos-and-photo-requests)
6. [Front-end only and not built yet](#6-front-end-only-and-not-built-yet)

---

## 1. Stops (Stop Library)

| Call | What it does |
| --- | --- |
| `GET /stops?school_id=&q=&status=&not_linked=1&page=&limit=` | The list. With `school_id`, the stops as that school sees them; without it, the whole company library |
| `GET /stops/:id?school_id=` | One stop with the schools that use it and the coverage table |
| `POST /stops` | Add a stop |
| `PATCH /stops/:id` | Change a stop |
| `DELETE /stops/:id` | Archive (the only delete: a stop is archived, never hard-deleted) |
| `GET /stops/nearby?lat=&lng=&school_id=` | "Nearby in Library": stops within 600 m that the school does not use yet, nearest first, with `metres` |

List parameters:

- `q` matches the stop name, the Stop ID, a PUDO ID (such as `0001c`) or an old ID; not postal codes (the prototype's
  search box is "Search name, Stop ID, PUDO ID or old ID").
- Paged as every list ([README § Responses](../README.md#responses)): `meta { page, limit, count, pages }`;
  each row carries its `subzone { code, name, planning_area }` (so do `GET /schools/:id/stops` and the `PUT` answer); default 50, `limit` up to 500.
- `status` is `approved`, `school` or `pending`.
- `not_linked=1` (with `school_id`) gives the stops that school does not use yet ("Browse Library").

```json
{ "id": 12, "code": "BDSZ03-0001", "name": "Blk 101 Bedok North", "subzone_code": "BDSZ03",
  "subzone": { "code": "BDSZ03", "name": "Bedok North", "planning_area": "Bedok" },
  "library_status": "approved", "owner_school": null, "requested_by": null, "requested_at": null, "former_codes": [],
  "points": [ { "id": 31, "suffix": "A", "pudo_code": "BDSZ03-0001A", "description": "Bus bay beside Blk 101", "usage": "both",
                "sizes": ["S", "M", "L"], "primary": true, "lat": 1.3304, "lng": 103.9203, "subzone_code": "BDSZ03",
                "street_view_url": "https://www.google.com/maps/@…", "photo": { "url": "…", "thumb_url": "…", … } | null,
                "photo_original": {…} | null, "photo_annotations": [...] | null, "photo_credit": "Mrs Tan (parent)" | null } ],
  "used_by": 2, "linked": true, "needs_attention": false, "coverage_warnings": [], "archived": false }
```

- `linked` is only set when `school_id` is given.
- `used_by` is the number of schools using the stop: "used by N schools".
- `needs_attention` is true when the stop has no point, or the coverage has a gap ("Size gap" badge).

`GET /stops/:id` adds two fields:

```json
"coverage": [ { "usage": "pickup", "sizes": { "S": ["A"], "M": ["A"], "L": [] }, "any": true },
              { "usage": "dropoff", "sizes": { … }, "any": true } ],
"schools": [ { "id": 3, "name": "St. Stephen's School", "riders": 12 } ]
```

In `coverage`, each cell lists the point letters that serve that size; an empty list is a gap. `coverage_warnings` holds
messages such as "No point serves Large buses for pick-up".

**Add / change a stop:**

```
POST /stops   { stop: { name, points: [{ description, usage: pickup|dropoff|both, sizes: ["S","M","L"], primary, lat, lng, street_view_url }] },
                school_id, in_library }
PATCH /stops/:id { stop: { name, points: [{ id, … }] }, school_id, confirmed }
```

- Send the whole list of points. A point with `id` is changed. A point without `id` is new and gets the next free
  letter. A point left out is removed (retired).
- Exactly one point is primary. If none is marked, the first point is.
- `street_view_url` must be a Google Maps link ("Street View link must be a Google Maps link").
- The answer is the stop: `201` when created, `200` when changed.
- On the Library page, send no `school_id` (or `in_library: true`). The stop is then `approved`.
- From a school's screen, send `school_id` and `in_library: false`. The stop belongs to that school
  (`library_status: "school"`) and is linked to it. Then ask "Add to the Stop Library?" (§2).

| Error (422) | Cause |
| --- | --- |
| "Enter a stop name" | No name |
| "Add at least one PUDO point" | No points |
| "Point A needs at least one bus size" | A point has no size |
| "Stops with postal codes or areas need both pick-up and drop-off points" | A school has a catchment on the stop |
| "No URA subzone found for Point A. Move it inside Singapore" | The new stop's primary point is outside every subzone |

**Changing a stop other schools use.** When points of a stop that other schools use are moved, added or removed, or
their use or sizes change, the API answers 422 with `code: "confirm_required"`:

```json
{ "error": { "code": "confirm_required", "message": "BDSZ03-0001 is used by other schools. Confirm to change it for them too",
             "details": { "schools": [ { "id": 5, "name": "Opera Estate Primary", "riders": 8 } ] } } }
```

Show the dialog with those schools and their riders, then send the same request again with `confirmed: true`. Every
school using the stop gets its "Stops changed since routing" time updated (`stops_changed_at`, §3).

**Archive:** `DELETE /stops/:id` works only when no school uses the stop ("Unlink BDSZ03-0001 from every school first"). It answers `200 { data: { unassigned: n } }`: riders still assigned to the stop's points (left by an older unlink) are unassigned in the same transaction.

## 2. Library membership and requests

| `library_status` | Who sees the stop |
| --- | --- |
| `approved` | Every school |
| `school` | Only its owner school |
| `pending` | Only its owner school, until a library reviewer answers |

| Call | Who | What it does |
| --- | --- | --- |
| `POST /stops/:id/library?school_id=` | `plans` | "Add to the Stop Library". With the `library` permission the stop is approved at once; otherwise it becomes `pending` with `requested_by` / `requested_at` |
| `GET /stops/requests` | `library` | The Requests tab: pending stops (Stop ID, name, `owner_school`, requested by and when). Its length is the menu badge "Stop Library (n)" |
| `POST /stops/:id/review { status: approved \| school }` | `library` | Approve, or Keep for School |

## 3. A school's stops and catchments

Each school has its own catchment on a stop:

- postal codes;
- drawn areas, with optional exclude areas;
- points the school does not use (turned off).

A rider whose home is inside the catchment may use the stop's points.

| Call | What it does |
| --- | --- |
| `GET /schools/:id/stops?attention=1` | The school's stops (the "School Stops N" / "Needs Attention N" chips) |
| `PATCH /schools/:id/stops/:stop_id` | Add to School / Use Stop (links it if needed) and change the catchment |
| `DELETE /schools/:id/stops/:stop_id` | Unlink: the school's hand links and the riders assigned to the stop's points go too (one transaction). Answers `200 { data: { unassigned: n } }`. The prototype only warns when riders use the stop; there is no block |
| `POST /schools/:id/stops/import { from_school_id, with_catchments }` | Import from Another School: links its stops that this school can see, with or without their catchments. Returns `{ data: { added: n } }` (no other field) |

```json
{ "data": [ { "stop": { …stop row… }, "postal_codes": ["460100"], "off_point_ids": [],
              "areas": [ { "name": "Blk 2xx", "latlngs": [[1.333, 103.933], …], "exclude": false, "how": "lasso" } ], "riders": 9 } ],
  "meta": { "counts": { "school_stops": 8, "needs_attention": 0 }, "stops_changed_at": "2026-11-02T09:00:00+08:00" } }
```

`riders` counts today's riders inside the catchment.

The `PATCH` body is `{ postal_codes: [...] | "460101, 460102", areas: [{ name, latlngs, exclude, how: lasso|corners|lot }],
off_point_ids: [...] }`. Send only the parts that change. The response is the row plus:

- `meta.invalid`: tokens that are not 6-digit codes. Show "Not added: …" and keep them in the input.
- `meta.shared`: `[{ postal, stop_code }]` for codes another of the school's stops also covers. Show "Riders here are
  eligible for both stops' PUDOs. Routing assigns one."

An area needs at least 3 corners. A stop with a catchment needs a pick-up and a drop-off point.

## 4. Stop Assignment

`GET /schools/:id/stop_assignment?date=` returns the riders on that date (the Plan For date) and the PUDO points each one
may use:

```json
{ "data": [ { "rid": "S-1001", "name": "Tan Wei Ling", "grade": "P3", "postal": "460100", "lat": 1.32, "lng": 103.92,
              "am": true, "pm": true, "cca_days": [2, 4], "starts_on": null, "status": "one", "cut_point_ids": [ 33 ],
              "assigned": { "point_id": 31, "pudo_code": "BDSZ03-0001A", "manual": false, "plan_id": 5, "notified_at": "2026-11-02T08:00:00+08:00" },
              "candidates": [ { "stop_id": 12, "stop_code": "BDSZ03-0001", "point_id": 31, "pudo_code": "BDSZ03-0001A", "usage": "both",
                                "how": "postal" | "area" | "manual", "manual": false, "metres": 52 } ] } ],
  "meta": { "date": "2026-11-02", "counts": { "riders": 65, "with_pudo": 65, "conflicts": 0, "no_stop": 0, "assigned": 60, "notified": 58 },
            "stops_changed_at": "…" } }
```

**Candidates.** `metres` is `null` when the rider's home has no location. A rider's candidate points are worked out like this, as in the prototype:

1. Start with every point of the school's stops whose catchment has the rider's home: by postal code, or inside an area
   and not in an exclude area.
2. Leave out the points turned off for the school.
3. Add the points linked to the rider or their postal code by hand (`how: "manual"`).
4. Leave out the points cut off from the rider (`cut_point_ids`: the hidden points; linking the rider to one again with
   `POST /schools/:id/rider_links` brings it back).

`assigned` is the point the rider is assigned to (from an adopted Route Plan, or set by hand: `manual: true`), or `null`;
`notified_at` is when **Notify** recorded it (`null` = not yet). `meta.counts.assigned` / `notified` count those riders.
Set as assigned, Move All Riders Here and Notify: [school-bus-routes § 5](school-bus-routes.md#5-adopt-plan-and-rider-assignments). Out of Date: `out_of_date` on a plan ([routes § 3](school-bus-routes.md#3-plans)).

Rider colours on the map follow `status`:

| `status` | Meaning |
| --- | --- |
| `one` | Assigned: one stop |
| `conflict` | Points of more than one stop |
| `none` | No stop |

**Tools:**

| Call | Tool |
| --- | --- |
| `POST /schools/:id/rider_links { stop_point_id, rids: [...], postals: [...] }` | Select Riders (S): link the picked riders or postal codes to a point as an alternative. Answers `204` |
| `POST /schools/:id/rider_links/remove { links: [{ rid or postal, point_id }] }` | Select Links (L) › Remove. A postal link removes the code for every rider of that code at the school: a hand link is deleted; a link from the catchment is cut off for that rider. A rider assigned to a removed point is unassigned. Answers `200 { data: { unassigned: n } }` |

Reload the assignment after either call.

## 5. Photos and photo requests

**A point's photo:**

```
POST /stops/:id/points/:point_id/photo   (multipart: photo = the image to show, with arrows and crop applied by the FE;
                                           photo_original; photo_annotations = JSON of the arrows / crop; photo_credit)
DELETE /stops/:id/points/:point_id/photo
```

Both return the point. Use `photo_annotations` with `photo_original` to reopen the editor.

**Photo requests** ask parents or drivers for a photo through the Convoy App. Until the app sends them, the office adds
the photos it received (Add Received Photos).

| Call | What it does |
| --- | --- |
| `GET /stop_photo_requests?status=open\|review\|closed\|all` | The requests with their photos; tabs Open / To Review (requests with photos to review) / Closed, counts in `meta.counts`. To Review = requests of any status with a photo waiting (a closed one can be in it; an open one is also in Open) |
| `POST /stop_photo_requests { stop_point_id, audience, school_rider_id, max_submissions }` | Ask for Photos (`201` the request; `404` for a point of an archived stop: an archived stop is out of the library) |
| `POST /stop_photo_requests/:id/close` | Close Request → the request |
| `POST /stop_photo_requests/:id/reopen` | Reopen a closed request → the request (`422` "Already at the max photos. Raise the max or reject some first") |
| `DELETE /stop_photo_requests/:id` | **Remove** a closed request with its photos (`204`). A photo already accepted stays the point's photo. Before 04/11/2026 this call closed the request: use `/close` for that |
| `POST /stop_photo_requests/:id/submissions` (multipart `photos[]`, `submitted_by_name`, `role: parent\|driver`, `street_view_url`) | Add Received Photos (office): up to 3 photos → `201` the request + `meta { added, closed }` |
| `POST /stop_photo_requests/submissions/:id/accept` | Accept a photo → the point |
| `POST /stop_photo_requests/submissions/:id/reject` | Reject a photo (`204`) |
| `PUT /stop_photo_requests/auto { driver, parent }` | Automatic requests on / off. Answers `{ data: { driver, parent, changed } }`, `changed` = the points whose request changed |

```json
{ "data": [ { "id": 4, "stop_id": 12, "stop_point_id": 31, "pudo_code": "BDSZ03-0001A", "stop_name": "…", "audience": "both",
              "parent_of": null, "max_submissions": 4, "status": "open", "auto": false, "created_by": "…", "created_at": "…", "live": 2,
              "submissions": [ { "id": 7, "by": "Mrs Tan Mei Ling", "role": "parent", "status": "pending", "submitted_at": "…",
                                 "street_view_url": null, "source": "app", "n": null, "of": null, "annotations": null,
                                 "photo": { "url": "…", "thumb_url": "…" } } ] } ],
  "meta": { "counts": { "open": 3, "review": 1, "closed": 2 }, "pending_photos": 2, "auto": { "driver": false, "parent": false } } }
```

- `meta.pending_photos` is the badge on the photo-requests button.
- `live` counts photos that are not rejected.
- A photo: `source` is `app` or `office` (Add Received Photos); `n` of `of` = "photo n of m" of the photos added together.

**Add Received Photos** (open requests only): the first 3 `photos[]` are added as pending photos, until the request's
max; when the max is reached the request closes. Toast: "N photo(s) received", plus ". Max reached, request closed" when
`meta.closed`. `422`: "This request is closed", "Enter who sent it", "Choose the photos". Defaults on the form (front end):
Sent By "Driver" for a driver request, else "Parent of <rider>" / "Parent"; Role from the audience.

**Ask for Photos:**

- `audience` is `parents` (parents at the stop), `driver`, `both`, or `parent` with `rid` (the `rid` of Stop Assignment, looked up among the schools that use the point's stop) or `school_rider_id` (one parent). Unknown `rid` → 404.
- `max_submissions` is 1–12; the default is 6.
- Each point has one open request: "BDSZ03-0001A already has an open photo request".

**Accept:**

- Optional multipart `photo` is the edited image, and `annotations` is the JSON of the arrows.
- The photo becomes the point's photo, credited "Name (role)". The original is kept.
- The point keeps its Street View link, or takes the photo's link when it has none.
- Any photo accepted earlier goes back to pending.

**Automatic requests:** points of stops that schools use and that have no photo get an open request (driver, parents or
both). When turned off, automatic requests nobody answered are removed.

## 6. Front-end only and not built yet

FE only:

- The map: layers, URA zones display, rider clusters.
- Drawing areas and tracing land lots.
- The photo editor (arrows, crop).
- Undo / redo, the Convoy AI panel and collaborator presence.

Not built yet:

- The photo upload from the Convoy App.
