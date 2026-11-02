# Phase 8 — Telematics: bảng + seed (31/10/2026)

- Migration `20261031110000`:
  - `occurrence_positions` partition tháng theo `occurrence_date` (cùng `Occurrences::Partitions`, TABLES = trip_occurrences +
    occurrence_positions), PK (id, occurrence_date), btree (occurrence_id, occurrence_date, recorded_at) + BRIN recorded_at.
    lat / lng double, speed_kmh real, heading smallint. Không FK tới trip_occurrences (như các bảng con khác).
  - `occurrence_stop_events` (theo position: arrived_at / departed_at timestamptz, skipped, boarded, alighted; không có row = không phục vụ).
  - `occurrence_trip_summaries` (1 / run): started / ended, distance, odometer, idle_seconds, max / avg moving speed,
    overspeed_seconds + speed_limit_kmh lúc tính, harsh_events, ping_count / interval, fuel_used / unit / estimated.
  - `trip_occurrences.max_delay_minutes` (cache cho On Time, `TripHistory::Punctuality`, update_columns) — lọc On Time bằng SQL
    với ngưỡng công ty mà không cần tính lại khi đổi ngưỡng. `companies.speed_limit_kmh` (mặc định 80).
- `Telematics::Record` (thay dữ liệu cũ của run: pings insert_all, stop events, rồi Summarize + Punctuality) — seed dùng;
  endpoint ingest làm cùng driver app. `Telematics::Summarize`: haversine, moving > 2 km/h, harsh = đổi tốc > 1.8 km/h/s,
  idle = đứng yên ngoài khoảng dừng ở stop, fuel ước tính 0.32 L/km (> 30 chỗ) hoặc 0.14.
- `TripHistory.stop_record` (planned vs actual, corrected trước; served / skipped / delay / late / on_board / was),
  `recorded_stops` từ stop events (phút của ngày run = start_time + (t − starts_at)), `on_time`, `pax` (boarded nếu biết).
  Correct Record gọi Punctuality → giờ đã sửa tính On Time.
- Query: ON_TIME theo max_delay_minutes + ngưỡng; distance từ summary; Needs a Look thêm Incomplete + overspeed.
- Record: `on_time_minutes`, `stops` mở rộng, `stop_summary`, `has_track`, `speed`, `driving_summary`, log "PD1A started /
  arrived (x min late) / departed / skipped / ended". `GET /trip_history/:id/track` (columns + rows cho map / replay / chart).
- Seed `93_telematics.rb`: 3 run gần nhất của 4 trip seed (12 run, ~2.000 ping), 1 run trễ 9 phút, 1 run vượt 80 km/h.
- Spec: `trip_history_spec.rb` thêm 1 case (record → on time, distance, summary, track, correction làm Late).

Khác HTML: tên đường (Road) trong replay không lưu; Ops on Duty / Incident Report / Client Feedback / Conditions chưa làm.
