# Driver app — Notifications and notices

The bell on Drive (red dot when unread) and the Notifications tab: what changed for the driver's trips today and
tomorrow, a bus to take over, and notices from the office — **Open** notices (a detail page) and **Acknowledge** notices
(the office needs them read; the time is recorded).
Conventions: [README.md](README.md). Paths start with `/api/v1`. Needs a picked company. Push notifications are not sent
yet: poll the list (on app start, when the app comes to the front, and every few minutes).

## Contents

1. [The bell](#1-the-bell-get-drivernotifications)
2. [Mark as read](#2-mark-as-read)
3. [Open a notice](#3-open-a-notice-get-drivernoticesid)
4. [Acknowledge a notice](#4-acknowledge-a-notice-post-drivernoticesidacknowledge)
5. [Values reference](#5-values-reference)

---

## 1. The bell: `GET /driver/notifications`

The last 30 days, newest first (100 at most), and the unread count for the red dot:

```json
{ "data": [
    { "id": 41, "kind": "notice", "title": "Route change from Friday: Siglap Road side gate closed",
      "body": "St. Stephen's School closes the side gate for works. Drop off at the main gate on Siglap View. Please acknowledge.",
      "at": "2026-11-02T08:10:00+08:00", "read": false, "run": null, "vehicle": null,
      "notice": { "id": 3, "kind": "ack", "acknowledged_at": null } },
    { "id": 40, "kind": "run_assigned", "title": "New trip assigned",
      "body": "St. Stephen's AM on tomorrow, 06:45. Open it to see the stops.", "at": "...", "read": true,
      "run": { "id": 812, "date": "2026-11-04" }, "vehicle": null, "notice": null },
    { "id": 39, "kind": "vehicle_switch", "title": "Vehicle switch today",
      "body": "Switch to PC1234X from 06:30 today. Do the handover inspection before you take it.", "at": "...", "read": false,
      "run": null, "vehicle": { "id": 9, "plate": "PC1234X" }, "notice": null }
  ],
  "meta": { "unread": 2 } }
```

Tap a line:

| `kind` | Opens |
| --- | --- |
| `run_assigned`, `run_changed`, `run_cancelled` | Trip Details of `run.id` ([runs.md § 4](runs.md#4-trip-details-get-driverrunsid)) |
| `run_unassigned`, `run_removed` | nothing (the trip is no longer the driver's) — mark it read |
| `vehicle_switch` | Switch Vehicle ([vehicle.md](vehicle.md)) |
| `notice` | the notice (§ 3) |

- Lines come for trips **today and tomorrow** that have not started: a trip given to the driver, moved (new time or bus),
  cancelled or back on by the office, given to another driver (a replacement), or no longer planned. Changes further
  ahead show as New on the trip card.
- `notice.acknowledged_at`: null on an Acknowledge notice not acknowledged yet (keep the line marked).

## 2. Mark as read

### 2.1 Mark one line read: `POST /driver/notifications/:id/read`

When a line is opened → `204`.

### 2.2 Mark all as read: `POST /driver/notifications/read_all`

→ `204`.

Acknowledge notices are not marked read by these: they stay unread until acknowledged (§ 4). Opening a notice (§ 3)
reads an Open notice's line.

## 3. Open a notice: `GET /driver/notices/:id`

The detail screen (`notice.id` from the bell). Opening it records that the driver read it.

```json
{ "data": { "id": 3, "kind": "ack", "title": "Route change from Friday: Siglap Road side gate closed",
            "summary": "St. Stephen's School closes the side gate…", "body": "From Friday the Siglap Road side gate is closed…",
            "image": { "url": "...", "thumb_url": "..." }, "image_caption": "Main gate and bay 2 (photo from the school)",
            "link": { "url": "https://simpledrive.sg/maps/sss-gate", "label": "Open the new gate map" },
            "from_name": "SimpleDrive Operations", "starts_at": "...", "ends_at": null,
            "read_at": "...", "acknowledged_at": null, "needs_ack": true } }
```

- `needs_ack: true` → show the Acknowledge button. `image`, `link` may be null.
- `404` for a notice not sent to this driver.

## 4. Acknowledge a notice: `POST /driver/notices/:id/acknowledge`

→ the notice with `acknowledged_at` (the office sees who acknowledged and when). Again is fine (the first time stays).
`422` "This notice needs no acknowledgement" on an Open notice.

## 5. Values reference

| Field | Values |
| --- | --- |
| `kind` | `run_assigned`, `run_changed`, `run_unassigned`, `run_cancelled`, `run_removed`, `vehicle_switch`, `notice` |
| `notice.kind` | `ack` (Acknowledge), `view` (Open) |
