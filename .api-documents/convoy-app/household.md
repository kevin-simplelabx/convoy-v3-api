# Convoy App — Household

Household (the Family): Set Up Your Family, the Household screen (Adults, Children), Add a Child and edit one, Add Family
Members (Quick Invite and Manual Invite), Asked to Join, Accept / Not Me, adult photos, Authorised Guardians, Delete Family.
Conventions: [README.md](README.md); sign-in: [auth.md](auth.md). Paths start with `/api/v1/app`. Every call needs the
Bearer token and a finished Create Your Account ([auth § 5](auth.md#5-profile_required)).

## Contents

1. [How a Family works](#1-how-a-family-works)
2. [Set Up Your Family](#2-set-up-your-family): [postal search](#21-postal-code-get-apphouseholdpostalpostal460412), [lists](#22-form-lists-get-apphouseholdoptions), [create](#23-create-post-apphousehold)
3. [The Household screen: `GET /app/household`](#3-the-household-screen-get-apphousehold)
4. [Children](#4-children): [add](#41-add-a-child-post-apphouseholddependants), [edit](#42-edit-a-child-patch-apphouseholddependantsid)
5. [Add Family Members](#5-add-family-members): [Quick Invite](#51-quick-invite-post-apphouseholdinvite_link), [the person opens the link](#52-the-person-opens-the-link), [Asked to Join](#53-asked-to-join-admin), [Manual Invite](#54-manual-invite), [Accept / Not Me](#55-accept--not-me)
6. [Adult photo](#6-adult-photo-patch-apphouseholdmembersid)
7. [Authorised Guardians](#7-authorised-guardians)
8. [Delete Family](#8-delete-family-delete-apphousehold)
9. [Values reference](#9-values-reference)

---

## 1. How a Family works

- A Family belongs to **people, not to a transport company**. Companies only see a child once a bus request is accepted
  (a later phase).
- **One Family per person.** The person who sets it up is its **Admin** (and the **Billing Contact** unless they switch
  that off). Adults are otherwise equal: any adult can add and edit children, invite, add photos and switch guardians.
  **Only the Admin** approves *Asked to Join* and deletes the Family (`403 admin_only` for others).
- Changing the Admin or Billing Contact, removing an adult, leaving a Family and removing a child are **not designed, so
  not built**.
- Until the person has a Family, `GET /app/household` answers `{ "data": null }` (Home: "Set Up Your Family") and every
  other call of this document except [§ 2](#2-set-up-your-family), [§ 5.2](#52-the-person-opens-the-link) and
  [§ 5.5](#55-accept--not-me) answers `404` with `code: "no_household"`.
- Join My Family (shows the person's mobile and emails so an adult can invite them) has no call of its own: show
  `GET /app/identities` ([account § 4.1](account.md#41-the-list-get-appidentities)). Invites are found by **mobile**.

## 2. Set Up Your Family

### 2.1 Postal code: `GET /app/household/postal?postal=460412`

The search button next to Postal Code. Fills Block / House No. and Street.

```json
{ "data": { "postal": "460412", "found": true, "block": "412", "street": "Bedok North Avenue 2",
            "address": "412 BEDOK NORTH AVENUE 2", "lat": 1.3236, "lng": 103.93 } }
```

- Not found, or the map service is down: `200` with `{ "found": false, "message": "Postal code not found, type the block and street" }`.
  Show the message and let the person type Block and Street.
- `422` "Enter a 6-digit postal code" when it is not 6 digits.

### 2.2 Form lists: `GET /app/household/options`

```json
{ "data": {
  "relationships": ["Mother", "Father", "Grandparent", "Relative", "Domestic Helper", "Family Friend"],
  "medical_tags": ["Asthma", "Food allergy", "Eczema", "Epilepsy", "Diabetes", "ADHD", "Autism", "Motion sickness", "Heart condition"],
  "genders": ["girl", "boy"],
  "level_year": 2027,
  "default_levels": ["Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6"],
  "schools": [ { "id": 3, "name": "St. Stephen's School", "levels": ["P1", "P2", "P3", "P4", "P5", "P6"] } ]
} }
```

- `schools`: every school Convoy runs buses for at an active transport company, once per name, sorted. The School field
  lists these **plus "Other"** (add it in the app). `levels` are that school's own levels; the Level field uses them, or
  `default_levels` for "Other". `level_year` is the year in the label "Level in 2027" (next year).
- `genders` are values; show them as Girl / Boy.

### 2.3 Create: `POST /app/household`

Step 1 of 2 (Family). Step 2 is [Add a Child](#41-add-a-child-post-apphouseholddependants), once per child.

```json
{ "household": { "name": "Tan Family", "postal": "460412", "block": "412", "street": "Bedok North Ave 2", "floor": "08",
                 "unit": "123", "line2": "", "billing_same": true, "billing_address": "", "billing_contact": true,
                 "relationship": "Mother" } }
```

| Field | Rule |
| --- | --- |
| `name` | required (Family Name) |
| `postal` | 6 digits |
| `block`, `street` | required. Landed homes: the house number as `block`, no `floor` / `unit` |
| `floor`, `unit`, `line2` | optional |
| `billing_same` | default `true`; `false` needs `billing_address` |
| `billing_contact` | "I am the Billing Contact", default `true` |
| `relationship` | optional: how the person is related to the children (a value of § 9). A Mother or Father can always receive the children ([§ 7](#7-authorised-guardians)) |

→ `201` the Household ([§ 3](#3-the-household-screen-get-apphousehold)). `422` messages follow the screen's order: "Enter the family
name", "Enter a 6-digit postal code", "Enter the block or house number and the street", "Enter the billing address";
"You are already in a Family". `details.<field>` names the field.

The home's map position is looked up from the postal code and kept for fares; it is never shown.

## 3. The household screen: `GET /app/household`

```json
{ "data": {
  "id": 1, "name": "Tan Family", "postal": "460412", "block": "412", "street": "Bedok North Ave 2", "floor": "08",
  "unit": "123", "line2": null, "address": "Blk 412 Bedok North Ave 2, #08-123", "billing_same": true, "billing_address": null,
  "you": { "member_id": 1, "admin": true, "billing_contact": true },
  "can_delete": true,
  "adults": [
    { "id": 1, "name": "Rachel Tan", "first_name": "Rachel", "phone": "+65 9188 2045", "relationship": "Mother", "admin": true,
      "billing_contact": true, "status": "active", "photo": null, "you": true, "needs_photo": false, "can_add_photo": true },
    { "id": 3, "name": "Tan Mei Ling", "first_name": "Mei Ling", "phone": "+65 9650 1187", "relationship": "Grandparent",
      "admin": false, "billing_contact": false, "status": "invited", "photo": null, "you": false, "needs_photo": false, "can_add_photo": false }
  ],
  "asked_to_join": [ { "id": 4, "name": "Maria Santos", "first_name": "Maria", "phone": "+65 8123 4410", "requested_at": "2026-11-16T10:15:00+08:00" } ],
  "children": [
    { "id": 1, "name": "Ethan Tan", "first_name": "Ethan", "birth_date": "2016-03-14", "level": "Primary 4", "gender": "boy",
      "student_id": "S4-0412", "medical_tags": [], "medical_note": null, "photo": null,
      "school": { "id": 3, "name": "St. Stephen's School" }, "status": { "code": "no_bus", "label": "No Bus Yet", "tone": "neutral" } }
  ]
} }
```

- **Adults** row: avatar (`photo`, else initials), `name`, badges **You** (`you`) and **Invited** (`status: "invited"`);
  meta line = `relationship · phone`, then " · Admin" and " · Billing Contact". `needs_photo` = the orange line "Add a
  photo before they can receive the children"; `can_add_photo` = the add-photo button ([§ 6](#6-adult-photo-patch-apphouseholdmembersid)).
  `phone` is the person's mobile (`null` if they have none).
- **asked_to_join**: people who opened the Quick Invite link. **Only the Admin gets rows** (everyone else `[]`). Show the
  Relationship select with Decline / Approve ([§ 5.3](#53-asked-to-join-admin)).
- **Children** row: name, "`level` · `school.name`", the badge `status.label` (tone `neutral` / `success` / ...). Today
  every child is "No Bus Yet"; the bus statuses (Active, Requested, ...) arrive with the School Bus phase.
- **can_delete**: show Delete Family only when `true` (the Admin).
- `address` is the line the screens print: flats "Blk 412 Bedok North Ave 2, #08-123", landed "20 Siglap View".

## 4. Children

Both calls need any adult of the Family. Fields (`dependant`):

| Field | Rule |
| --- | --- |
| `name` | required, as on the birth certificate |
| `birth_date` | required, `YYYY-MM-DD`, in the past |
| `school_id` | a `schools[].id` of [§ 2.2](#22-form-lists-get-apphouseholdoptions) |
| `school_name` | for "Other": the name typed (ignored when `school_id` is sent). One of the two is required |
| `level` | required; the level next year (text, from `levels` / `default_levels`) |
| `gender` | optional: `girl` / `boy` |
| `student_id` | optional ("From the school") |
| `photo` | optional image file (`multipart/form-data`, `dependant[photo]`) |
| `medical_tags` | optional list from `medical_tags` of § 2.2 (`dependant[medical_tags][]`) |
| `medical_note` | optional free text (details) |

### 4.1 Add a Child: `POST /app/household/dependants`

→ `201` `{ "data": child }` (the same object as a Household `children` row). `422` messages: "Enter the full name",
"Enter the date of birth", "Choose the school", "Choose the level"; an unknown medical tag, a future birth date, a gender
that is not `girl` / `boy`.

Bus service is applied for separately, when the school opens its application window (a later phase). Saving a child
never starts a request.

### 4.2 Edit a child: `PATCH /app/household/dependants/:id`

Send only what changed. `remove_photo: true` clears the photo. `medical_tags: []` clears the tags. → `200` the child.
`404` for a child of another Family.

## 5. Add Family Members

Household › Adults › Add Family Members opens Quick Invite or Manual Invite. Any adult can do either.

### 5.1 Quick Invite: `POST /app/household/invite_link`

```json
{ "data": { "token": "TAN-7KQ2", "url": "https://convoy.sg/j/TAN-7KQ2", "expires_at": "2026-11-23T10:15:00+08:00",
            "message": "Rachel Tan has invited you to join their Convoy for Family account to manage the family travel needs. Join here: https://convoy.sg/j/TAN-7KQ2" } }
```

Show `message`; Copy Link / Messages / WhatsApp / Telegram / More share it from the phone. The link works **7 days**; the same live
link is returned while it lasts, a new one after it ends. Nobody joins without the Admin approving.

### 5.2 The person opens the link

The link opens the app (deep link `convoy.sg/j/<token>`): the person signs in (or signs up), then:

- `GET /app/household/links/:token` → `{ "data": { "family": "Tan Family", "invited_by": "Rachel Tan", "expires_at": "..." } }`
  (show "<invited_by> invited you to join <family>").
- `POST /app/household/links/:token/join` → `201` `{ "data": { "status": "requested", "family": "Tan Family" } }`. Show
  "Waiting for the Admin to approve". Sending it again changes nothing.

Errors: `404` no such link; `422` with `code: "link_expired"` ("This invite link has expired. Ask for a new one"; also when the Family
was deleted); `422` "You are already in a Family". These calls work for a person without a Family.

### 5.3 Asked to Join (Admin)

The Admin sees the person under `asked_to_join` ([§ 3](#3-the-household-screen-get-apphousehold)), sets the Relationship and taps:

- **Approve**: `POST /app/household/members/:id/approve { "relationship": "Father" }` → `200` the Household. The person is now an
  adult. Toast "<first_name> joined the <Family name>". `422` "Choose how <first> is related" when `relationship` is missing.
- **Decline**: `POST /app/household/members/:id/decline` → `200` the Household. Toast "Request declined".

`:id` is the `id` of the `asked_to_join` row. `403` `admin_only` for any other adult; `422` "This request was already answered";
`422` "<first> joined another Family in the meantime".

### 5.4 Manual Invite

Three steps in the app: pick contacts → relationship → send. Contacts are the **phone's own contacts** (and "Add Someone" typed by
hand, mobile `8` or `9` + 7 digits): the API never searches Convoy users.

**Pick: `POST /app/household/invites/check`** `{ "contacts": [ { "name": "David Tan", "phone": "9177 3301" } ] }` →

```json
{ "data": [ { "name": "David Tan", "phone": "+6591773301", "valid": true, "on_convoy": true, "in_household": false } ] }
```

- `on_convoy: true` → gets an in-app invite; ask for the Relationship (required). `false` → gets the link instead.
- `in_household: true` → already invited, asked, or in the Family: show disabled.
- `valid: false` → not a Singapore mobile (`phone` is `null`).

**Send: `POST /app/household/invites`** `{ "contacts": [ { "name": "David Tan", "phone": "9177 3301", "relationship": "Father" }, { "name": "Tan Mei Ling", "phone": "9650 1187" } ] }` →
`201`

```json
{ "data": { "invited": [ { "id": 2, "name": "David Tan", "status": "invited", "relationship": "Father", "...": "an adults row of § 3" } ],
            "link_for": [ { "name": "Tan Mei Ling", "phone": "+6596501187" } ] } }
```

- `invited`: people with an account now show under Adults with the **Invited** badge until they accept. No Admin approval.
- `link_for`: contacts without an account. Go to the "Invite the Rest by Link" step and show the Quick Invite message ([§ 5.1](#51-quick-invite-post-apphouseholdinvite_link)); they ask to join and the Admin approves. When `link_for` is empty, finish.
- Sending the same person again re-sends (a declined invite becomes Invited again). A person already in the Family is skipped.
- `422` "Choose at least one contact", "Choose how <first> is related", "Check the mobile number of <name>".

### 5.5 Accept / Not Me

The invited person sees the invite on Home (the card is built with Home, a later phase; the call works now). Works for a
person without a Family.

- `GET /app/household/invitations` → `{ "data": [ { "id": 2, "family": "Tan Family", "invited_by": "Rachel Tan", "relationship": "Father", "invited_at": "..." } ] }`
- **Accept**: `POST /app/household/invitations/:id/accept` → `200` the Household (the person is an adult, `you.admin: false`).
  `422` "You are already in a Family" (one Family per person; leaving a Family is not built).
- **Not Me**: `POST /app/household/invitations/:id/decline` → `{ "data": { "declined": true } }`.
- `404` for an invite sent to someone else or already answered; `422` "This Family no longer exists".

## 6. Adult photo: `PATCH /app/household/members/:id`

"Add a Photo of <first>": the bus attendant checks the adult's face against this photo before hand-over, so a person
with no photo cannot receive the children. Any adult can add it, for any adult who has joined (the add-photo button shows
when `can_add_photo`).

`multipart/form-data`: `member[photo]` (image, required) → `200` the Household. `:id` is the adult's `id` in `adults`.
`422` "Add a photo first"; "<first> has not accepted the invite yet". This is the photo for hand-over, not the person's own profile photo.

From Authorised Guardians, **Save and Allow** = this call, then the switch call of § 7.

## 7. Authorised Guardians

Per child (the pills "Can Receive <first> · n of m") the adults who may receive the child at drop-off.

**`GET /app/household/guardians`** →

```json
{ "data": [ {
  "id": 1, "name": "Ethan Tan", "first_name": "Ethan", "can_receive": 2, "of": 3,
  "adults": [
    { "member_id": 1, "name": "Rachel Tan", "photo": null, "relationship": "Mother", "status": "active", "state": "always", "allowed": false, "can_receive": true },
    { "member_id": 2, "name": "David Tan", "photo": null, "relationship": "Father", "status": "active", "state": "always", "allowed": false, "can_receive": true },
    { "member_id": 3, "name": "Tan Mei Ling", "photo": null, "relationship": "Grandparent", "status": "active", "state": "needs_photo", "allowed": false, "can_receive": false }
  ] } ] }
```

| `state` | Show |
| --- | --- |
| `always` | Mother / Father: "Always", the switch locked on |
| `on` / `off` | the switch (on / off) |
| `needs_photo` | "Needs a photo" and the Add Photo button ([§ 6](#6-adult-photo-patch-apphouseholdmembersid), then switch on) |
| `pending` | "Can be switched on once they accept the invite" |

`can_receive` (child) = adults who can receive; `of` = adults listed.

**Switch: `PUT /app/household/dependants/:dependant_id/guardians/:member_id`** `{ "allowed": true }` → `200` that child, as above.
`:member_id` is the adult's `id`. `422` with `code`: `always` (Mother / Father cannot be switched), `not_accepted` ("Can be switched on once <first>
accepts the invite"), `needs_photo` ("<first> needs a photo first"). Switching off always works. Any adult of the Family may switch.

"Add Someone to the Household" → [§ 5](#5-add-family-members).

## 8. Delete Family: `DELETE /app/household`

Admin only (`403 admin_only`; show the button when `can_delete`). Ask first: "Delete <Family name>? The Family, its children and pending
requests are removed for every adult in it. Your own account stays, with your shuttles and bookings. Records the school and
transport company must keep stay with them."

→ `200` `{ "data": { "deleted": true } }`; then `GET /app/household` answers `null` and the person can Set Up Your Family again.

**Blocked** while a child has an active bus service, an accepted request or an unpaid bill: `422`
`{ "error": { "code": "family_blocked", "message": "This Family can't be deleted yet. Stop the service with the transport company and settle invoices first.", "details": { "reasons": [ { "code": "active_service", "label": "..." } ] } } }`
→ show the dialog "This Family can't be deleted yet" with an OK button. Until School Bus requests and fees exist (later phases)
nothing blocks it.

If the last adult's account is removed (Delete Account, [account § 6](account.md#6-delete-account-delete-appprofile)) the Family is removed too.

## 9. Values reference

| Field | Values |
| --- | --- |
| `relationship` | `Mother`, `Father`, `Grandparent`, `Relative`, `Domestic Helper`, `Family Friend` (Mother and Father = the "parents") |
| adult `status` | `active`, `invited` (Accept / Not Me pending). `requested` people are in `asked_to_join`, `declined` ones are not listed |
| `gender` | `girl`, `boy` |
| guardian `state` | `always`, `on`, `off`, `needs_photo`, `pending` |
| child `status.code` | `no_bus` (more with School Bus) |
| error `code` | `no_household` (404), `admin_only` (403), `link_expired`, `family_blocked`, `always`, `not_accepted`, `needs_photo` (422) |
