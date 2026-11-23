# Convoy App — changes the front-end must make

Changes to calls the app already uses. Newest first.

## 23/11/2026 — Push notifications (no breaking change)

**State: built on the server, not on staging yet** (this line will say "Live on staging" once deployed). The app already
registers its token (`PUT /app/device`); nothing changes in the calls.

| # | What to change | Doc |
| --- | --- | --- |
| 1 | Firebase project `convoy-transport-company-stg` (as the old Convoy apps): register the Convoy App there; on iOS turn on Push Notifications + Background Modes → Remote notifications. Send the **FCM** token on iOS too (no APNs setup needed) | [auth § 4.1](auth.md#41-register-the-push-token-patch-appdevice) |
| 2 | Each new inbox alert arrives as a push: `title` / `body` as in the inbox, `data` = `type: "app_alert"`, `id`, `kind`, `target`, `target_id`, `trip_id` (strings). Tap → `POST /app/alerts/:id/read`, open `target` as in the inbox | [home § 4.1](home.md#41-push-notifications) |
| 3 | Notifications › Push (`notify_push`) now really stops push on every phone of the account | [account § 3](account.md#3-account-changes-patch-appprofile) |

## 19/11/2026 — Live updates over a WebSocket (**breaking**: stop polling)

The app no longer polls. Guide: [../websocket.md](../websocket.md).

| # | What to change | Doc |
| --- | --- | --- |
| 1 | New: `POST /app/cable_ticket` (after Create Your Account) → open `wss://<host>/cable?ticket=…` (subprotocol `actioncable-v1-json`) | [websocket § 1–2](../websocket.md#1-connect) |
| 2 | `AppChannel` while signed in: `alerts_changed` → fetch the Alerts inbox / badge again | [websocket § 3](../websocket.md#3-channels-and-messages) |
| 3 | `TrackChannel` per open live screen with its REST params: `home`, `school_live` (`bus`), `shuttle_route` (`employer_id`, `route_id`, `date`, `direction`, `run_id`), `booking_track` (`booking_id`). `run_changed` → fetch the screen again; `position` → move the bus marker; `gone` → fetch again and unsubscribe | [websocket § 4](../websocket.md#4-convoy-app-screens-trackchannel) |
| 4 | Live Tracking: `poll_seconds` is gone from `GET /app/school/live`; remove every polling timer (Live Tracking, Track Buses, shuttle route page, Home) | [home § 6](home.md#6-live-tracking-get-appschoollive) |
| 5 | New fields to match `position.run_id` and `run_changed.run_id`: `bus.occurrence_id` (Live Tracking), `timing.occurrence_id` + `timings[].occurrence_ids` (shuttle route page), `up_next[].occurrence_ids` (Home); Track Buses already had `buses[].occurrence_id` | [home](home.md), [shuttles](shuttles.md), [bookings § 9](bookings.md#9-track-buses) |
| 6 | Fetch once on (re)connect and when the app comes to the front (the socket is closed in the background); reconnect with a new ticket | [websocket § 5](../websocket.md#5-reconnecting-and-the-app-in-the-background) |

Try it: Rachel Tan `+65 9188 2045` → Live Tracking of Ethan's St. Stephen's AM 1 bus (Siti Nurhaliza drives it today);
Rachel Tan `rachel.tan@google.com` → MBC Campus Shuttle route page.
