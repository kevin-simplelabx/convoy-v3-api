# Phase 1 — Trips list (30/10/2026)

- `GET /occurrences/list` (collection route của occurrences; `index` giữ cho driver app / grid). Query object `RunSearch`
  (`app/queries/run_search.rb`): from / to bắt buộc (≤ 183 ngày → 422), q, kind, operator (`own` / `none` / id), status_group, sort.
- Status group: `TripOccurrence#status_group` và `RunSearch::STATUS_SQL` (CASE, cùng thứ tự với `grid_status`): cancelled → completed
  (completed / ended / đã qua giờ kết thúc) → unassigned → live → assigned. Run unassigned đã qua giờ tính là completed (như HTML `schSt`).
- Operator lấy từ `trip_occurrences.operator_id` (người chạy run thật, gồm assignment cho operator), không lấy operator của xe.
- `meta`: page + `counts` (mọi filter trừ status) + `kinds` + `operators` trong khoảng ngày.
- Blueprint view `:list`: status_group, client_name, customer (Service For hoặc client), vehicle_seats, required_vehicle_type (theo slot), operator.
- Search ILIKE (trip_label, trip title / service_for, client, plate, driver, operator, school / route, EXISTS tên stop). Không pg_trgm.
- Không thêm bảng / seed (đọc dữ liệu có sẵn). Spec: `spec/requests/api/v1/trips_list_spec.rb` (4). Tổng 158 specs.
- Đo dev: 30 ngày, q="a", 369 run → ~0.5 s gồm facets (chưa tối ưu, chấp nhận).
