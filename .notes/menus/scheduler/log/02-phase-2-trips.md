# Phase 2 — Trip template ✅ (30/10/2026)

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| trips | template: kind (ad_hoc, corporate_shuttle, airport_transfer, disposal, school_run), client (+ site), title (để trống = Service For khi sub-contract, else client), label; Trip ID; ngày / giờ (phút, end có thể > 1440), hours (Disposal), days int[] (0 = CN), end_mode none / never / date / count, ends_on, occurrence_count, skip_public_holidays, calendar; pax, luggage theo size, vehicles_count; requestor, guest; notes, BU, project, booking_ref; airport (direction, flight, flight time, terminal, wait, meet & greet, signboard, fee); revenue (price, price_per route / vehicle, price_set same / each, price_basis trip / day / month, hourly_rate), cost (trip_value + mode + rounding, operator_cost, operator_cancel_rule); sub-contract (subcontracted, client_end_customer = Service For, contractor contact, require app); two-way (pair, is_return, return_billing); lock_version; soft delete |
| trip_stops | direction (1, 2 = return stops của shuttle), position, name, use pu / do / both / via (Waypoint Only), address, lat/lng, driver_note, street_view_url, client_site, scheduled_time (School Run) |
| trip_stop_photos | ≤3 / stop (ImageUploader) |
| trip_route_vias | pin kéo trên đường sau stop `from_position` |
| trip_vehicle_requirements | vehicle_type × count |
| trip_vehicle_slots | slot 1..N: xe dự kiến + giá riêng (price_set each) |
| trip_standbys (+ photos ≤3) | location, minutes, pin, address, note, Street View; `report_time` = start − minutes |
| trip_attachments | DocumentUploader |
Order unique (stops, vias, slots) là **DEFERRABLE** constraint → đổi thứ tự trong 1 lần lưu được.

## Trip ID
`TID` + `trip_no`; trip lặp lại giữ 1 block số liên tiếp (1 số / ngày) từ `trip_no_from`: TID của ngày d = trip_no + (d − trip_no_from);
nhiều xe thêm `-slot`. End: Never → block 3653 ngày (~10 năm). Sửa ngày ra ngoài block → lấy block mới.
`CompanySequence.next_block!(:trip_no, n, start: 100_001)` (row lock).

## Lịch
`Calendars::Context` (port logic/calendars.js): skips_public_holiday? (Working Holiday, observed holidays theo calendar / company),
day_off, no_school?, time_shift (Changed Times mọi trip; Early Dismissal chiều; Late Arrival sáng; School Run theo session),
runs_on?, nth_run_date. Calendars có thêm morning_time / afternoon_time (07:30 / 13:30).
End: After N → `ends_on` tính bằng Context khi lưu.

## API
- `GET /trips` (q: title / client / label / Trip ID; kind, client_id, vehicle_id, from + to), `GET /trips/:id` (view full),
  `POST /trips { trip, return_trip }`, `PATCH /trips/:id` (lock_version → 409 khi người khác vừa sửa), `DELETE` (soft).
- Nested: `stops_attributes` (+ `photos_attributes`), `route_vias_attributes`, `vehicle_requirements_attributes`,
  `vehicle_slots_attributes`, `standby_attributes` (+ photos), `attachments_attributes`; JSON hoặc multipart.
- `POST /trips/:id/attachments { file }`, `DELETE`.
- Two-Way (`Trips::Save`): chỉ trip Ad Hoc mới; return copy outbound, có start / stops / standby / xe riêng, title "(Return)",
  pair 2 chiều; chặn return bắt đầu trước khi outbound kết thúc; `return_billing` two_way nếu mọi stop chiều về cách stop chiều đi ≤ 200 m
  (không có pin → theo form).
- Validations như `schSaveTrip`: client, giờ, end ≠ start, Disposal hours, recurring days + end, arrival wait, pick-up / drop-off, vehicles required.

## Audit
Mỗi model tự khai `audited`; phần con của trip `audited associated_with: :trip`, `Trip has_associated_audits` → "Changes to This Trip".
TenantScoped kiểm `company_id` thay vì load company (tránh N+1 khi lưu nested).

## Chờ phase sau
- Phase 3: shuttle (runs, timetable, price table, rate card), các cột shuttle.
- Phase 4: lưu / xoá trip → `Occurrences::Sync`.
- Phase 8: School Run (session, students, paid months...).

## Seeds `40_trips`
Airport arrival (meet & greet), MBS gala two-way (2 xe + standby), DBS disposal 6 h, Google offsite chưa gán xe,
sub-contract Eastern Coaches → Nanyang Polytechnic, Jurong East staff pick-up mỗi ngày thường (Google Office Calendar).

## Specs
82 examples (thêm 19): Calendars::Context, Trip (số, block, title, end time, After N, validations, audit), request (create, two-way,
return sớm, reorder + ảnh multipart, 409, list filters, soft delete + calendar đang dùng).
