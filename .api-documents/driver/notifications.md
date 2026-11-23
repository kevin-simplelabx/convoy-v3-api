# Driver app — Notifications and notices

The bell on Drive (red dot when unread) and the Notifications tab: what changed for the driver's trips today and
tomorrow, a bus to take over, and notices from the office — **Open** notices (a detail page) and **Acknowledge** notices
(the office needs them read; the time is recorded).
Conventions: [README.md](README.md). Paths start with `/api/v1`. Needs a picked company (not the push token, § 5).
Fetch the list on app start, when the app comes to the front, and when the WebSocket says `notifications_changed`
([../websocket.md](../websocket.md)); no polling. Every new line is also sent as a **push notification** (§ 5), so a
closed app hears about it too.

## Contents

1. [The bell](#1-the-bell-get-drivernotifications)
2. [Mark as read](#2-mark-as-read)
3. [Open a notice](#3-open-a-notice-get-drivernoticesid)
4. [Acknowledge a notice](#4-acknowledge-a-notice-post-drivernoticesidacknowledge)
5. [Push notifications](#5-push-notifications)
6. [Values reference](#6-values-reference)

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
      "run": { "id": 812, "date": "2026-11-04", "open": true }, "vehicle": null, "notice": null },
    { "id": 38, "kind": "run_assigned", "title": "New trip assigned",
      "body": "Google Shuttle on tomorrow, 08:00. Open it to see the stops.", "at": "...", "read": true,
      "run": { "id": 790, "date": "2026-11-04", "open": false }, "vehicle": null, "notice": null },
    { "id": 39, "kind": "vehicle_switch", "title": "Vehicle switch today",
      "body": "Switch to PC1234X from 06:30 today. Do the handover inspection before you take it.", "at": "...", "read": false,
      "run": null, "vehicle": { "id": 9, "plate": "PC1234X" }, "notice": null }
  ],
  "meta": { "unread": 2 } }
```

Tap a line — every tap marks it read (§ 2) first:

| Line | Opens |
| --- | --- |
| `run.open: true` | Trip Details of `run.id` ([runs.md § 4](runs.md#4-trip-details-get-driverrunsid)) |
| `run.open: false` (any run kind; always for `run_unassigned` / `run_removed`) | nothing; toast "This trip is no longer assigned to you" |
| `vehicle_switch` (`run: null`) | Switch Vehicle ([vehicle.md](vehicle.md)) |
| `notice` (`run: null`) | the notice (§ 3) |

- `run.open`: `true` when Trip Details opens for this driver now — the run is still theirs, or a replacement took it
  (it shows as Replaced), cancelled runs included; `false` when it was given to another driver or is no longer planned.
  Worked out on each fetch, so every line of the same run says the same, and the old lines open again if the run
  comes back to the driver (the bell refetches on `notifications_changed`). Use it instead of looking at the run's
  newest line. Keep the `404` on Trip Details as a safety net (the run was taken between the fetch and the tap).
- Optional: show `open: false` lines dimmed.
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

## 5. Push notifications

Firebase Cloud Messaging, Android and iOS (Firebase project `convoy-transport-company-stg`; the APNs key is already in
it, nothing to set up for iOS on the server). Each new bell line (§ 1, all 7 kinds) is pushed once to the phone the
driver is signed in on, **from every company the driver works for**, not only the picked one. Nothing else is pushed.

### 5.1 Register the push token: `PUT /driver/device`

`{ device: { platform, push_token } }` → `204`. `platform` is `ios` or `android`; `push_token` is the FCM registration
token (up to 4096 characters). `PATCH` works the same; flat parameters (`{ platform, push_token }`) are accepted too.
Call it after sign-in and whenever Firebase gives a new token (`onTokenRefresh`). No company needs to be picked.

- One token per sign-in: a second call replaces it. A token another sign-in registers moves to that sign-in.
- The token goes with the sign-in: **Sign Out** and signing in on another phone remove it (one phone at a time).
- A token Firebase answers as gone (app removed, token expired) is dropped by the server; register again on the next
  token from Firebase.
- `422` an unknown `platform` (`details`); `400` / `422` when `push_token` is missing.

### 5.2 Remove it: `DELETE /driver/device`

→ `204`. For "stop notifications on this phone" (the OS permission turned off). Sign Out removes it too.

### 5.3 The message

`notification` = the bell line's `title` and `body` (default sound). `data` (all values are strings; keys with no value
are left out):

```json
{ "type": "driver_notification", "id": "41", "kind": "run_assigned", "company_id": "3", "membership": "driver-12",
  "run_id": "812", "run_date": "2026-11-04" }
```

| Key | Meaning |
| --- | --- |
| `type` | always `driver_notification` |
| `id` | the bell line (`GET /driver/notifications` → `data[].id`) |
| `kind` | as § 6 |
| `company_id`, `membership` | the company of the line; `membership` is the key for Switch Company ([auth § 4.1](auth.md#41-switch-company-patch-driversession)) |
| `run_id`, `run_date` | run lines (`run_*` kinds) |
| `notice_id` | `notice` lines |
| `vehicle_id` | `vehicle_switch` lines |

**Tap** (app opened from the push):
1. If `membership` is not the current one (`GET /driver/session` → `current`), Switch Company to it first
   (`PATCH /driver/session { membership }`). A membership no longer active answers `422` (or `404`): just open the bell.
2. Fetch the bell (§ 1) and open line `id` as a tap on it there (mark read, then open by `run.open` / kind). If the
   line is not in the list any more, open the bell.

**In the foreground** the WebSocket already refreshes the bell (`notifications_changed`); show the push as a banner or
not, as the app prefers.

## 6. Values reference

| Field | Values |
| --- | --- |
| `kind` | `run_assigned`, `run_changed`, `run_unassigned`, `run_cancelled`, `run_removed`, `vehicle_switch`, `notice` |
| `notice.kind` | `ack` (Acknowledge), `view` (Open) |
