# Pay (HR) — hiện trạng

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| pay_rate_plans (+ vehicle_types, periods, period_ranges, rates) | rate theo type × ngày (mon..sun, ph) × giờ; period priority; lock; discard |
| pay_schemes (+ route_bands, volume_tiers, target_tiers) | 3 loại; 1 default / company; lock; discard |
| driver_pay_schemes, driver_vehicle_types | gán theo ngày, không chồng (`DatedAssignment.recut!`), lùi ≤ 1 tháng |
| pay_bonuses (+ tiers, payments, schemes, drivers, excluded_periods) | trip_target / reliability_*; lock; discard |
| driver_pay_months (+ lines, runs) | tháng đã confirm (snapshot); runs giữ `(occurrence_id, occurrence_date)` |
| driver_point_lots, driver_point_deductions, driver_point_allocations | sổ điểm FIFO, lô 24 tháng |
| pay_rewards | photo CarrierWave ≤ 2 MB; active / inactive |
| pay_simulator_templates | 5 slot / company, jobs + routes jsonb |

## Quy tắc
- Engine `Pay::Engine` (port `DP.simulate`) + `Pay::Month` (chia tháng theo scheme, pro-rate fixed pay / guarantee / retainer / mục tiêu tháng).
- Earnings `Pay::DriverMonth`: run completed (đã chạy, không issue) của driver trên xe own; giờ cho disposal / trip theo giờ (0.25); type theo assignment hoặc xe.
- Bonus `Pay::Bonuses`: Trip Target daily / weekly / monthly thật; reliability chỉ simulator; overlap additive / supercede / prevail.
- Confirm: snapshot + điểm bonus → lô; raise / clear issue run của tháng đã confirm → 422; Reopen xoá snapshot + lô bonus (chặn nếu đã dùng).
- Quyền: xem finance / finview; ghi finance; unlock / reopen admin hoặc `users`. Audit Log đọc `audits` (`Pay::AuditLog`).
- Route `/pay/...` với controller `pay_*` (không dùng namespace `Pay` vì trùng module service).

## Seeds
`70_pay`: Standard (locked), Basic + Trips (default, locked) + Monthly 2,400, gán scheme / type, template, tháng trước đã confirm,
2 bonus, điểm + rewards.
