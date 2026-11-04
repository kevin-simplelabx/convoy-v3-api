# Client Portal — sign in, pick an organisation

For the Client Portal app (people at Managed Clients), not Convoy OS. It has its **own Bearer token** (scope
`portal_account`): a Portal token is refused by the Convoy OS API (`401`) and a Convoy OS token is refused here.
Paths are under `/api/v1/portal`. Calls marked 🔒 need `Authorization: Bearer <portal token>`.

## 1. The screens

| Screen / button | Call | Next |
| --- | --- | --- |
| Work Email → Continue | `POST /portal/session/lookup { email }` | `next: "password"` → Password screen; `next: "code"` → One-Time Code screen (code emailed) |
| Password → Sign In | `POST /portal/session { email, password, device_name }` | Signed in (§ 2) |
| Forgot password? Send a code instead | `POST /portal/session/code { email }` | One-Time Code screen (`purpose: "reset"`) |
| One-Time Code → Verify | `POST /portal/session/verify { email, code }` | `{ set_password_token, purpose }` → Set Password screen |
| Set Password and Sign In | `POST /portal/password { set_password_token, password, password_confirmation, device_name }` | Signed in (§ 2) |
| Account picker (several clients) | 🔒 `PATCH /portal/session { client_user_id }` | `current` set |
| Page load | 🔒 `GET /portal/session` | Session (§ 2) |
| Sign Out | 🔒 `DELETE /portal/session` | `204` |

Lookup / code response: `{ email, next: "code", purpose: "first" | "reset", dev_code? }`.
Texts: first → "First sign-in: we sent a one-time code to your email. Enter it, then set your own password.";
reset → "We sent a one-time code to your email. Enter it to set a new password."

**`dev_code`**: email sending is not set up yet. On staging (and dev with `PORTAL_SHOW_CODE=1`) the response carries the
code: show it like the prototype ("Sample: the code is 123456 until email sending is set up"). Production never sends it.

Errors (`422` unless noted):
- "No client account for this email. Ask your transport company to add you under Managed Clients"
- "That code is not right. Check the email and try again" (5 tries), "That code has expired. Send a new one" (15 minutes, works once)
- "Too many codes asked for. Try again in an hour" (5 codes an hour)
- Set password: `details.password` "Password needs at least 8 characters", `details.password_confirmation` "doesn't match Password";
  "This link has expired. Ask for a new code" (the token works once, for 15 minutes)
- Sign in: `401` "Email or password is incorrect".
- Too many tries: `429` `too_many_requests` with `Retry-After` and `details.retry_after` (seconds). The email step (lookup,
  send a code) allows 30 a minute per IP; the password and code steps 10 a minute per IP and 5 a minute per email, so
  mistyped emails do not lock the password step. See [README § Rate limits](../README.md#rate-limits).

## 2. Session

```json
{ "data": {
  "token": "eyJ…", "token_type": "Bearer", "expires_at": "2026-12-02T09:00:00Z",
  "account": { "id": 3, "email": "priya.raman@google.com", "name": "Priya Raman" },
  "accounts": [
    { "client_user_id": 11, "name": "Priya Raman", "title": "Transport Lead", "role": "super", "role_label": "Super Admin", "wide": true,
      "client": { "id": 1, "name": "Google Asia Pacific", "kind": "company" },
      "company": { "id": 1, "name": "SimpleDrive", "display_name": "SimpleDrive", "theme_color": "#0B6E6E", "logo": null } }
  ],
  "current": { "client_user_id": 11, "...": "same shape" } } }
```

- `token` only on sign-in. Tokens last 30 days; setting a new password signs out every other device.
- `accounts`: every client this person is a user of (removed users, deleted clients and transport companies that are
  suspended are left out). With one account it
  is picked straight away (`current`); with several, `current` is `null` until the picker sends `PATCH /portal/session`.
- Sample (seed): `priya.raman@google.com` / `Portal123!` (Google and St. Stephen's School: the picker),
  `kenneth.ong@google.com` / `Portal123!`, `meiling@google.com` (not signed in yet: goes through the code).

## 3. After sign-in: the account picked

Every other Portal call (`/portal/me`, bookings, settings…) works for the account in `current`. Without one — none picked
yet, or the one picked is no longer usable (the person was removed, the client deleted, the transport company
suspended) — the call answers `422` with `code: "pick_account"`, "Pick an organisation first": show the picker
(`GET /portal/session` lists what is left). Each request runs in that client's transport company and its timezone
("today" on Home and the Map is the company's day).
