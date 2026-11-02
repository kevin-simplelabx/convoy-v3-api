# Finance menu — feature inventory (prototype → Rails)

Source: `/Users/kevinluu/workspace/convoy-v3/Convoy Project/` (`Convoy OS.dc.html` = HTML, `logic/...` = JS). Line numbers are from 02/11/2026.
Rails: `/Users/kevinluu/workspace/convoy-v3/convoy-v3-api/`.

Menu (`logic/mixins/admin.js:1058-1064`): `cfcol` School Bus Collections, `cinv` Client Invoices, `cfdocs` Documents, `cfpay` Operator Payments (all need `canFin()`), `vehfin` Vehicle Financials (`canVehFin()`), `finset` Finance Settings (`canFin() && canFinSet()`).

Permissions (`finance.js:9-16`, `fleet.js:56`, descriptions `admin.js:1479-1497`):
- `canFin()` = super OR perms include `finview` OR `finance`. Write actions are further gated by `finRO()` (`vs-engine.js:1258`: read-only unless perm `finance`) and `isRO()`/`roStop()` (company read-only, e.g. Convoy Admin).
- `canFinSet()` = super OR perm `finset`. `canVehFin()` = super OR perm `vehfin`.
- Rails already has these four permissions: `User::PERMISSIONS = %w[users schools plans planview library vehicles finance finview finset vehfin]` (`app/models/user.rb:51`), presets `finmgr` (finance finview finset vehfin) / `finops` (finance finview) in the prototype (`admin.js:1544-1553`).
- `finview` vs `finance`: "finance = Set fares and look after billing … Record payments and mark bills paid"; "finview = See the money side of operations" (`admin.js:1479-1493`). So `finview` = read, `finance` = write.

---

## 0. Summary

| Page | Main entities (proposed) | Data it needs | Dependency status |
| --- | --- | --- | --- |
| **Client Invoices** (`cinv`) | `client_invoices` (+ `client_invoice_lines`, `client_invoice_line_runs`), `client_invoice_payments`, `client_credit_notes` (or same table, kind), `client_invoice_sends`, `client_billing_settings` (terms, PO, cancel cut-off per client/site), `invoice_settings` (prefixes, bank, PayNow, note), `company_sequences` | trip_occurrences (price, status, cancelled_at, cancelled_by_client, issue_raised_at, client_id, trip_id, vehicle_id), trips (client_site_id, kind, title/label, trip_no, days/ends_on), clients / client_sites (own_billing) / client_billing_contacts, vehicles (seats), vehicle_types | **Buildable now** (only Trips/Clients data). School Run trips are ordinary trips here. |
| **Finance Settings** (`finset`) | `finance_settings` (1 row per company: GST on/rate/mode/reg no, approval mode single/maker, brand fields, lock), `finance_document_prefixes` (or columns), `finance_approvers` (user_id, role prepare/approve), invoice settings (shared with cinv) | users (active count, emails), banks / bank_branches | **Buildable now**. |
| **Operator Payments** (`cfpay`) | `operator_payment_requests` (derived, or materialised), `operator_pay_items` (manual extra / deduction), `operator_cost_overrides` (per run / per assignment-day / per assignment-month), `operator_pay_batches` (kind batch/adhoc, pay_date, bank file), `operator_pay_batch_operators` (payment notice no, pay_to snapshot), `operator_pay_batch_lines`, `operator_pay_payments` | trip_occurrences (operator_id, operator_cost, vehicle_id, status, cancelled), trip_assignments (operator_id, pay_amount, pay_basis), replacements (arranged_by, deduction, premium), operators (payment_method, bank_id, account, paynow_uen, cost_per_trip), finance settings approvers | **Trip part buildable now.** The "School routes" source (per-school monthly operator pay runs = `payouts`) is **blocked by School Bus** (route plans, operator pay rates per bus, pay schemes, terms, maker-checker prepare/approve). |
| **Documents** (`cfdocs`) | No own table: a union view over INV/CN/DN/RCP (school bills), PV (school payout vouchers), PN (operator payment notices) | school `bills`/`docs`, `payouts`, `opRuns` | PN part buildable with cfpay; INV/CN/DN/RCP/PV are **School Bus**. Note: **client invoices (cinv) are NOT listed here** in the prototype. |
| **School Bus Collections** (`cfcol`) | `school_bills` (+ lines), `school_bill_payments`, `school_finance_documents` (CN/DN/RCP), `school_bill_waivers`, family bill drafts, payment & refund policy versions, school payment methods | families, riders, fares (locked fare table + billing periods), fare adjustments, policy (due/late/withdrawal/deposit), calendars/terms, requests | **Blocked by School Bus** (none of families/riders/fares/bills/policy exist in Rails). |
| **Vehicle Financials** (`vehfin`) | `vehicle_financials` (1 per own vehicle: fund, price, down, buy date, lender, acct, loan, rate, tenure, term charge, first/monthly/last, first due, file), `vehicle_loan_payments` (instalment n, date, by), `vehicle_finance_entries` (manual revenue/cost, repeat monthly until), `vehicle_cost_spike_acks`, document_reads (AI schedule) | trip_occurrences (price, vehicle_id, completed), fuel_entries (cost, km from odometer), maintenance_visits+lines (done, GST), vehicle_insurance_policies (premium, starts/ends), vehicles (coe_expires_on, road_tax_expires_on, seats, operator_id null = own), drivers + vehicle_driver_schedules, driver pay (HR), driver_kyc_profiles (date_of_birth, residential_status) for CPF | **Mostly buildable now.** School Bus route revenue line needs School Bus (route operator pay) → show 0 / omit until then. Driver salary: prototype simulates the pay scheme; Rails has HR (`driver_pay_months` confirmed totals) — design decision. |

### Open questions / decisions needed
1. **One numbering/prefix system or two?** Prototype has two: Finance Settings `pfx` {INV, CN, DN, RCP, PV, PN, PR→"PB"} with `PREFIX-YYYY-0001` (4 digits, computed as max+1 over the list) for School Bus docs + operator pay (`finance.js:86,107-113`), and Client Invoices' own `cinvSet.prefix/cnPrefix` with `PREFIX-YYYY-000001` (6 digits, persistent counter `cinvSeq`) (`cinv.js:247-254`). Both default to `INV`/`CN` → collisions possible. Recommend one `company_sequences`-based numbering per doc type, 6 digits, restart yearly; decide whether cinv keeps its separate prefix fields.
2. **GST snapshot**: cinv stores `gstOn/gstPct/gstMode` on the invoice at draft time (editable mode while draft); school bills store `g {sub,gst,amt,rate,mode}`. Keep a per-document snapshot (matches "Documents already issued keep the settings they were issued with", `Convoy OS.dc.html` finset page). GST rounding: per document on the line sum, `round2(sum*rate/100)` excl or `round2(sum*rate/(100+rate))` incl.
3. **Client billing fields missing in Rails**: payment terms (days, default 30, Individuals 0 = "Due on receipt"), default PO, late-cancel cut-off hours (`cxHrs`, default 24) per client (`cinv.js:43-70`). Rails `clients` has only `billing_address`; `client_sites` has `own_billing, billing_name/uen/address`; contacts in `client_billing_contacts`. Add columns to clients (data-ownership says billing screens belong to Finance).
4. **Late cancellation rule source**: prototype bills a client-cancelled run in full if cancelled less than `cxHrs` before start (`cinv.js:136-148`). Rails has `cancelled_at`, `cancelled_by_client`. Should only `cancelled_by_client` runs be billable? (Prototype checks any cancel record `SC.cancel[key].at`.) Also Rails has `trips.operator_cancel_rule` for operator side — mirror for client?
5. **Billable statuses**: prototype bills runs with price>0, not cancelled, date ≤ today (recurring monthly), not `|h` keys, not with an open issue (`SC.iss[key]`), not already on a non-void invoice. Rails mapping: `status = completed` only, or also `scheduled` past runs? `skipped`/`removed` excluded. Run with `issue_raised_at` → "cannot be billed". Decide.
6. **Double-billing guard**: prototype `ciUsed` = occurrence keys on any non-void invoice, drafts included (`cinv.js:82-89`). In Rails: unique index on `client_invoice_line_runs(occurrence_id, occurrence_date)` scoped to non-void invoices (partial unique index needs status on the child or a trigger) — design.
7. **Correct Record / price change after invoicing**: backlog item "Correct Record chưa đổi pay / invoice". Prototype has no re-check for client invoices (only for school bills: "billing differences" → raise DN/CN, `finance.js:791-829`). Decide: credit note only (no DN for cinv in prototype).
8. **Client invoices: no Debit Notes, no Receipts** — only payments recorded on the invoice + credit notes (`cinv.js:613-680`). School bills have CN (reduce/refund/carry), DN, RCP, waivers. Unify into one `finance_documents` model or keep two domains? Recommend keep client invoices separate now (buildable), school docs later.
9. **Operator Payments when School Bus missing**: build the trip-based sources (per-run operator cost, assignment day/month rates, replacement deductions, manual items) now; leave `src: 'school'` for the School Bus menu. Confirm.
10. **Maker-checker scope**: in the prototype the prepare/approve separation (`approval: 'maker'`) is only enforced on the per-school operator pay run (`finance.js:1998, 2115-2137`). In `cfpay` the only rule is "approver list membership" (`canRun`, `finance.js:1370`); trip items have no preparer (system-generated), manual items are added by anyone with write access (`canPrep = !RO`). Decide whether maker-checker should also apply to manual items / ad hoc payments in Rails (e.g. an item added by X cannot be approved by X).
11. **Approver identity**: prototype stores approver/preparer emails (`finSet.appr`, `finSet.prep`). Rails should store `user_id`s. Validation "Add at least one approver for operator pay runs" is required on save (`finance.js:2292`). Backlog row "Cảnh báo maker-checker khi chỉ còn 1 user active" refers to this.
12. **Bank file format**: one CSV per batch, columns fixed (`finance.js:1863`), FAST limit S$200,000 per payment. Real bank formats (DBS IDEAL, UOB, OCBC) are not modelled. Keep generic CSV?
13. **Vehicle P&L driver salary**: prototype = pay-scheme simulation with no jobs (`DP.simulate(... jobs: {})`) × share of month days the driver was the default driver of the bus, + employer CPF (`fleet.js:323-352`). Rails has HR confirmed `driver_pay_months.total` (and runs with `occurrence_id`). Options: (a) confirmed month total split by vehicle via `driver_pay_month_runs` (accurate), (b) prototype approach. Backlog says "lương driver theo pay scheme". Decide; CPF needs `driver_kyc_profiles.date_of_birth/residential_status` (exist, seed-only).
14. **Vehicle P&L revenue basis**: prototype trip revenue = `price` of non-cancelled runs on own vehicles with date ≤ today (`fleet.js:448-473`); no late-cancel revenue, ignores invoices. Use `trip_occurrences.price` where `status = completed`? Should cancelled-but-billed runs count?
15. **Depreciation**: straight-line purchase price over months from buy month to COE expiry month (else 120 months), no residual value (`fleet.js:310-316`). Confirm (no PARF/COE rebate).
16. **Insurance premium**: prototype uses `insPrem` (before GST?) spread over cover months; Rails `vehicle_insurance_policies` has `premium`, `gst`, `total`. Which one counts as cost? (Due list uses `insTotal || insPrem`, `fleet.js:553`.)
17. **Persisting computed P&L**: compute on the fly (query objects + groupdate) vs monthly snapshot table. Prototype computes live. Recommend live queries; maybe cache.
18. **Documents page** should it include client invoices + credit notes? Prototype excludes them (cinv lives only in Client Invoices). Probably yes in Rails (one archive).
19. **Email sending**: cinv "Email" only records `sent` ("Sending email comes later", `cinv.js:610`). Keep as record only (like backlog for mail).
20. **PDFs**: prototype prints HTML via browser. Rails: render PDF server-side (gem needed, e.g. Grover/WickedPDF/Prawn — ask before adding) or return data and let FE print.

---

## 1. Client Invoices (`cinv`)

Files: `logic/mixins/cinv.js` (all), HTML `Convoy OS.dc.html:11379-11478` (page), `228-294` (invoice editor `ciG.ed`), `295-337` (Billing Details `ciG.bd`), `~17498` (Invoice Settings `ciS`), page intro text. Client Portal reads them: `logic/app-feed.js:423-438` (`clientBills`).

### 1.1 What the user sees / does
Page header: "Client Invoices" + buttons **How It Works**, **Invoice Settings**. Intro: "Invoices to your Managed and Connected Clients, companies or individuals, for the trips in the Scheduler. Recurring trips are invoiced monthly, one line per trip with its date range. Ad hoc trips can be invoiced any time, before or after the trip. School Bus fare bills to families and schools are in School Bus Collections".

- **Month picker** (`s.ciM`, the month to invoice).
- **KPIs** (`cinv.js:349-372`): "Owed to You" (sum of balances of issued invoices), "Overdue" (balance of issued invoices past due), "Invoiced <Mon YYYY>" (issued this month), "Collected <Mon YYYY>" (payments dated this month).
- **Aging card** (`ciAging`, `cinv.js:312-325`): buckets "Current" (≤0 days past due), "1 to 30 days", "31 to 60 days", "61 to 90 days", "Over 90 days" — amount + count; days = today − (due || date).
- **Ready to Invoice** (`cinv.js:374-400`): one row per client billing entity (client itself + each site with own billing): name (`"<Billing name> | <Site>"` for site entities), "Connected" tag, "N trips, M runs", "N late cancellation(s)", "N cannot be billed" with tooltip (date, trip id, reason), amount, "N drafts open", button **Create Draft** (`ciNew(cid, ym, null, ek)`).
- **Ad Hoc Trips** (`cinv.js:401-421`): non-recurring trips of managed clients dated ≥ today−90 days that still have unbilled runs (top 12, newest first): date, trip ref, title, client, amount, chip "Upcoming"/"Done", button **Invoice Now** (`ciNew(cid, null, tripId)` — works before the trip runs).
- **Invoices list** with tabs: Drafts, Unpaid, Paid, Void, Credit Notes (`cinv.js:492`); row shows no, client, date, period, total, status chip, "Balance S$x". Empty: "Nothing here".
- **Clients card** (`cinv.js:456-490`): per client entity balance, buttons **Statement** (print Statement of Account) and **Billing Details** (dialog).
- **Invoice dialog** (`ciEdVals`, `cinv.js:508-683`; HTML 228-294): title + status chip; fields: Bill To name, Attention, PO, Invoice Date, Terms (days) → "Due <date>", Billing address; lines table (each: Trip ref, Description, Details, Period, Qty, Amount; delete); **Add Line** (manual line `{src:'manual', qty 1}`); late-cancellation lines expand to runs with toggle "Billed"/"Waived"; Notes; GST mode select (draft only): "Charge GST on Top" / "Prices Include GST" with text "GST is added on top of the trip prices" / "The trip prices are the final amount. GST is absorbed inside them"; if GST off: "GST is off in Finance Settings, so no GST is charged"; totals Subtotal / GST / Total, Paid, Credit notes, Balance; payments list "<date> | <method> <ref>"; sent list "Emailed to <to> on <date> (recorded)".
  - Actions: **Save Draft** ("Draft saved"), **Issue** (validations "Add at least one line", "Enter who the invoice is billed to"; flash "Invoice <no> issued to <name>"), **Delete draft** (confirm "Delete this draft? Its runs go back to Ready to Invoice"; "Draft deleted"), **Print**, **Email** (connected client → "Recorded as sent to <name>'s Convoy account"; else needs To: "Add who the invoice goes To in Billing Details"; "Recorded as emailed to <to>, CC <cc>. Sending email comes later"), **Record Payment** (fields date default today, amount default balance, method Bank Transfer/PayNow/GIRO/Cheque/Cash, reference; "Enter the amount received", "More than the balance of S$x"; "Payment of S$x recorded"), **Credit Note** (amount, reason; "Enter the credit amount", "More than the balance of S$x", "Enter the reason"; "Credit note <no> issued"), **Void** (only issued with no payments; confirm "Void <no>? Its runs go back to Ready to Invoice. Use a credit note instead if the client has the invoice"; "<no> voided").
- **Billing Details dialog** (`ciBdVals`, `cinv.js:725-758`, people via `billPplVals` 688-723): billing name, UEN, address, people list [{name, email, cc (CC instead of To), attn (named as Attn)}], terms (days), PO, late-cancel cut-off hours (`cxHrs`). Save: "Billing details saved for <name>". (In Rails these are mostly on Managed Clients: client + `client_billing_contacts`, sites own billing.)
- **Invoice Settings** (`ciStVals`, `cinv.js:760-800`; also embedded on Finance Settings as "Payment Details"): Invoice Prefix, Credit Note Prefix, Bank (SG bank list), Account Number, Account Name, PayNow (UEN/mobile), "Payment Note on Invoices" (default "Please pay by the due date and quote the invoice number."). Validations: "Enter the credit note prefix, so credit notes are told apart from invoices", "Invoices and credit notes need different prefixes", "Enter the account number" (when bank picked). Flash "Invoice settings saved".
- **Statement of Account** (`ciStatement`, `cinv.js:288-311`): issued invoices (charge = total), payments (credit), credit notes (credit), sorted by date with running balance + aging table.
- **How It Works** (`ciHiw`, `cinv.js:326-339`) texts: late cancellation "A run the client cancels inside their cut-off (24 hours by default) is billed in full", "Waive it run by run on the draft", "Invoice Now makes a draft for that trip, even before it runs. Its runs are then left off the monthly invoice".

### 1.2 Data (prototype)
`cinv.js:2-3`:
- `cfg.cinv[]` = `{id, kind 'inv'|'cn', no, cid, site, bill {name, uen, addr, email, att}, po, date, terms, due, per {from, to, lbl}, lines [{id, src 'trip'|'cx'|'manual', ref, desc, det, per, qty, unit, amt, runs [{key, d, tm, tid, amt, waived, done, vid, hrs}]}], gstOn, gstPct, gstMode, notes, status 'draft'|'issued'|'void', pays [{id, date, amt, method, ref, by, at}], sent [{at, to, cc, by}], ref (CN: invoice id), reason, amt (CN), by, at, issuedBy, issuedAt, voidBy, voidAt, nb (not billable list, draft only)}`.
- `cfg.cinvSeq {'INV|2026': n}` — counter per prefix+year.
- `cfg.cinvSet {prefix, cnPrefix, bankId, acct, acctName, payNow, note}` (`cinv.js:13-24`).
- `cfg.cbill {clientId: {name, uen, addr, email, att, ppl[], more[], terms, po, cxHrs}}`; site own billing in `clients[].sites[].bill {own, name, uen, addr, email, att, ppl, more}`.

### 1.3 Rules
- **Billing entity**: a trip bills to its site when the site has `bill.own`, else the client (`ciEnt`, `cinv.js:72-77`). Terms, PO, cut-off always come from the client (`cinv.js:58`). Individuals: no UEN/attention, terms default 0 (`cinv.js:45-57`); others terms 30.
- **Runs** (`ciRuns`, `cinv.js:124-162`), between a..z (month) or one trip (any date):
  - skip ghost runs, keys ending `|h`, other clients (matched by name), already used (`ciUsed`), other entity.
  - **cancelled run**: hours = (run start − cancel time)/3600; if `hrs < cxHrs` (default 24) and price>0 → late-cancel run at full price (`cx`). Otherwise ignored.
  - monthly mode: skip runs after today (both recurring and ad hoc); per-trip mode (Invoice Now) allows future runs.
  - price ≤ 0 → not billable "No client price on the trip"; open issue on the run (monthly mode) → "An issue is raised on this run".
  - else billable run `{key, d, tm, tid, amt: price}`.
- **Lines** (`ciLines`, `cinv.js:176-212`): one line per trip: desc "<title> (<kind>)", det "For <svc>. " + "Route <label> | <pickup> to <dropoff> | 1 Way/2 Way/AM 1 Way/Disposal N h | <bus size>" (`ciTripDet`, 164-175), period = date or "d1 to d2", qty = runs, unit = price if all equal else null, amt = sum. Second line per trip for late cancellations "Late cancellation: <title>".
- **Totals** (`ciTot`, `cinv.js:91-123`): cx line amount = sum of non-waived runs; lsum = Σ lines; GST excl: `gst = r2(lsum*rt/100)`, total = lsum+gst; incl: `gst = r2(lsum*rt/(100+rt))`, sub = lsum−gst, total = lsum. paid = Σ pays; cn = Σ non-void CNs referencing it; bal = max(0, total−paid−cn).
- **Status**: Draft | Void | Paid (bal ≤ 0.005) | Overdue (due < today) | Partly Paid (paid>0 or cn>0) | Issued. Tones: neutral/neutral/success/danger/warning/info.
- **Due** = invoice date + terms days (`cinv.js:532`).
- **Numbering** at issue only: `PREFIX-YYYY-NNNNNN` from the invoice date's year (`ciNext`, `cinv.js:247-254`); CN uses cnPrefix and today's year.
- CN amount ≤ balance; CN has no lines/GST breakdown (just amt + reason).
- Default GST from Finance Settings at draft creation (`ciGst`, `cinv.js:25-29`: rate default 9).

### 1.4 Reads from other areas → Rails
| Prototype | Rails |
| --- | --- |
| `memoTrips` runs (key, d, s/e, price, cancel, tid, vid, kind, t) | `trip_occurrences` (id+date, starts_at, start/end_time, price, status, cancelled_at, cancelled_by_client, issue_raised_at, vehicle_id, client_id, trip_id, kind, trip_label) |
| trip (title/label, pickup/dropoff, days/until, site, svc, vreq) | `trips` (title, label, trip_no, kind, client_site_id, days, end_mode/ends_on, service_for, client_end_customer_id), `trip_stops`, `trip_vehicle_requirements` |
| `SC.cancel[key].at` | `trip_occurrences.cancelled_at` (+ `cancelled_by_client`) |
| `SC.iss[key]` | `trip_occurrences.issue_raised_at` |
| clients, sites bill own | `clients`, `client_sites` (own_billing, billing_*), `client_billing_contacts` (send_as, attention) |
| `cbill.terms/po/cxHrs` | **missing** (add) |
| vehicles seats, vehicle type names | `vehicles.seats`, `vehicle_types` |
| banks | `banks`, `bank_branches` |
| connected clients | not built (backlog: Connected Clients Coming Soon) |

### 1.5 Sample / not real
- `clSeedInd` (`cinv.js:802-835`: two Individual clients), `ciSeedAh` (836-974), `ciSeed`/`ciSeed2` (975-1143) — demo invoices; seed only.
- Email: recorded only ("Sending email comes later").

### 1.6 Dependencies
Only Trips/Clients/Fleet data (all in Rails). Not School Bus. Not HR.

---

## 2. Finance Settings (`finset`)

HTML `Convoy OS.dc.html:13049-13196`; logic `finance.js:81-92` (`finSet`), `2275-2407` (`finSetVals`), plus `ciStVals` (cinv.js:760) for the "Payment Details" card.

### 2.1 UI
Header buttons: Cancel, Save, **Save & Lock**, Lock, Unlock (Unlock admin only). Lock banner: "Locked by <name> on <date>. New documents use these settings. Unlock to change them" / "Ask an Admin to unlock them". Intro: "For the whole company. These apply to new documents. Documents already issued keep the settings they were issued with."
Cards:
1. **GST** "Turn on if the company is GST-registered": Switch "Charge GST", "GST Rate" (number, %), "GST Registration No." (placeholder M90012345A); mode cards "Fares Are Before GST" ("GST is added on top. A S$100 fare is billed as S$109.00 with GST shown as its own line") / "Fares Include GST" ("The fare is the final price. A S$100 fare stays S$100.00 and the bill shows the S$8.26 GST inside it" — amounts computed from the rate, shown here at 9%) (`finance.js:2357-2358`).
2. **Payment Details** (cinv settings): "Where clients and parents pay: shown on client invoices and on School Bus bills in the Convoy App (a school can use its own account in Payment Methods). Also the client invoice numbers." Fields Invoice Prefix, Credit Note Prefix, Bank, Account Number, Account Name, PayNow, Payment Note; own Save/Cancel.
3. **Operator Pay Run Approval** "Who has to sign off before an operator is paid": mode cards "One Person" ("The same person can prepare, approve and pay a pay run. For small teams") / "Maker-Checker" ("A second person approves a pay run before it can be paid. The person who prepared it cannot approve it"; disabled with "Needs at least two active users. This company has N, so add another user first"). Lists **Can Prepare** ("Add lines, attach claims and send for approval. Approvers can also prepare") and **Can Approve** / "Can Prepare and Approve" (user search by name/email among non-suspended users; "Not a user in this company" warning for stale emails; "Everyone who matches is already added"). Warning: "Maker-checker is on, but only N active user is left, so no pay run can be approved. Switch to One Person".
4. **On Documents** "Shown on invoices, notes, receipts and vouchers, with the company logo": Company Name on Documents, UEN, Address, Phone, Email, Footer Note (default "Thank you for riding with us.").
5. **Document Numbers** "Prefix, year, then a running number that restarts each year": INV Invoice, CN Credit Note, DN Debit Note, RCP Receipt, PV Payment Voucher, PN Payment Notice, PR Payment Batch (default prefix `PB`); input uppercased, `[A-Z0-9]`, max 6 chars; example `<PFX>-2026-0001`.

### 2.2 Data
`cfg.finSet = {gst {on=false, rate=9, mode 'excl'|'incl', reg}, approval 'single'|'maker', pfx {INV,CN,DN,RCP,PV,PN,PR}, brand {name, uen, addr, email, phone, note}, lock {by, at}|null, prep [emails], appr [emails]}` (`finance.js:81-92`). Plus `cfg.cinvSet` (above).

### 2.3 Rules / validation (`finance.js:2285-2293, 2398-2400`)
- "Finance Settings are locked. Unlock to change them".
- "Enter a GST rate between 0 and 100" (when GST on; 0 < rate < 100).
- "Every document type needs a prefix".
- "Add at least one approver for operator pay runs".
- maker: "Maker-checker needs at least two people: add a second approver or a preparer" (≥2 approvers, or a preparer who is not an approver); switching to maker with <2 active users: "Maker-checker needs at least two active users. Add another user first".
- Lock/Unlock flashes: "Finance Settings saved and locked", "Finance Settings locked", "Finance Settings unlocked".
- GST split helper `gstOf` (`finance.js:96-105`).

### 2.4 Rails
New: `finance_settings` (company_id unique), `finance_approvers` (user_id, can_prepare/can_approve) or two arrays of user ids; prefixes per doc type. Reuse `companies.logo/name`, `users` (active count), `banks`. `company_sequences` (exists) for numbering.
Dependencies: none (buildable now).

---

## 3. Operator Payments (`cfpay`)

HTML `Convoy OS.dc.html:10727-11080`; logic `finance.js:1152-1945` (`opRec`, `payTo`, `opDue`, `pnView`, `opPayVals`, `opPayBatches`), per-school pay run page `finance.js:1947-2274` (`payrunVals`, School Bus menu `payouts`, HTML ~7406).

### 3.1 UI
Header "Operator Payments" + **Ad Hoc Payment**. Intro: "Everything the company owes operators: school route pay, trips on their buses and extra items. Finance approves requests and sets the pay date. Approvals with the same pay date pool into one batch, which makes one bank file and one payment notice per operator". Non-approver note: "Only approvers in Finance Settings can approve requests, set pay dates and record payments".
KPIs (`finance.js:1937-1939`): "Waiting for Approval" (sum of ready items, "N items from M operators"), "Approved, Not Paid" (unpaid batch balances, "N batches"), "Next Pay Date" (date, "<batch no> | S$x"; red if past; else "None set" / "Set when requests are approved").
Tabs: "Requests N" / "Batches N".
- **Requests tab**: grouped by operator (row: Transport Operator, Pays By (payTo m/t with warning), To Approve, Not Ready Yet, **Pay Now** → Ad Hoc); expanded table Source, Details, Date, Amount, Status (why: "Not sent to Finance", "Waiting for approval", "Approved, needs pay date", "Not run yet", "Month not over", "Set the pay on the Assign page", "Set the cost"). Trip rows have an editable cost (validation "Enter a cost of 0 or more"; "Trip cost saved", stored in `cfg.opCost[key]`). School rows have Open (go to school payouts). Item rows delete ("Item deleted"). **Add Item for <operator>**: sign select "Pay the operator"/"Deduct", description, date, amount ("Describe the item", "Enter the amount", "Pick the date"; "Item added for <op>"). Selection bar: Select All / Clear, text "N items from M operators selected" or "Select the requests to approve. Finance sets the pay date when approving", button **Approve and Set Pay Date**. Empty: "No payment requests right now".
- **Approve dialog** "Approved items are paid on the date you set. Everything approved for the same date pools into one batch, so each operator gets one payment": Pay Date, "Or add to an open batch" chips; info "Pick the pay date" / "This date has passed. Pick today or later" / "Joins <no>, which already pays N operators on <date>" / "<no> for <date> has already gone to the bank, so this starts a new batch" / "Starts a new batch paying on <date>"; flash "N items approved. New batch|Added to <no>, paying <date>"; validation "Pick today or a later pay date".
- **Batches tab**: Payment Batch, Pay Date, Operators, Total, Paid, Status (Scheduled / Sent to Bank / Overdue / Part Paid / Paid). Expanded: Operator, Pay To, Payment Notice no, Amount, Still to Pay, Status, **Pay** (record payment: date, amount, method FAST/GIRO/Bank Transfer/PayNow/Cheque/Cash, ref; "Enter the amount paid", "Pick the date paid", "Amount is more than the S$x left to pay"; "S$x paid to <op>"). Batch actions: change Pay Date ("Pick today or a later date"; confirm "<no> already pays on <date>. Pool <no> into it?"; "<no> now pays on <date>"), **Cancel Batch** (confirm "Cancel <no>? Its items go back to Payment Requests. Tell the bank too, as the bank file was already made"; "<no> cancelled"), **Mark All Paid** ("Records S$x paid to N operators, each by their own pay method"; "<no> marked paid"), **Bank Instructions/Bank File** dialog: "Bank Transfers By" FAST/GIRO (texts `finance.js:1888`), rows name/method/details/amount, errors "Add payment details for X in Managed Operators first" / "FAST allows up to S$200,000 per payment. Use GIRO for X"; **Make Bank File** ("Makes one CSV for the bank with every payment in this batch, and issues each operator's payment notice. The batch is then locked"; "<no> bank file made. N payments, N payment notices issued") / **Download Again**. Empty: "No payment batches yet. Approve requests in Payment Requests to start one".
- **Ad Hoc Payment dialog** "Pay one operator outside the usual batches. Picking items here approves them. The payment gets its own batch, bank file and payment notice": operator, pay date, ready items checklist, extra line (desc + amount), "Total to pay"; validations "Pick the pay date", "Describe the extra line", "The payment must be more than S$0"; creates `kind:'adhoc'` batch "<no> created for <op>".
- Payment Notice PDF (`pnView`, `finance.js:1333-1352`): lines, totals, payments, foot "We will pay S$x on <date> by <method>. Please check the details above and tell us of any difference before then." / "Paid in full."

### 3.2 Data
- `cfg.opRuns[]` batch = `{id, no (PR prefix), kind 'batch'|'adhoc', payDate, at, by, bank {at, by, type FAST|GIRO}|null, ops [{k (operator name), pn (PN no), payTo {m, t, warn}, lines [{ref, src, t, sub, d, amt, sid, ym, k, appBy, appAt}], pays [{id, date, amt, method, ref, by, at}]}]}` (`finance.js:1404-1426`).
- `cfg.opItems[]` = `{id, k, t, date, amt (signed), by, at}`.
- `cfg.opCost {runKey | runKey|r | asgd|<asgId>|<date> | asgm|<asgId>|<ym>: amount}` (cost overrides).
- `cfg.payouts[sid][ym][operator] ` (School Bus pay run) `{base, n, adj [{id, type, sign, amt, date, route, reason, files, by, at}], autoSnap, pays[], status draft|ready|approved, preparedBy(Email), opsBy(Email), opsAt, approvedBy(Email), approvedAt, returnedBy/At, runId, runNo, runPay, invNo, pv {no, date, amt}}`.
- Operator payment details: `subcons[] {name, kind, payDef bank|paynow, bankId, acct, acctName, brCode, paynow, email, costTrip}`.

### 3.3 Rules
- **Due items** (`opDue`, `finance.js:1163-1331`), excluding refs already in any batch:
  1. *School* (`src:'school'`, ref `sch|sid|ym|op`): per school month pay run not in a batch with balance>0; net = `runNet(base, R)` = base + Σ(sign·amt of adj incl. autoSnap) (`finance.js:1945`); ready when status ready/approved. **School Bus.**
  2. *Trip, per-run assignment pay* (ref `trip|<key>`): runs from 3 months ago to end of this month, ad hoc source, where the trip assignment (`A.op`, from "From This Date On" assignment) is an operator; counted if run on that operator's bus (or replacement), and not cancelled unless operator cancel rule is "full" (`T.oCx === 'full'`); amount = override `opCost[key]` else `A.pay.amt`; ready when amount set and run done (date < today or ended).
  3. *Trip, day/month assignment pay* (ref `asgd|id|date` / `asgm|id|ym`): grouped; share `sh = counted runs / runs`; month factor `f0 = sh × min(1, served days / month service days)`; amount = override else `round2(pay.amt × f0)`; ready when period over (`finance.js:1270-1294`).
  4. *Trip on an operator vehicle without assignment* (ref `trip|<key>` or `<key>|r`): cost = override, else scheduler cost `SCO[key].amt`, else external operator `costTrip` ("company rate").
  5. *Replacement deduction* (`rded|<id>`): replacements where we found the bus (`opBy === 'us'`) for an operator: −(ded + premium), always ready.
  6. *Manual items* (`item|<id>`): signed amount, always ready.
- **Who may act**: `canRun` = not read-only AND (no approvers configured OR my email in `finSet.appr`); `canPrep = !RO` (`finance.js:1370`).
- **Batching**: approving items with pay date d joins the open (no bank file, nothing paid) non-adhoc batch with that pay date, else creates a new one (`finance.js:1428-1434`). Linking school pay runs sets them approved + runId.
- **Batch status**: Paid (paid ≥ total) / Part Paid / Overdue (payDate < today) / Sent to Bank (bank file made) / Scheduled (`finance.js:1387-1391`). Open = no bank file and nothing paid.
- **Payment notices** numbered `PN-YYYY-NNNN` (by pay date year) when the bank file is first made (`issue`, `finance.js:1421-1427`); payTo snapshot taken then.
- **Bank CSV** columns: Value Date, Payee Name, Payment Type, Bank Name, Bank Code, Branch Code, Account Number, Account Name, PayNow Proxy Type (UEN), PayNow Proxy, Amount (SGD), Reference (PN no), Payee Email (`finance.js:1863`). FAST max S$200,000 per bank payment.
- **payTo** (`finance.js:1154-1161`): external operator without default → PayNow UEN; `payDef bank` → bank; else PayNow, else bank, else "Not set".
- **School pay run maker-checker** (`finance.js:1957-2137`, School Bus page): statuses Open/To Check → "With Finance" (ready, `opsBy`) → Approved → Part Paid/Paid; preparer cannot approve when `approval === 'maker'` ("Maker-checker is on. An approver other than <name> approves this"); only approvers approve ("Only an approver can approve: …"; "Add approvers in Finance Settings first"); recall/return/reopen; adjustment types: Taxi claim(−), Replacement bus we arranged(−), Penalty / late arrival(−), Damage(−), Covered another route(+), Extra trips(+), ERP / parking claim(+), Other addition(+), Other deduction(−) (`finance.js:1965`), files ≤3 MB.

### 3.4 Reads → Rails
| Prototype | Rails |
| --- | --- |
| assignment `A {op, vid, pay {b run/day/month, amt}}` | `trip_assignments` (operator_id, vehicle_id, pay_amount, pay_basis) ✅ |
| run cost override `opCost[key]` | `trip_occurrences.operator_cost` + `overridden_fields` ✅ (per run); day/month group overrides → new table |
| scheduler cost `SCO[key].amt`, trip operator cost | `trips.operator_cost`, `trip_occurrences.operator_cost` ✅ |
| operator cancel rule `T.oCx` | `trips.operator_cancel_rule` ✅ |
| external operator costTrip | `operators.cost_per_trip`, `cost_per_day` ✅ |
| replacements opBy/ded/prem | `replacements.arranged_by, deduction, premium` ✅; `school_route_replacements.deduct_from_operator` |
| operator payment details | `operators.payment_method, paynow_uen, bank_id, bank_code, branch_code, account_number, account_name, email` ✅ |
| school payouts | ❌ School Bus |

### 3.5 Sample
`finSample` also seeds sample payouts (`finance.js:333+`, School Bus Collections "Load Sample Data").

### 3.6 Dependencies
Trip sources (2–6), batches, notices, bank file: **buildable now**. School source (1) + per-school pay run page + PV vouchers: **School Bus**.

---

## 4. Documents (`cfdocs`)

HTML `Convoy OS.dc.html:10679-10726`; logic `finance.js:1075-1148`.

- UI: "Documents", school filter (All Schools (N) / each school), intro "Every invoice, credit note, debit note, receipt and payment voucher across the company. For a statement of account, open Documents in the school". Type filter: All, Invoices, Credit Notes, Debit Notes, Receipts, Vouchers, Notices (with counts); search "Search number, name or school". Columns Number, Type (chip), School ("Company-wide" for notices), Date, To, Amount, Status; PDF button. Max 300 rows ("Showing the latest 300 of N documents. Search or pick a school to narrow it down"); empty "No documents match"/"No documents yet".
- Rows: school bills (INV, status from billCalc), `docs` (CN status Applied/Refunded/To Next Bill, DN Issued, RCP Received, Void), payout vouchers PV (Paid), payment notices PN from `opRuns` (Paid/Part Paid/Issued).
- Data: none of its own (union). PDFs: `docView`/`pvView`/`pnView` + `docHtml` (brand header: company name, UEN, GST Reg No., address, phone|email, logo; title "Tax Invoice" when GST on else "Invoice", "Credit Note", "Debit Note", "Official Receipt", footer note).
- Dependencies: PN — with Operator Payments (buildable); everything else School Bus. Client invoices/CNs are not listed (open question 18).

---

## 5. School Bus Collections (`cfcol`)

HTML `Convoy OS.dc.html:10593-10678` (company view), per-school Collections `~7267-7336`; logic `finance.js:115-252, 529-887, 1007-1074`, `fam-inv.js`, `family-bills.js`, policy `school-finance.js:367-583`.

### 5.1 UI (company view)
"School Bus Collections", school filter, intro "Fare bills to families and schools for the School Bus service, across every school. Open a school to record payments, raise bills, or issue credit and debit notes. Invoices to clients for trips are in Client Invoices". KPIs Billed (amt + debit notes, "N bills"), Collected, Outstanding ("N bills not fully paid"), Overdue ("N bills past due and grace", red). By School table (Bills, Billed, Collected, Outstanding, Overdue, Open). Status segmented All/Due/Overdue/Part Paid/Paid/Credited (+counts), search "Search invoice, family or school"; columns Invoice, School, Bill To, Period, Amount, Owed, Due, Status, PDF, Open in school. Max 200 rows. Empty "No invoices yet. Raise bills in each school's Collections".
Per-school page (School Bus menu): period filter, raise bills dialog, record payment (methods PayNow, Bank Transfer, GIRO, Cheque, Cash, Card; "Enter the amount received", "Pick the date received", "Amount is more than the S$x owed"), bulk mark paid ("Tick the bills that were paid"; "N bills marked paid. Receipt <no>"), waive late fee ("Enter the amount to waive", "Enter a reason for the waiver", "You can waive up to S$x"), CN/DN ("Enter what the credit|debit is for", "Enter the amount", "Enter a reason", "Only S$x is owed on this bill. Refund the rest or take it off the next bill"; CN use: "Take off this bill" / "Refund to the payer" / "Take off the next bill"), billing differences (raised vs current fares → Raise Debit/Credit Note), CSV export, family bill drafts (auto N days before due), Load/Clear Sample Data.

### 5.2 Data
- `cfg.bills[sid][]` = `{id, no, ay, pi (period index), ym, label, to {kind school|family|multi, id, name, code, email, uen, addr, att, cid, site}, lines [{t, a, rid, cn}], g {sub, gst, amt, rate, mode}, amt, issued, due, pays [{id, date, amt, method, ref, by, at, rcp, rcpNo}], waives [{id, kind late|other, amt, reason, by, at}], sample}` (`finance.js:760-781`).
- `cfg.docs[sid][]` = CN/DN `{id, type, no, date, inv, to, lines, g, amt, reason, use reduce|refund|carry, refund {date, method, ref}, applied (bill no), void, by, at}`; RCP `{type 'RCP', no, date, to, method, ref, alloc [{inv, no, amt}], amt, void, voidWhy}` (`finance.js:547-578, 700-718`).
- `cfg.fiSet {days (7), start prorate|full|half}`, `cfg.fiDraft[ym][sid]`, `cfg.fiPaid`, `cfg.payM[sid]` payment methods, `cfg.policy[sid].versions[] {v, eff, d {due, late, rem, wd, dep, addr, ack}}`, app payments `localStorage cv-fpay-v1`.

### 5.3 Rules
- Bill status (`billCalc`, `finance.js:115-142`): cnReduce = Σ CN(use reduce); dn = Σ DN; paid = Σ non-void pays; waived other / late; `net = max(0, amt + dn − cnReduce − waivedOther)`; grace date = due + policy.late.grace days; `base = max(0, net − paid)`; overdue when base>0 and today > grace; late fee: pct → `base × pct/100 × max(1, ceil(days/30))`, flat → flat, none → 0; capped by `cap`; `late = max(0, lateRaw − waivedLate)`; `owed = max(0, net + late − paid)`. Status: Credited (net≈0 and amt>0) / Paid / Part Paid / Overdue / Due.
- Due date (`billDue`, 161-166): rule `before` (default 14 days before period start) or `day` (day 1–28 of the billed month).
- Default policy (`school-finance.js:371-389`): due before 14; late grace 7, flat S$20 (or 1%/month), flag after 30 days; reminders 7 days before / on / 3 days after; withdrawal 1 month notice, prorate by days; deposit S$200 offset, registration fee S$50.
- Drafting (`billDraft`, 168-250): payer `bus` (school pays per bus: busRates × buses + route charges), `school` (per rider), `family` (per family, rider fares by distance/zone tier, AM/PM/2-way, small-bus share, size columns, fare adjustments `adjAmt/adjOnce`). Proration for joiners/leavers in `family-bills.js` (start rule prorate/full/half-from-16th; stop basis days). Carry-forward CNs become negative lines on the next bill. GST via `gstOf`.
- Numbering `docNo` max+1 per prefix+year, 4 digits.

### 5.4 Rails
Nothing exists: no families, riders, fares, billing periods, policies, bills. `schools`, `school_plans`, `school_routes` are seed only; `calendars` exist but not term/billing periods.

### 5.5 Sample
`finSample` (`finance.js:333`), "Load Sample Data" button.

### 5.6 Dependencies
**Fully blocked by School Bus** (families, riders, fares, policy, calendars-terms, requests, Convoy App payments).

---

## 6. Vehicle Financials (`vehfin`)

HTML `Convoy OS.dc.html:12163-13048` (page), vehicle record mini card `~15186-15197` (`vmf`); logic `fleet.js:56-1410`, `logic/vehicle-loan.js`, `logic/cpf.js`, `fleet.js:1974-1996` (`vInsCost`), `maint.js:31` (`mtCost`), `fuel.js:48,97` (`flStats`, `flCost`). Backlog row (31/10/2026, fleet) lists the same scope.

### 6.1 UI
Page "Vehicle Financials" + How It Works; intro "What each own vehicle cost and how it is financed. Only people with the Vehicle Financials permission see this page and the Financials section on a vehicle".
- **List** (own vehicles only: `operator_id` null): KPIs "Fleet Purchase Cost", "Still Owed on Loans", "Monthly Instalments", "Due This Month" (`fleet.js:1242-1270`); filter All / Loan / Paid in Full / No Details (`fleet.js:1272`), search plate/make/model/lender; columns plate, status chip, lender ("Paid in full"/"Not entered"), owed, monthly. Empty "No own vehicles yet. Add them in Fleet > Vehicles".
- **Status** (`vfStat`, 66-68): No Details (neutral) / Paid in Full (success) / Incomplete (warning, loan terms missing) / Overdue (danger) / Loan Paid Off (success) / Loan Active (info).
- **Vehicle detail**: purchase kv (Funding Loan/Paid in Full, Purchase Date, Purchase Price, Down Payment), loan kv (Lender, Account, Loan, Rate, Tenure "N months", Term Charge, instalments), progress % paid, schedule table (n, due, amount, interest, principal, balance, status; tick to mark paid/unpaid — "Instalment n marked paid", "N instalments marked paid", "Instalment n marked unpaid"; `fleet.js:1299-1305`).
- **Edit form** (`fleet.js:1385-1405`): Funding (Loan / Paid in Full), Purchase Price (ph 125,000.00), Down Payment (auto price−loan), Purchase Date, Lender (ph "Think One Credit Pte Ltd"), Account (ph "TOC26/0916/117228"), Loan Amount (110,000.00), Rate % (3.58), Tenure months (48), Term Charge (auto), First Instalment Due, First / Monthly / Last instalment (auto). Required for loan: "Loan Amount", "Tenure", "First Instalment Due". Check line: "The instalments add up to S$x, but loan plus term charge is S$y. Check the figures against the schedule". Save: "<plate> financials saved".
- **Upload lender schedule** (PDF/JPG/PNG ≤3 MB: "Use a PDF, JPG or PNG file", "<name> is over 3 MB. Pick a smaller file") → Claude reads (`vfReadAI`, prompt `fleet.js:75`) keys: isSchedule, plate, lender, acct, buyDate, loan, rate, termCharge, tenure, first, monthly, last, firstDue, make, model, chassis, engine, regDate, paid[{n,date}]; fills empty fields and marks paid instalments ("Schedule read. Empty fields are filled in and paid instalments are marked. Check them, then Save"). Plate mismatch: warning "This schedule is for another plate. Use Anyway or Remove File first"; unknown plate → `vfPend` dialog to pick vehicle ("Pick a vehicle first") or create the vehicle (`vfAfterVeh`).
- **P&L view**: period Month / Year to Date / This Year / Last Year / Last 12 Months / All Time; basis **Profit** / **Cash** (`fleet.js:979-982`); 12-month line chart; summary paragraph (`vfSummary`, 843-884); profit bar per vehicle "View by Revenue" / "View by Cost", sort "Weakest First"/"By Plate"; dive (category → client/driver/fuel type → route/company); **Cost per km by Bus Size** (Minibus/Medium Bus/Coach); **Break-even**; **Cost Spikes** (Mark Checked → "Marked as checked"); **Due in the next 90 days**.
- **Manual entries** (`fleet.js:1043-1132`): kind Cost/Revenue; categories rev: School Bus, Charter and Trips, Contract, Other Revenue; cost: Road Tax, Parking and ERP, Cleaning, Other Cost; date, amount ("Enter an amount above zero", "Pick the date"), repeat monthly ("Counted every month from the start date until you stop it" / "Counted once, in the month of the date"), note; revenue confirm dialog "Is This Already Counted?" … "It Is Other Income, Add It" (with "don't ask again" in localStorage); delete repeating: confirm "Delete <cat> from every month it repeats in?"; stop a repeat from a month (`until`).
- **Vehicle record mini** (`vfMini`, 1173-1206): Funding/price/date or lender/loan summary.

### 6.2 Data
`cfg.vfin[vehicleId] = {fund 'loan'|'cash', price, down, buyDate, lender, acct, loan, rate, tenure, termCharge, first, monthly, last, firstDue, file, pays {n: {date, by, at}}, ent [{id, kind rev|cost, cat, date, amt, rep, until, note, by, at}], updAt, updBy}` (`fleet.js:1396-1403`, 1115-1127). `cfg.vfAck {vid|cat|ym: {by, at}}`. `cfg.vfSeedRev` (sample flag).

### 6.3 Rules
- **Loan** (`vehicle-loan.js:9-14`): `tcA = r2(loan × rate/100 × tenure/12)` (flat rate); `tc = termCharge || tcA`; `tot = r2(loan + tc)`; `moA = ceil(tot/ten)`; `mo = monthly || moA`; `first = first || mo`; `laA = ten>1 ? r2(tot − first − (ten−2)·mo) : tot`; `last = last || laA`. Valid when fund≠cash, loan>0, tenure>0, firstDue date. Rows i=1..ten: due = firstDue + (i−1) months (day clamped to month end), amt first/mo/last, interest = tc/ten each (rounding remainder on the last), principal = amt − interest, balance; status Paid (pays[i]) / Overdue (due < today) / Due (same month) / Upcoming. Totals: owed = sched − paid, prinOwed, intPaid, intOwed, next, over, end; down = down || max(0, price − loan).
- **P&L month lines** (`vfPL`, `fleet.js:229-321`):
  - Revenue "<Trip kind> (auto)" (Shuttle for Corporate Shuttle): Σ price of runs on own vehicle, not cancelled, date ≤ today, price>0, last 12 months; drill client → route (`vfTripRev`, 448-473).
  - Revenue "School Bus (auto)": own vehicle running school routes, valued at the route's operator pay (`routeCost`) (`vfSchRev`, 475-498) — **School Bus**.
  - Cost "Insurance Premium (auto)": each policy premium spread evenly over cover months (from..to, max 60; open-ended 12), remainder on last month (`vInsCost`, `fleet.js:1974-1996`).
  - Cost "Fuel and Energy (auto)": Σ fuel entry cost by month, drill fuel type → company.
  - Cost "Maintenance (auto)": completed visits, line amounts × (total incl GST / subtotal), drill line type → description (`maint.js:31`).
  - Manual entries (once or monthly repeat until).
  - Cost "Driver Salary (auto)" + "Employer CPF (auto)": for each month (max 36 back, ≤ current), each default driver of the bus by `vehicle_driver_schedules` history: share = days assigned / days in month; salary = pay-scheme simulation total × share; CPF = `cpf.employer(wage, dob, ym, residency)` × share (`fleet.js:323-352`).
  - CPF (`cpf.js`): only Singapore Citizens/PR; employer rate by age band (≤55, 55-60, 60-65, 65-70, >70): 2025: 17/15.5/12/9/7.5, OW ceiling 7,400; 2026: 17/16/12.5/9/7.5, ceiling 8,000; band moves the month after the birthday; wage ≤ 50 → 0; `amt = round(min(wage, ow) × rate)/100`.
  - Basis **cash**: Purchase (fund cash) or Down Payment in buy month + Loan Instalments by due month. Basis **profit**: Depreciation = price / life months from buy month (life = months to COE expiry, else 120) + Loan Interest by due month.
- **Break-even** (`vfBreak`, 502-536): rev, cost; trip revenue = auto revenue; runs n = completed priced runs; per = tripRev/n; `need = ceil((cost − otherRev)/per)`; gap = cost − rev; "Short by"/"Covered by".
- **Cost spikes** (649-688): cost item this month > 1.5 × median of the previous 6 months (≥3 months with that cost) and ≥ S$100 over; excludes Purchase/Down Payment; ack per vid|cat|ym.
- **Cost/km** (618-707): km = Σ km between fills from Fuel & Energy odometer in period; cost/km, revenue/km, profit/km by size.
- **Due 90 days** (`vfDue`, 538-586): unpaid instalments ≤ today+90 (incl. overdue), insurance renewal at `insTo` (estimate last premium total), road tax expiry (estimate last Road Tax entry ×12 if repeating), COE expiry ("COE expires: renew or deregister").
- Company Dashboard reuses: P&L this vs last month, loans due/overdue (`admin.js:100-119`).

### 6.4 Reads → Rails
| Prototype | Rails |
| --- | --- |
| own vehicles | `vehicles` where `operator_id IS NULL` ✅ (`seats`, `coe_expires_on`, `road_tax_expires_on`, plate, make, model, chassis/engine) |
| runs price | `trip_occurrences.price`, `vehicle_id`, `status`, `date`, `client_id`, `trip_id` ✅ |
| fuel | `fuel_entries.cost, kind, fuel_company_id, odometer, km_since` ✅ |
| maintenance | `maintenance_visits` (status, date, gst_on, gst_rate) + `maintenance_lines` (line_type, quantity, unit_price) ✅ |
| insurance | `vehicle_insurance_policies.premium, gst, total, starts_on, ends_on, insurer, policy_number` ✅ |
| driver history | `vehicle_driver_schedules` ✅ |
| driver pay | HR: `driver_pay_schemes`, `pay_schemes`, `driver_pay_months` (+ runs) ✅ (method TBD) |
| CPF inputs | `driver_kyc_profiles.date_of_birth, residential_status` ✅ (seed only) |
| school route revenue | ❌ School Bus |
| AI read | `document_reads` + `Ai::Extract` + new reader ✅ pattern exists; file via CarrierWave |

### 6.5 Sample
`vfSeedRev` (`fleet.js:1134-1169`): one-off monthly contract revenue on two own vehicles (~25% / 8% above costs). Seed only.

### 6.6 Dependencies
Buildable now except "School Bus (auto)" revenue (needs School Bus). Driver salary needs HR (built) — choose method.

---

## 7. Existing Rails to reuse (summary)
- Tables: `trip_occurrences` (price, trip_value, operator_cost, overridden_fields, operator_id, vehicle_id, client_id, status, cancelled_at, cancelled_by_client, issue_raised_at, replacement_id, trip_assignment_id), `trips` (price, operator_cost, operator_cancel_rule, client_site_id, kind, title, trip_no, booking_ref), `trip_assignments` (operator_id, pay_amount, pay_basis), `replacements` (arranged_by, deduction, premium), `bookings` (po_number, cost_centre — could prefill invoice PO), `clients` (+ `client_sites` own billing, `client_billing_contacts`), `operators` (payment details, cost_per_trip/day), `vehicles`, `fuel_entries`, `maintenance_visits/lines/invoices`, `vehicle_insurance_policies`, `vehicle_driver_schedules`, `driver_kyc_profiles`, `driver_pay_months`, `banks`/`bank_branches`, `company_sequences`, `users` (permissions finance/finview/finset/vehfin), `document_reads`, `audits`.
- `.notes/data-ownership.md`: clients billing → "Finance (billing của client)"; fuel/maintenance → "Finance (Vehicle Financials đọc chi phí)"; trip_occurrences read by Finance (invoice); `driver_pay_months` → "Finance (payroll sau)".
- `.notes/backlog.md`: Vehicle Financials row (fleet, 31/10); "Correct Record chưa đổi pay / invoice" (trips); maker-checker warning with 1 active user (settings); HR payroll/CPF/bank export (hr) — HR payroll is NOT in Finance menu HTML.
- `.notes/decisions.md:30`: skipped occurrences are excluded from invoice and pay.
