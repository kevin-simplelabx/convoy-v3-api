# Phase 1 — Vehicles & Operator Vehicles (31/10/2026)

- `Vehicle.search` thêm team, default driver hôm nay (own, subquery `vehicle_driver_schedules` ≤ hôm nay), operator driver trên xe.
  Scope `in_team` (`team_id=none` = No Team). Scheduler dùng chung nên search Scheduler cũng rộng hơn.
- `VehicleSearch#facets` thêm `teams { all, none, list [{ id, name, color, count }] }` theo `ownership[]` (không áp team).
- `PUT /vehicle_teams/bulk` → `VehicleTeams::Save`: row có id = sửa, không id = thêm, thiếu = xoá (xe nullify);
  đổi tên tạm `__<id>` trước để đổi chéo tên không vướng unique index.
- `GET /vehicles/:id` view `:record`: `upcoming_drivers`, `fuel` (null tới Phase 7), `financials: null` (Finance).
- `DELETE /vehicles/:id` → `Vehicles::Remove`: **khác HTML** (HTML xoá luôn) — chặn khi còn run scheduled chưa kết thúc hoặc
  maintenance scheduled từ hôm nay (tránh run trỏ xe đã xoá); operator driver rời xe.
- `GET /operator_drivers/assign_preview` → `OperatorDrivers::AssignPreview` (effects, swap, ok_label, apply); apply = `assign_vehicle` có sẵn.
- Không cần seed mới (teams, operator driver đã có trong `30_fleet`).
- Spec `fleet_vehicles_spec.rb` (9). Tổng 189 specs.
