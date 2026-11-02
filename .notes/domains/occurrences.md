# Occurrences (runs) — hiện trạng

Một run = trip (hoặc School Bus route) × ngày × run shuttle × vehicle slot × part, đã resolve sẵn (giờ, xe, driver, giá).
Scheduler, driver app, invoice, pay, report đều đọc bảng này. Trip / route chỉ là template.
Vì sao materialize (option B) thay vì tính lúc đọc: `menus/scheduler/log/00a-occurrence-storage-comparison.md`.

## Bảng `trip_occurrences`
- `PARTITION BY RANGE (date)` theo tháng, partition `trip_occurrences_yYYYYmMM` tạo lúc chạy (`Occurrences::Partitions.ensure!`,
  daily job tạo trước 3 tháng). Không dùng pg_partman. Schema ở `db/structure.sql`.
- PK `(id, date)`; model `primary_key = :id`. **Bảng con trỏ tới run giữ `(occurrence_id, occurrence_date)` hoặc identity.**
- Identity (unique): `(trip_id, school_route_id, date, trip_run_id, slot_no, part)`; CHECK đúng một trong trip / school_route.
  `part` 2 = phần sau của Handover.
- Cột chính: `run_key`, `client_id`, `kind`, `trip_label` (TID), `start_time` / `end_time` (phút, > 1440 qua đêm), `starts_at` / `ends_at`,
  `shift_minutes`, `pax`, `vehicle_id`, `driver_id` | `operator_driver_id` | `driver_name/phone`, `operator_id`, `original_vehicle_id` (ghost),
  `trip_assignment_id`, `replacement_id`, `status` (scheduled / cancelled / completed / removed), cancel / issue / ended,
  `price`, `trip_value`, `operator_cost`, `overridden_fields` text[], `source_digest`, `lock_version`, `skip_reason`, `cancelled_by_client`.
- `status`: scheduled / cancelled / completed / removed / **skipped** (ngày lịch bỏ qua của trip: PH, day off — giữ cho Trip History, giá 0;
  `visible` loại removed + skipped nên Scheduler, list, pay, invoice không thấy; Edit / Move chặn).
- Index: identity, (company, date), (vehicle, date), (driver, date), (operator_driver, date), unassigned partial, (company, starts_at).

## Layer model (thứ tự resolve)
| # | Layer | Lưu ở | Undo |
| --- | --- | --- | --- |
| 1 | Trip / route template | trips, vehicle slots, run slots; school_route_vehicle_changes, school_route_replacements | sửa template |
| 2 | Assignment | `trip_assignments` (+ slots), mọi loại trip | xoá assignment |
| 3 | Sửa tay trên row | `overridden_fields` (vehicle_id, operator_cost, shift_minutes) | Back to Regular Bus / time reset |
| 4 | Replacement | `replacements` (theo identity run, hoặc range trên xe gốc) | xoá replacement |
| 5 | Status | cancel / issue trên row | Restore / Clear Issue |

- Xe gốc = (3) ?? (2) ?? (1). Driver = lịch default driver của xe gốc ngày đó (managed = operator driver).
- Replacement theo run luôn áp; theo range chỉ áp khi xe gốc ngày đó = `original_vehicle_id`.
- Run huỷ vẫn giữ xe + replacement để Restore về đúng chỗ.
- Spec chạy chuỗi thao tác từng bước: `spec/requests/api/v1/replacements_spec.rb`.

## Engine
- `Occurrences::Generator` (thuần Ruby): áp layer 1–4, nhận row đang lưu làm layer 3. `RouteGenerator` cho School Bus route.
  Ngày chạy qua `Calendars::Context` (load trọn tháng), giá qua `Pricing::TripPrice`.
- `Occurrences::Sync.call(trips:, routes:, from:, to:)`: so `source_digest`, chỉ ghi row khác.
  - Insert thiếu (backfill tối đa 400 ngày), horizon = hôm nay + **120** (`Sync::HORIZON_DAYS`). **Không bao giờ lưu row sau horizon.**
  - **Không đụng row đã bắt đầu.** Row không còn sinh ra: xoá; có dữ liệu phụ thuộc (issue, sửa tay, cancel) → `removed`.
  - Chỉ đụng tới khoảng `from..to` được gọi (to bị kẹp ở horizon). `pg_advisory_xact_lock` theo trip.
- **Không có run virtual** (bỏ 30/10/2026): sau horizon không có row, Scheduler / list chỉ đọc bảng (`OccurrenceWindow`),
  user không xem / thao tác quá horizon. Thay đổi cho tương lai là **rule** (assignment, range replacement, time change,
  calendar, PH, driver schedule, trip) nên tự áp khi daily job thêm ngày mới. Preview replacement chỉ đếm run tới horizon.
- Daily job sync ngày horizon cho **mọi trip chạy ngày đó** (`active_between`, gồm trip một lần đặt xa) + route đang chạy.
  Job không chạy thì rìa grid thiếu ngày → theo dõi job, chạy `occurrences:verify`.
- Generator sinh cả row skipped (`Calendars::Context#trip_skips`); Sync đổi skipped ↔ scheduled khi lịch đổi (trừ status người đặt).
  School Bus route không sinh skipped.
- Thứ không đọc bảng mà tính bằng generator: Next 12 Months (School Run), Assign page (`Assignments::Board`), verify.
- "Every Run From Today" = `trip_time_changes` (không tách series). "From This Date On" (kéo thả / Assign page) = assignment.
- Thao tác trên run: `Occurrences::Edit` (cancel, restore, issue, time), `Move` / `MovePreview` (+ `Members` = Runs That Move Together),
  `SchoolRoutes::Move`, `BusPattern`, `ShareTracking`.
- Lịch sử thao tác = audits (gắn trip), không có bảng event riêng.
- Trip History: `GET /trip_history` (`TripHistoryQuery`: completed / cancelled / skipped tới hôm nay), record `TripHistory::Record`,
  notes `occurrence_notes`, driver report `occurrence_driver_reports` (+ photos), trỏ run bằng (occurrence_id, occurrence_date).
- Correct Record (`TripHistory::Correct`): giá trị đã sửa nằm ở `occurrence_corrections` (+ `_stops` theo position, `_logs`),
  **không ghi vào trip_occurrences**; `TripHistory.outcome / driver_name / vehicle` và SQL trong `TripHistoryQuery` đọc
  giá trị đã sửa trước — giữ hai bản khớp nhau.
- Telematics: `occurrence_positions` (partition tháng như trip_occurrences, cùng `Occurrences::Partitions`),
  `occurrence_stop_events`, `occurrence_trip_summaries`; ghi qua `Telematics::Record`. `trip_occurrences.max_delay_minutes`
  là cache On Time (`TripHistory::Punctuality`, gọi sau telematics và Correct Record) — không thuộc digest / Sync.
- Trang Trips: `GET /occurrences/list` qua `RunSearch` (status_group = `TripOccurrence#status_group` / `RunSearch::STATUS_SQL`, giữ hai bản khớp nhau).

## Quy tắc
1. **Chỉ service ghi occurrence**, không ghi từ controller / callback.
2. Thay đổi nhỏ (1 trip) sync inline cùng transaction; thay đổi lan rộng → job sau commit.
3. Gửi `lock_version` → 409 khi lệch.
4. Thêm nguồn dữ liệu mới ảnh hưởng run → thêm vào digest + một dòng bảng trigger dưới đây + spec.

## Trigger sync
| Thay đổi | Cách |
| --- | --- |
| Tạo / sửa / xoá trip (`Trips::Save`) | inline |
| Assignment, kéo thả, replacement, time change | inline trong service |
| Public holiday, calendar day, calendar observed / sessions, company observed_holidays | after_commit → `OccurrenceSyncJob` |
| Default driver schedule, operator driver gán xe | `OccurrenceDriverJob` (chỉ driver của run chưa bắt đầu) |
| Hằng ngày 01:30 | `OccurrenceDailyJob`: partition, đẩy horizon, complete, purge School Run, xoá tracking link cũ |
| Mỗi 5 phút | `OccurrenceCompleteJob` |
| Maintenance visit | không sync, chỉ cảnh báo clash |

Kiểm tra: `bin/rails occurrences:verify` (so generator vs DB), `occurrences:sync`, `occurrences:daily`.

## Chưa làm
- Bulk actions nhiều run một lần (`POST /occurrences/bulk`) — HTML chưa có.
- Trả `conflicts` khi rule mới phủ lên run đã sửa tay (hiện: sửa tay luôn thắng).
