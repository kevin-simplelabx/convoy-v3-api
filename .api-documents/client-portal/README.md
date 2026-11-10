# Client Portal API — Front-end Guide

The web portal for people at Managed Clients (client admins, transport managers, facility managers). Design reference:
`Client Portal.dc.html`. Everyone signs in with a work email (one account across every organisation that adds the email),
picks an organisation, and sees what their role and sites allow.

Start with [screen-map.md](screen-map.md): every screen and button → the call → the section that explains it.

## Documents

| Area | Document |
| --- | --- |
| Screen and button → call | [screen-map.md](screen-map.md) |
| Answers to the front-end's findings and the changes it must make (newest first) | [fe-updates.md](fe-updates.md) |
| Sign in, pick an organisation, password, session | [auth.md](auth.md) |
| Shell: who am I, rail, what each role can do, Role Permissions | [shell.md](shell.md) |
| Settings: Users, Teams, Logo and Colour, Sites, Billing Details | [settings.md](settings.md) |
| Home: tiles, upcoming trips, today's shuttles, notices | [home.md](home.md) |
| Bookings: list, detail, New Booking (estimate, approval preview), Accept Changes | [bookings.md](bookings.md) |
| Approvals: Waiting for You / Others, Approve, Decline, the approval progress | [approvals.md](approvals.md) |
| Settings › Approval Flows, Try a Booking | [approval-flows.md](approval-flows.md) |
| Map (today): activities, runs, the trip card, find a student | [map.md](map.md) |
| Shuttles (routes, timetables) | [shuttles.md](shuttles.md) |
| Notices to riders | [notices.md](notices.md) |
| Invoices | [invoices.md](invoices.md) |

Apidog: import [`../convoy-v3-api.openapi.json`](../convoy-v3-api.openapi.json); the Portal's calls are in the folder
**Client Portal** (security scheme `portalAuth`).

## Conventions

The shared rules (JSON in snake_case, `{ data }` answers, the error format, rate limits, signed file links) are in
[../README.md](../README.md). Every Portal call uses the Bearer token of scope `portal_account` (security scheme
`portalAuth`); a Convoy OS token is refused.

## Not built (not in the design, or later)

- Asking to cancel a booking, a day or a trip; replying to changes (only Accept Changes); editing a booking or giving it a title.
- Sending a notice to the client's riders (Notices is read only).
- Paying invoices online, statements, invoice PDFs.
- The Map for other days (today only); rain and traffic layers (sample data in the design).
- The bell, and telling approvers by email that a booking waits for them.
- Emails are not sent yet (the one-time code shows as `dev_code` on staging, see [auth.md](auth.md)).
