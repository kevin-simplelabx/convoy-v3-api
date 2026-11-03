# Phase 6 — CCA Rides (03/11/2026)

- Bảng: `cca_ride_settings` (1 / trường: enabled, price, days[] 1–5, seats), `cca_bookings` (family, rider?, bill, child, class, date, price, paid_on,
  method, late, not_riding; unique family + child + date), `cca_off_days` (trường + ngày, reason, by), `cca_credits` (family, booking, amount, reason),
  `school_bill_lines` (dòng bill, credit âm); `school_bills` thêm kind `cca`, gross, credit_used, week_of.
- `CcaRides` (port cca.js): cut-off = thứ Bảy trước tuần 23:59, phase past / today / late / open, credit = tổng credit − credit đã dùng, giá Bus Fares
  (CCA per trip fixed của năm hiện tại → khoá giá), calendar (ngày không học: tên holiday; special day), week (ngày CCA của tuần, rider, trạng thái,
  Bus Not Running / No School, KPI: rides, collected, late, not riding, credit given), default_week.
- `SaveSettings` (kiểm như HTML), `NotRunning` (lý do school / weather / bus / other / no_school + note; mỗi ride → credit; 1 lần / ngày),
  `Pay` (phía Convoy App — dùng cho seed / spec: chỉ tuần sau, đúng ngày CCA, không trùng, ngày không chạy, late còn ghế; 1 bill CCA paid / lần trả,
  dòng theo con, trừ credit trước).
- API: `GET /schools/:id/cca_rides?week_of=`, `PUT /schools/:id/cca_rides`, `POST /schools/:id/cca_rides/not_running`. Quyền: xem show?, sửa setup?.
- Same Days Every Week, Not Riding, đặt / trả: Convoy App (backlog). Seed: S$8 Thứ 3 / 5, tuần trước (Thứ 5 mưa → credit), tuần sau. Spec 1.
