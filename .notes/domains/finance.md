# Finance — hiện trạng

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| finance_settings, finance_approvers | 1 / company: GST, approval single / maker, brand, payment details, prefix 7 loại, lock |
| clients (payment_terms_days, default_po, late_cancel_hours) | billing terms; người nhận = `client_billing_contacts` |
| client_invoices (+ lines, line_runs, payments, sends) | invoice / credit_note; draft → issued → void; GST snapshot; run trên tối đa 1 hóa đơn chưa void |
| operator_cost_overrides, operator_pay_items, operator_pay_batches (+ batch_operators, lines, payments) | khoản trả operator, batch theo ngày trả, PN, CSV |
| vehicle_financials (+ vehicle_loan_payments), vehicle_finance_entries, vehicle_cost_spike_acks | mua xe / khoản vay, entries tay, spike đã xem |

## Quy tắc
- Đánh số: `Finance::Numbering.next!(type, date:)` = CompanySequence `doc:<type>:<year>` → `PREFIX-YYYY-000001`.
- Client Invoices: `ClientInvoices::Billable` (run tới hôm nay, price > 0, không issue; huỷ trễ chỉ khi `cancelled_by_client` trong cut-off; entity
  = site own billing hoặc client), `Draft`, `Edit` (issue / void / destroy), `Money` (pay / credit / send), `Report`.
- Operator Payments: `OperatorPay::Due` (run operator theo `operator_cost` / override / cost_per_trip; replacement arranged_by us; item) và
  `OperatorPay::Batches` (chỉ approver; batch mở theo ngày; bank file đánh số PN). Maker-checker chỉ áp cho pay run trường (chưa làm).
- Vehicle Financials: `Finance::LoanSchedule`, `Finance::VehiclePl` (live), `Finance::VehicleReport`, `Finance::Cpf`; reader `VehicleLoanSchedule`.
- Documents: `Finance::Documents` (union, không bảng). In PDF = FE.

## Seeds
`75_finance`: settings + approvers, hóa đơn issued (trả 1 nửa) + draft, batch operator, xe vay + xe trả đủ, entries.
