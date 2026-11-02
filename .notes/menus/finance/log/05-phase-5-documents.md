# Phase 5 — Documents (02/11/2026)

- `Finance::Documents` (không bảng riêng): client invoice / credit note có số + payment notice (batch operator có PN), lọc type / q,
  300 mới nhất, `counts`. `FinanceDocumentsController`: index, payment_notice (dữ liệu in), brand (header / footer + payment details + logo).
- In = FE (không gem PDF). Chứng từ School Bus để menu School Bus. Spec thêm vào `finance_operator_payments_spec.rb`.
