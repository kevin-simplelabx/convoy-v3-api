# HR menu API — Plan

> Bắt đầu 02/11/2026. Scope: `scope.md`, chi tiết HTML: `inventory.md`. Hiện trạng ở `../../domains/pay.md` (tạo mới) khi phase xong.
> Mỗi phase: migration + model + policy + blueprint + controller + request spec + seed + `.api-documents/hr.md`.
> Tiền decimal(12,2), giờ trong ngày = phút (`MinuteTime`). Gem mới: không.

## Phase 0 — Scope & plan ✅ (02/11/2026)

## Phase 1 — Rate Plans ✅ (02/11/2026, xem log/)
- `pay_rate_plans` (company, name, description, locked_at, locked_by, discard), `pay_rate_plan_vehicle_types`,
  `pay_rate_periods` (plan, name, days string[] mon..sun ph, takes_priority, position), `pay_rate_period_ranges` (start / end phút),
  `pay_rates` (period, vehicle_type, per_trip, per_hour).
- Lưu cả plan một lần (`PayRatePlans::Save`, thay nested), validation như HTML; lock / unlock; xoá chặn khi scheme dùng / đang lock.
- `Pay::RateLookup` (port `DP.period`, qua nửa đêm, PH, priority). `GET /pay/rate_plans/:id/coverage` (8 × 48 ô + gaps + rates trống).
- Policy `PayPolicy` dùng chung (xem / ghi / unlock). Seed "Standard".

## Phase 2 — Pay Schemes ✅ (02/11/2026, xem log/)
- `pay_schemes` (cột theo inventory § 2.3, enum type, rate plan FK, default unique / company, lock), `pay_scheme_route_bands`,
  `pay_scheme_volume_tiers`, `pay_scheme_target_tiers` (weekly / monthly). CRUD lưu cả scheme, default, lock, xoá (giữ ≥ 1, không xoá default).
- Seed "Basic + Trips" (như HTML).

## Phase 3 — Drivers (pay assignments) ✅ (02/11/2026, xem log/)
- `driver_pay_schemes` (driver, scheme, starts_on, ends_on), `driver_vehicle_types` (driver, vehicle_type, starts_on, ends_on);
  không chồng (assignment mới cắt cái trước), start lùi tối đa 1 tháng.
- `GET /pay/drivers` (own drivers active: plate, age KYC, scheme hôm nay, cảnh báo rate trống), CRUD assignments.
- `Pay::DriverTerms`: đoạn ngày (scheme, plan, vehicle type) của một driver trong tháng (mặc định scheme default khi không có assignment).

## Phase 4 — Pay engine + Salary Simulator ✅ (02/11/2026, xem log/)
- `Pay::Engine` (port `DP.simulate`, inventory § 8.3) nhận đoạn tháng → breakdown, ngày, tuần, dòng job; pro-rate fixed pay theo ngày lịch.
- `POST /pay/simulate` (scheme, vehicle type, month, jobs, routes, holidays, rejected, otp, attendance) + bonus trong simulator.
  `GET /pay/simulate/sample?month=` (Fill Sample Month). `pay_simulator_templates` (5 ô, jobs jsonb).

## Phase 5 — Earnings ✅ (02/11/2026, xem log/)
- `Pay::MonthJobs` (run đã chạy của driver trong tháng → job trip / giờ), `Pay::DriverMonth` (engine + bonus).
- `GET /pay/earnings?month=&q=` (tổng, trạng thái Confirmed / Held / To Confirm / Open), `GET /pay/earnings/:driver_id?month=` (runs + breakdown).
- `driver_pay_months` (driver, month, total, trips, confirmed_by / at) + `driver_pay_month_lines` + `driver_pay_month_runs`
  (identity occurrence, amount). Confirm / Reopen (admin). Chặn raise / clear issue run của tháng đã confirm.

## Phase 6 — Bonuses ✅ (02/11/2026, xem log/)
- `pay_bonuses` (+ tiers, eligible schemes, eligible drivers, sign-ups, excluded periods, payout trenches); CRUD, lock, period options.
- Bonus trong simulator (như HTML) và Trip Target thật trong `Pay::DriverMonth` (deconfliction).

## Phase 7 — Points & Rewards ✅ (02/11/2026, xem log/)
- `driver_point_lots` (+ / hết hạn 24 tháng, nguồn manual / bonus) + `driver_point_entries` (deduct) + phân bổ FIFO; balance, earned,
  used, expired, sắp hết hạn 60 ngày. Award / Deduct. Bonus points vào sổ khi confirm tháng.
- `pay_rewards` (photo CarrierWave ≤ 2 MB, points, active).

## Phase 8 — Audit Log ✅ (02/11/2026, xem log/)
- `GET /pay/audit_log` từ `audits` của model HR (action, item, tên, chi tiết, người, giờ), lọc search / action / item.

## Phase 9 — Docs & kiểm tra ✅ (02/11/2026, xem log/)
- `.api-documents/hr.md`, integration, screen-map, README, OpenAPI; domains `pay.md`, data-ownership, backlog; kiểm tra đủ.
