# Driver app — Sign in and companies

Sign-in screen (mobile number → Send OTP → code), Create an Account, "Use email address instead", Sign Out,
Account › Transport Company (Switch Company, Disconnect), invitations and Employment History.
Conventions: [README.md](README.md). Paths start with `/api/v1`.

## Contents

1. [Sign in with the mobile number](#1-sign-in-with-the-mobile-number)
2. [Sign in with email and password](#2-sign-in-with-email-and-password-post-driversessionemail)
3. [The session](#3-the-session-get-driversession)
4. [Switch Company and Sign Out](#4-switch-company-and-sign-out)
5. [Companies, invitations, Employment History](#5-companies-invitations-employment-history)
6. [Values reference](#6-values-reference)

---

## 1. Sign in with the mobile number

| Screen / button | Call | Next |
| --- | --- | --- |
| Mobile Number → Send OTP | `POST /driver/session/code { phone }` | show the code boxes |
| Code typed | `POST /driver/session { phone, code, device_name }` | the session with the token (§ 3) |
| Resend code | `POST /driver/session/code { phone }` again | older codes stop working |

### 1.1 Send OTP: `POST /driver/session/code`

`{ phone }` → `{ phone, phone_display, new_account }`

- `phone` may be typed with or without `+65` and spaces (`"9123 4567"`, `"+65 9123 4567"`); the answer gives it back in
  E.164 (`"+6591234567"`) and as shown (`"+65 9123 4567"`). Send the E.164 value in the next step.
- **No SMS is sent yet: the code is always `123456`.** Nothing changes in the app when real SMS starts.
- `new_account: true` = no account for this mobile yet: the correct code creates it (there is no separate Create an
  Account call; show "Create an Account" wording if you like).
- `422` "Enter a valid mobile number" (`details.phone`); "Too many codes asked for. Try again in an hour" (5 codes an hour
  per mobile).

### 1.2 Sign in with the code: `POST /driver/session`

`{ phone, code, device_name }` → the session (§ 3) with `token`.

- A code works once, for 10 minutes, with 5 tries. `422` "That code is not right. Check the SMS and try again"
  (`details.code`); "That code has expired. Send a new one".
- On the first sign-in, every company record with this mobile (drivers the companies added or invited) becomes the
  driver's (see `memberships`). A driver with exactly one active company gets it picked at once.
- Signing in ends the account's other sign-ins (one phone at a time).
- `device_name`: optional, e.g. "Pixel 8".

Send `Authorization: Bearer <token>` on every later call. The token lasts 30 days; after that (or after a sign-in on
another phone) calls answer `401` and the app goes back to the sign-in screen.

## 2. Sign in with email and password: `POST /driver/session/email`

"Use email address instead": `{ email, password, device_name }` → the session (§ 3). Works once the driver has added an
email and password in Account ([profile.md § 3](profile.md#3-email-and-password-patch-driverprofileemail)). `401` "Email or password is incorrect" otherwise.

## 3. The session: `GET /driver/session`

Also the answer of every sign-in (with the token):

```json
{ "data": {
  "token": "eyJhbGciOi...", "token_type": "Bearer", "expires_at": "2026-12-03T10:15:00+08:00",
  "account": { "id": 1, "phone": "+6592104100", "phone_display": "+65 9210 4100", "name": "Eric Pang",
               "email": null, "password_set": false },
  "memberships": [
    { "key": "driver-4", "kind": "own", "status": "active",
      "company": { "id": 1, "name": "SimpleDrive", "display_name": "SimpleDrive", "theme_color": "#004F59", "logo": null },
      "employer_name": "SimpleDrive", "managed_by": null, "name_on_record": "Eric Pang",
      "invited_at": "2026-05-03T09:00:00+08:00", "joined_at": "2026-05-03T09:00:00+08:00", "left_at": null },
    { "key": "driver-21", "kind": "own", "status": "pending", "company": { "id": 3, "name": "Island Coaches", "...": "..." },
      "employer_name": "Island Coaches", "invited_at": "2026-11-01T10:00:00+08:00", "joined_at": null, "left_at": null },
    { "key": "driver-20", "kind": "own", "status": "past", "company": { "id": 2, "name": "Comfort Charter Services", "...": "..." },
      "joined_at": "2023-01-10T00:00:00+08:00", "left_at": "2024-09-30T00:00:00+08:00" }
  ],
  "current": { "key": "driver-4", "...": "the picked membership, or null" }
} }
```

- `token`, `token_type`, `expires_at` only in sign-in answers.
- `memberships`: active first, then pending (invitations), then past; by company name inside each. Declined invitations
  are not listed.
- `current: null` = no company picked (several active companies, or none): show the company picker, or the invitations.
- `logo`: `{ url, thumb_url, name, size, content_type }` signed link (no header needed), or null.

## 4. Switch Company and Sign Out

### 4.1 Switch Company: `PATCH /driver/session`

Account › Switch Company → pick one: `{ membership: "operator_driver-2" }` → the session.

- Only an `active` membership can be picked: `422` "You can only switch to a company you work for". Unknown key → `404`.
- Picking a company starts the driver's app session in that company (Ops Control shows the driver as signed in to the app).

### 4.2 Sign Out: `DELETE /driver/session`

→ `204`. The token stops working.

## 5. Companies, invitations, Employment History

| Screen / button | Call |
| --- | --- |
| Account › Transport Company, Employment History, invitations | `GET /driver/companies` |
| Invitation → Accept | `POST /driver/companies/:key/accept` |
| Invitation → Decline | `POST /driver/companies/:key/decline` |
| Account › Transport Company › Disconnect from … | `POST /driver/companies/:key/disconnect` |

### 5.1 List companies: `GET /driver/companies`

→ `{ data: [membership] }`, the same rows as `memberships` in the session, each with `trips_completed` (completed trips at
that company). Employment History = the `active` and `past` rows: company, `joined_at` → `left_at`, "`trips_completed` trips".

### 5.2 Accept an invitation: `POST /driver/companies/:key/accept`

→ the membership with `status: "active"`. It is picked for this sign-in when none was picked.

### 5.3 Decline an invitation: `POST /driver/companies/:key/decline`

→ `status: "declined"`; it drops off the list.

### 5.4 Disconnect from a company: `POST /driver/companies/:key/disconnect`

→ `status: "past"`; if it was the picked company, the session's `current` becomes null. This is the company's Remove: the
driver stops being the default driver of the company's buses from today. The driver's account and profile stay; the
company keeps its record (Past Drivers).

For 5.2–5.4: `422` "<name> is <status>, so this can't be done" when the row is not in the right status (e.g. accept twice);
`404` for a key that is not the driver's.

## 6. Values reference

| Field | Values |
| --- | --- |
| `membership.kind` | `own` (the company's own driver), `managed` (drives for a sub-contractor on the company's trips: show `employer_name`, "Managed by `managed_by`") |
| `membership.status` | `pending` (invitation), `active`, `past` (left) |
