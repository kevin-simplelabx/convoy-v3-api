# Phase 7 — Correct Record (31/10/2026)

- Migration `20261031100000`: `occurrence_corrections` (1 dòng / run, unique (occurrence_id, occurrence_date): outcome
  completed | incomplete, vehicle_id + vehicle_plate, driver_id + driver_name, lock_version; nil = như đã ghi),
  `occurrence_correction_stops` (theo `position` trong thứ tự chạy + `stop_name` chụp lại: arrived_at / departed_at phút,
  boarded / alighted), `occurrence_correction_logs` (user, reason, `items text[]` dạng "Stop 1 arrival: N/A to 08:03").
  Giá trị đã sửa ở cột → query / thống kê được; lịch sử chỉ để đọc nên dùng text[] (như `booking_trip_changes`).
- `TripHistory::Correct`: chỉ run `completed`; field bỏ trống = giữ nguyên; bắt buộc lý do; "Nothing has changed"; đặt lại
  đúng giá trị đã ghi → xoá correction của field đó (lịch sử vẫn giữ, run vẫn Needs a Look); plate / tên driver khớp fleet
  thì gắn id; departure trước arrival → 422; lock_version luôn tăng (kể cả chỉ đổi stop).
- `TripHistory` module: `outcome` / `driver_name` / `vehicle` trả giá trị đã sửa; `recorded_*` = bản gốc;
  `planned_stops` (chuyển từ Record); `recorded_stops` = [] (Phase 8 lấy từ stop events).
- Query: left join correction → OUTCOME_SQL có `incomplete`, DRIVER_SQL / VEHICLE_SQL (plate ngoài fleet = value là plate),
  NEEDS_LOOK có correction, search theo plate đã sửa. List: `corrected`, pax = tổng boarded đã sửa nếu có.
- Record: `corrected`, `can_correct`, `correction_lock_version`, `was` (outcome_label / plate / driver_name), stops có
  `position` + arrived_at / departed_at / boarded / alighted + `was`, `corrections`, log "Record corrected: <lý do>".
- `POST /trip_history/:id/correction`; policy `correct?` + `permitted_attributes_for_correct`.
- Seed 92: 1 run shuttle sửa giờ đến / rời stop 1 + boarded 11.
- Spec: `trip_history_spec.rb` thêm 1 case (lỗi, sửa, list / filter / facet, lock 409, đặt lại, run huỷ).

Khác HTML: chọn xe / driver bằng id (fleet) hoặc gõ plate / tên như HTML; không có "Restore recorded values" (HTML Trip
History không có, Reports thì có).
Chưa làm: correction chưa đổi pay / invoice (driver pay theo driver đã sửa) — backlog. On Time từ giờ đã sửa: Phase 8.
