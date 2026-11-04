# Finance — API Guide

The Finance menu (rail icon `account_balance`): **Client Invoices**, **Documents**, **Operator Payments**,
**Vehicle Financials**, **Finance Settings**, and **School Bus Collections** (see [school-bus-finance § 6](school-bus-finance.md#6-company-finance-pages)). What is not built
yet is in [§ 8](#8-not-built-yet).

Conventions (sign-in, errors, paging, files, background reads) are in [README.md](../README.md). All paths start with `/api/v1`.

**Permissions.** Finance pages need `finance` or `finview` (read); changing needs `finance`. Finance Settings need `finset`;
Vehicle Financials need `vehfin`. Unlock needs an Admin (admin, Super Admin or the `users` permission). Convoy Admin: read only.

**Document numbers.** Every document type has its own prefix (Finance Settings) and a running number that restarts each
year: `INV-2026-000001`. Numbers are given when a document is issued and never repeat.

**Printing.** Invoices, statements, credit notes and payment notices are printed by the front end from the data of each
call (the prototype's layouts). Email is recorded only (no email is sent yet).

## Contents

1. [Finance Settings](#1-finance-settings)
2. [Client Invoices](#2-client-invoices)
3. [Client Invoices: payments, credit notes, reports](#3-client-invoices-payments-credit-notes-reports)
4. [Operator Payments](#4-operator-payments)
5. [Documents](#5-documents)
6. [Vehicle Financials: purchase and loan](#6-vehicle-financials-purchase-and-loan)
7. [Vehicle Financials: profit and loss](#7-vehicle-financials-profit-and-loss)
8. [Not built yet](#8-not-built-yet)
9. [Changes to existing endpoints (02/11/2026)](#9-changes-to-existing-endpoints-02112026)

---

## 1. Finance Settings

| Action | Call |
| --- | --- |
| Open | `GET /finance/settings` |
| Save / Save & Lock | `PATCH /finance/settings { settings: {...}, lock: false }` |
| Lock / Unlock (Admin) | `POST /finance/settings/lock`, `POST /finance/settings/unlock` |

Fields (save body = response):

| Card | Fields |
| --- | --- |
| GST | `gst_on`, `gst_rate` (default 9), `gst_mode` (`excl` Fares Are Before GST / `incl` Fares Include GST), `gst_reg_no` |
| Payment Details | `bank_id` (`GET /banks`), `account_number`, `account_name`, `paynow`, `payment_note` |
| Operator Pay Run Approval | `approval` (`single` One Person / `maker` Maker-Checker), `approvers [{ user_id, can_prepare, can_approve }]` (response adds `name`, `email`, `active`) |
| On Documents | `brand_name`, `brand_uen`, `brand_address`, `brand_phone`, `brand_email`, `brand_note` (+ the company logo) |
| Document Numbers | `prefix_inv`, `prefix_cn`, `prefix_dn`, `prefix_rcp`, `prefix_pv`, `prefix_pn`, `prefix_pb` (upper-cased, A–Z 0–9, up to 6); `doc_types` = labels |

Also: `locked`, `locked_at`, `locked_by`, `active_users`, `maker_checker_warning` ("Maker-checker is on, but only 1 active
user is left, so no pay run can be approved. Switch to One Person"). Disable Maker-Checker when `active_users < 2`
("Needs at least two active users…"). GST examples on the mode cards are worked out on the front end from the rate.

`422`: "Finance Settings are locked. Unlock to change them", "Enter a GST rate between 0 and 100", "Every document type needs a
prefix", "Each document type needs its own prefix", "Enter the account number", "Add at least one approver for operator pay
runs", "Maker-checker needs at least two active users. Add another user first", "Maker-checker needs at least two people: add
a second approver or a preparer", "Some approvers are not users of this company".

## 2. Client Invoices

Invoices to clients for the trips in the Scheduler. Recurring trips are invoiced monthly (one line per trip with its date
range); one-off trips can be invoiced any time, before or after the trip (Invoice Now).

| Action | Call |
| --- | --- |
| Month picker → Ready to Invoice | `GET /finance/invoices/ready?month=2026-10` |
| Ad Hoc Trips | `GET /finance/invoices/ad_hoc` |
| Create Draft | `POST /finance/invoices { client_id, client_site_id, month: "2026-10" }` |
| Invoice Now | `POST /finance/invoices { trip_id }` |
| Tabs Drafts / Unpaid / Paid / Void / Credit Notes | `GET /finance/invoices?tab=drafts&client_id=&q=` (`meta.counts` per tab) |
| Open an invoice | `GET /finance/invoices/:id` |
| Save Draft | `PATCH /finance/invoices/:id { invoice: {...} }` |
| Issue | `POST /finance/invoices/:id/issue` |
| Void (confirm in the prototype) | `POST /finance/invoices/:id/void` |
| Delete draft ("Delete this draft? Its runs go back to Ready to Invoice") | `DELETE /finance/invoices/:id` |
| Billing Details (a client) | `GET` / `PATCH /finance/billing/:client_id` |

### 2.1 Which runs are billed

- Runs of the month up to today (Invoice Now: every run of the trip, also future ones), not skipped / removed, not on an
  invoice that is not void.
- A run with no client price → not billed ("No client price on the trip"); with an issue raised → not billed ("An issue is
  raised on this run"). These come back in `blocked` for the tooltip.
- A run **the client cancelled** (`cancelled_by_client`) less than the client's cut-off (`late_cancel_hours`, 24 by default)
  before its start → billed in full as a **late cancellation** (can be waived run by run on the draft). Other cancelled runs are not billed.
- A trip whose site is billed as its own entity (Clients > site > own billing) bills that site; otherwise the client.

Ready to Invoice row: `{ client_id, client_site_id, name ("<billing name> | <site>" for a site), trips, runs, late_cancels, amount,
drafts_open, blocked [{ date, trip_label, reason }] }` → "N trips, M runs", "N late cancellations", "N cannot be billed", "N drafts open".
Ad Hoc row: `{ trip_id, ref, title, client { id, name }, date, amount, done, client_site_id }` (chip Upcoming / Done; up to 12).

### 2.2 The invoice

List row: `{ id, kind, number, status, display_status, client_id, client_name, client_site_id, invoice_id, trip_id, bill_to_name,
issued_on, due_on, period_from, period_to, period_label, subtotal, gst, total, balance }`.
`display_status`: `draft`, `void`, `paid`, `overdue`, `partly_paid`, `issued` (chips Draft / Void / Paid / Overdue / Partly Paid / Issued).

Invoice (`GET /finance/invoices/:id`) adds `bill_to_uen, bill_to_address, attention, po, terms_days, gst_on, gst_rate, gst_mode,
notes, paid, credited, lines, payments, credit_notes, sends` ([§ 3](#3-client-invoices-payments-credit-notes-reports)).
Line: `{ id, source: trip | late_cancel | manual, trip_id, ref, description, details, period_text, quantity, unit_price, amount,
runs [{ id, occurrence_id, date, start_time, trip_label, amount, waived }] }`.

Save Draft body (drafts only, `422` "Only drafts can be changed"):

```json
{ "invoice": { "bill_to_name": "Google Asia Pacific", "bill_to_uen": "200817984R", "bill_to_address": "…", "attention": "Priya Raman",
               "po": "PO-77", "issued_on": "2026-11-02", "terms_days": 30, "notes": "", "gst_mode": "excl",
               "manual_lines": [ { "description": "ERP charges", "quantity": 1, "unit_price": 15 } ],
               "remove_line_ids": [12], "waived_run_ids": [88] } }
```

- `manual_lines` is the whole list of manual lines (Add Line); `amount` = given, else quantity × unit price.
- `remove_line_ids`: trip / late cancellation lines taken off (their runs go back to Ready to Invoice).
- `waived_run_ids`: late cancellation runs Waived (the rest are Billed).
- GST (`gst_on`, `gst_rate`) comes from Finance Settings when the draft is made; `gst_mode` can change while a draft:
  `excl` "Charge GST on Top", `incl` "Prices Include GST". GST off → "GST is off in Finance Settings, so no GST is charged".
- Bill-to, attention, terms and PO start from the client (or the site billed as its own entity). Terms: the client's
  `payment_terms_days`, else 0 for individuals ("Due on receipt") and 30 for others.

Issue: numbered `INV-2026-000001` (year of the invoice date), `issued_on` = the date set or today, `due_on` = date + terms.
`422`: "Add at least one line", "Enter who the invoice is billed to". Void: issued invoices with no payments
(`422` "<number> has payments. Use a credit note instead"); its runs go back to Ready to Invoice.

### 2.3 Billing Details

`{ client_id, name, kind, billing_name, bill_name, uen, billing_address, payment_terms_days, terms_days, default_po, late_cancel_hours,
billing_contacts [{ id, name, email, send_as, attention }] }`. Save body `{ billing: { billing_name, uen, billing_address,
payment_terms_days, default_po, late_cancel_hours, billing_contacts: [...] } }` (people rules as Edit Site,
[clients § 2.1](clients.md#21-sites)).

- **Billing Name** (field "Billing Name"): the legal name invoices are billed to; blank = the client's name. `bill_name` is
  the one used (new invoices' `bill_to_name`). The client can also change it in the Client Portal (Legal Name), with UEN,
  address, the first person invoices go To and the Attention name.

## 3. Client Invoices: payments, credit notes, reports

| Action | Call |
| --- | --- |
| KPIs and Aging card | `GET /finance/invoices/summary?month=2026-11` |
| Clients card (balance by billing entity) | `GET /finance/invoices/clients` |
| Statement (print) | `GET /finance/invoices/statement?client_id=&client_site_id=` |
| Record Payment | `POST /finance/invoices/:id/payments { paid_on, amount, method, reference }` |
| Credit Note | `POST /finance/invoices/:id/credit_note { amount, reason }` |
| Email | `POST /finance/invoices/:id/send { to: [], cc: [] }` (recorded only) |

All three need an issued invoice (`422` "Only an issued invoice can take this") and return the invoice.

- **Payments**: `method` one of `Bank Transfer`, `PayNow`, `GIRO`, `Cheque`, `Cash`; `paid_on` defaults to today, `amount` to the balance on the
  front end. `422` "Enter the amount received", "More than the balance of S$x", "Pick how it was paid".
  Shown as "<paid_on> | <method> <reference>".
- **Credit note**: a document of its own (`kind: credit_note`, `CN-2026-000001`, no GST breakdown) that reduces the invoice's balance.
  `422` "Enter the credit amount", "More than the balance of S$x", "Enter the reason". Listed in the Credit Notes tab and in the invoice's `credit_notes`.
- **Email**: no email is sent yet; `to` / `cc` default to the billing people (To / CC). `422` "Add who the invoice goes To in Billing Details".
  `sends [{ at, to, cc, by }]` → "Emailed to <to> on <date> (recorded)".
- Invoice amounts: `paid`, `credited`, `balance` = total − paid − credit notes (not below 0).

Summary: `{ owed, overdue, invoiced, collected, month, aging [{ key, label, amount, count }] }` — Owed to You (open balances),
Overdue (past due), Invoiced <Mon> (issued that month), Collected <Mon> (payments that month). Aging buckets: `current`
(not past due), `1_30`, `31_60`, `61_90`, `over_90` (days past due).

Clients: `[{ client_id, client_site_id, name, balance, invoices }]`, largest balance first.

Statement: `{ client, client_site_id, date, rows [{ date, type: invoice | payment | credit_note, number, text, charge, credit, balance }],
balance, aging }` — the Statement of Account with a running balance.

## 4. Operator Payments

Everything the company owes operators. Finance approves requests and sets the pay date; approvals with the same pay date
pool into one batch, which makes one bank file and one payment notice per operator. Approving, changing pay dates and
recording payments need an approver of Finance Settings (`422` "Only approvers in Finance Settings can approve requests,
set pay dates and record payments"); when no approver is set, anyone with `finance` can.

| Action | Call |
| --- | --- |
| Payment Requests tab, KPIs | `GET /finance/operator_pay/requests` |
| Set a run's cost | `PUT /finance/operator_pay/costs { ref, amount }` (`422` "Enter a cost of 0 or more") |
| Add Item for <operator> | `POST /finance/operator_pay/items { operator_id, sign: pay \| deduct, description, item_on, amount }` |
| Delete an item | `DELETE /finance/operator_pay/items/:id` |
| Approve and Set Pay Date | `POST /finance/operator_pay/approve { refs: [], pay_date }` or `{ refs: [], batch_id }` (Or add to an open batch) |
| Ad Hoc Payment / Pay Now | `POST /finance/operator_pay/ad_hoc { operator_id, pay_date, refs: [], extra: { description, amount } }` |
| Batches tab | `GET /finance/operator_pay/batches` |
| A batch | `GET /finance/operator_pay/batches/:id` |
| Change Pay Date (pool into another batch) | `PATCH /finance/operator_pay/batches/:id { pay_date, merge: true }` |
| Cancel Batch | `DELETE /finance/operator_pay/batches/:id` |
| Pay (one operator) | `POST /finance/operator_pay/batches/:id/payments { batch_operator_id, paid_on, amount, method, reference }` |
| Mark All Paid | `POST /finance/operator_pay/batches/:id/mark_paid` |
| Make Bank File | `POST /finance/operator_pay/batches/:id/bank_file { transfer_type: FAST \| GIRO }` → the batch + `csv`, `filename` |
| Download Again | `GET /finance/operator_pay/batches/:id/bank_file.csv` (CSV file) |

### 4.1 Requests

`data`: one group per operator `{ operator { id, name }, pays_by { method, to, warn }, to_approve, not_ready, items }`.
Item: `{ ref, source: trip | replacement | item, description, details, item_on, amount, ready, why, editable }`.

- `trip`: a run on the operator's bus (3 months back to the end of this month) at its operator cost: the pay agreed on the
  assignment (split per run for day / month pay), else the trip's operator cost, else the external operator's cost per trip,
  or the cost set here (`editable`). Cancelled runs count only when the trip pays operators in full for cancellations.
  `why`: "Set the cost", "Not run yet".
- `replacement`: a replacement bus we arranged for the operator: its deduction and premium, taken off (negative).
- `item`: a manual item (negative = deduction).
- `meta`: `{ waiting, waiting_items, waiting_operators, approved_unpaid, approved_batches, next_pay { date, number, amount, overdue } | null, can_approve }`
  (Waiting for Approval, Approved Not Paid, Next Pay Date; `can_approve` false → the note for non-approvers).

`422` on approve: "Select the requests to approve", "Pick the pay date", "Pick today or a later pay date",
"<n> of the items are not ready: <why>", "<batch> has gone to the bank, so this starts a new batch".
Ad hoc: "Describe the extra line", "The payment must be more than S$0".

### 4.2 Batches

Batch: `{ id, number (PB-2026-000001), kind: batch | adhoc, pay_date, transfer_type, bank_file_at, status, open, total, paid, operators_count }`,
`status`: `scheduled`, `sent_to_bank`, `overdue`, `part_paid`, `paid`. `open` = no bank file and nothing paid (new approvals
for its date join it). A batch adds `operators [{ id, operator, pays_by, notice_number, total, paid, left, status, lines, payments }]`.

- Change Pay Date onto a date with another open batch: `422` "<other> already pays on <date>. Pool <batch> into it?" → send `merge: true`.
- Cancel Batch: its items go back to the requests (`422` when it has payments). Tell the bank if the file was made.
- Bank file: every operator needs payment details ("Add payment details for X in Managed Operators first"); FAST allows up to
  S$200,000 per bank payment ("… Use GIRO for X"). Issues each operator's payment notice (`PN-2026-000001`) with how it is
  paid, and locks the batch. CSV columns: Value Date, Payee Name, Payment Type, Bank Name, Bank Code, Branch Code, Account Number,
  Account Name, PayNow Proxy Type, PayNow Proxy, Amount (SGD), Reference (the PN), Payee Email.
- Payments: `method` `FAST`, `GIRO`, `Bank Transfer`, `PayNow`, `Cheque`, `Cash`; `422` "Enter the amount paid", "Pick the date paid",
  "Amount is more than the S$x left to pay". Mark All Paid records what is left for every operator, by its pay method.
- Payment notice (print): the operator's lines, total, payments; "We will pay S$x on <date> by <method>…" / "Paid in full."

## 5. Documents

| Action | Call |
| --- | --- |
| List, type filter, search (number or name), one school | `GET /finance/documents?type=&q=&school_id=` |
| Print a client invoice / credit note | `GET /finance/invoices/:id` |
| Print a payment notice | `GET /finance/documents/payment_notices/:id` |
| Header / footer of every printed document | `GET /finance/documents/brand` |

Row: `{ type, id, number, date, to, amount, status, batch_id }`; `type`: `invoice`, `credit_note`, `payment_notice`, and the School Bus
types `school_invoice`, `school_credit_note`, `debit_note`, `receipt`, `payment_voucher` (rows add `school_id`, `school`, `school_type`;
they open from School Finance, see [school-bus-finance § 6](school-bus-finance.md#6-company-finance-pages)). `meta { count, shown, counts { per type }, types }`; the latest 300 are listed
("Showing the latest 300 of N documents…"). Status: invoices as `display_status`; credit notes `issued` / `void`; payment notices
`issued`, `part_paid`, `paid`; School Bus documents as in School Finance.

Brand: `{ name, uen, gst_reg_no (when GST is on), address, phone, email, note, logo, payment { bank, account_number, account_name, paynow, note } }`.
Title of an invoice: "Tax Invoice" when the invoice has GST, else "Invoice".

Payment notice: `{ number, pay_date, batch, operator { id, name, uen, email }, pays_by { method, to }, total, paid, left, lines, payments, brand }`.

## 6. Vehicle Financials: purchase and loan

Own vehicles only. Needs the `vehfin` permission.

| Action | Call |
| --- | --- |
| List, filter All / Loan / Paid in Full / No Details, search, KPIs | `GET /finance/vehicles?filter=all\|loan\|cash\|none&q=` |
| A vehicle (purchase, loan, schedule) | `GET /finance/vehicles/:vehicle_id` |
| Edit form → Save | `PATCH /finance/vehicles/:vehicle_id { financial: {...} }` (multipart with `financial[schedule_file]`) |
| Upload the lender's schedule (Claude) | `POST /document_reads` `kind=vehicle_loan_schedule`, poll, then Save with `document_read_id` |
| Tick instalments paid / unpaid | `POST /finance/vehicles/:vehicle_id/instalments { numbers: [1, 2], paid: true, paid_on }` |
| Financials on the vehicle record | `financials` of `GET /vehicles/:id` (users with `vehfin`) |

Row: `{ vehicle_id, plate, make, model, status, funding, lender, purchase_price, owed, monthly, due_this_month }`;
`meta { purchase_cost, owed, monthly, due_this_month }` (Fleet Purchase Cost, Still Owed on Loans, Monthly Instalments, Due This Month).
`status`: `no_details` (No Details), `paid_in_full`, `incomplete` (loan terms missing), `overdue`, `loan_paid_off`, `loan_active`.

Vehicle adds `financial` (the form fields + `schedule_file { url, name }`), `schedule` and `rows`:

- Form fields: `funding` (`loan` / `cash` = Paid in Full), `purchase_price`, `down_payment` (empty = price − loan), `bought_on`, `lender`,
  `account_number`, `loan_amount`, `rate` (% a year), `tenure_months`, `term_charge`, `first_due_on`, `first_instalment`,
  `monthly_instalment`, `last_instalment` (empty = worked out). A loan needs Loan Amount, Tenure and First Instalment Due.
- `schedule`: `{ loan, rate, tenure, term_charge, term_charge_auto, total, scheduled, first, monthly, monthly_auto, last, last_auto, down,
  valid, paid_count, paid_amount, owed, principal_owed, interest_paid, interest_owed, next_due, overdue_count, ends_on, check }`.
  Auto values: term charge = loan × rate × tenure / 12 (flat rate); monthly = (loan + term charge) / tenure rounded up; last = the rest.
  `check` = "The instalments add up to S$x, but loan plus term charge is S$y. Check the figures against the schedule" (or `null`).
- `rows`: `[{ n, due_on, amount, interest, principal, balance, paid_on, status: paid | overdue | due | upcoming }]` (interest spread evenly).
- Reading a schedule fills only empty fields and marks the instalments it shows as paid. A schedule for another plate:
  `422` "This schedule is for PD1234A, not PC7475L. Use Anyway or Remove File first" → resend with `use_anyway: true`.

Vehicle record `financials`: `{ status, funding, purchase_price, bought_on, lender, loan_amount, monthly, owed, ends_on }`, `{ status: "no_details" }`,
or `null` for users without `vehfin` and operator buses.

## 7. Vehicle Financials: profit and loss

| Action | Call |
| --- | --- |
| Period, basis, fleet totals, profit by vehicle, categories, 12-month chart, cost per km by bus size | `GET /finance/vehicles/pl?period=&basis=&month=2026-10` |
| A vehicle's P&L, break-even, manual entries | `GET /finance/vehicles/:vehicle_id/pl?period=&basis=&month=` |
| Cost Spikes / Mark Checked | `GET /finance/vehicles/spikes?month=`, `POST /finance/vehicles/spikes/ack { vehicle_id, category, month: "2026-10" }` |
| Due in the next 90 days | `GET /finance/vehicles/due` |
| Add a manual revenue / cost | `POST /finance/vehicles/:vehicle_id/entries { entry: { kind, category, entry_on, amount, repeats_monthly, note } }` |
| Stop a repeat from a month / edit | `PATCH /finance/vehicles/:vehicle_id/entries/:id { entry: { repeat_until: "2026-12-31" } }` |
| Delete an entry (repeating: "Delete <cat> from every month it repeats in?") | `DELETE /finance/vehicles/:vehicle_id/entries/:id` |

`period`: `month` (the `month` given), `ytd` (Year to Date), `this_year`, `last_year`, `last_12` (Last 12 Months), `all` (All Time).
`basis`: `profit` (depreciation and loan interest) or `cash` (purchase / down payment and loan instalments when paid out).

Fleet: `{ period, basis, from, to, revenue, cost, profit, margin, vehicles [{ vehicle_id, plate, seats, revenue, cost, profit }] (weakest first),
categories [{ kind, category, amount }], chart [{ month, revenue, cost, profit }] (12 months to `month`),
cost_per_km [{ size: Minibus | Medium Bus | Coach, vehicles, km, cost_per_km, revenue_per_km, profit_per_km }] }`.
Vehicle: the same totals, `categories`, `chart`, `break_even { revenue, cost, trip_revenue, runs, per_run, runs_needed, gap }`
("Short by" when `gap` > 0, else "Covered by") and `entries`.

What is counted (each month):

| Category | Kind | From |
| --- | --- | --- |
| "<Trip kind> (auto)", e.g. "Ad Hoc / Charter (auto)", "Shuttle (auto)" | revenue | Client price of runs on the bus, not cancelled, up to today |
| Manual entries | revenue / cost | Once in the month of `entry_on`, or every month from it until `repeat_until` |
| "Insurance Premium (auto)" | cost | Each policy's premium (before GST) spread over its cover months |
| "Fuel and Energy (auto)" | cost | Fuel & Energy entries |
| "Maintenance (auto)" | cost | Completed maintenance visits (with GST) |
| "Driver Salary (auto)", "Employer CPF (auto)" | cost | Each default driver's pay scheme for the month with no trips (fixed pay and top-up), × the share of the month they were the bus's default driver; CPF for Citizens / PR by age band (KYC) |
| "Depreciation" (profit) | cost | Purchase price over the months to COE expiry (else 120 months) from the buying month |
| "Loan Interest" (profit) | cost | Interest of each instalment in its due month |
| "Purchase" / "Down Payment", "Loan Instalments" (cash) | cost | In the buying month / each instalment's due month |

Manual categories: revenue `School Bus`, `Charter and Trips`, `Contract`, `Other Revenue`; cost `Road Tax`, `Parking and ERP`,
`Cleaning`, `Other Cost`. `422`: "Enter an amount above zero", "Pick the date", "Category is not a <kind> category".
The "Is This Already Counted?" question before adding revenue is front end only.

Cost spike: `{ vehicle_id, plate, category, amount, usual, month, checked }` — a cost this month above 1.5 × its median of the six
months before (present in at least three) and S$100 over it.

Due: `[{ vehicle_id, plate, date, kind: instalment | insurance | road_tax | coe, text, amount }]` — unpaid instalments (also overdue),
insurance renewals (last premium total), road tax expiry (estimated from the Road Tax entries), COE expiry.

## 8. Not built yet

- The "School Bus (auto)" revenue of a vehicle (comes with the School Bus Dashboard). School Bus Collections, documents and
  school pay runs are in [school-bus-finance.md](school-bus-finance.md).
- Debit notes and receipts for client invoices (the prototype has none).
- Sending email (sends are recorded only); bank-specific file formats (one generic CSV now); PDF files (printed by the front end).
- Connected clients (their own Convoy account).

## 9. Changes to existing endpoints (02/11/2026)

| Endpoint | Before | Now |
| --- | --- | --- |
| `GET /vehicles/:id` | `financials: null` | The Vehicle Financials summary for users with `vehfin` ([§ 6](#6-vehicle-financials-purchase-and-loan)) |
| `GET /users` | `meta.counts` | Also `meta.maker_checker_warning` ([settings § 1.2](settings.md#12-list-get-users)) |
