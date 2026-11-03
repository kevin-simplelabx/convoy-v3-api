# Driver app — My Vehicle Today, Switch Vehicle, Vehicle History

The office gives each driver a bus for the day (Edit Vehicle › Default Driver, from a date and now also a time of day).
When the driver moves to another bus during the day (for example from 06:30), Drive shows the Switch Vehicle card;
before taking the bus over the driver does the handover inspection: six photos (marked up where something is wrong)
and the declaration. The runs already follow the office's plan; the handover is the record.
Conventions: [README.md](README.md). Paths start with `/api/v1`. Needs a picked company. Files as `multipart/form-data`.

## Contents

1. [My Vehicle Today](#1-my-vehicle-today-get-drivervehicle)
2. [The Switch Vehicle card on Drive](#2-the-switch-vehicle-card-on-drive)
3. [Handover inspection](#3-handover-inspection-post-drivervehiclehandovers)
4. [Vehicle History](#4-vehicle-history-get-drivervehiclehistory)

---

## 1. My Vehicle Today: `GET /driver/vehicle`

```json
{ "data": {
  "current": { "id": 7, "plate": "PC8812K", "name": "Toyota Coaster", "seats": 29, "photo": { "url": "...", "thumb_url": "..." },
               "since": "2026-10-01", "since_time": null },
  "switches": [ { "vehicle": { "id": 9, "plate": "PC1234X", "name": "Toyota Coaster", "seats": 29, "photo": null, "since": null, "since_time": null },
                  "starts_at": "2026-11-03T06:30:00+08:00", "handover_done": false } ],
  "handovers": [ { "id": 3, "at": "...", "vehicle": { "id": 9, "plate": "PC1234X" }, "photos": ["..."] } ]
} }
```

- `current`: the bus the driver is on **now** (also the plate in the Drive header), or null ("None planned").
  `since` / `since_time`: "Assigned to you from 06:30 today" (`since_time` null = from the start of that day). Managed
  drivers: their operator's bus (`since` null).
- `switches`: buses the driver takes over later today or tomorrow (Switch Vehicle row: "PC1234X at 06:30", "Handover
  inspection needed" until `handover_done`).
- `handovers`: today's handovers (My Vehicle Today shows their photos and time).

## 2. The Switch Vehicle card on Drive

[`GET /driver/runs`](runs.md#1-drive-the-days-runs-get-driverruns) has `meta.vehicle_switches` for the days asked:

```json
{ "meta": { "from": "2026-11-03", "to": "2026-11-03",
            "vehicle_switches": [ { "starts_at": "2026-11-03T06:30:00+08:00", "vehicle": { "id": 9, "plate": "PC1234X" }, "handover_done": false } ] } }
```

Place the card among the trip cards by `starts_at`. Each run card's `vehicle` already shows the bus for that run.

## 3. Handover inspection: `POST /driver/vehicle/handovers`

Multipart:

| Field | |
| --- | --- |
| `client_id` | a UUID made by the app (sending it again answers the same handover, `meta.replayed: true`) |
| `vehicle_id` | the bus taken over: `current` or one of `switches` |
| `photos[front]`, `photos[left]`, `photos[right]`, `photos[back]`, `photos[odometer]`, `photos[inside]` | the six photos (all required) |
| `marked[<side>]` | the marked-up copy of a photo (optional) |
| `marks[<side>]` | the shapes drawn on it, JSON (optional): e.g. `[{"kind":"circle","x":120,"y":200,"r":30}]` in 400 × 300 photo units |
| `declaration` | `true`: "I have checked the vehicle…" (required) |
| `at` | when it was done (ISO 8601; default now) |
| `note` | optional ("Scratch on the rear bumper") |

→ `201` the handover: `{ id, at, declared_at, note, vehicle { id, plate }, photos: [{ side, label, photo, marked_photo, marks }] }`.

- `422` code `photos_needed` with `details.missing: ["inside"]`; `declaration_needed`; `not_your_bus`.
- Photos and marks are kept for the office (incidents, damage claims).

## 4. Vehicle History: `GET /driver/vehicle/history`

`?month=YYYY-MM` (default this month) → the buses driven each day (from the trips driven) and the month's handovers:

```json
{ "data": { "month": "2026-11",
            "days": [ { "date": "2026-11-03", "vehicles": [ { "id": 7, "plate": "PC8812K", "runs": 1 }, { "id": 9, "plate": "PC1234X", "runs": 4 } ] } ],
            "handovers": [ "..." ] } }
```
