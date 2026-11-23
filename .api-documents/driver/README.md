# Convoy Driver app API — Front-end Guide

The phone app for drivers (Flutter repo **Convoy-Driver**). It uses this API only; the old API (`convoy-official-api`,
`/api/v1/drivers/*`, `/api/v2/drivers/*`) is no longer used. Design reference: `Convoy Driver.dc.html` (and
`design_handoff_driver_app/`).

Start with [screen-map.md](screen-map.md): every screen and button → the call → the section that explains it.

## Documents

| Area | Document |
| --- | --- |
| Screen and button → call | [screen-map.md](screen-map.md) |
| Sign in, sign out, Switch Company, invitations, Employment History | [auth.md](auth.md) |
| Account: profile, Career Metrics, email and password, Driving Credentials, Transport Company, Company Links | [profile.md](profile.md) |
| Drive (Today / Tomorrow), Plan, the on-going trip, Trip Details, New | [runs.md](runs.md) |
| On Route: start, arrive, leave, skip, attendance, count, Edit Route, complete, force end, skip trip; offline | [driving.md](driving.md) |
| GPS, geofence, app settings (GPS profile, reasons, date and time format) | [gps.md](gps.md) |
| Disposal: start and end odometer, runs, Extend Time, the block clock | [disposal.md](disposal.md) |
| My Vehicle Today, Switch Vehicle (handover inspection), Vehicle History | [vehicle.md](vehicle.md) |
| The bell: trip changes, vehicle switch, notices from the office (Open, Acknowledge) | [notifications.md](notifications.md) |
| Live updates: the WebSocket (ticket, DriverChannel, reconnecting) | [../websocket.md](../websocket.md) |
| What the app works out itself, and changes the app must make | [fe-updates.md](fe-updates.md) |

Apidog: import [`../convoy-v3-api.openapi.json`](../convoy-v3-api.openapi.json); the Driver app's calls are in the
folder **Driver App** (security scheme `driverAuth`).

## Conventions

The shared rules (JSON in snake_case, `{ data }` answers, the error format, rate limits, signed file links) are in
[../README.md](../README.md). For the app:

- Every path starts with **`/api/v1/driver`**.
- **Sign in** with a mobile number and a one-time code (always `123456` until SMS is set up; [auth.md](auth.md)), then
  send `Authorization: Bearer <token>` on every call. The token has its own scope: a Convoy OS or Client Portal token
  gets `401` here, and a Driver app token gets `401` on Convoy OS endpoints. **One phone at a time**: a sign-in on a new
  phone signs the old one out (`401` → back to the sign-in screen).
- A driver can work for several transport companies. Each is a **membership**, named by a `key` such as `"driver-4"`
  (own driver) or `"operator_driver-2"` (a sub-contractor's driver, "Managed by" the company). Work calls (trips, bus,
  GPS, bell) run in the company picked for the sign-in; without one they answer `422 "Pick a company first"`.
- **Times**: `HH:MM` strings for planned times (24-hour; the company's `time_format` is in `GET /driver/config` for
  display), ISO 8601 with the offset for moments (`2026-11-03T07:58:12+08:00`), in the company's timezone (Singapore).
- **Errors**: `{ "error": { "code", "message", "details" } }`. `message` is written for the driver and can be shown as
  is; `code` tells the app what to do (lists in [driving.md § 12](driving.md#12-errors-and-reasons)); `details.<field>`
  for a field. `401` signed out, `404` not the driver's, `422` a rule, `429` too many tries (`Retry-After`).
- **Files** (photos, card pictures, signatures): `multipart/form-data`, image files (JPEG / PNG). Files come back as
  `{ url, thumb_url, name, size, content_type }`: signed links valid for an hour that need no header (an image source);
  fetch the record again for fresh links.
- **Offline**: every driving action carries a `client_id` (UUID) and `at` (when it happened): queue them and send them in
  order when back online; sending one twice does nothing the second time (`meta.replayed: true`). GPS points are
  queued and sent in batches. Reading calls need the network.
- **Live updates**: a WebSocket, no polling ([../websocket.md](../websocket.md)): `DriverChannel` says when the driver's runs
  (`runs_changed`) or bell (`notifications_changed`) changed → fetch `GET /driver/runs` / `GET /driver/notifications` again.
  Fetch once on app start, on each (re)connect and when the app comes back to the front (the socket is closed in the
  background; push notifications are not sent yet).

## Sample accounts (staging and local seed)

Sign in with the mobile and code `123456`:

| Mobile | Driver | Good for |
| --- | --- | --- |
| `+65 9210 4100` | Eric Pang (SimpleDrive, own, bus PD997M) | complete profile verified with Singpass (email `eric.pang@gmail.com` / `Driver123!`), an invitation (Island Coaches), Employment History (Comfort Charter Services), a **disposal every day 08:00–11:30** (DBS Roadshow Disposal: Disposal start / run / Extend Time / end), a **bus swap tomorrow at 12:00** (Switch Vehicle card + handover inspection; he then drives Frankie's 14:00 transfer, and both are back on their own bus the day after) |
| `+65 9580 7810` | Tony Tan (Hup Seng, managed) | shuttles, a half-done profile, a licence expiring soon; Vehicle History: the five days before yesterday driven (PC7475L) |
| `+65 9284 4842` | Ah Beng (SimpleDrive, bus PE1290S) | School Bus: St. Stephen's AM 2 and PM 2 every school day (children, Bus Not Required, QR passes) |
| `+65 9002 3344` | Lee Kok Wah (SimpleDrive, bus PD4472H) | School Run (name list) every school day, and the Cross-site Shuttle's 12:00 return every weekday |
| `+65 9001 2233` | Kumar s/o Rajan (SimpleDrive, bus PD3318K) | his next run (weekdays 07:45) taken by a replacement: shows as Replaced |
| `+65 9247 4471` | Frankie Ho (SimpleDrive, bus PC7939R) | the other side of Eric's bus swap; a transfer every day at 14:00 |
| `+65 9003 4455` | Siti Nurhaliza (SimpleDrive, bus PC8841T) | St. Stephen's AM 1 every school day (Ethan Tan has a photo; the attendant has a note) and the MBC Campus Shuttle; her last ended runs (Plan; dates below): on the **last school day before the seed**, St. Stephen's AM 1 left its first point early with a child not boarded (`left_early`), skipped the next point and was completed with feedback; on the **last day before the seed with her shuttles**, a shuttle force ended (Accident) and the next one skipped before the start; Vehicle History: the five days before yesterday driven |

How long it lasts: the runs above come from recurring trips and routes, so they exist every day up to 120 days ahead
(the daily job adds the next day). Three things are made by the seed for the day it runs: the bus swap (tomorrow),
Kumar's Replaced run (his next run), Siti's ended runs (the last school day / shuttle day before the seed: in the school holidays that is the last day of term, e.g. 20/11/2026) and Siti's / Tony's driven days (the five days before
yesterday). They are made again each time staging is re-seeded.

**School holidays:** School Bus and School Run follow the MOE school calendar. There are no school runs in the holidays
(Year-End Holidays 21/11–31/12/2026; school is back on 04/01/2027): Ah Beng has no runs then, and Lee Kok Wah only has his
shuttle. Try School Bus / School Run on a school day.

Any other mobile can sign up (Create an Account); it has no company until a company invites that number.
