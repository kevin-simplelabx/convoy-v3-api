# Phase 5 — Scheduler actions ✅ (30/10/2026)

## Bảng
| Bảng / cột | Ghi chú |
| --- | --- |
| trip_assignments | trip, effective_from, assignee own / operator / none, operator, vehicle (trống = operator đã nhận, chưa biết xe), pay_amount + pay_basis run / day / month |
| trip_assignment_slots | slot được giao: trip_run (trống với trip không phải shuttle) + slot_no |
| trips.no_fixed_bus | No Fixed Bus |
| trip_occurrences.trip_assignment_id | assignment mà run đang theo |
Assignment dùng cho **mọi loại trip** (layer 2 của layer model), không chỉ shuttle.

## Generator (layer 2)
Xe của run = assignment mới nhất (effective_from ≤ ngày, có slot) > xe theo run > xe của trip. Assignment cho operator: operator_id
(kể cả khi chưa có xe → run nằm ở Unassigned, mang tên operator), operator_cost = pay: run giữ nguyên; day chia số slot của
assignment; month chia thêm số ngày chạy trong tháng. Calendars::Context luôn load trọn tháng (giá / pay theo tháng).

## Kéo thả: `Occurrences::Move`
- `GET /occurrences/:id/move_preview?vehicle_id=` → `scopes` (one, later), `members` (số run đi cùng), `warnings`
  (xe đã có run trùng giờ, thiếu ghế, operator hết hạn `valid_until` — ngày theo Date Format của company), `cost` gợi ý
  (pay đã thoả thuận với operator trên trip, else operator_cost của trip; Disposal theo giờ).
- `POST /occurrences/:id/move { vehicle_id (trống = Unassigned), scope: one | later, cost, cost_basis: run | day | month | hour, lock_version }`:
  - Runs That Move Together đi cùng (cùng ngày).
  - `one`: override xe (+ driver, operator) trên run; cost → operator_cost override (hour × số giờ; day / số run nhóm; month / nhóm / ngày chạy).
  - `later`: tạo assignment từ ngày đó cho các slot; bỏ override xe tay của các slot đó từ ngày đó.
  - Trip không lặp lại, hoặc kéo ở ngày đầu của series: đổi xe trên chính trip (vehicle slot / run slot).
- `PATCH /occurrences/:id/regular_bus`: Back to Regular Bus (bỏ override xe, sync lại ngày đó).
- Không có swap trip (HTML chỉ có move; swap chỉ là của driver).

## Assign page
- `GET /trips/:id/assignments?from=` → mỗi run × slot (key `d1r0|1`, `trip|1`) với ai đang chạy vào ngày đó + lịch sử.
- `POST /trips/:id/assignments { effective_from, slots[], assignee, operator_id, vehicle_id, pay_amount, pay_basis }`
  (slot đã giao cùng ngày bị gỡ khỏi entry cũ; sync từ ngày đó).
- `DELETE /trips/:id/assignments/:id` → run quay về thứ đang có trước đó.
- If the Client Cancels a Run = `operator_cancel_rule` (done / full) trên trip (PATCH /trips).
- `GET /scheduler/assign_summary` → Assign Trips: shuttle đang chạy, n / tổng slot đã giao, `meta.open`.

## Drawer
- `bus_pattern` (shuttle lặp lại): trong 5 ngày gần nhất bao nhiêu lần run bị chuyển xe tay, xe hay dùng nhất → gợi ý
  "Make X the Regular Bus" (= move scope later) hoặc No Fixed Bus (`PATCH /trips/:id { no_fixed_bus }`).
- Runs That Move Together: `POST /trips/:id/run_groups { slots: ["d1r0|1", ...] }`, `DELETE /trips/:id/run_groups/:id`.
- Assign External Vehicle = `POST /vehicles/external` rồi `move`.

## Seeds `42_assignments`
Hup Seng chạy xe 2 của MBC Campus Shuttle (4.500 S$ / tháng → 42,86 S$ / run); Cross-site Shuttle chuyển sang PD5126A từ tuần sau.
`rake occurrences:verify`: all match.

## Specs
124 examples (thêm 9): trip một lần đổi xe trên trip, one / later (assignment + pay), warnings + prefill, Disposal theo giờ,
unassign, Back to Regular Bus, nhóm run cùng đi + pay theo ngày, operator chưa có xe + pay theo tháng + assign summary + xoá,
nhóm / bỏ nhóm, chuỗi layer (assign → cancel → kéo tay → xoá assignment).
