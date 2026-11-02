# Phase 4 — Operator Payments (02/11/2026)

- Khoản phải trả (`OperatorPay::Due`, không lưu): run trên xe operator (3 tháng trước → hết tháng này) theo `trip_occurrences.operator_cost`
  (generator đã chia pay assignment run / day / month cho từng run — khác prototype gom theo ngày / tháng, ready khi run xong),
  fallback `operators.cost_per_trip`; huỷ chỉ khi trip `operator_cancel_rule = full`; replacement `arranged_by us` = −(deduction + premium);
  item tay. Ref `run:<id>:<date>` / `replacement:<id>` / `item:<id>`; loại ref đã vào batch.
- Bảng `operator_cost_overrides` (cost Finance đặt cho run — không ghi vào run đã chạy), `operator_pay_items`, `operator_pay_batches`
  (+ batch_operators (PN, pay_method / pay_to snapshot), lines (ref unique), payments).
- `OperatorPay::Batches`: chỉ approver (hoặc chưa có approver); approve! (gộp batch mở cùng ngày, hoặc batch_id), ad_hoc!, change_date! (merge),
  cancel! (chặn khi có payment), pay!, mark_all_paid!, bank_file! (kiểm chi tiết trả, FAST ≤ 200k, số PN, khoá), `csv`.
- Seed: 1 deduction + batch từ request tháng trước. Spec `finance_operator_payments_spec.rb` (2).
