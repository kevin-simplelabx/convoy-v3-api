# Convoy App — Fees and CCA Bus (parents)

**Account › Fees** (invoices, payment history, an invoice and how to pay it) and **CCA Bus** (rides charged per ride, next
week). Design: `Convoy App.dc.html` screens `fees`, `inv`, `cca`. Conventions: [README.md](README.md); the School Bus page
that opens them: [school.md](school.md). Paths start with `/api/v1/app`. Money is a decimal string (`"54.5"`): show it with
two decimals ("S$54.50"). Dates are the transport company's (Singapore time).

> **Payments are simulated** (decision 04/11/2026): a card, PayNow or bank transfer payment is **collected at once**, whatever
> the method, and recorded in Convoy OS as a payment with `source: "app"`. No provider, no pending bank match. The FE shows
> the card form, the PayNow QR and the bank details as designed and then calls Pay; nothing is charged. When a provider is
> chosen only the server changes (the FE contract below stays).

## Contents

1. [Who can do what](#1-who-can-do-what)
2. [Fees: `GET /app/fees`](#2-fees-get-appfees)
3. [Invoice: `GET /app/fees/invoices/:id`](#3-invoice-get-appfeesinvoicesid)
4. [Pay: `POST /app/fees/invoices/:id/pay`](#4-pay-post-appfeesinvoicesidpay)
5. [CCA Bus week: `GET /app/cca`](#5-cca-bus-week-get-appcca)
6. [Quote and Pay to confirm](#6-quote-and-pay-to-confirm)
7. [Not Riding and Same Days Every Week](#7-not-riding-and-same-days-every-week)
8. [Home card and badges](#8-home-card-and-badges)
9. [Errors](#9-errors)

---

## 1. Who can do what

| | Billing Contact | Other adult |
| --- | --- | --- |
| Fees, Invoice, Pay (registration fee, first invoice, period bills) | yes | `403 { code: "billing_only" }` on all three calls |
| CCA Bus: look at the week, quote, Same Days Every Week, Not Riding / Riding After All | yes | yes |
| CCA Bus: **Pay to confirm** | yes | `403 { code: "billing_only" }` (the week says `can_pay: false`: show the button disabled, "Ask the Billing Contact to pay") |

- The Fees quick action and the badge are only for the Billing Contact: `GET /app/school` → `actions.fees` is `null` for
  anyone else, `{ "due": 2 }` for the Billing Contact (bills still to pay; `due` = `outstanding.count`).
- A bill is found among the **Family's own**. Another Family's bill, or a bill of another company, is `404` on Invoice and Pay.
- The bills of the Family: the **period bill** of each billing period (issued by the company), the **registration fee**
  bill of a request sent from the app, the **first invoice** of an accepted request, and a **CCA bill** for each CCA payment
  (always already paid). Drafts are never shown. One school can be served by several companies: bills of all of them come
  in one list, each with `company { name, mark }`.

## 2. Fees: `GET /app/fees`

```json
{ "data": {
  "family": { "name": "Tan Family" },
  "outstanding": { "total": "512.3", "count": 2, "pay_first_id": 22,
    "items": [ { "id": 22, "number": "INV-2026-000022", "period": "Registration · AY2027", "due_on": "2026-11-16", "owed": "54.5",
                 "school": { "id": 1, "name": "St. Stephen's School" }, "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" } } ] },
  "invoices": [ { "id": 24, "number": "INV-2026-000024", "kind": "period", "period": "Term 4 | Sep 2026",
                  "school": { "id": 1, "name": "St. Stephen's School" }, "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" },
                  "total": "457.8", "owed": "457.8", "status": { "label": "Due", "tone": "info" },
                  "issued_on": "2026-11-09", "due_on": "2026-11-23", "paid_on": null, "method": null, "can_pay": true } ],
  "payments": [ { "id": 12, "amount": "457.8", "admin_fee": "0.0", "method": "PayNow", "paid_on": "2026-10-04", "bill_id": 23,
                  "number": "INV-2026-000023", "period": "Term 3 | Jun 2026", "receipt_number": "RCP-2026-000003",
                  "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" } } ]
} }
```

- **Outstanding card**: `outstanding.total` (S$ amount), `outstanding.items` (one line per bill: "`period` · due `due_on`", the
  design's `dueSub`). `count == 0` → green "All paid. Nothing outstanding." **Pay with PayNow** opens the Invoice of
  `pay_first_id` (the earliest due bill).
- **Invoices tab**: `invoices` newest first. Row: `period`, "`number` · Paid `paid_on`" when `status.label == "Paid"` else
  "`number` · Due `due_on`", `total`, badge `status` (`label`, `tone`: Paid success, Part Paid warning, Overdue danger,
  Due info, Credited neutral). `owed` is what is still to pay today, **a late fee included** once the bill is overdue (the
  school's Payment & Refund Policy); `can_pay` is false for a paid bill and for a first invoice that cannot be paid now
  (request no longer Accepted). `kind`: `period`, `registration`, `first`, `cca`.
- **Payments tab**: `payments` newest first. Row: "`amount` · `method`", "`paid_on` · `number` · `period`". **Receipt**: `receipt_number`
  is set for a payment with a receipt (period bills, first invoice, registration fee) and `null` for a CCA payment (the
  invoice is the receipt). No email is sent yet: show the receipt number / the Invoice (§ 3 `payment.receipt_to` is the
  address it will go to).
- Everything is returned in one call (a Family has a handful of bills a year).

## 3. Invoice: `GET /app/fees/invoices/:id`

The `invoices[]` row plus the detail. Fields not in a row:

| Field | Meaning |
| --- | --- |
| `subtotal`, `gst { rate, amount }` | the bill before / the GST in it (`total` includes GST) |
| `late_fee`, `credited`, `debited`, `paid` | late fee added today, credit notes taken off, debit notes added, already paid. `owed = total + debited − credited + late_fee − paid` |
| `lines[]` `{ child, description, amount }` | the header lines ("Ethan Tan", "0 to 3 km · 2-way") |
| `billed_to { family, contact, email }` | "Billed to **Tan Family · Rachel Tan**"; `email` is where the receipt goes |
| `request_id` | the bus request this bill belongs to (registration fee, first invoice), else `null` |
| `methods[]` | only while there is something to pay: the school's ways to pay, see below |
| `pay_to` | where to pay (below); `null` once paid |
| `payment` | once paid: `{ paid_on, method, amount, admin_fee, receipt_number, receipt_to }` → "Paid `paid_on` by `method`" and "Receipt sent to `receipt_to`" |

`methods[]` come from the school's OS **Payment & Refund Policy › Payment Methods** (only the ones switched on; Bank
Transfer and PayNow when the school saved nothing):

```json
{ "key": "card", "label": "Card", "icon": "credit_card", "fee_kind": "pct", "fee": "3.0", "fee_text": "+3% admin fee",
  "admin_fee": "1.64", "total": "56.14" }
```

`fee_kind` `none` / `fixed` (S$) / `pct` (a percentage); `fee_text` is the pill under the method ("No fee", "+S$0.50 admin
fee", "+3% admin fee"); `admin_fee` is the fee on **this** invoice's `owed` and `total = owed + admin_fee` is what the card
button shows ("Total with admin fee", "Pay by Card"). The invoice itself stays at `owed`; the fee is the method's surcharge,
kept beside the payment.

`pay_to` = `{ own, bank, bank_code, account_name, account_number, paynow, reference, amount }`: the school's own account when
it has one (`own: true`), else the company's (Finance Settings). **Bank Transfer** card: Bank, Account Name, Account Number,
Bank Code, `reference` (the invoice number), `amount`. **PayNow**: `account_name`, `paynow` (UEN) and the `reference` for the
QR (**the API does not generate the QR image or SGQR string**: draw it from `paynow`, `amount`, `reference`).

## 4. Pay: `POST /app/fees/invoices/:id/pay`

```json
{ "method": "paynow" }
```

`method` is one of the `methods[].key` of the invoice (`bank`, `paynow`, `card`). The card number, expiry and CVC are **not
sent** (nothing is charged). Pays everything `owed` in one payment: no partial payments. Answers `200` with the invoice
(§ 3) now paid (`status.label: "Paid"`, `payment` filled, `methods: []`). Show the "Paid" state.

What happens in Convoy OS: a payment `source: "app"` (reference `SIM-…`, the admin fee beside it) with a receipt on the bill.
A **registration fee** bill paid in full marks its requests' fee paid (the badge moves from Fee Unpaid to Requested). A
**first invoice** paid makes the request **Active** and puts the child on the route plans from the start date, exactly as OS's
Record First Invoice Paid. Refresh the School Bus page after paying a bill.

`422`: `{ code: "already_paid" }` (someone paid it a moment ago: reload), `{ code: "not_payable" }` (a first invoice whose
request is not Accepted any more), or "Pick how to pay" (unknown / switched-off method). Two taps cannot pay twice.

## 5. CCA Bus week: `GET /app/cca`

Query: `school_id` (optional: the first school), `tab` = `next` (default) or `this`. Shown only when a school charges the CCA
bus **per ride** (OS CCA Rides on, price above 0) and the Family has a child riding there; otherwise `{ "data": { "schools": [] } }`
(hide the card). `404` for a `school_id` the Family has no riding child at.

```json
{ "data": {
  "schools": [ { "id": 1, "name": "St. Stephen's School", "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" } } ],
  "school": { "id": 1, "name": "St. Stephen's School" }, "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" },
  "price": "8.0", "days": [2, 4], "days_text": "Tue and Thu", "seats": 40,
  "rule": "Tue and Thu. Book next week by Saturday 23:59 and pay to confirm. After that, a ride can be added if the bus has a seat.",
  "credit": { "amount": "8.0", "text": "S$8.00 credit", "sub": "From rides the bus did not run. Used first when you pay." },
  "tab": "next", "week_of": "2026-11-23", "week_text": "Week of Mon 23 Nov",
  "deadline": { "open": true, "closes_at": "2026-11-21T23:59:59.000+08:00", "urgent": false, "text": "Book and pay by Sat 21 Nov, 23:59 · closes in 5 days" },
  "kids": [ { "dependant_id": 1, "school_rider_id": 67, "name": "Ethan Tan", "class": "P4",
    "same_days": { "shown": true, "on": true, "days": [2, 4], "text": "Tue and Thu are picked for Ethan each week. Still pay by Saturday 23:59 to confirm" },
    "days": [ { "date": "2026-11-24", "label": "Tue 24 Nov", "phase": "open", "seats_left": 40, "can_pick": true, "picked_by_same_days": true,
                "tag": null, "tone": "neutral", "sub": "S$8.00 · picked by Same Days Every Week", "booking": null,
                "can_not_riding": false, "not_riding_label": null } ] } ],
  "methods": [ { "key": "paynow", "label": "PayNow", "icon": "qr_code_2", "fee_kind": "none", "fee": "0.0", "fee_text": "No fee" } ],
  "can_pay": true,
  "note": "Paid rides cannot be removed. Not Riding tells the bus not to wait, and the ride is still charged. A ride the bus does not run becomes credit."
} }
```

- **School pills** when `schools.length > 1` (pass `school_id`). The teal card: `price` "a ride" and `rule`. `credit` (when
  not null) is the green "S$8.00 credit" card.
- **Tabs** Next Week / This Week (`tab`). `week_text` and `deadline.text` are the lines under them; `deadline.open` is true
  only on Next Week before the cut-off, and `urgent` is true the day before and the day of (orange). The cut-off is
  **Saturday 23:59 in the company's time** (`closes_at`); from Sunday 00:00 the week is "late": a ride can still be added
  while the bus has a seat, and is paid at once. Never decide the cut-off from the phone's clock: use `phase`.
- **Each child**: `same_days` (the switch under the name, only `shown` on Next Week) and `days`: the school's CCA bus days of
  the week. A day's fields:
  - `can_pick`: **Add Ride** / **Riding** pill (the FE keeps what is picked locally). `picked_by_same_days`: start it as
    Riding (the child's Same Days Every Week) and show `sub` as is.
  - `tag` + `tone` + `sub`: the badge and the grey line when the day is not pickable: **Not Running** (warning: the bus did
    not run, "<why> · S$8.00 credit" when booked), **No School** (holiday, "No Service" day, outside CCA periods), **Booked**
    (success, "Paid 13 Jan 2027 · PayNow", " · added after the cut-off"), **Not Riding** (neutral, "Charged · the bus will
    not wait"), **Rode** / **Did Not Ride** (the day is past), **Closed** (today), **Not Booked** (past), **Full** (danger,
    seats gone). A pickable day has `tag: null`; after the cut-off its `sub` is "After the cut-off · 2 seats left · paid at once".
  - `booking { id, paid_on, method, late, not_riding, price, bill_id }` when booked. `can_not_riding` shows the ghost button
    labelled `not_riding_label` ("Not Riding" / "Riding After All"). `phase`: `past`, `today`, `late`, `open`. `seats_left`
    counts riders who did not say Not Riding.
- `methods`: the school's ways to pay **without Bank Transfer** (too slow to confirm a seat); PayNow with no fee when the
  school has none left. `note` is the grey footnote.

## 6. Quote and Pay to confirm

Both take the same body; the picks are the days the parent turned on (`dependant_id` of the child, `date`):

```json
{ "school_id": 1, "method": "card", "picks": [ { "dependant_id": 1, "date": "2026-11-24" }, { "dependant_id": 2, "date": "2026-11-24" } ] }
```

**`POST /app/cca/quote`** (any adult; writes nothing; call it when the picks or the method change) → the pay bar:

```json
{ "data": { "school_id": 1, "rides": 3, "price": "8.0", "gross": "24.0", "credit": "8.0", "subtotal": "16.0", "late": false,
  "method": "card", "admin_fee": "0.32", "total": "16.32", "book_with_credit": false,
  "rows": [ { "k": "3 rides × S$8.00", "v": "24.0" }, { "k": "Credit", "v": "-8.0" }, { "k": "Card admin fee", "v": "0.32" } ],
  "methods": [ { "key": "paynow", "label": "PayNow", "fee_text": "No fee", "admin_fee": "0.0", "total": "16.0" } ] } }
```

`rows` are the summary lines, `total` the "Total" and the button amount ("Pay S$16.32"). **Credit comes first**: it pays the
rides, the admin fee is charged on what is left. `book_with_credit` (nothing left to pay): the button reads **Book with
Credit** and no method is needed (`method: null`). The same checks as paying run here, so a wrong pick answers `422` with the
message to show (below).

**`POST /app/cca/payments`** (Billing Contact) → `201`:

```json
{ "data": { "rides": 3, "paid": "16.32", "admin_fee": "0.32", "method": "Card",
  "invoice": { "id": 31, "number": "INV-2026-000031", "period": "CCA Bus · Week of Mon 23 Nov", "total": "16.0" },
  "week": { "...": "the Next Week page of GET /app/cca" } } }
```

`method: "Credit"` and `paid: "0.0"` when credit covered it. Toast: "Paid S$16.32. 3 rides booked. Receipt INV-2026-000031 in Fees"
(or "Paid with credit. …"). Use `week` to redraw. One CCA bill is created per payment (lines per child, a Credit line), booked
and paid at once, listed in Fees.

Rules checked (`422` messages the HTML shows): not charged per ride at this school; pick at least one day; the CCA bus does
not run on <weekday>s; <day> can no longer be booked (today or past); only next week can be booked; the CCA bus is not running
on <day> (Bus Not Running); there is no CCA bus on <day> (no school); <child> is already booked on <day>; the CCA bus on <day>
is full (after the cut-off only). Paying checks again under a lock, so two parents cannot take the last seat together.

## 7. Not Riding and Same Days Every Week

**`PATCH /app/cca/bookings/:id/not_riding`** `{ "not_riding": true }` (any adult) → `{ "data": { "id", "date", "not_riding" } }`.
Tells the bus not to wait and frees the seat (the ride is still charged). `false` = **Riding After All** (needs a seat).
Reload the week, or flip the day locally (`tag` "Not Riding", `sub` "Charged · the bus will not wait"). `422`: "A ride that has
gone cannot be changed"; "The CCA bus is not running on <day>"; "The CCA bus on <day> is full, so the seat cannot be taken
back". Another Family's booking is `404`.

**`PUT /app/cca/same_days`** `{ "school_id": 1, "dependant_id": 1, "days": [2, 4] }` (any adult) → `{ "data": { "dependant_id",
"on", "days", "text" } }`. `days: []` turns it off. Weekdays are 1 Mon … 5 Fri and must be among the school's CCA bus days
(`422` "The CCA bus runs on Tue and Thu"). It only **pre-picks** next week (`picked_by_same_days`); the parent still pays by
Saturday 23:59. When the switch is turned on, the FE sends the days currently picked or booked on Next Week, or all the
school's `days` when none is.

## 8. Home card and badges

`GET /app/school` → `cca` is `null` or `{ "title": "CCA Bus · Next Week", "booked": true, "school_id": 1, "sub": "Booked: Ethan Tue, Ethan Thu" }`
(or `sub` "Book and pay by Sat 21 Nov, 23:59 · S$8.00 a ride" when nothing is booked; green when `booked`, orange when not;
tap opens CCA Bus on `school_id`). The Pay Registration Fee / View First Invoice / **Pay S$x** buttons of
[school.md](school.md) open the Invoice with the `bill_id` they carry (Billing Contact only).

Delete Family (`DELETE /app/household`) is also refused while a bill of the Family is unpaid (`unpaid_bill` in `details.reasons`).

## 9. Errors

`403 billing_only` · `404` not the Family's own bill / booking / school · `422 { code: "invalid" }` with the message of the
rule (above), `already_paid`, `not_payable`. Everything else: [README.md § Conventions](README.md#conventions).
