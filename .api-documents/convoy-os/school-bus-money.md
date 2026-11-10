# School Bus › Fares, Policy, Payment Methods, Operator Pay — API Guide

This guide covers the money steps of School Bus Year Setup:

- Bus Fares, with its Extra Charges;
- Payment & Refund Policy;
- Payment Methods;
- Operator Pay, including the Break Month Calculator and the bus attendant prices.

Schools, academic years and the other setup steps are in [school-bus-setup.md](school-bus-setup.md). Conventions are in
[README.md](../README.md); paths start with `/api/v1`.

**Permissions**

| What | Who |
| --- | --- |
| Bus Fares, Policy, Payment Methods (read) | Every user who opens the school |
| Operator Pay (read) | `finance` or `finview` |
| Every change and unlock on these pages | `finance` |

A Convoy Admin can read but change nothing.

**Locks.** Bus Fares and Operator Pay use the same Save & Lock pattern as the other steps:

- Save checks the whole step and locks it.
- To change it again, unlock it first:
  - Bus Fares: `POST /academic_years/:id/unlock { section: "fares" }`
  - Operator Pay: `POST /schools/:id/unlock { section: "operator_pay" }`
- The Policy is not locked. Each change is published as a new version.

## Contents

1. [Bus Fares](#1-bus-fares)
2. [The fare table (worked out)](#2-the-fare-table-worked-out)
3. [Extra Charges](#3-extra-charges)
4. [Payment & Refund Policy](#4-payment--refund-policy)
5. [Payment Methods](#5-payment-methods)
6. [Operator Pay](#6-operator-pay)
7. [Front-end only and not built yet](#7-front-end-only-and-not-built-yet)

---

## 1. Bus Fares

There is one fare table per academic year. It needs that year's **Terms & Semesters locked** first.

| Call | What it does |
| --- | --- |
| `GET /academic_years/:id/fares` | The table, its billing periods, the worked-out fares and the bus types |
| `PATCH /academic_years/:id/fares` | Save & Lock the whole table, as the wizard's Review step sends it (JSON) |
| `POST /academic_years/:id/fares/preview` | A draft table worked out before saving: its bills, fares and the first failing check. Nothing is saved. |
| `GET /academic_years/:id/fares/copy?from_id=` | "Copy AY X Fares": another year's table as a draft, without ids. Nothing is saved. |

`GET` returns:

```json
{ "table": { …the table, same shape as the PATCH body below; tiers and surcharges also carry their "id"… } | null,
  "locked": { "at": "…", "by": "…" } | null, "calendar_locked": true,
  "periods": [ { "label": "Term 1", "short": "Term 1", "starts_on": "2026-01-02", "ends_on": "2026-03-13", "school_days": 50, "cca_days": 50 } ],
  "fares": [ …see §2… ],
  "bus_types": [ { "key": "SMALL_13", "label": "13-seater", "seats": 13, "student_seats": 12 } ],
  "plan_runs": { "LARGE_40": 3, "SMALL_13": 2 } }
```

- `bus_types[].student_seats` = `seats` less 1 when the school's Bus Attendants setting needs an attendant on that
  size (the attendant takes a seat). Bus Rates shows "45 seats, 44 for students" and the price per student seat.
- `plan_runs` counts the routes per bus type in the AM and PM route plans in use today (an AM and a PM run count as 2).
  Bus Rates "From Route Plans" shows "3 runs in the route plans" or "Not in the route plans". Routes without a bus
  type are left out.

The PATCH body is the whole table. Send only the parts that apply:

```json
{ "payer": "parents" | "school" | "bus",
  "bill_to": { "name": "SSS Finance", "contact": "…", "email": "fin@sss.edu.sg" },
  "basis": "distance" | "zone",
  "trip": "both" | "one" | "ampm",
  "cycle": "period" | "month", "months": [1, 2, 3],
  "distribution": "equal" | "prorated" | "bill" | "billpro" | "custom",
  "one_way": { "type": "pct" | "flat" | "custom", "value": 60 },
  "by_size": false, "size_columns": [ { "max_seats": 15 }, { "max_seats": null } ],
  "tiers": [ { "id": 31, "max_km": 3, "name": null, "sectors": ["45", "46"],
               "areas": [ { "latlngs": [[1.35, 103.94], [1.36, 103.95], [1.34, 103.96]], "exclude": false } ],
               "fare": 1680, "pm_fare": null, "one_way_fare": null, "period_fares": [], "period_pm_fares": [],
               "small_fare": null, "express_fare": null, "cca_fare": null,
               "sizes": [ { "fare": 1800, "pm_fare": null, "one_way_fare": null, "period_fares": [], "period_pm_fares": [] } ] } ],
  "surcharges": [ { "id": 7, "name": "Sentosa", "sectors": ["09"], "areas": [], "kind": "flat" | "pct" | "fixed", "amount": 200,
                    "one_way_kind": "same" | "pct" | "fixed", "one_way_value": null } ],
  "small": { "on": true, "type": "pct" | "flat" | "custom", "value": 10, "seats": 15 },
  "express": { "on": false, "type": "pct", "value": null },
  "cca": { "on": true, "per": "trip" | "period", "price": "fixed" | "tier", "fixed": 8, "split": "equal" | "days", "with_services": false,
           "riders": { "non": { "on": false, "type": "pct" | "flat" | "fixed", "amount": null }, "am": {…}, "pm": {…} } },
  "bus_count": "plan" | "booked",
  "bus_rates": [ { "bus_type": "SMALL_13", "rate": 1500, "booked_runs": null } ] }
```

**Who pays (`payer`)**

| `payer` | Meaning | Extra fields |
| --- | --- | --- |
| `parents` | Each family is billed | — |
| `school` | The school pays per rider | `bill_to` (name and email) |
| `bus` | The school pays per bus | `bill_to`, plus `bus_rates` (a rate per bill for each bus size) and `bus_count` (by the plan, or `booked` runs) |

The wizard's steps for `bus` are Who Pays, Billing, Bus Rates and Review.

**How the fares are set (`payer: parents` or `school`)**

| Field | Values |
| --- | --- |
| `basis` | `distance`: `tiers` by `max_km`, in increasing order; the last tier is open-ended. `zone`: each tier has a `name`, postal `sectors` (first 2 digits) and/or drawn `areas`; the first matching zone applies. |
| `trip` | `both`: one 2-way fare plus a 1-way rule. `one`: 1-way only. `ampm`: AM and PM fares, where 2-way = AM + PM. |
| `cycle` | `period`: one bill per term or semester. `month`: one bill per month listed in `months`, where 1 = January. |
| `distribution` | How the annual fare is spread over the bills (table below) |
| `one_way.type` | `pct`: % of the 2-way fare. `flat`: amount off the 2-way fare. `custom`: each tier's `one_way_fare`. |
| `by_size` | Adds price columns by bus size (`size_columns`). The first column uses the tier's own fares; each tier's `sizes[k]` holds the prices for column k + 2. |
| `small`, `express` | `pct` / `flat` extra on the standard fare, or `custom`, which uses each tier's `small_fare` / `express_fare` |
| `cca` | Optional CCA / ASA fares; see the wizard |

`distribution` values:

| `distribution` | Bill amounts |
| --- | --- |
| `equal` | The annual fare split evenly over the bills |
| `prorated` | The annual fare split by each bill's school days |
| `bill` | `fare` is the amount of every bill |
| `billpro` | `fare` per bill, scaled by the bill's school days against the average |
| `custom` | Each bill is typed in: `period_fares`, plus `period_pm_fares` when `trip` is `ampm` |

`sectors` may be sent as an array or as text such as `"45, 46"`.

**Drawn areas (`areas`).** Zones and location surcharges can have several outlines drawn on the map, like a stop's
catchment: `areas: [{ latlngs: [[lat, lng], …], exclude }]`. A home counts when it is inside an outline with
`exclude: false` and inside no outline with `exclude: true` (a cut-out). An area needs at least 3 corners ("Zone 1: area 1
needs at least 3 corners"); cut-outs alone do not count as a drawn area. The old single `area` field is gone: sending it
is a 422 "area is replaced by areas: [{ latlngs, exclude }]".

**Ids (`id`).** Send back each tier's and surcharge's `id` from `GET`. Save & Lock keeps those rows (and their ids) and
updates them; rows without an id (or with an id of another table) are added; rows left out are removed. Extra Charges
point at tier ids, so they keep working after unlock + save. A tier an Extra Charge targets cannot be removed: 422
"Tier 2 is used by the Extra Charge "Toll". Keep it, or remove it from that charge first" (zones use their name).
"Copy AY X Fares" returns the other year's table without ids, so saving it adds new rows.

**Checks (422).** The error messages are the wizard's, step by step. `error.details` names the wizard step to go back to:
`{ "step": 2, "step_name": "Fares" }`. `step` is the prototype's step index: 0 Who Pays, 1 Billing, 2 Fares (Bus Rates when
the school pays per bus), 3 Services, 4 CCA / ASA. Errors raised before the checks ("Before saving" below, areas,
removed tiers) have no `details`. Examples:

| Step | Example message |
| --- | --- |
| Who Pays | "Enter who the school bill goes to", "Enter a billing email for the school" |
| Billing | "Pick at least one billing month", "Enter the 1-way fare percentage", "The 1-way percentage cannot be more than 100" |
| Fares | "Tier 2 must end further out than tier 1", "Above 3 km: enter the 2-way fare", "Zone 1 needs a name" |
| Bus sizes | "Size column 2 must have a higher seat limit than the one before" |
| Surcharges | "Sentosa: enter the surcharge amount" |
| Services | "Small Bus: enter the extra percentage" |
| CCA / ASA | "CCA / ASA: enter the fare" |
| Bus Rates | "13-seater: enter a rate above 0", "Enter how many runs the school booked" |
| Before saving | "Save and lock the Terms & Semesters first", "Bus Fares is locked. Unlock to edit" |

**Preview of a draft (`POST /academic_years/:id/fares/preview`).** Send the wizard's draft (same body as `PATCH`, any
step, incomplete is fine). The answer works the table out without saving it:

```json
{ "periods": [ { "label": "Semester 1", "school_days": 105, "cca_days": 105, … } ],
  "fares": [ …as in §2… ],
  "problem": { "message": "Above 3 km: enter the 2-way fare", "step": 2, "step_name": "Fares" } | null }
```

`periods` counts school days from the calendar now (not the frozen numbers). Missing fares count as 0. `problem` is the
first check Save & Lock would fail, or `null`. Needs the finance permission.

**Frozen school days.** When the table is locked, each bill's school days and CCA days are frozen, so holidays added later
do not change the bills. `periods` shows the frozen numbers while the table is locked. When it is unlocked, they are
counted again from the calendar.

## 2. The fare table (worked out)

`fares` in `GET /academic_years/:id/fares` is worked out on the server with the prototype's formula (`logic/fares.js`).
Amounts are strings with 2 decimals; so are the fares in `table` (tier and size `fare`, `pm_fare`, `one_way_fare`,
`period_fares`, `small_fare`, `express_fare`, `cca_fare`, `cca.fixed`, bus `rate`).

```json
[ { "tier_id": 31, "position": 1, "label": "0 to 3 km",
    "std": { "two": { "annual": "1680.00", "periods": ["420.00", "420.00", "420.00", "420.00"] },
             "one": { "annual": "1008.00", "periods": ["252.00", "252.00", "252.00", "252.00"] } },
    "small": { "two": {…}, "one": {…} } | null,
    "express": null,
    "sizes": [ { "column": "Above 15 Seats", "fares": { "two": {…}, "one": {…} } } ] } ]
```

| `trip` | Keys in `std` |
| --- | --- |
| `both` | `two`, `one` |
| `one` | `one` |
| `ampm` | `two` (AM + PM), `am`, `pm` |

- Amounts are spread over the bills to the cent; the last bill takes the rounding.
- With a per-bill distribution, `annual` is the sum of the bills.
- Distance labels read "0 to 3 km", "3 to 6 km" and "Above 10 km" (or "Any distance" for a single tier). Zones use their
  name.
- When the school pays per bus, each row is a bus size: `{ "bus_type": "SMALL_13", "label": "13-seater",
  "booked_runs": null, "std": { "two": { "annual", "periods" } } }`. The rate applies to every bill.
- Surcharges, CCA and rider conditions are shown from `table` as entered.
- CSV export is done by the FE.

## 3. Extra Charges

Extra Charges are added on top of a **locked** fare table, such as a fuel surcharge. Adding one does not unlock the table.

| Call | What it does |
| --- | --- |
| `GET /academic_years/:id/extra_charges` | This year's charges, then the ones carried over from earlier years |
| `POST /academic_years/:id/extra_charges` | Add a charge |
| `PATCH /academic_years/:id/extra_charges/:charge_id` | Edit (Scheduled only) |
| `DELETE /academic_years/:id/extra_charges/:charge_id` | Delete (Scheduled only) |
| `POST /academic_years/:id/extra_charges/:charge_id/end { to_month }` | Set End (Active and not one-off): the last month charged |
| `POST /academic_years/:id/extra_charges/preview` | The next 4 bills before and after the draft charge |

The add and edit body is `{ name, kind: pct|amt|once, value, from_month: "2027-01", to_month, tier_ids: [], bus_types: [], note }`.

```json
{ "id": 4, "name": "Fuel Surcharge", "kind": "pct", "value": "5.00", "from_month": "2026-12", "to_month": null,
  "tier_ids": [], "bus_types": [], "note": "…", "state": "scheduled", "created_by": "Ops Admin", "created_at": "…",
  "carried_from": null, "can_edit": true, "can_delete": true, "can_end": false }
```

**How a charge works**

| `kind` | Effect |
| --- | --- |
| `pct` | Adds a % of the fare to every bill |
| `amt` | Adds an amount to every bill |
| `once` | Adds an amount to the one bill raised in `from_month` |

- Every bill is raised in the month of its term start, or in its chosen month.
- `to_month: null` means no end. Such a charge carries into later academic years, where it shows with `carried_from` set
  to the year it came from. It is read only there.
- `tier_ids` lists the tiers / zones it applies to (ids from `table.tiers[].id`); when the school pays per bus,
  `bus_types` lists the bus sizes instead (sizes with a rate). Both empty = all riders. `targets` is gone: sending it is
  a 422 "targets is replaced by tier_ids and bus_types".
- The checks follow the form, in this order: "Give the charge a name", "Enter an amount above 0", "Percentage must be 100
  or less", "Pick the start month", "Bills before this month are already raised. Pick this month or later", "No bill is
  raised in that month" (one-off charge), "End month must be on or after the start month". Then the targets: "Pick
  tiers of this year's Bus Fares" (or zones), "Pick bus sizes only when the school pays per bus", "The school pays per
  bus. Pick bus sizes, not tiers", "Pick bus sizes the fares have a rate for".

**States and messages**

| Field | Meaning |
| --- | --- |
| `state` | `scheduled` (not started), `active`, or `ended` |
| `meta.warning` (on save, not one-off) | "No AY 2027 bills fall between February 2027 and May 2027", or with no end "No AY 2027 bills fall from February 2027 to the end of the year. It starts on AY bills of later years" |

The preview body is the draft charge. Add `id` when editing, so the old version of that charge is left out. It shows the
first picked tier / bus size (or the first of the table). The response:

```json
{ "data": [ { "bill": "Term 1", "before": "420.00", "after": "441.00", "change": "21.00" } ],
  "meta": { "example": "0 to 3 km, 2-way rider" } }
```

`meta.example` is the line above the table ("Example: 0 to 3 km, 2-way rider").

## 4. Payment & Refund Policy

The policy is set per school and published as versions. Each version applies from its `effective_on` date.

| Call | What it does |
| --- | --- |
| `GET /schools/:id/policy` | The versions, the current and scheduled versions, a draft for "New Version", and this year's collection cycle |
| `POST /schools/:id/policy` | Publish (JSON) |

```json
{ "versions": [ { "version": 2, "effective_on": "2027-02-01", "state": "scheduled", "published_by": "…", "published_at": "…" },
                { "version": 1, "effective_on": "2026-11-02", "state": "in_use", … } ],
  "current": { …fields…, "version": 1, "effective_on": "2026-11-02" },
  "scheduled": { … } | null,
  "draft": { …fields…, "reminders": [...], "effective_on": "2027-02-01" },
  "collection": { "year": "2026", "cycle": "period", "months": [...], "payer": "parents", "bill_to_name": null, "bill_to_email": null } }
```

- `state` is `scheduled`, `in_use` or `replaced`.
- `draft` starts from the scheduled version if there is one, otherwise the current one, otherwise the Convoy defaults.
- "Collection cycle" and the school-pays banner ("Due dates, late fees and reminders apply to the school bill…") come from
  `collection`. They come from the year running today, else the next one to start, else the latest year; `collection` is `null` only
  when the school has no year (or that year has no fares yet).

**Fields (publish body)**

| Group | Fields |
| --- | --- |
| Due | `due_rule`: `before` (`due_days_before`), `day` (`due_day`, 1–28) or `first` (first school day) |
| Late payment | `late_type`: `none`, `flat` (`late_flat`) or `pct` (`late_pct` per month, optional `late_cap`). Also `late_grace_days` and `late_flag_days` (flag the account for an Admin; service is never stopped automatically) |
| Reminders | `reminders: [{ timing: before\|on\|after, days, email, whatsapp, app, email_subject, email_body, whatsapp_body, app_title, app_body }]`. Tokens: `[Parent Name]`, `[Child Name]`, `[Amount]`, `[Due Date]`, `[Period]`, `[School]`, `[Pay Link]`, `[Late Charge]` |
| Withdrawal | `withdrawal_notice` + `withdrawal_unit` (`days`, `weeks`, `months`); `refund_basis` (`days`, `months`, `term`); `refund_method` (`credit`, `bank`, `parent`); `refund_within_days`; `withdrawal_fee` |
| Change of address | `address_notice_days`; `address_start` (`any`, `mon`, `first`); `address_max_days` (at least the notice) |
| Deposit and fees | `deposit_amount`; `deposit_return` (`offset`, `separate`); `registration_fee` |
| Acknowledgement | `ack_required`, `ack_reaccept`, `ack_text` |

Publishing rules:

- `effective_on` must be today or later.
- Publishing **replaces a version that has not started yet**; that version keeps its number. Otherwise the new version
  gets the next number.

| Error (422) | Cause |
| --- | --- |
| "The effective date cannot be in the past" | `effective_on` before today |
| "Pick a due day from 1 to 28" | `due_day` out of range |
| "Enter the late fee" | `flat` late type without `late_flat` |
| "Keep at least one reminder" | No reminders |
| "3 days after due: pick a channel and fill in each message" | A reminder has no channel or an empty message |
| "Enter the acknowledgement text" | `ack_required` without `ack_text` |

Reminders are set up here only; they are not sent yet.

## 5. Payment Methods

This sets how parents pay a school's bills in the Convoy App.

| Call | What it does |
| --- | --- |
| `GET /schools/:id/payment_methods` | The current methods and accounts |
| `PATCH /schools/:id/payment_methods { bank: { on, fee_kind, fee }, paynow: {…}, card: {…}, own_account, bank_id, account_number, account_name, paynow_id }` | Save |

```json
{ "saved": true, "bank": { "label": "Bank Transfer", "on": true, "fee_kind": "none", "fee": null },
  "paynow": { "label": "PayNow", "on": true, … }, "card": { "label": "Card", "on": true, "fee_kind": "pct", "fee": "3.0" },
  "own_account": false, "account_bank": null, "account_number": null, "account_name": null, "paynow_id": null,
  "updated_by": "…", "updated_at": "…",
  "company_account": { "bank": { "id": 2, "name": "DBS Bank", "code": "7171" }, "account_number": "…", "account_name": "…", "paynow": "…" } }
```

- Not saved yet means Bank Transfer and PayNow with no fee, paid into the company account. Show "Not saved yet. Parents
  see Bank Transfer and PayNow with no fee".
- `fee_kind` is `none`, `fixed` (S$) or `pct` (up to 10).
- `own_account: true` pays into the school's own account, using `bank_id` (from `GET /banks`), `account_number`,
  `account_name` and `paynow_id`. Otherwise the company's Finance Settings › Payment Details are used (`company_account`).

| Error (422) | Cause |
| --- | --- |
| "Turn on at least one way to pay" | Every method is off |
| "Enter the admin fee for Card" | A fee kind is set without a fee |
| "The admin fee for Card looks too high: use a percentage up to 10" | `pct` fee above 10 |
| "Bank Transfer needs the company's bank account: add it in Finance Settings, Payment Details, or use this school's own account" | Bank Transfer is on with no account |
| "PayNow needs the company's PayNow UEN…" | PayNow is on with no PayNow ID |

## 6. Operator Pay

This is set per school, and only finance users see it.

| Call | What it does |
| --- | --- |
| `GET /schools/:id/operator_pay` | Settings and prices per bus size |
| `PATCH /schools/:id/operator_pay` | Save & Lock |
| `POST /schools/:id/operator_pay/calculator { academic_year_id, start_date, price }` | Break Month Calculator |

```json
{ "saved": true, "locked": { "at": "…", "by": "…" },
  "scheme": "some", "paid_months": [1,2,3,4,5,7,8,9,10,11], "part_pct": "50.0", "part_basis": "school",
  "break_months": [6, 12], "break_pay": "earned", "earn_by": "terms", "grace_start_days": 0, "deduct_days": 0,
  "rates": [ { "bus_type": "MEDIUM_23", "label": "23-seater", "seats": 23, "student_seats": 23, "ba_required": false,
               "fixed_on": true, "monthly": "3600.0", "rider_on": true, "base_price": "3000.0", "riders_included": 15, "per_rider": "60.0",
               "default_mode": "fixed", "ba_operator": null, "ba_us": null } ] }
```

The PATCH body has the same fields: `rates: [{ bus_type, fixed_on, monthly, rider_on, base_price, riders_included,
per_rider, default_mode, ba_operator, ba_us }]`.

**Settings**

| Field | Meaning |
| --- | --- |
| `scheme` | `all`: 12 months, full pay. `some`: the `paid_months` only. `part`: `paid_months` in full and the other months at `part_pct` % |
| `part_basis` | Part months count `school` days or `cal` (calendar) days |
| `break_months` | Months paid as a retainer |
| `break_pay` | `full`, or `earned` |
| `earn_by` (when earned) | `terms`: each term the route ran in counts equally; within one term, its halves count. `days`: school days run out of the term's school days, with `grace_start_days` (a start within this many days counts from day 1) and `deduct_days` |
| Prices per size | Fixed Monthly (`fixed_on`, `monthly`) and/or Fixed + Per Rider (`rider_on`, `base_price`, `riders_included`, `per_rider`). Keep at least one; `default_mode` chooses between them when both are on. The bus attendant add-ons are `ba_operator` ("their BA") and `ba_us` ("our BA"); `ba_required` follows the Bus Attendants step; `student_seats` is `seats` less the attendant's seat when `ba_required` |

The Bus Attendants page (`GET /schools/:id/bus_attendants`) shows `ba_operator` / `ba_us` for each bus type.

| Error (422) | Cause |
| --- | --- |
| "Pick at least one paid month" | `some` or `part` with no `paid_months` |
| "Enter a percentage from 0 to 100" | `part_pct` out of range |
| "13-seater: enter the base price, riders included and extra per rider" | Per Rider is partly filled |

**Break Month Calculator.** For each break month of the chosen year, it shows what a route starting on `start_date` at
`price` a month is paid. It uses the settings as they are saved. Part pay is multiplied by the retainer earned in the term
or terms before (terms less than 21 days apart count together).

```json
[ { "month": "2027-06", "label": "Jun 2027", "rate": "0.5", "earned": "0.5", "pct": 25, "amount": "500.0",
    "note": "Ran in 1 of 2 halves of the term, at 50% part pay" } ]
```

- `rate` and `earned` are always decimal strings (an unpaid month is `"0.0"`, not the number `0`); `amount` is `null` when no `price` is sent.
- `note` follows the prototype: "Not a paid month under the Pay Scheme" (rate 0), "Route not started yet" (the route starts after the
  month; both rows have `pct: 0` and `amount: "0.0"`), "Full pay for any route on contract", "No earlier term in the calendar, so paid in full",
  "Ran N of M school days" (+ ", less D days" when days are deducted), "Started on school day N, inside the G-day grace period",
  "Ran in N of 2 halves of the term", "Ran in N of M terms", each with ", at P% part pay" when the rate is below 100%.

## 7. Front-end only and not built yet

FE only:

- The wizard screens.
- Drawing zones and surcharge areas on the map.
- Previews of reminder messages.
- CSV export.
- How It Works.

Route Charges (an extra per AM / PM run when the school pays per bus) are built: [school-bus-routes § 6](school-bus-routes.md#6-route-bus-and-money).

Not built yet:

- Sending reminders.
- Payments in the app (PayNow QR, card) and passing on the card fee.
- (Applying the policy to bills, e.g. late fees and terms, is built in School Finance: [school-bus-finance.md](school-bus-finance.md).)
