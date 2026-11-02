# Finance menu API — Plan

> Bắt đầu 02/11/2026. Scope: `scope.md`, chi tiết HTML: `inventory.md`. Hiện trạng ở `../../domains/finance.md` (tạo mới).
> Mỗi phase: migration + model + policy + blueprint + controller + request spec + seed + `.api-documents/finance.md`.

## Phase 0 — Scope & plan ✅ (02/11/2026)

## Phase 1 — Finance Settings + đánh số ✅ (02/11/2026, xem log/)
- `finance_settings` (1 / company: GST on / rate / mode / reg no, approval single / maker, brand, payment details bank / account / PayNow / note,
  prefixes INV CN DN RCP PV PN PB, lock) + `finance_approvers` (user, can_prepare / can_approve). Validation như HTML.
- `Finance::Numbering.next!(type, date)` (CompanySequence theo type + năm). Cảnh báo maker-checker ở Settings > Users (backlog settings).

## Phase 2 — Client Invoices: billing + Ready to Invoice + drafts ✅ (02/11/2026, xem log/)
- Cột `clients`: payment_terms_days, default_po, late_cancel_hours; Billing Details endpoint.
- `client_invoices` (kind invoice / credit_note, no, client, site, bill-to snapshot, po, date, terms, due, period, GST snapshot, status, notes,
  issued / void by-at), `client_invoice_lines` (src trip / late_cancel / manual), `client_invoice_line_runs` (occurrence identity, amount, waived).
- `ClientInvoices::Billable` (run tính tiền / huỷ trễ / không tính được), Ready to Invoice, Ad Hoc trips, tạo draft (tháng / một trip), sửa, issue, void, xoá draft.

## Phase 3 — Client Invoices: tiền + báo cáo ✅ (02/11/2026, xem log/)
- `client_invoice_payments`, credit note (ref invoice), `client_invoice_sends` (ghi lại). KPIs, aging, tabs, Clients card, Statement of Account.

## Phase 4 — Operator Payments ✅ (02/11/2026, xem log/)
- `Operators::PayDue` (trip / assignment run · day · month / xe operator / replacement deduction / manual item), `operator_cost_overrides`,
  `operator_pay_items`, `operator_pay_batches` (+ operators (PN, pay-to snapshot), lines, payments). Approve + pay date, ad hoc,
  đổi ngày / gộp, huỷ batch, pay / mark all paid, bank file CSV + payment notices.

## Phase 5 — Documents ✅ (02/11/2026, xem log/)
- `GET /finance/documents` (client invoices, credit notes, payment notices) + dữ liệu in từng chứng từ.

## Phase 6 — Vehicle Financials: mua xe + khoản vay ✅ (02/11/2026, xem log/)
- `vehicle_financials` (+ file CarrierWave), `vehicle_loan_payments`, schedule (`Finance::LoanSchedule`, port `vehicle-loan.js`), list KPIs / status,
  reader Claude `VehicleLoanSchedule` + dialog plate không khớp, mini trên record xe.

## Phase 7 — Vehicle Financials: P&L ✅ (02/11/2026, xem log/)
- `vehicle_finance_entries` (manual, lặp tháng), `vehicle_cost_spike_acks`. `Finance::VehiclePl` (doanh thu run, bảo hiểm, nhiên liệu,
  bảo dưỡng, lương driver mô phỏng + CPF, khấu hao / lãi hoặc cash), kỳ, basis, theo xe, break-even, cost/km, cost spikes, due 90 ngày.

## Phase 8 — Docs & kiểm tra ✅ (02/11/2026, xem log/)
