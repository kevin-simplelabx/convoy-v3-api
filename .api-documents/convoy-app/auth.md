# Convoy App — Sign in, session, devices

Sign In (mobile or email), One-Time Code, app start, Sign Out, the push token, and the rules every call follows:
`profile_required`, rate limits. Conventions: [README.md](README.md). Paths start with `/api/v1`.

## Contents

1. [Send the code](#1-send-the-code-post-appsessioncode)
2. [Sign in with the code](#2-sign-in-with-the-code-post-appsession)
3. [The session and Sign Out](#3-the-session-and-sign-out)
4. [Several phones and the push token](#4-several-phones-and-the-push-token)
5. [profile_required](#5-profile_required)
6. [Codes and rate limits](#6-codes-and-rate-limits)
7. [Values reference](#7-values-reference)

---

## 1. Send the code: `POST /app/session/code`

Sign In screen: Mobile or Email → Continue. Public (no token).

`{ mobile }` **or** `{ email }` → `{ "data": { "kind", "value", "display" } }`

```json
{ "data": { "kind": "mobile", "value": "+6591882045", "display": "+65 9188 2045" } }
{ "data": { "kind": "email", "value": "rachel@gmail.com", "display": "rachel@gmail.com" } }
```

- `mobile` may be typed with or without `+65` and spaces (`"9188 2045"`, `"+65 9188 2045"`). `email` may have capitals and
  spaces around it. The answer gives the cleaned value (`value`: E.164 mobile / lower-case email) and how to show it
  (`display`). Send `value` in the next step.
- Only Singapore mobiles (8 digits starting with 8 or 9).
- **No SMS or email is sent yet: the code is always `123456`.** Nothing changes in the app when real codes start.
- The same call serves sign in and sign up: the first correct code for a mobile or email nobody has used creates the
  account (§ 2).
- `422` "Enter an 8-digit Singapore mobile number" (`details.mobile`); "Enter a valid email address" (`details.email`);
  "Too many codes asked for. Try again in an hour" (5 codes an hour per mobile / email, § 6). `400` when neither
  `mobile` nor `email` is sent.

## 2. Sign in with the code: `POST /app/session`

One-Time Code screen. Public.

`{ mobile | email, code, device_name }` → the session (§ 3) **with** `token`.

```json
{ "data": {
  "token": "eyJhbGciOi...", "token_type": "Bearer", "expires_at": "2026-12-16T10:15:00+08:00",
  "account": {
    "id": 1, "first_name": null, "last_name": null, "name_order": "first", "display_name": null,
    "delete_requested_at": null, "profile_complete": false, "needs_identity": false, "photo": null,
    "notifications": { "push": true, "sms": false, "email": true },
    "identities": [ { "id": 1, "kind": "mobile", "tag": "personal", "value": "+6591882045", "display": "+65 9188 2045" } ]
  }
} }
```

- Any verified mobile or email of the person signs in to the same account (Rachel's mobile and her gmail open one
  account).
- A value no account has yet **creates the account**, with that value as its first identity: a mobile and a
  personal-provider email are `tag: "personal"`, any other email is `tag: "work"` (it is then checked again every 12
  months, [account.md § 4.6](account.md#46-work-email-verify-again)). The answer has `profile_complete: false`: show
  **Create Your Account** ([account.md § 1](account.md#1-create-your-account-patch-appprofile)). A signed-in person with
  `profile_complete: true` goes straight to Home.
- Signing in within 30 days of **Delete Account** keeps the account: the deletion is cancelled
  (`delete_requested_at` is `null` in the answer; [account.md § 6](account.md#6-delete-account-delete-appprofile)).
- A code works once, for 10 minutes, with 5 tries. `422` "That code is not right. Try again" (`details.code`); "That code
  has expired. Send a new one" (no code asked for, used, older than 10 minutes, or 5 wrong tries: ask for a new one).
- `device_name`: optional, e.g. "Pixel 8" (kept with the sign-in).
- `expires_at`: the token lasts 30 days; after that (or after Sign Out / Delete Account) calls answer `401` and the app
  goes back to the sign-in screen.

Send `Authorization: Bearer <token>` on every later call.

## 3. The session and Sign Out

### 3.1 App start: `GET /app/session`

→ `{ "data": { "account": { ... } } }`: the same `account` as in § 2, **without** `token`. Call it when the app starts
and when it comes back to the front: `401` = signed out; `account.profile_complete: false` = Create Your Account;
`account.needs_identity: true` = the banner in [account.md § 2](account.md#2-the-account-get-appprofile). The account
carries everything the Account header needs, so the app can show it without another call.

### 3.2 Sign Out: `DELETE /app/session`

→ `204`. Ends **this phone's** sign-in only (other phones stay signed in) and removes its push token. Go back to the
Sign In screen.

## 4. Several phones and the push token

- A person can be signed in on several phones at once; each sign-in has its own token (`app_jwts`, `device_name`).
- **Delete Account** signs out every phone ([account.md § 6](account.md#6-delete-account-delete-appprofile)).

### 4.1 Register the push token: `PATCH /app/device`

`{ device: { platform, push_token } }` → `204`. `platform` is `ios` or `android`; `push_token` is the FCM / APNs token
(up to 4096 characters). `PUT` works the same (Rails accepts both). Call it after sign-in and whenever the OS gives a new token. Works before Create Your Account.

- One token per sign-in: a second call replaces the first. A token that another sign-in registers moves to that
  sign-in (a phone passed to another person never keeps the old person's token).
- Flat parameters (`{ platform, push_token }`) are accepted too.
- `422` an unknown `platform` (`details`); `400` / `422` when `push_token` is missing.
- Nothing is pushed yet: alerts will be kept in the app's inbox (later phase).

### 4.2 Remove it: `DELETE /app/device`

→ `204`. For "turn off notifications on this phone". Sign Out removes it too.

## 5. `profile_required`

Until Create Your Account is saved, every call except the ones below answers

```json
HTTP 403
{ "error": { "code": "profile_required", "message": "Create your account first" } }
```

Reachable before Create Your Account: `POST /app/session/code`, `POST /app/session`, `GET /app/session`,
`DELETE /app/session`, `GET` / `PATCH /app/profile`, all of `/app/identities`, `PATCH` / `DELETE /app/device`.
`DELETE /app/profile` (Delete Account) and `POST /app/company_suggestions` need a finished account.

The app should not rely on the `403`: read `account.profile_complete` from the sign-in answer or `GET /app/session` and
send the person to Create Your Account. The `403` is the safety net (an old screen, a deep link).

## 6. Codes and rate limits

Per code (sign in, Add Mobile / Email, Verify Again):

| Rule | Value |
| --- | --- |
| Works | once |
| Lifetime | 10 minutes |
| Wrong tries | 5, then it is "expired" |
| A new code | replaces older unused codes of the same kind (sign-in codes and Add Mobile codes of one account do not cancel each other) |
| Codes asked for | 5 an hour per mobile / email (`422` "Too many codes asked for. Try again in an hour") |

Per request (`429`, usual body, `Retry-After` header):

| Calls | Limit |
| --- | --- |
| `POST /app/session/code`, `POST /app/identities/code` | 30 a minute per IP |
| `POST /app/session`, `POST /app/identities/verify` | 10 a minute per IP |
| `POST /app/session` | 5 a minute per mobile / email (any IP) |
| every `/api/` call | 300 a minute per IP |

```json
HTTP 429  Retry-After: 42
{ "error": { "code": "too_many_requests", "message": "Too many tries. Try again in 42 seconds", "details": { "retry_after": 42 } } }
```

Show `message` as is, and disable Resend for `details.retry_after` seconds.

## 7. Values reference

| Field | Values |
| --- | --- |
| `kind` (identity) | `mobile`, `email` |
| `tag` (identity) | `personal`, `work` (a mobile is always `personal`) |
| `name_order` | `first` ("Rachel Tan"), `last` ("Tan Rachel") |
| `platform` | `ios`, `android` |
| error `code` | `profile_required`, `too_many_requests`, `invalid` (422 on a form), `unauthorized`, `not_found`, `bad_request` |
