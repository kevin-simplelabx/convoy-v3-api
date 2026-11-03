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
- **Push** is not sent yet: poll `GET /driver/notifications` and `GET /driver/runs` (app start, back to the front, every
  few minutes, after each action).

## Sample accounts (staging and local seed)

Sign in with the mobile and code `123456`:

| Mobile | Driver | Good for |
| --- | --- | --- |
| `+65 9210 4100` | Eric Pang (SimpleDrive, own) | complete profile verified with Singpass (email `eric.pang@gmail.com` / `Driver123!`), an invitation (Island Coaches), Employment History (Comfort Charter Services), a disposal record, a bus swap tomorrow at 12:00 |
| `+65 9580 7810` | Tony Tan (Hup Seng, managed) | shuttles, a half-done profile, a licence expiring soon |
| `+65 9284 4842` | Ah Beng (SimpleDrive) | School Bus (children, Bus Not Required, QR passes) |
| `+65 9002 3344` | Lee Kok Wah (SimpleDrive) | School Run (name list) and shuttles |
| `+65 9001 2233` | Kumar s/o Rajan (SimpleDrive) | a trip taken by a replacement (Replaced) |
| `+65 9247 4471` | Frankie Ho (SimpleDrive) | the other side of Eric's bus swap |

Any other mobile can sign up (Create an Account); it has no company until a company invites that number.
