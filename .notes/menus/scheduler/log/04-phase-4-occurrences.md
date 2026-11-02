# Phase 4 — Occurrence engine ✅ (30/10/2026)

## Bảng `trip_occurrences` (partition theo tháng)
- `PARTITION BY RANGE (date)`, partition `trip_occurrences_yYYYYmMM` tạo lúc chạy (`Occurrences::Partitions.ensure!`), không nằm trong structure.sql.
- PK `(id, date)` (PG bắt buộc gồm cột partition). Model dùng `primary_key = :id`; **bảng con trỏ tới occurrence phải giữ `(occurrence_id, occurrence_date)`** (FK composite).
- Schema chuyển sang **db/structure.sql** (schema.rb không mô tả được partition).
- Cột: date, trip, run (trip_run_id + run_key), slot_no, part (2 = handover), client, kind, trip_label (TID),
  start_time / end_time (phút, > 1440 qua nửa đêm), starts_at / ends_at (timestamptz), shift_minutes, pax,
  vehicle, driver (own) / operator_driver, operator, original_vehicle (ghost, Phase 6), status scheduled / cancelled / completed / removed,
  cancelled_at/by, ended_at, issue_reason/at/by, price, trip_value, operator_cost, overridden_fields, source_digest, lock_version.
- Index: identity unique (trip, date, run, slot, part), (company, date), (vehicle, date), (driver, date), (operator_driver, date), unassigned partial, (company, starts_at).

## Engine
- `Occurrences::Generator` (thuần): ngày chạy (Calendars::Context.trip_dates) × run × slot → times (calendar shift + time change), xe (Vehicle for Each Run > vehicle slot; assignment / replacement thêm ở Phase 5 / 6), driver (default driver schedule; managed = operator driver), giá (Pricing::TripPrice), trip value (run > return > trip; per day chia số run), operator cost (xe không phải own), TID (shuttle: `TID…-k`, k = run × xe).
- `Occurrences::Sync`: insert thiếu (kể cả quá khứ, backfill tối đa 400 ngày), không bao giờ sửa row đã bắt đầu, update row tương lai khi digest đổi (giữ `overridden_fields`), row không còn: xoá, hoặc `removed` khi có issue / sửa tay / cancel. Advisory lock theo trip. Horizon = hôm nay + 90 ngày. Row đã materialize xa hơn horizon vẫn được cập nhật.
- `Occurrences::Fleet`: driver của xe theo ngày, operator, own? (load 1 lần).
- Kiểm chứng: `rake occurrences:verify` (so generator với DB, không sửa gì), `rake occurrences:sync`, `rake occurrences:daily`.

## Khi nào sync
| Thay đổi | Cách |
| --- | --- |
| Tạo / sửa trip (Trips::Save) | inline, cùng transaction |
| Xoá trip | inline từ hôm nay |
| Public holiday | after_commit → OccurrenceSyncJob (trip lặp lại có skip_public_holidays) |
| Calendar day | after_commit → job (trip dùng calendar, các ngày đổi) |
| Calendar observed / sessions | after_update_commit → job |
| Company observed_holidays | after_update_commit → job (trip không có calendar) |
| Default driver schedule | after_commit → OccurrenceDriverJob (chỉ driver_id của run chưa bắt đầu) |
| Hằng ngày 01:30 | OccurrenceDailyJob: partition 3 tháng tới, đẩy horizon 1 ngày, complete |
| Mỗi 5 phút | OccurrenceCompleteJob: run đã hết giờ → completed |
(config/recurring.yml, production / solid_queue)

## Thay HTML: Every Run From Today
HTML tách series thành 2 trip. Rails lưu **`trip_time_changes`** (trip, effective_from, minutes, run tuỳ chọn); generator áp change mới nhất ≤ ngày.
Không nhân bản trip, Trip ID giữ nguyên, lịch sử rõ ràng.

## API
- `GET /api/v1/scheduler?from=&to=` (+ filters xe: ownership[] size[] tags[] vip team_id q sort; tối đa 42 ngày):
  `data { vehicles, occurrences (có xe), unassigned }`, `meta { horizon, facets, unassigned_before, unassigned_after }`.
  Ngày sau horizon → run **virtual** (`id: null, virtual: true`, có `key` = trip|date|run|slot|part).
- `GET /api/v1/occurrences` (date | from+to, driver_id, operator_driver_id, vehicle_id, trip_id, client_id, status, unassigned) — trip hôm nay / ngày mai / 1 ngày của driver.
- `GET /api/v1/occurrences/:id` (drawer: run + trip full + changes từ audits).
- `POST /api/v1/occurrences { trip_id, date, trip_run_id, slot_no }`: materialize run virtual trước khi thao tác.
- `PATCH :id/cancel`, `PATCH :id/restore`, `POST :id/issue { reason }` (chỉ run đã xong), `DELETE :id/issue`,
  `PATCH :id/time { scope: today | from_here | reset, start_time }`. Gửi `lock_version` → 409 khi người khác vừa sửa.
- `grid_status`: cancel / cancel_unassigned / done / unassigned / live / replaced / ok.
- Lịch sử thao tác trên run = audits (audited, gắn trip) → không cần bảng occurrence_events riêng.

## Số liệu seed
1.402 run (SimpleDrive), sync 2,2 s; chạy lại 0 thay đổi; verify: all match; tuần Scheduler 0,87 s (dev).

## Specs
115 examples (thêm 15): sync (backfill, idempotent, không đụng quá khứ, giữ override + cancel, removed, calendar shift + time change, PH + driver job, nhãn shuttle, daily), API (grid, virtual + materialize, run của driver, cancel / restore / 409, time today / from_here / reset, issue, xoá trip).
