# Phase 1 — Rate Plans (02/11/2026)

- Bảng `pay_rate_plans` (company, name unique kept, description, locked_at / by, discard), `pay_rate_plan_vehicle_types`,
  `pay_rate_periods` (days string[] mon..sun ph, takes_priority, position), `pay_rate_period_ranges` (phút), `pay_rates`
  (per_trip, per_hour; null = 0). Bảng con không có company_id (đi qua plan).
- Concern `PayLockable` (dùng lại cho scheme, bonus): lock / unlock, `ensure_unlocked!`, audited chỉ create / destroy, update ghi
  `audits` bằng `log_audit!(comment)` (Saved: …, Locked, Unlocked) → Audit Log Phase 8.
- `PayRatePlans::Save`: thay cả plan (periods tạo lại), validation như HTML; `lock: true` = Save and Lock.
- `Pay::RateLookup` (port `DP.period`: ph label, qua nửa đêm thuộc ngày bắt đầu, phút ≥ 1440 sang ngày sau, priority), `Pay::Coverage`
  (8 × 48 ô, gaps, rate trống). `PayPolicy` (xem finance / finview, ghi finance, unlock / reopen admin hoặc `users`).
- Route `scope "pay"` + controller `pay_*` (tránh namespace `Api::V1::Pay` trùng module service `Pay`).
- Seed `70_pay`: Standard (4 period, mọi type đang offer, đã lock). Spec `hr_rate_plans_spec.rb` (3).
