# Phase 2 — Client Invoices: billing + Ready to Invoice + drafts (02/11/2026)

- `clients`: payment_terms_days (nil = 0 individual / 30), default_po, late_cancel_hours (24). Billing Details `/finance/billing/:client_id`;
  `ClientBillingContact.replace!` dùng chung cho site và client.
- Bảng `client_invoices` (kind invoice / credit_note, status draft / issued / void, number unique khi có, bill-to + GST snapshot, totals),
  `client_invoice_lines` (trip / late_cancel / manual), `client_invoice_line_runs` (occurrence identity, waived, `active` + partial unique
  = một run chỉ trên một hóa đơn chưa void). Tạo luôn `client_invoice_payments`, `client_invoice_sends` (Phase 3).
- `ClientInvoices::Billable` (entity client / site own billing; huỷ trễ chỉ khi `cancelled_by_client` trong cut-off — user chốt; blocked với lý do),
  `Draft` (tháng hoặc trip), `Edit` (update draft: field, manual lines, remove lines, waive; issue! đánh số `Finance::Numbering`; void! trả run; destroy!).
- Ready to Invoice, Ad Hoc (trip không lặp, 90 ngày, còn run chưa bill, tối đa 12), tabs có `meta.counts`.
- Seed: 1 hóa đơn issued + 1 draft tháng trước. Spec `finance_client_invoices_spec.rb` (3).
