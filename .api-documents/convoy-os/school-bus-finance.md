# School Bus › School Finance — API Guide

This guide covers School Finance for one school in Convoy OS: **Collections** (with the Family Bills card),
**Documents**, and **Operator Payments** (the school's operator pay runs). It also covers what School Bus adds to the
company Finance pages. Conventions are in [README.md](../README.md). Paths start with `/api/v1`.

**Permissions**

| What | Who |
| --- | --- |
| Read Collections, Documents, Operator Payments | `finance` or `finview`; only the schools the user may open |
| Draft, issue, record payments, credit or debit notes, waive late fees, void receipts, change pay runs | `finance` |
| Prepare a pay run (add lines, send to Finance, recall) | `finance` and a preparer or approver in Finance Settings. When nobody is set up there, anyone with `finance` may prepare |
| Approve, send back or reopen a pay run | `finance` and an approver in Finance Settings. With maker-checker on, the approver cannot be the person who sent it |

A Convoy Admin can read but change nothing.

**Money.** Amounts are decimal strings such as `"1464.96"`. GST follows Finance Settings: on top of the amount or
included in it. Document numbers come from Finance Settings and are shared across the company, for example
`INV-2026-000001`, `CN-…`, `DN-…`, `RCP-…`, `PV-…`. Printing is done by the front end. Each document's data comes from
the calls below, and the company header and footer from `GET /finance/documents/brand`.

## Contents

1. [Family Bills: draft and issue](#1-family-bills-draft-and-issue)
2. [Collections](#2-collections)
3. [One bill: payments, notes, late fees](#3-one-bill-payments-notes-late-fees)
4. [Documents and statements](#4-documents-and-statements)
5. [Operator Payments (pay runs)](#5-operator-payments-pay-runs)
6. [Company Finance pages](#6-company-finance-pages)
7. [Not built yet](#7-not-built-yet)

---

## 1. Family Bills: draft and issue

Convoy drafts **one bill per payer per billing period**:

- **Parents pay:** one bill per family.
- **The school pays per rider or per bus:** one bill to the school.

Billing periods come from the year's locked Bus Fares: one per term or semester, or one per chosen month.

| Call | What it does |
| --- | --- |
| `GET /schools/:school_id/bill_runs?academic_year_id=&period_index=&q=` | The Family Bills card. See below |
| `POST /schools/:school_id/bill_runs` | Draft Now / Draft Again: `{ academic_year_id, period_index }`. Bills already issued stay as they are; every other payer gets a fresh draft. `meta.drafted` = drafts now |
| `POST /schools/:school_id/bill_runs/issue` | Issue: `{ academic_year_id, period_index, bill_ids: [] }`. Leave out `bill_ids` to issue every draft. `meta.issued` = count |
| `PATCH /school_bills/settings` | `{ draft_days, start_rule: prorate \| full \| half }`. These are company-wide and apply to the next drafts. `422`: "Enter the days before the due date", "Pick how a child who starts mid-period is charged" |

When `academic_year_id` is left out, the call uses the year covering today that has locked Bus Fares, or else the
latest year with locked Bus Fares. When `period_index` is left out, it uses the first period billed from next month, or
else from this month, or else the last period.

**The card (`data`):**

- `on`: false (with `error`) until the year's Bus Fares are locked. `GET` answers `200 { on: false, error }` also when **no** year of the school has locked fares (before: `422`); `POST` Draft / Issue still answer `422` then. The messages are "Lock the Bus Fares for a year first" (no year) and "Lock the Bus Fares for this year first" (the year asked for).
- `payer`: `family`, `school` or `bus`.
- `periods`: `[{ index, label, month }]`. The label is `"Semester 1 | billed Jan 2027"`, or `"Jan 2027"` for monthly bills.
- `due_on`: the due date of the period's bills.
- `draft_on`: the day Convoy drafts them, `due_on` less `draft_days`.
- `bill_to`: for school bills, `{ managed_client: { id, name } | null, linked }`. A school bill can only be issued when the
  school is linked to a Managed Client. It then carries that client's name and its first Send Invoices To email.
- `run`: the last draft, or `null` before the first one:
  - `drafted_at`, and `by` (`"Convoy"` when the daily job drafted it, with `auto: true`).
  - `label` and `due_on`.
  - `skipped`: the notes on children left out, such as `"Lim Kai: this month is on the first invoice INV-…"` or
    `"…: service stopped 01/10/2026"`.
  - `unlinked`: riders with no family, so not billed. Ask the user to link them in Families & Riders.
- `counts`: `{ bills, drafts, issued, amount }`.
- `can_issue`, and `settings`: `{ draft_days, start_rule }`.
- `rows`: up to 150, drafts first. Each row has:
  - `id`, `status` (`draft` or `issued`), `number`, `bill_to`, `bill_to_code`, `children`.
  - `amount`: before GST for a draft, the total for an issued bill.
  - `part_charges`: how many lines are part charges.
  - `lines: [{ rid, child_name, description, note, amount }]`.
- `more`: the count of rows not shown.

**How a bill is worked out.**

- **The children billed.** Children on the AM / PM route plans in use when the period starts, plus children who join
  before it ends.
- **Each child's fare.**
  - The tier comes from the straight-line distance from the school: add 0.05 km, then round up to 0.1 km. For zones, the
    tier is the first zone whose postal sectors or drawn area hold the home.
  - 2-way, 1-way, or AM / PM fares follow the sessions the child rides.
  - A small bus or a bus-size column applies for the days the child's bus was that size.
  - The bill month's Extra Charges are added.
- **A child who joins mid-period** is charged by the start rule: prorated by school days, the full period, or half from
  the 16th. The line `note` says how, for example `"Joins 01/03/2027, 58 of 98 school days"`.
- **A child who stops** (a Stop Service request, or the rider's end date) pays up to that day. When the policy's refund
  basis is days, this is prorated by school days.
- **A month on a request's first invoice** is skipped.
- **When the school pays per bus,** the bill has one line per bus size (`"3 x LARGE_45 at S$4200.00"`). A further
  `"Route charges and changes during the period"` line covers Route Charges and plan changes within the month.

**Issuing.** Issuing gives the bill its INV number and GST. It also takes off the payer's credit notes that were waiting
for the next bill, each as a line `"Credit from CN-…"` with `credit_note: true`. Parents see their bills in the Convoy
App, and the school sees its bill in the Client Portal (when those apps come).

**Automatic drafting.** A daily job at 01:00 drafts the coming period of every school year with locked Bus Fares, once
`draft_on` has come. It does not draft a period twice.

## 2. Collections

| Call | What it does |
| --- | --- |
| `GET /schools/:school_id/bills?academic_year_id=&period_index=&status=&q=&page=&limit=` | Issued bills of every kind (period bills, first invoices, CCA), newest first |
| `GET /schools/:school_id/bills/export?…` | CSV of the same list |
| `GET /schools/:school_id/bills/differences?academic_year_id=` | Billing differences |
| `POST /schools/:school_id/bills/pay` | Mark Paid: `{ bill_ids: [], paid_on, method, reference }`. Each ticked bill is paid what it owes today, on one receipt. Returns `{ receipt, bills, amount }` |

**Filters.**

- `period_index` with `academic_year_id` narrows the list to one billing period.
- `status` is `Due`, `Overdue`, `Part Paid`, `Paid` or `Credited`. `Overdue` also brings part-paid bills that are past
  their due date and grace days.
- `q` searches the number, bill to, code and line text.

**Row:**

- Who and what: `id`, `number`, `kind` (`first`, `cca` or `period`), `payer`, `family_id`, `bill_to`, `bill_to_code`,
  `bill_to_email`, `children`, `lines_count`, `period`, `academic_year_id`, `period_index`.
- Dates and amounts: `issued_on`, `due_on`, `total`, `paid`, `owed`.
- Fees and notes: `late_fee`, `late_waived` (a money string, like `late_fee`), `credited` (credit notes taken off the bill and other waivers), `debited`.
- Status: `overdue`, `days_overdue`, `status`, `tone`.

**`meta`:**

- `counts` per status, plus `all`.
- `methods`: PayNow, Bank Transfer, GIRO, Cheque, Cash, Card.
- `kpis` for the bills in the chosen period:
  - `billed` (total plus debit notes) and `bills`.
  - `collected`.
  - `outstanding` and `not_paid`.
  - `overdue` and `overdue_bills`.
  - `credited`: credit notes taken off bills, plus waivers, plus late fees waived.

**Late fees.** Late fees are worked out live, from the Payment & Refund Policy in use today. Once a bill is past its due
date plus the grace days and money is still owed, the fee is one of:

- a flat amount, or
- a percentage of what is owed for every 30 days (at least one).

The fee is capped when the policy has a cap. It is never a document.

**Billing differences.** For every issued period bill, the call compares what it would come to now (today's riders and
fares) with what it billed, adjusted for the debit and credit notes since. A credit note counts here even when it was
refunded or carried to the next bill. Each row has:

- `bill_id`, `number`, `bill_to`, `period`.
- `was`, `now`, and `gap` (positive means more is due now).
- `suggest: { doc_type, description, amount, reason, credit_use }`, ready for the note form.

## 3. One bill: payments, notes, late fees

| Call | What it does |
| --- | --- |
| `GET /school_bills/:id` | The bill (see below) |
| `POST /school_bills/:id/payments` | `{ paid_on, amount, method, reference }`. One receipt; cannot be more than is owed today. `meta.receipt` = its number. `422`: "Pick the date received", "Enter the amount received", "Pick how it was paid" (one of `meta.methods`), "Amount is more than the S$x owed on INV-…" |
| `POST /school_bills/:id/waive_late` | `{ amount, reason }`. Up to the late fee owed |
| `POST /school_bills/:id/notes` | `{ doc_type: cn \| dn, description, amount, reason, credit_use, issued_on, method, reference }`. `meta.number` |

**Credit and debit notes.**

- A credit note's `credit_use` is one of:
  - `reduce`: taken off this bill. It cannot be more than is owed.
  - `refund`: refunded to the payer. Give `method` and `reference`.
  - `carry`: taken off the payer's next bill when it is issued.
- A debit note adds to the bill.
- The amount is entered before or with GST, as Finance Settings say. The note keeps `subtotal`, `gst` and `total`.

**The bill (`data`)** is the Collections row plus:

- `lines: [{ id, rid, child_name, description, note, amount, credit_note }]`.
- `subtotal`, and `gst` (`{ rate, amount, mode }`, or null).
- `late_fee_raw` (before waivers) and `net`.
- `drafted_at`, `issued_at`, `issued_by`.
- `history`: newest first. Each entry has a `kind`:
  - `payment`: with its receipt, method, reference and source (`console` or `app`).
  - `cn` or `dn`: with `number`, `credit_use` and `reason`.
  - `waiver`.
- `can: { pay, waive_late, notes }`.

For printing, the title is `Tax Invoice` when GST is on, and `Invoice` otherwise.

**First invoices.** Record First Invoice Paid in Bus Service Requests now writes a receipt and a payment the same way.

## 4. Documents and statements

| Call | What it does |
| --- | --- |
| `GET /schools/:school_id/documents?type=&payer=&q=` | Invoices, credit notes, debit notes, receipts and payment vouchers, newest first (latest 300) |
| `GET /school_documents/:id` | A credit note, debit note or receipt to print |
| `POST /school_documents/:id/void` | `{ reason }`. Only a receipt can be made void. Its payments are voided too, so the bills it paid are owed again. `422`: "Enter why the receipt is void" |
| `GET /schools/:school_id/statement?payer=` | Statement of Account. `422` "No bills for this payer" |

**The list.**

- `type` is `inv`, `cn`, `dn`, `rcp` or `pv`.
- `payer` is `family:<id>`, `school` or `operator:<id>`. A receipt also shows under every payer whose bill it paid.
- Each row has:
  - `type`, `id`, `number`, `date`, `school_id`, `school`, `to`, `amount`.
  - `status`: the bill status; `Applied`, `Refunded` or `To Next Bill` for a credit note; `Issued`; `Received`;
    `Paid`; or `Void`.
  - `tone`.
  - `links`: for example `"Pays INV-…"`, `"For INV-…"`, or `"Paid S$…, RCP-…, CN-…"`.
  - `can_void` (receipts only).
- `meta` has `counts` (per type, plus `all`), `payers: [{ key, name }]`, `types`, `count` and `shown`.

To open each type:

- An invoice opens with `GET /school_bills/:id`.
- A credit note, debit note or receipt opens with `GET /school_documents/:id`.
- A payment voucher opens with `GET /school_payouts/:id/voucher`.
- Voucher on a payout: `voucher: { number, on }`, or `null` until the voucher is numbered (`number` is "Draft" on the voucher page).
  The voucher is numbered at the first payment, so a part-paid run has one: its `status` is `Part Paid` until the net is paid, then `Paid`. The voucher page and the documents list (`payment_voucher`) both carry it; the voucher page also has `paid` and `balance`.
- Payout `history` (newest first by when each step was recorded, so two payments on one day keep their order; `at` on a `paid` entry is the date paid), each entry has a `kind`: `returned` (Sent back to Ops), `sent` (Sent to Finance), `approved`
  (with the net), or `paid` (a payment with its amount, method and reference). The entries are the prototype's steps.

**A credit note, debit note or receipt (`data`).** Every type has:

- `type`, `title` (`Credit Note`, `Debit Note` or `Official Receipt`), `number`, `date`, `to`, `to_code`, `status`,
  `total`, `reason`, `by`.
- `void`: `{ at, reason, by }`, or null.

A receipt also has `method`, `reference`, `can_void` and `applied: [{ bill_id, number, amount }]`.

A credit or debit note also has:

- `bill`.
- `lines: [{ description, amount }]` and `subtotal`.
- `gst`.
- `credit_use` and `use_text`, for example `"Taken off INV-…"` or `"Will be taken off the next bill"`.
- `refund`.

**Statement (`data`).** It covers every bill issued, debit note, credit taken off a bill, payment, and the late fee to
date, oldest first:

- `payer`, `name`, `as_of`, `balance`.
- `lines: [{ date, details, charge, credit, balance }]`.

## 5. Operator Payments (pay runs)

There is one pay run per operator per school month. Route pay is worked out live until Ops sends the pay run to Finance.
From then on, the route pay, the routes and the replacement lines are kept.

| Call | What it does |
| --- | --- |
| `GET /schools/:school_id/payouts?month=YYYY-MM` | The month (default: this month) |
| `POST /schools/:school_id/payouts/:operator_id/lines` | Add a line (multipart for files): `{ month, kind, adj_on, route, amount, reason, paired_operator_id, files: [] }` |
| `DELETE /schools/:school_id/payouts/:operator_id/lines/:line_id?month=` | Remove a line. Lines added automatically, and lines on a pay run sent to Finance, cannot be removed |
| `PATCH /schools/:school_id/payouts/:operator_id` | `{ month, invoice_number }`: the operator's invoice number |
| `POST /schools/:school_id/payouts/:operator_id/send` | Send to Finance. The prototype labels this button "Approve and Send to Finance" (month ended) or "Approve Early and Send to Finance" (month not ended): it is this call, shown when `can.send`; it does not approve |
| `POST /schools/:school_id/payouts/:operator_id/recall` | Recall, back to draft |
| `POST /schools/:school_id/payouts/:operator_id/send_back` | Send Back to Ops (an approver) |
| `POST /schools/:school_id/payouts/:operator_id/approve` | Approve (an approver; the maker-checker rule applies) |
| `POST /schools/:school_id/payouts/:operator_id/reopen` | Reopen an approved run that has no payment and is not in a batch |
| `POST /schools/:school_id/payouts/:operator_id/payments` | Pay: `{ month, paid_on, amount, method, reference }`. Up to what is left. The first payment numbers the Payment Voucher. `422`: "Pick the date paid", "Enter the amount paid", "Pick how it was paid" (one of `methods`), "Amount is more than the S$x left to pay" |
| `GET /school_payouts/:id/voucher` | The Payment Voucher to print |

Every action returns the whole month again, like `GET` (adding a line and paying answer `201`). A send, recall, approve or reopen that the state does not allow is a `422` in Operator Pay's words, for example "Only an open pay run can be sent to Finance".

**The month (`data`).**

- `month`, `month_label`, `future`, and `month_text`, which is shown when the month has not ended.
- `rights: { prepare, approve, set_up, maker }` and `rights_text`.
- `kpis: { net_payable, paid, still_to_pay, operators_to_pay }`. Money is always a decimal string, `"0.0"` when the net is zero or negative (`balance` too).
- `kinds: [{ kind, sign }]`, `methods`, and `routes` (labels for the line form).
- `rows`, one per operator. Each row has:
  - Who: `key` (the operator id, `own` or `none`), `operator`, `name`, `payable`, `id`, `routes_count`.
  - Money: `base` (route pay), `additions`, `deductions`, `net`, `paid`, `balance`.
  - Status:
    - `status`: `No Operator` (routes with no bus), `Our Buses` (the company's own buses, nothing to pay), `Paid`,
      `Part Paid`, `Approved`, `With Finance`, `To Check` (the month has ended) or `Open`.
    - `tone`.
  - Documents: `invoice_number`, `voucher: { number, on }`, and `batch: { number, pay_date, notice_number }` when the
    pay run is in an Operator Payments batch.
  - `routes`: `[{ route, session, plan, bus_type (code, e.g. `LARGE_40`), bus_type_label (e.g. `40-seater`; show this), plate, price, unpriced, days, of, break_month, earned, rate, from, to, amount, note, attendant }]`.
    `attendant { amount, by: operator | us }` (or `null`): the monthly bus attendant price inside `price` → "Incl. S$`amount` BA
    (theirs)" when `by` is `operator`, "(ours)" when `us`. Which sizes need one follows Bus Attendants (statutory / all / selected sizes).
    For example, `days` 11 `of` 21 with the `note` `"Took over from Beta Coaches on 16/11/2026"`.
  - `lines`: `[{ id, kind, sign, adj_on, route, amount, reason, auto, paired_with, by, can_remove, files: [{ id, name, url, size, content_type }] }]`. Auto lines (`auto: true`) carry only `id`, `kind`, `sign`, `adj_on`, `route`, `amount`, `reason`, `auto` and `can_remove`.
  - `history`: newest first, with `kind` `sent`, `returned` (sent back to Ops), `approved` or `paid`. "Approved for S$…" is the **net** (route pay plus additions less deductions), as the prototype's `runNet`.
  - `can: { edit, send, recall, send_back, approve, reopen, pay, need_other }`. `send` is `false` when the net is `0` or below (deductions only): the send call answers `422` "Nothing to pay (deductions only)". `pay` needs an approved run.
  - `note`: shown for `own` and `none`.

**Route pay.** Each school day a route runs earns that day's price, spread over the month's school days:

- **The price** is the route's own price history, or else the school's default for the bus size (Operator Pay). It is
  either fixed monthly, or a base for some riders plus a rate for each rider above them. The bus attendant is added
  when the policy needs one.
- **Calendar days** are used instead of school days in a break month, or when part months go by calendar days.
- **The Operator Pay scheme** sets the share of the month that is paid, and the retainer earned applies in a break
  month.
- **A route split between operators.** When the route's regular bus moves to another operator mid-month, each operator
  gets their own days.

**Lines.**

- **Kinds that deduct:** Taxi claim, Replacement bus we arranged, Penalty / late arrival, Damage, Other deduction.
- **Kinds that add:** Covered another route, Extra trips, ERP / parking claim, Other addition.
- **Covered another route.** With `paired_operator_id`, the call also deducts the same amount from that operator, as
  "Route covered by …". The other pay run must still be open.
- **Replacement buses.** A replacement bus we arranged at a daily rate is added automatically (`auto: true`). It is
  deducted from the regular operator and added to the replacement's operator.

**Paying.** There are two ways to pay, as in Convoy OS:

- **Here.** Record the payment on the pay run, which gives it a Payment Voucher.
- **In a batch.** An approved pay run appears in Finance › Operator Payments › Payment Requests. Once it is in a batch,
  it is paid there with a Payment Notice, and this page shows `batch` with its paid share.

## 6. Company Finance pages

| Call | What it does |
| --- | --- |
| `GET /finance/school_collections?school_id=&status=&q=` | Finance › School Bus Collections: the latest 200 bills of every school the user may open, with `school_id` and `school` |
| `GET /finance/documents?type=&q=&school_id=` | Finance › Documents now also lists School Bus documents (types below) |
| Operator Payments | `GET /finance/operator_pay/requests` lists school pay runs: `ref: school_payout:<id>`, `source: school` |

**School Bus Collections.** `data` = the bills: each is the Collections row ([§ 2](#2-collections)) plus `school_id` and
`school` (name). `status=` takes `Due`, `Overdue`, `Part Paid`, `Paid`, `Credited`; `q` matches number, bill to, code and
school name. `meta` has:

- `kpis` (every bill of the schools, not only the shown ones): `{ bills, billed, collected, outstanding, not_paid, overdue, overdue_bills }`
  (`not_paid` = bills with something owed, `overdue` = S$ owed past due, `overdue_bills` = how many). No `credited` here.
- `by_school`: a row per school with `school_id`, `name`, `bills`, `billed`, `collected`, `outstanding`, `not_paid`,
  `overdue` and `overdue_bills`.
- `counts` `{ all, Due, Overdue, Part Paid, Paid, Credited }`, `count` (bills matching the filters), `shown` (≤ 200 in `data`),
  and `schools [{ id, name }]` for the picker.

```json
{ "data": [ { "id": 301, "number": "INV-2026-000301", "kind": "period", "payer": "family", "family_id": 44, "bill_to": "Tan Wei Ming",
              "bill_to_code": "F0044", "bill_to_email": "weiming.tan@example.com", "children": ["Tan Jia Hui"], "lines_count": 2,
              "period": "Term 4 2026", "academic_year_id": 2, "period_index": 3, "issued_on": "2026-10-01", "due_on": "2026-10-15",
              "total": "420.0", "paid": "0.0", "late_fee": "10.0", "late_waived": "0.0", "credited": "0.0", "debited": "0.0",
              "owed": "430.0", "overdue": true, "days_overdue": 20, "status": "Overdue", "tone": "danger",
              "school_id": 1, "school": "St. Stephen's School" } ],
  "meta": { "kpis": { "bills": 182, "billed": "76440.0", "collected": "61200.0", "outstanding": "15240.0", "not_paid": 36, "overdue": "8120.0", "overdue_bills": 19 },
            "by_school": [ { "school_id": 1, "name": "St. Stephen's School", "bills": 182, "billed": "76440.0", "collected": "61200.0",
                             "outstanding": "15240.0", "not_paid": 36, "overdue": "8120.0", "overdue_bills": 19 } ],
            "counts": { "all": 182, "Due": 17, "Overdue": 19, "Part Paid": 4, "Paid": 140, "Credited": 2 }, "count": 182, "shown": 182,
            "schools": [ { "id": 1, "name": "St. Stephen's School" } ] } }
```

Opening a bill goes to its school's Collections.

**Documents.** The School Bus types are `school_invoice`, `school_credit_note`, `debit_note`, `receipt` and
`payment_voucher`. Each row carries:

- `school_id` and `school`.
- `school_type` (`inv`, `cn`, `dn`, `rcp` or `pv`), which tells the front end how to open the document (see section 4).

**Operator Payments.** A school pay run appears in Payment Requests:

- The description is `"<School> | School routes"`. The details give the month, the routes and anything paid before.
- `amount` is what is left to pay.
- It is `ready` once approved. Otherwise `why` is `"Waiting for approval"` or `"Not sent to Finance"`.

Approving it into a batch works like any other item.

## 7. Not built yet

- **Payments in the Convoy App.** PayNow QR and card are not built, so no admin fee is added to bills.
- **Sending.** Bills, reminders and statements are not sent by email or WhatsApp yet.
- **The school's Dashboard money widgets** come with School Bus sub-menu 7.
