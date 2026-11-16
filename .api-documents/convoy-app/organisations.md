# Convoy App — Organisations

Account › **Organisations** (the employers and schools that found the person), the invitation card on Home and after Add Work
Email (Accept / Not Me), Remove Link, and a work email that is past its re-check. Conventions: [README.md](README.md);
sign-in: [auth.md](auth.md); work emails: [account.md § 4](account.md#4-mobile-and-emails). Paths start with `/api/v1/app`.
Every call needs the Bearer token and a finished Create Your Account ([auth § 5](auth.md#5-profile_required)).

## Contents

1. [How links work](#1-how-links-work)
2. [The screen: `GET /app/organisations`](#2-the-screen-get-apporganisations)
3. [After Add Work Email](#3-after-add-work-email)
4. [Accept / Not Me](#4-accept--not-me)
5. [An overdue work email pauses its links](#5-an-overdue-work-email-pauses-its-links)
6. [Remove Link](#6-remove-link)
7. [Values reference](#7-values-reference)

---

## 1. How links work

- Employers and schools find a person by **work email only**, never by mobile. A link is an **invitation**: nothing is linked
  until the person taps **Accept**; **Not Me** answers it for good (it is not offered again).
- Two kinds of link, each to one client of one transport company:
  - **`shuttle`** — staff shuttle. The client lists its **email domains** in Convoy OS; a verified work email on one of them
    invites the person as a **Rider**.
  - **`bookings`** — a teacher or booker. The client added the person (their work email) as a Client Portal user; a verified
    work email equal to it offers them the link as **Booker** or **Approver** (when they approve in the client's approval flow).
- Matching runs when a work email is verified (add or Verify Again) and every time `GET /app/organisations` is called (a client
  may add the domain later). The person is **never told** whether a company is on Convoy: an email nobody holds just shows
  under `unlinked`.
- A person cannot unlink: Remove Link only says "Ask <organisation>'s office to remove the link" ([§ 6](#6-remove-link)).
- A work email that is in an **accepted** link cannot be removed from Mobile and Emails (`422` "Used by Google Asia Pacific
  shuttle. Add another first, then switch", [account § 4.4](account.md#44-remove-delete-appidentitiesid)). Its `uses` show
  "<client> shuttle" or "Bookings with <company>". Removing a work email drops the invitations it found.

## 2. The screen: `GET /app/organisations`

```json
{ "data": {
  "invitations": [ { "kind": "shuttle", "id": 1, "status": "invited", "state": "invited",
                     "organisation": "Google Asia Pacific", "company": "SimpleDrive", "role": "Rider",
                     "matched_email": "rachel.tan@google.com", "added_by": "Your employer", "added_on": "2026-11-16",
                     "paused_since": null } ],
  "links": [ { "kind": "bookings", "id": 4, "status": "accepted", "state": "active", "organisation": "St. Stephen's School",
               "company": "SimpleDrive", "role": "Booker", "matched_email": "priya_nair@moe.edu.sg",
               "added_by": "Ops Admin", "added_on": "2026-11-16", "paused_since": null } ],
  "unlinked": [ { "identity_id": 9, "email": "rachel@unknown-co.com", "domain": "unknown-co.com", "company_guess": "Unknown Co" } ]
} }
```

| Part | Shows |
| --- | --- |
| `links` (accepted) | Linked rows. `shuttle`: "Staff shuttle by `company` · `role`", "Added by your employer · matched by work email `matched_email`". `bookings`: "Bookings with `company` · `role`", "Added by `added_by` on `added_on` · matched by `matched_email`" |
| `invitations` | Cards to **Accept** / **Not Me** ([§ 4](#4-accept--not-me)): "`organisation` added you to its staff shuttle. Matched by your work email `matched_email`. Accept to see its shuttle routes here." Home shows the same list |
| `unlinked` | One row per work email no organisation holds: "Nothing linked yet … Until then, book and pay yourself with a receipt in the company's name" + **Suggest Convoy** ([account § 5](account.md#5-suggest-convoy-post-appcompany_suggestions), prefill the company name with `company_guess`). Empty `links`, `invitations` and `unlinked` → "Work started using Convoy? … Add Work Email" |

A link is the pair (client, transport company): the same school at two companies is two links. `id` is unique per `kind`, so
always send both. `added_by` is the OS user / Portal person who added the booker, else "Your school"; riders: "Your employer".

## 3. After Add Work Email

`POST /app/identities/verify` ([account § 4.2](account.md#42-add-code-then-verify)) also answers `invitations`: the links this
work email just found and the person has not answered, in the shape of [§ 2](#2-the-screen-get-apporganisations).

- Not empty → "`organisation` added `email`. Accept to see it on Home and in Shuttles." with **Accept** / **Not Me** ([§ 4](#4-accept--not-me)).
- `[]` → the neutral "Nothing is linked to `email` yet…" + **Suggest Convoy** / **OK**.

## 4. Accept / Not Me

| Button | Call | Answer |
| --- | --- | --- |
| Accept | `POST /app/organisations/:kind/:id/accept` | the link (`status: "accepted"`, `state: "active"`) |
| Not Me | `POST /app/organisations/:kind/:id/decline` | `{ "declined": true }`; flash "Told `organisation` this is not you" |

`:kind` is `shuttle` or `bookings`. `404`: not the person's own, or the client / company is gone. `422`: "This was already
answered" (the same card tapped twice, or an accepted link: the person cannot decline it), "Verify <email> again to accept"
(the email is past its re-check, [§ 5](#5-an-overdue-work-email-pauses-its-links)), "<email> is not on your account any more".

## 5. An overdue work email pauses its links

A work email is checked every 12 months ([account § 4.6](account.md#46-work-email-verify-again)). Past the due date every
link found by it has **`state: "paused"`** and `paused_since` = the due date (an invitation can be shown but not accepted).
Nothing is deleted: **Verify Again** (same value, `tag: "work"`) makes the links `active` again. Show "Links paused since
`paused_since`. Verify `matched_email` again to use them." No new invitations are made for a paused email.

## 6. Remove Link

**No API.** The person cannot remove a link; the button only shows "Ask `organisation`'s office to remove the link". The
office does it in Convoy OS: removing a staff rider or a client user ends the link at once (the row disappears from `links`
the next time the screen is fetched). A removed or declined rider is not invited again by the same domain.

## 7. Values reference

| Field | Values |
| --- | --- |
| `kind` | `shuttle` (client riders), `bookings` (client user) |
| `status` | `invited` (waiting for the person), `accepted` (only these two are listed) |
| `state` | `invited`, `active`, `paused` |
| `role` | `Rider` (shuttle), `Booker`, `Approver` (bookings) |
