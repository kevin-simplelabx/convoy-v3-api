# Convoy App — Account

Create Your Account, the Account tab (name, photo, notification switches), Mobile and Emails (Add Work Email, Add /
Change Mobile, Add / Change Personal Email, Verify Again, remove), Suggest Convoy, Privacy and Data › Delete Account.
Conventions: [README.md](README.md); sign-in: [auth.md](auth.md). Paths start with `/api/v1/app`.

## Contents

1. [Create Your Account](#1-create-your-account-patch-appprofile)
2. [The account](#2-the-account-get-appprofile)
3. [Account changes](#3-account-changes-patch-appprofile)
4. [Mobile and Emails](#4-mobile-and-emails): [list](#41-the-list-get-appidentities), [add](#42-add-code-then-verify), [remove](#44-remove-delete-appidentitiesid), [mobile moves](#45-a-mobile-on-another-account), [Verify Again](#46-work-email-verify-again)
5. [Suggest Convoy](#5-suggest-convoy-post-appcompany_suggestions)
6. [Delete Account](#6-delete-account-delete-appprofile)
7. [Values reference](#7-values-reference)

---

## 1. Create Your Account: `PATCH /app/profile`

Shown right after the first sign-in (`account.profile_complete: false`). Fields: First Name, Last Name, Show My Name As,
Terms of Use and Privacy Notice.

`{ profile: { first_name, last_name, name_order, accept_terms } }` → the account (§ 2).

```json
{ "profile": { "first_name": "Rachel", "last_name": "Tan", "name_order": "first", "accept_terms": true } }
```

- `first_name`, `last_name`: required, trimmed, 60 characters at most.
- `name_order`: `first` (default) or `last`. "Show My Name As" = how `display_name` is built.
- `accept_terms: true`: required the first time; the time is recorded. After that it is ignored.
- Done = `profile_complete: true`. Then every call of the app works ([auth.md § 5](auth.md#5-profile_required)).
- `422` "Enter your first and last name" (`details.first_name` / `details.last_name`: "can't be blank"); "Agree to the Terms
  of Use and Privacy Notice to continue" (`details.accept_terms`: "must be accepted"); an unknown `name_order`.
- A second personal identity can be added during sign-up with the Mobile and Emails calls (§ 4): they work before this
  step.

## 2. The account: `GET /app/profile`

The Account header, Show My Name As, Notifications and the banner, in one answer (the same `account` as the session in
[auth.md § 2](auth.md#2-sign-in-with-the-code-post-appsession)):

```json
{ "data": {
  "id": 1, "first_name": "Rachel", "last_name": "Tan", "name_order": "first", "display_name": "Rachel Tan",
  "delete_requested_at": null, "profile_complete": true, "needs_identity": false,
  "photo": { "url": "https://.../download/...", "name": "rachel.jpg", "size": 48213, "content_type": "image/jpeg",
             "thumb_url": "https://.../download/..." },
  "notifications": { "push": true, "sms": false, "email": true },
  "identities": [
    { "id": 2, "kind": "email", "tag": "personal", "value": "rachel.tan@gmail.com", "display": "rachel.tan@gmail.com" },
    { "id": 1, "kind": "mobile", "tag": "personal", "value": "+6591882045", "display": "+65 9188 2045" }
  ]
} }
```

- `display_name`: follows `name_order`; `null` before Create Your Account.
- `photo`: `null` or the file object (signed links, one hour).
- `identities` here are the short form (for the header and the sign-in line). Mobile and Emails uses the full list (§ 4.1).
- `delete_requested_at`: set after Delete Account until the person signs in again (the app cannot normally see it: every
  phone is signed out).
- **`needs_identity: true`** = the account has no mobile or email left. This happens when its only mobile was added to
  another person's account (numbers get reissued, § 4.5). The person stays signed in. Show a banner on Home and Account:
  **"Add a mobile or email to keep this account"** → Mobile and Emails with Add Mobile / Add Personal Email open (§ 4.2).
  Until they add one they cannot sign in again after Sign Out, and an account with no mobile or email and no phone
  signed in for 30 days is deleted. The banner goes away on its own: `needs_identity` is `false` once one is added.

## 3. Account changes: `PATCH /app/profile`

Account › name, photo, Notifications (push, SMS, email switches). Send only what changed.

`{ profile: { first_name, last_name, name_order, photo, remove_photo, notify_push, notify_sms, notify_email } }` → the
account (§ 2).

| Screen / control | Field |
| --- | --- |
| Edit name | `first_name`, `last_name` (still required) |
| Show My Name As | `name_order`: `first` / `last` |
| Photo: choose | `photo` (file; the request is `multipart/form-data`, field `profile[photo]`) |
| Photo: remove | `remove_photo: true` |
| Notifications switches | `notify_push`, `notify_sms`, `notify_email` (booleans; defaults on / **off** / on) |

- `notify_push` off stops push notifications to every phone of the account ([home § 4.1](home.md#41-push-notifications));
  the inbox still gets every alert. SMS and email are not sent yet, so `notify_sms` / `notify_email` change nothing today.
- `422` as in § 1 (a name cannot be emptied); a file that is not an image (JPEG, PNG, WebP, HEIC).

## 4. Mobile and Emails

Account › Mobile and Emails. **One account for home and work**: one mobile, one personal email, and a work email for each
employer or school. Every one of them signs in. Adding one is two calls (code, then verify); an identity is only stored
once its code is right.

### 4.1 The list: `GET /app/identities`

```json
{ "data": [
  { "id": 2, "kind": "email", "tag": "personal", "value": "rachel.tan@gmail.com", "display": "rachel.tan@gmail.com",
    "domain": "gmail.com", "verified_at": "2026-10-17T10:15:00+08:00", "reverify_due_on": null, "reverify_state": null,
    "uses": [] },
  { "id": 3, "kind": "email", "tag": "work", "value": "rachel.tan@google.com", "display": "rachel.tan@google.com",
    "domain": "google.com", "verified_at": "2026-08-16T10:15:00+08:00", "reverify_due_on": "2027-08-16", "reverify_state": "ok",
    "uses": [] },
  { "id": 1, "kind": "mobile", "tag": "personal", "value": "+6591882045", "display": "+65 9188 2045",
    "domain": null, "verified_at": "2026-10-17T10:15:00+08:00", "reverify_due_on": null, "reverify_state": null, "uses": [] }
] }
```

- Order: emails (personal first), then the mobile. A row = a Sign-in line plus its `tag` chip (Personal / Work).
- `reverify_due_on`, `reverify_state`: work emails only ([§ 4.6](#46-work-email-verify-again)).
- `uses`: what the identity is used for besides signing in, as labels to show on the row: the Family's name on the personal
  mobile ("Tan Family"), "Invoices and receipts" on the personal email of the Billing Contact. Employer and school links are added
  with the later phases; `uses` is also what blocks removing an identity (§ 4.4).
- Works before Create Your Account.

### 4.2 Add: code, then verify

| Button | `kind` | `tag` | `replace` |
| --- | --- | --- | --- |
| Add Work Email | `email` | `work` | — |
| Add Personal Email | `email` | `personal` | — |
| Change Personal Email | `email` | `personal` | `true` |
| Add Mobile | `mobile` | (always personal) | — |
| Change Mobile | `mobile` | (always personal) | `true` |

**Step 1: `POST /app/identities/code`** `{ kind, value, tag, replace }` → what to verify:

```json
{ "data": { "kind": "email", "value": "rachel@google.com", "display": "rachel@google.com", "tag": "work", "replace": false } }
```

Everything is checked here, before the code is sent: show the `422` message on the form field. Send the answer's
`value`, `tag` and `replace` unchanged in step 2.

**Step 2: `POST /app/identities/verify`** `{ kind, value, tag, replace, code }` →

```json
{ "data": {
  "outcome": "added",
  "identity": { "id": 3, "kind": "email", "tag": "work", "value": "rachel@google.com", "display": "rachel@google.com",
                "domain": "google.com", "verified_at": "2026-11-16T10:15:00+08:00", "reverify_due_on": "2027-11-16",
                "reverify_state": "ok", "uses": [] },
  "identities": [ "...the full list, as in § 4.1" ],
  "invitations": [ "links this work email just found, see organisations.md § 3; [] for a mobile, a personal email or when nothing matched" ]
} }
```

`outcome` tells which message to show:

| `outcome` | Meaning |
| --- | --- |
| `added` | a new row |
| `changed` | Change Mobile / Change Personal Email: the old personal one was replaced |
| `reverified` | Verify Again of a work email: `verified_at` renewed, no new row |
| `moved` | a mobile that another account had is now on this one ([§ 4.5](#45-a-mobile-on-another-account)) |

Codes: same rules as sign-in ([auth.md § 6](auth.md#6-codes-and-rate-limits)); the same wrong-code messages (`422`,
`details.code`). A code asked for one value does not work for another.

**Messages of step 1 and 2** (`422`, `error.message`):

| Case | Message |
| --- | --- |
| Not an 8-digit SG mobile / not an email | "Enter an 8-digit Singapore mobile number" / "Enter a valid email address" |
| `tag` not personal / work | "Choose personal or work" |
| Work email at Gmail, Outlook, Yahoo, iCloud ... | "Gmail, Outlook and other personal providers can't be a work email. Add it as your personal email instead" |
| A second work email at the same domain | "You already have a work email at google.com" |
| A second personal mobile / email without `replace` | "Only one mobile number. Use Change Mobile" / "Only one personal email. Use Change Personal Email" |
| Already on this account | "Already on your account" |
| Email that another account has | "This email is on another Convoy account. Sign in with it there" |
| Two requests added the same value at once | "This was added just now. Reload Mobile and Emails" |

The personal providers list: gmail, googlemail, hotmail, outlook, live, msn, yahoo, yahoo.com.sg, ymail, icloud, me,
mac, aol, proton.me, protonmail, qq, 163, 126, singnet.com.sg, zoho, gmx, mail.com, yandex. The app does not need the
list: send the value and show the message.

### 4.3 Change

Change Mobile / Change Personal Email = the same two calls with `replace: true`. The old one is removed and the new one
added in one step, so the account never has an empty moment when the mobile is its only identity. `outcome: "changed"`.

### 4.4 Remove: `DELETE /app/identities/:id`

The X on a row → the list again (§ 4.1, a `data` array).

- `422` "Used to sign in. Add another first, then switch": it is the account's last mobile / email (it signs in).
- `422` "Used by Tan Family. Add another first, then switch": the identity is in `uses` (a Family, invoices, an employer or
  school link): add the other one first. Show it from `uses` instead of waiting for the error (disable the X).
- `404` an identity of another account.

### 4.5 A mobile on another account

Numbers get reissued. A mobile that is already on another account **moves** to the person who verifies it: the
outcome is `moved`, the other account loses it (and nothing else of that account comes with it), and the old owner is
told by email when they have one. This is the same flow as Add / Change Mobile: show no extra warning on the form. The
old owner may be left with no identity: that account stays signed in and gets `needs_identity: true` (§ 2).

An **email** is never moved: "This email is on another Convoy account. Sign in with it there".

### 4.6 Work email: Verify Again

A work email is checked again every 12 months. Rows of work emails carry:

| `reverify_state` | When | Show |
| --- | --- | --- |
| `ok` | more than 30 days before `reverify_due_on` | "Verified `verified_at` · next check `reverify_due_on`" |
| `due_soon` | within 30 days before `reverify_due_on` | "Verify again by `reverify_due_on` to keep its links" + **Verify Again** |
| `paused` | `reverify_due_on` reached | "Links paused since `reverify_due_on`" + **Verify Again** (employer and school links found by this email are paused until verified, [organisations § 5](organisations.md#5-an-overdue-work-email-pauses-its-links)) |

`reverify_state` and `reverify_due_on` are `null` for a mobile and a personal email.

**Verify Again** has no call of its own: it is Add Work Email with the **same** value (`POST /app/identities/code`, then
`POST /app/identities/verify`, `tag: "work"`). The answer has `outcome: "reverified"`, the same row id, a new `verified_at`
and `reverify_state: "ok"`. No new row is added and the "second work email at the same domain" check does not apply.

## 5. Suggest Convoy: `POST /app/company_suggestions`

Mobile and Emails or Organisations › a work email that links to nothing → Tell Convoy. Creates a Company Lead for Convoy
Admin (Convoy Admin › Company Leads, source "Convoy app"). The person is named only if they agree.

`{ identity_id, company_name, contact, named }` →

```json
HTTP 201
{ "data": { "id": 12, "company_name": "Acme Pte Ltd", "domain": "acme.com", "named": false } }
```

| Field | |
| --- | --- |
| `identity_id` | id of one of the person's **work** emails (the domain of it is the company's) |
| `company_name` | required; trimmed to 120 characters (prefill it from the domain: first label, title-cased) |
| `contact` | optional, "Who to contact" (200 characters) |
| `named` | "Convoy May Say I Suggested It" switch (default `false`); `true` gives Convoy the person's `display_name` and the email |

- `422` "Suggest Convoy from a work email" (a mobile or personal email); "Enter the company name"
  (`details.company_name`). `404` an identity of another account. `403` `profile_required`.
- The call never says whether the company is already on Convoy.
- Sharing the fixed message ("could we use Convoy for our staff shuttles and bus bookings? ...") is the phone's native
  share sheet: no call.

## 6. Delete Account: `DELETE /app/profile`

Privacy and Data › Delete Account → confirm. Needs a finished account.

→ `{ "data": { "delete_on": "2026-12-16" } }` (30 days from now).

- Every phone is signed out at once (`401` from now on, including this one: go to Sign In). A confirmation goes to the
  account's email (personal first) when it has one. Show: "Request recorded. A confirmation email is on its way".
- **Signing in again before `delete_on` cancels it** (nothing to ask; `delete_requested_at` is `null` again in the session).
  After `delete_on` a daily job deletes the account with its mobiles, emails and sign-ins. Records that schools and
  transport companies must keep (riders, bills, bookings) stay with them.
- There are no blocking conditions.
- Accounts nobody can come back to are deleted by the same job after 30 days: no phone signed in and either Create Your
  Account never finished or no mobile / email left.

## 7. Values reference

| Field | Values |
| --- | --- |
| `outcome` | `added`, `changed`, `reverified`, `moved` |
| `reverify_state` | `ok`, `due_soon`, `paused` (work emails), `null` |
| `notify_*` defaults | push `true`, sms `false`, email `true` |
| `photo` | `null` or `{ url, name, size, content_type, thumb_url }` |
