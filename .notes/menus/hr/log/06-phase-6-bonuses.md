# Phase 6 — Bonuses (02/11/2026)

- Inflection `bonus` → `bonuses` (Rails giữ "bonus"). Bảng `pay_bonuses` (+ tiers, payments (split), schemes (eligible), drivers
  (role eligible / signed_up, signed_up_by), excluded_periods). `PayBonus#ends_on`, `status`, `tier_for`.
- `PayBonuses::Save` (list gửi thì thay; validation như HTML + reliability chỉ monthly+), `Pay::BonusPeriods` (port `payPeriods`).
- `Pay::Bonuses`: Trip Target daily / weekly (tuần thứ 2 – CN trong tháng) / monthly từ số trip theo ngày của engine; reliability chỉ
  simulator (OTP / attendance nhập tay, monthly); quarterly+ không tính; overlap additive / supercede (adjust = −incentive scheme) / prevail;
  paid_now khi end_of_period / next_payroll. Earnings: kiểm eligible driver + sign-up; `Out#total` = scheme + bonus paid_now;
  Confirm lưu dòng "Bonus: …". Simulator: `total_with_bonuses`.
- Seed: Year-End Trip Bonus (monthly, locked) + On-Time Quarter (sign-up, split). Spec `hr_bonuses_spec.rb` (2).
