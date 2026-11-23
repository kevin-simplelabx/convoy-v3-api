# WebSocket — live updates (Driver app, Convoy App)

The **Convoy Driver** app and the **Convoy App** get live changes over one WebSocket instead of polling. Convoy OS and the
Client Portal still poll (their docs say how often); they move to the socket later.

How it works in one line: open the socket once, subscribe to the channels of what is on screen, and when a message says
something changed, **fetch the same REST endpoint again** — the REST response stays the source of truth. Only bus positions
come in full in the message (they change every few seconds).

## Contents

1. [Connect](#1-connect)
2. [The protocol (frames)](#2-the-protocol-frames)
3. [Channels and messages](#3-channels-and-messages)
4. [Convoy App screens (TrackChannel)](#4-convoy-app-screens-trackchannel)
5. [Reconnecting and the app in the background](#5-reconnecting-and-the-app-in-the-background)
6. [Checklist](#6-checklist)

---

## 1. Connect

1. Ask for a ticket with the normal Bearer token (no body):

   | App | Call |
   | --- | --- |
   | Driver app | `POST /api/v1/driver/cable_ticket` |
   | Convoy App | `POST /api/v1/app/cable_ticket` (after Create Your Account, else `403 profile_required`) |

   ```json
   { "data": { "ticket": "BzWKQLNqiwz7AfDCLfbZtopiqzEM7ZkVAlEm53qG-es", "expires_in": 60, "url": "/cable" } }
   ```

2. Open `wss://<api host>/cable?ticket=<ticket>` within `expires_in` seconds, with the subprotocol `actioncable-v1-json`
   (staging: `wss://convoy-api-staging.convoy.sg/cable?ticket=…`; local: `ws://localhost:3000/cable?ticket=…`).

- A ticket opens **one** socket, once. Every new connection (reconnect, app back to the front) needs a new ticket.
- The ticket is not your token: never put the Bearer token in the URL.
- A bad, used or expired ticket: the server sends `{"type":"disconnect","reason":"unauthorized","reconnect":false}` and
  closes. Get a new ticket; if the ticket call itself answers `401`, the sign-in has ended → sign-in screen.
- Handle a socket that closes **before** `welcome` without that frame the same way (new ticket; `401` on the ticket
  call → sign-in screen). Do not retry the same ticket.
- One socket per app is enough: subscribe to several channels on it.

## 2. The protocol (frames)

The socket speaks the Action Cable protocol: JSON text frames. Flutter: a small client on `web_socket_channel` (or an
Action Cable package) is enough. `identifier` is a **JSON string** (a channel name and its params, encoded as text).

| Direction | Frame | Meaning |
| --- | --- | --- |
| server → app | `{"type":"welcome"}` | Connected: subscribe now |
| app → server | `{"command":"subscribe","identifier":"{\"channel\":\"DriverChannel\"}"}` | Join a channel |
| server → app | `{"identifier":"…","type":"confirm_subscription"}` | Joined |
| server → app | `{"identifier":"…","type":"reject_subscription"}` | Refused (not yours / not allowed, § 3–4) |
| server → app | `{"identifier":"…","message":{ "type": "runs_changed", … }}` | A message of that channel (§ 3) |
| app → server | `{"command":"unsubscribe","identifier":"…"}` | Leave a channel (screen closed) |
| server → app | `{"type":"ping","message":1763532000}` | Every 3 s: the socket is alive (ignore it) |
| server → app | `{"type":"disconnect","reason":"…","reconnect":true\|false}` | The server closes the socket (§ 5) |

Send the `identifier` back exactly as you subscribed with it (same key order) to unsubscribe and to tell which channel a
message is for.

## 3. Channels and messages

| Channel | App | Subscribe with | Messages |
| --- | --- | --- | --- |
| `DriverChannel` | Driver app | `{"channel":"DriverChannel"}` | `runs_changed`, `notifications_changed` |
| `AppChannel` | Convoy App | `{"channel":"AppChannel"}` | `alerts_changed` |
| `TrackChannel` | Convoy App | `{"channel":"TrackChannel","screen":"…", …the screen's params}` (§ 4) | `run_changed`, `position`, `gone` |

| Message | What changed | What the app does |
| --- | --- | --- |
| `{"type":"runs_changed","run_ids":[626],"dates":["2026-11-19"]}` | The driver's runs on those dates: the office changed or cancelled one, a run was added / taken away / given to someone else, a run completed, attendance or a point was recorded, the trip was edited (runs of today and tomorrow) | Fetch `GET /driver/runs` again when one of `dates` is on screen (Drive, Plan), and the open Trip Details when its id is in `run_ids` |
| `{"type":"notifications_changed"}` | New bell lines or notices | Fetch `GET /driver/notifications` again (red dot) |
| `{"type":"alerts_changed"}` | New Convoy App alerts | Fetch `GET /app/alerts` / the badge (`GET /app/home` `badges.alerts`) again |
| `{"type":"run_changed","run_id":626}` | A run on the open screen changed (status, times, bus, driver, stops reached, boardings) | Fetch the screen's REST endpoint again (§ 4) |
| `{"type":"position","run_id":626,"lat":1.31,"lng":103.79,"heading":90.0,"speed_kmh":42,"recorded_at":"2026-11-19T08:01:12+08:00"}` | The bus of that run moved (newest point of a GPS batch, every 15–30 s while driving) | Move the bus marker of that run; do **not** refetch |
| `{"type":"gone"}` | The screen has nothing to track any more (e.g. Track Buses after the last bus) | Fetch the screen again (it answers `404` / an empty state), then unsubscribe |

- Signals come in bursts (one driver action can change a run, a point and the attendance): refetch **at most once per
  second** per screen (debounce).
- Messages carry no data to show: always show what the REST call returns.

## 4. Convoy App screens (TrackChannel)

Subscribe when the screen opens (after its first `GET`), with the same params as that `GET`; unsubscribe when it closes or
its params change (another chip, date, direction or timing → unsubscribe, then subscribe with the new params). The server
reads the screen with the same rules as the REST call, so a screen the person may not see is rejected.

| `screen` | Params (same as the REST call) | REST endpoint to fetch on `run_changed` | Positions |
| --- | --- | --- | --- |
| `home` | — | `GET /app/home` | none |
| `school_live` | `bus` (the chip key, optional) | `GET /app/school/live?bus=` | only in state `near` (privacy: from 10 min before the child's stop) |
| `shuttle_route` | `employer_id`, `route_id`, and `date`, `direction`, `run_id` when picked | `GET /app/shuttles/:employer_id/routes/:route_id?date=&direction=&run_id=` | the picked timing's lead bus (`timing.occurrence_id`) while on the road |
| `booking_track` | `booking_id` | `GET /app/bookings/:booking_id/track` | each bus (`trips[].buses[].occurrence_id`) while on the road |

Example: `{"command":"subscribe","identifier":"{\"channel\":\"TrackChannel\",\"screen\":\"booking_track\",\"booking_id\":4012}"}`

- The server re-reads the screen every 30 s, so new runs and School Live's 10-minute window start streaming by themselves;
  no need to resubscribe for that.
- To match a `position` with a bus: `run_id` = `bus.occurrence_id` (School Live), `timing.occurrence_id` (shuttle route),
  `buses[].occurrence_id` (Track Buses).

## 5. Reconnecting and the app in the background

- **On every (re)connect**, after `confirm_subscription`: fetch what is on screen once (changes made while the socket was
  closed are not replayed).
- **App to the background**: iOS / Android close the socket; nothing arrives on it until the app is opened again. New
  bell lines (Driver app) and inbox alerts (Convoy App) come as push notifications meanwhile
  ([driver/notifications.md § 5](driver/notifications.md#5-push-notifications), [convoy-app/home.md § 4.1](convoy-app/home.md#41-push-notifications)). **App back to the front**: new ticket → connect → subscribe → fetch the screen.
- **Lost connection** (network change, `close` without a `disconnect` frame, no frame for 10 s — pings come every 3 s):
  reconnect with a new ticket, waiting 1 s, 2 s, 4 s … up to 30 s between tries.
- **`disconnect` with `reconnect: true`** (server restart, a deploy): reconnect as above.
- **`disconnect` with `reconnect: false`**: the sign-in ended (signed out, the driver signed in on another phone, account
  deleted) or the ticket was bad. Do not retry with the same ticket; ask for a new one, and on `401` go to the sign-in screen.

## 6. Checklist

1. One helper: get ticket → open socket → on `welcome` subscribe to the channels → dispatch messages by `identifier`.
2. Driver app: `DriverChannel` while signed in (a company switch needs no new subscription).
3. Convoy App: `AppChannel` while signed in (after Create Your Account); `TrackChannel` per open live screen (§ 4).
4. Refetch on (re)connect and when the app comes to the front; debounce refetches; move markers on `position`.
5. Remove every timer that polled these screens.
