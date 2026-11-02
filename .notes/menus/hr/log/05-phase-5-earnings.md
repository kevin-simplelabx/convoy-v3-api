# Phase 5 — Earnings (02/11/2026)

- `Pay::DriverMonth`: run của driver trong tháng (`visible`, xe own hoặc không xe), status completed (đã chạy, không issue) /
  issue / running / upcoming / cancelled. Job: trip (trip_value) hoặc theo giờ (kind disposal hoặc trip `trip_value_mode = hours`,
  giờ làm tròn 0.25 theo `trip_value_rounding`). Vehicle type: assignment ngày đó, không thì type của xe run (seats).
  Route retainer: route run thật là job `route: true` (engine `route_days: false` → đếm như trip, trả 0), routes = route đã chạy trong tháng.
- `Pay::ConfirmMonth` + `blocker` (đã confirm / tháng chưa hết / không scheme / còn issue). Snapshot: `driver_pay_months`
  (+ `driver_pay_month_lines` theo đoạn, `driver_pay_month_runs` với `(occurrence_id, occurrence_date)`). Audit comment Confirmed / Reopened.
- `Occurrences::Edit` raise / clear issue → 422 khi tháng của driver đã confirm (đổi hành vi endpoint cũ, ghi ở hr.md § Changes).
- `PayEarningsController` index (driver active + driver có run trong tháng, meta tổng), show, confirm, reopen (admin).
  Export Statement = FE in từ dữ liệu detail.
- Seed: confirm tháng trước cho driver đầu tiên đủ điều kiện. Spec `hr_earnings_spec.rb` (2). Tổng 268 specs.
