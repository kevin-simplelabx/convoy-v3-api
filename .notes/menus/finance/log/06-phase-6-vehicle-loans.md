# Phase 6 — Vehicle Financials: mua xe + khoản vay (02/11/2026)

- Bảng `vehicle_financials` (1 / xe own; funding loan / cash, giá, down, ngày, lender, account, loan, rate, tenure, term charge,
  first / monthly / last, first due; `schedule_file` CarrierWave; document_read), `vehicle_loan_payments` (instalment_no unique).
  Tạo luôn `vehicle_finance_entries`, `vehicle_cost_spike_acks` (Phase 7).
- `Finance::LoanSchedule` (port `vehicle-loan.js`: term charge flat, monthly ceil, last = phần còn lại, lãi chia đều, ngày cộng tháng
  kẹp cuối tháng (`Date#>>`), status paid / overdue / due / upcoming, tổng owed / principal / interest, check lệch).
- Reader `Ai::Readers::VehicleLoanSchedule` (+ `DocumentRead::READERS`); `VehicleFinance::Save` điền ô trống từ bản đọc, đánh dấu kỳ đã trả,
  plate khác → 422 trừ khi `use_anyway`.
- `VehicleFinancialsController` (index KPIs / filter / q, show, update, instalments). Record xe `financials` (chỉ user `vehfin`) — đổi
  từ `null` (spec fleet cập nhật). Seed: 1 xe vay (đã trả tới tháng trước), 1 xe trả đủ. Spec `finance_vehicle_financials_spec.rb` (2).
