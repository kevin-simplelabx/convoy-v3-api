# Phase 4 — Bookings: dữ liệu + form (30/10/2026)

- Migration `20261030170000_create_bookings`: `bookings` (number unique / company, client, site, end customer, coordinator_*,
  PO, cost centre, notes, source console / portal / app, estimate_amount, lock_version), `booking_days` (unique booking + date),
  `booking_trips` (booking_id denormalize để query; kind one_way / two_way / disposal / airport, status, giờ phút, airport, pax,
  luggage theo size như trips, contact, note, distance_km / return_distance_km từ FE, estimate_amount + estimate_lines jsonb snapshot),
  `booking_trip_points` (leg out / back, position, use, pin, note), `booking_trip_standbys` (leg), `booking_trip_vehicles`, `booking_attachments`.
- Status trip: `pending`, `awaiting_ack` (HTML `changed`; đổi tên vì enum `changed` đụng `changed?` của AR), `awaiting_client`,
  `approved`, `rejected`. Tab booking tính bằng SQL (`Booking::STATS_SQL` / `TAB_SQL`) và Ruby (`#tab`), giữ khớp.
- Way back: chỉ lưu khi đổi (leg back ≥ 2 điểm); không thì đảo way there (port `Convoy.route.back`).
- `RateCards::Pricer` tách từ Quote (period, leg, distance, stop, disposal km, M&G); `Bookings::Estimate` port `rcPrice` / `bkEst`
  (Two Way xa > 200 m → 2 one-way; khác HTML: thiếu rate ở bất kỳ leg nào cũng đếm `without_rate`).
- `Bookings::TripBuilder` (dùng cho Save và `POST /bookings/estimate`), `Bookings::Save` (thay toàn bộ, khớp id, trip locked giữ nguyên,
  đổi ngày qua chỗ trống tạm để giữ unique, luật + câu báo như `bkFormVals.save`).
- Số booking: `company.code` + YY + 6 số, `company_sequences` `booking_YY` (HTML lấy chữ hoa của tên ngắn).
- Chưa làm (Phase 5): approve → Scheduler trip, change history + client ack, reject, cancel request, chuông; nhãn Unassigned / Assigned.
- Seed `46_bookings` (Google 3 ngày pending, DBS awaiting_ack, MBS rejected, Tan Family airport arrival + M&G).
- Spec `bookings_spec.rb` (6). Tổng 170 specs.
