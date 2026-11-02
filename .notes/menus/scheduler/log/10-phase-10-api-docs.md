# Phase 10 — Tài liệu API cho FE (30/10/2026)

User không muốn sửa FE nữa; thay bằng tài liệu đưa FE team.

- Thư mục `convoy-v3-api/.api-documents/`, tiếng Anh, Markdown.
  - `README.md`: quy ước chung (base `/api/v1`, snake_case, giờ/tiền, cookie session, format response/lỗi, paging/ransack,
    lock_version, file ký 1 giờ, document_reads + poll, runs/`key`/virtual).
  - `scheduler.md`: theo màn → thao tác → method + path + param + mô tả + JSON mẫu (lấy từ response thật của dev seed).
- Mỗi menu sau này thêm 1 file + 1 dòng vào bảng trong README. **Đổi API thì sửa doc cùng lúc.**

Sửa khi lấy mẫu:
- `VehicleBlueprint`: `model` trả cả record Draper → `field(:model) { |v| v.object.model }`.
- Key run của School Bus route thiếu route id → `r<route_id>|date|0|1|1`.
- Thêm `pair_trip_id`, `is_return` vào run (vẽ link line outbound → return).

## Tổ chức lại `.notes` (30/10/2026)
Theo cấu trúc trong `.notes/README.md`: tài liệu sống `domains/`, nhật ký `menus/scheduler/log/` (đổi số từ 10–22 → 00–10).
Khi viết `domains/fleet.md` phát hiện: gán operator driver vào xe không cập nhật run, và `Occurrences::RefreshDrivers` ghi thẳng
`driver_id` nên đè driver của replacement (Driver Away). Sửa: RefreshDrivers sync lại trip / route có run trên xe đó (digest có driver),
`OperatorDriver` after_commit → `OccurrenceDriverJob` cho xe cũ và xe mới. +2 spec (153).

