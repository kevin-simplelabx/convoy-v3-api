# Phase 4 — Sửa tay route (02/11/2026)

- `Plans::Edit`: set_stops (thứ tự + rider từng stop, vias; rider đặt vào route này rời route khác — route khác retime, rỗng thì bỏ; rider bị bỏ →
  unassigned "Removed by hand"), add_route (New Route: locked + manual, số / label kế tiếp), change_type, remove_route (rider → "Route deleted"),
  reset (route gốc của run theo route_key; rider không còn → "Taken off by Reset Route"). Mọi thay đổi retime qua service; summary tính lại
  (`Plans.summary`); plan đã adopt → resync. Xoá route của plan đã adopt bị chặn (có run trên Scheduler).
- Route Again: `routing_runs.kind = again` + `target_plan`; input bỏ rider của route khoá; fleet giới hạn (`types[].max` / `on: false`);
  `Plans::MergeAgain` thay route không khoá, đánh số vào chỗ trống, ghi lại id route vào result để Reset tìm được.
- Service: `/retime` nhận `type` (đổi bus type / route vẽ tay) lấy ghế, capacity, floor từ `prepTypes` của engine.
- API: `PUT /routes/:id/stops`, `POST /plans/:plan_id/routes`, `PATCH /routes/:id` (bus_type, locked, hidden, attendant_id), `DELETE /routes/:id`,
  `POST /routes/:id/reset`, `POST /plans/:plan_id/route_again`. Spec 2.

# Phase 5 — Adopt (02/11/2026)

- `Plans::Adopt` (từ ngày ≥ đầu tháng này và > ngày bắt đầu plan đang chạy; plan đang dùng tại ngày đó kết thúc hôm trước; plan scheduled sau ngày đó bị
  huỷ; AM → `rider_assignments` từ rider của plan, giữ gán tay), `Plans::Adopt.cancel` (scheduled → draft, plan trước chạy tiếp), `Plans.resync`
  (sync route của các plan liên quan, kể cả plan cũ kết thúc). Scheduled = in_use + effective_from tương lai (RouteGenerator tự xử lý, không cần job).
- `rider_assignments` (rid → stop_point, manual, plan, notified_at); Stop Assignment trả `assigned` + counts assigned / notified.
- API: `POST /plans/:id/adopt { from }`, `/cancel_adoption`; `POST /schools/:id/rider_assignments` (Set as assigned), `/move` (Move All Riders Here),
  `/notify` (ghi lại). Spec 2. Ghi chú: AM adopt ngày tương lai gán rider ngay (HTML gán khi plan thành current).

# Phase 6 — Route: xe, giá operator, Route Charges (02/11/2026)

- `school_route_prices` (lịch sử giá theo ngày: fixed / rider), `route_charges` (amt / pct ≤ 100, từ ngày, 0 = kết thúc, status ok / check,
  carried_from). `RouteCharges.on` (charge hiệu lực), `RouteCharges.carry` (khi adopt: route mới chung nhiều rider nhất rồi nhiều stop nhất; không khớp
  → không route, status check).
- API: `POST /routes/:id/vehicle` (xe thường từ ngày, vehicle_changes có sẵn; resync), `POST /routes/:id/prices` (finance), `GET /schools/:id/route_charges`
  (run của plan đã adopt: bus rate theo fare per bus, extra hiện tại, thay đổi kế tiếp, lịch sử; unmatched; to_check), `POST /routes/:id/charges`,
  `PATCH /route_charges/:id` (xác nhận / chuyển), `DELETE /route_charges/:id` (chỉ chưa bắt đầu hoặc đang check). Route trong plan detail có vehicles,
  prices, charges. Attendant qua `PATCH /routes/:id`. Replacement theo ngày giữ ở Scheduler (có sẵn). Spec 2.
