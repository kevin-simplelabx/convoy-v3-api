# School Bus › Stop Library & Stop Assignment — API Guide

In Convoy OS the Stop Library (company), Stop Assignment (per school) and Route Plans are one map screen with three
modes. This guide covers the first two; Route Plans comes later. Conventions are in [README.md](README.md); paths start
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
| `GET /stops?school_id=&q=&status=&not_linked=1&page=` | The list. With `school_id`, the stops as that school sees them; without it, the whole company library |
| `GET /stops/:id?school_id=` | One stop with the schools that use it and the coverage table |
| `POST /stops` | Add a stop |
| `PATCH /stops/:id` | Change a stop |
| `DELETE /stops/:id` | Archive |
| `GET /stops/nearby?lat=&lng=&school_id=` | "Nearby in Library": stops within 600 m that the school does not use yet, nearest first, with `metres` |

List parameters:

- `q` matches the stop name, the Stop ID, a PUDO ID (such as `0001c`) or an old ID.
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
- `street_view_url` must be a Google Maps link.
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

**Archive:** `DELETE /stops/:id` works only when no school uses the stop ("Unlink BDSZ03-0001 from every school first").

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
| `PUT /schools/:id/stops/:stop_id` | Add to School / Use Stop (links it if needed) and change the catchment |
| `DELETE /schools/:id/stops/:stop_id` | Unlink (the school's hand links to its points go too) |
| `POST /schools/:id/stops/import { from_school_id, with_catchments }` | Import from Another School: links its stops that this school can see, with or without their catchments. Returns `{ added: n }` |

```json
{ "data": [ { "stop": { …stop row… }, "postal_codes": ["460100"], "off_point_ids": [],
              "areas": [ { "name": "Blk 2xx", "latlngs": [[1.333, 103.933], …], "exclude": false, "how": "lasso" } ], "riders": 9 } ],
  "meta": { "counts": { "school_stops": 8, "needs_attention": 0 }, "stops_changed_at": "2026-11-02T09:00:00+08:00" } }
```

`riders` counts today's riders inside the catchment.

The `PUT` body is `{ postal_codes: [...] | "460101, 460102", areas: [{ name, latlngs, exclude, how: lasso|corners|lot }],
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
              "am": true, "pm": true, "cca_days": [2, 4], "starts_on": null, "status": "one",
              "candidates": [ { "stop_id": 12, "stop_code": "BDSZ03-0001", "point_id": 31, "pudo_code": "BDSZ03-0001A", "usage": "both",
                                "how": "postal" | "area" | "manual", "manual": false, "metres": 52 } ] } ],
  "meta": { "date": "2026-11-02", "counts": { "riders": 65, "with_pudo": 65, "conflicts": 0, "no_stop": 0 },
            "stops_changed_at": "…" } }
```

**Candidates.** A rider's candidate points are worked out like this, as in the prototype:

1. Start with every point of the school's stops whose catchment has the rider's home: by postal code, or inside an area
   and not in an exclude area.
2. Leave out the points turned off for the school.
3. Add the points linked to the rider or their postal code by hand (`how: "manual"`).
4. Leave out the points cut off from the rider.

Rider colours on the map follow `status`:

| `status` | Meaning |
| --- | --- |
| `one` | Assigned: one stop |
| `conflict` | Points of more than one stop |
| `none` | No stop |

**Tools:**

| Call | Tool |
| --- | --- |
| `POST /schools/:id/rider_links { stop_point_id, rids: [...], postals: [...] }` | Select Riders (S): link the picked riders or postal codes to a point as an alternative |
| `POST /schools/:id/rider_links/remove { links: [{ rid, point_id }] }` | Select Links (L) › Remove: a hand link is deleted; a link from the catchment is cut off for that rider |

Reload the assignment after either call.

## 5. Photos and photo requests

**A point's photo:**

```
POST /stops/:id/points/:point_id/photo   (multipart: photo = the image to show, with arrows and crop applied by the FE;
                                           photo_original; photo_annotations = JSON of the arrows / crop; photo_credit)
DELETE /stops/:id/points/:point_id/photo
```

Both return the point. Use `photo_annotations` with `photo_original` to reopen the editor.

**Photo requests** ask parents or drivers for a photo through the Convoy App. Photos sent from the app are seed data
until the app exists.

| Call | What it does |
| --- | --- |
| `GET /stop_photo_requests?status=open\|closed\|all` | The requests with their photos |
| `POST /stop_photo_requests { stop_point_id, audience, school_rider_id, max_submissions }` | Ask for Photos |
| `DELETE /stop_photo_requests/:id` | Close the request |
| `POST /stop_photo_requests/submissions/:id/accept` | Accept a photo |
| `POST /stop_photo_requests/submissions/:id/reject` | Reject a photo |
| `PUT /stop_photo_requests/auto { driver, parent }` | Automatic requests on / off. Returns how many requests changed |

```json
{ "data": [ { "id": 4, "stop_id": 12, "stop_point_id": 31, "pudo_code": "BDSZ03-0001A", "stop_name": "…", "audience": "both",
              "parent_of": null, "max_submissions": 4, "status": "open", "auto": false, "created_by": "…", "created_at": "…", "live": 2,
              "submissions": [ { "id": 7, "by": "Mrs Tan Mei Ling", "role": "parent", "status": "pending", "submitted_at": "…",
                                 "street_view_url": null, "annotations": null, "photo": { "url": "…", "thumb_url": "…" } } ] } ],
  "meta": { "pending_photos": 2, "auto": { "driver": false, "parent": false } } }
```

- `meta.pending_photos` is the badge on the photo-requests button.
- `live` counts photos that are not rejected.

**Ask for Photos:**

- `audience` is `parents` (parents at the stop), `driver`, `both`, or `parent` with `school_rider_id` (one parent).
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

- "Set as assigned", "Move All Riders Here" and **Notify** need Route Plans, so they come with it.
- Marking plans Out of Date. Until then, use `stops_changed_at` for the "Stops changed since routing" note.
- The photo upload from the Convoy App.
