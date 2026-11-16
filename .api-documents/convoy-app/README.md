# Convoy App API — Front-end Guide

The consumer phone app of Convoy (parents, staff who ride a company shuttle, people who book buses). Design reference:
`Convoy App.dc.html`. It uses this API only.

**Status (2026-11-16):** built and documented here: account and sign-in, Mobile and Emails, Household, Organisations,
School Bus (page, Bus Information, Request School Bus, Application Status, Renew / Change Service / Stop, Change of Address),
Fees and CCA Bus, Shuttles, Bookings, Home, Activity, the Alerts inbox and Live Tracking. **Not built yet (Phase 4b):** Bus
Not Required, School Calendar, Contact + Report an Issue, Stop Photos; those buttons have no API until their document is
added to this folder. A few HTML screens are not built by decision (Child Login, Discover, Language, Send Feedback,
Download My Data, prepaid school bookings): [screen-map.md § Not built](screen-map.md#not-built).

Start with [screen-map.md](screen-map.md): every screen, sheet and button of the HTML → the call → the section that
explains it (or "FE only" / "Not built").

## Documents

| Area | Document |
| --- | --- |
| Screen and button → call | [screen-map.md](screen-map.md) |
| Sign in / sign up, the one-time code, the session, Sign Out, several phones, push token, `profile_required`, rate limits | [auth.md](auth.md) |
| Create Your Account, Account (name, photo, notifications), Mobile and Emails, Suggest Convoy, Delete Account | [account.md](account.md) |
| Household: Set Up Your Family, children, Quick / Manual Invite, Asked to Join, Accept / Not Me, adult photo, Authorised Guardians, Delete Family | [household.md](household.md) |
| School Bus (parents): School Bus page, Bus Information, Request School Bus, Application Status, Renew / Change Service / Stop, Change of Address | [school.md](school.md) |
| Fees (bills, payments, invoice, Pay: simulated) and CCA Bus per ride (next week, pay to confirm, Not Riding, Same Days Every Week) | [fees.md](fees.md) |
| Shuttles (staff): employer route list, tags, pins, My Usual Shuttle, route page (14-day strip, timings, buses, changes, stops, bell), View Schedule, Alert Settings, Pause Alerts, the change alerts | [shuttles.md](shuttles.md) |
| Bookings: accounts (Personal, school / company), list, booking detail, New Booking (estimate, approval preview, Pay Myself), Pick a Point, Accept Changes / Can't Accept, Cancel (charge first), Book Again, Track Buses | [bookings.md](bookings.md) |
| Home (greeting, invitations, notice banners + dismiss, Up Next, tiles + badges, Get Started), Activity, the Alerts inbox (filter, read, Mark All Read, every alert kind and when it is written), Live Tracking (10-minute rule, privacy) | [home.md](home.md) |

Apidog: import [`../convoy-v3-api.openapi.json`](../convoy-v3-api.openapi.json); the Convoy App's calls are in the folder
**Convoy App** (security scheme `appAuth`).

## Conventions

The shared rules (JSON in snake_case, `{ data }` answers, the error format, rate limits, signed file links) are in
[../README.md](../README.md). For the app:

- Every path starts with **`/api/v1/app`**. Examples in these documents leave out `/api/v1`.
- One **account per person**, not per company. It is signed in with **any** verified mobile or email of the person
  ([account.md § 4](account.md#4-mobile-and-emails)). Signing in with a new mobile or email creates an account: there is
  no separate sign-up call.
- **Sign in** = mobile or email → one-time code (always `123456` until SMS and email are set up) → token
  ([auth.md](auth.md)). Send `Authorization: Bearer <token>` on every call. The token has its own scope: a Convoy OS,
  Client Portal or Driver app token gets `401` here, and an app token gets `401` on their endpoints.
- **Several phones at once** (unlike the Driver app): each sign-in has its own token; Sign Out ends only that phone.
- Until **Create Your Account** is done (first and last name, Terms accepted) every call other than the session, the
  profile, Mobile and Emails and the push token answers `403` with `code: "profile_required"`
  ([auth.md § 5](auth.md#5-profile_required)). The sign-in answer says it too: `account.profile_complete: false`.
- **Errors**: `{ "error": { "code", "message", "details" } }`. `message` is written for the person and can be shown as
  is; `details.<field>` names the field of a form. `400` a required parameter is missing, `401` signed out, `403`
  `profile_required`, `404` not the person's own, `422` a rule or a wrong code, `429` too many tries (`Retry-After`).
- **Files** (account, adult and child photos): `multipart/form-data`, JPEG / PNG / WebP / HEIC. A file comes back as
  `{ url, name, size, content_type, thumb_url }`: signed links valid for an hour that need no header (an image
  source); fetch the account again for fresh links.
- **Push** is not sent yet. The phone still registers its token ([auth.md § 4](auth.md#4-several-phones-and-the-push-token)),
  so nothing changes in the app when push starts. Every alert is in the inbox (`GET /app/alerts`, [home.md § 4](home.md#4-alerts-tab-inbox)).
- Names shown to people (`display_name`) follow **Show My Name As** (`name_order`): "Rachel Tan" or "Tan Rachel".

## Sample accounts (staging and local seed)

Sign in with the mobile or email and code `123456`:

| Sign in with | Person | Good for |
| --- | --- | --- |
| `+65 9188 2045` or `rachel.tan@gmail.com` | Rachel Tan (parent) | a mobile and a personal email on one account; Admin and Billing Contact of the **Tan Family** (2 children, a live invite link); **School Bus**: Ethan rides at St. Stephen's (a Change of Address waits for Agree; Live Tracking, boarded / alighted yesterday, running late this morning), Lucas has an AY 2027 application with the registration fee unpaid; **Fees**: Term 3 paid in the app, Term 4 due, the registration fee; **CCA Bus**: a ride the bus did not run (S$8 credit), Same Days Every Week Tue + Thu, a ride next week booked with that credit; **Bookings** (Personal with SimpleDrive): one paid by PayNow waiting for confirmation (receipt in a company name), one paid by card and confirmed; a full **Alerts** inbox and Home (Early Dismissal notice banner) |
| `+65 9177 3301` | David Tan (parent) | mobile only; Father in the Tan Family (sees Ethan's bus and alerts, no Fees: `403 billing_only`); try Add Mobile with Rachel's number to see a mobile move |
| `+65 9650 1187` | Tan Mei Ling (grandparent) | has a Tan Family invite waiting: Accept / Not Me |
| `rachel.tan@google.com` | Rachel Tan (Google staff) | work email only: no mobile, no personal email; **Shuttles**: Google Asia Pacific link accepted, My Usual Shuttle = MBC Campus Shuttle 07:45 from Alexandra Road (pinned), next weekday a relief driver on the 07:45 and another bus on the 08:15, a Cross-site run cancelled the day after; a shuttle notice in the inbox |
| `+65 9166 7720` or `priya_nair@moe.edu.sg` | Priya Nair (St. Stephen's teacher) | a mobile and a work email; **Bookings**: St. Stephen's account (accepted) with a booking waiting for Ms Lim's approval, a confirmed one and one changed by SimpleDrive (Accept / Can't Accept); also Personal |

Any other mobile or email can sign up: the correct code creates the account, and `profile_complete` is `false` until
Create Your Account is saved. An email at a personal provider (Gmail, Outlook, ...) becomes the personal email; any
other email becomes a work email.
