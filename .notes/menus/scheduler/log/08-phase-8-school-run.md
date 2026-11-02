# Phase 8 — School Run ✅ (30/10/2026)

## Bảng
| Bảng / cột | Ghi chú |
| --- | --- |
| trips + | session am / pm, paid_months_mode all / some / part, unpaid_months int[], unpaid_month_share %, charge_no_school_days, school_time_estimated, route_list_name / imported_at, students_purged_at |
| trip_stop_students | stop → học sinh: name, class_name, parent_name, phone, phone2, note; **key** (uuid) giữ nguyên qua các lần import |
| route_list_versions (+ stops, students) | Earlier Lists: danh sách trước một Apply From, `valid_until` |
| student_attendances | Passenger List: run identity (trip, ngày, run, slot) + student_key, boarded_at, alighted_at, absent, ai ghi |
| pickup_points | Saved Pick-up Points: name, postal_codes[] (GIN), pin, note |

## Quy tắc (port HTML)
- Trip School Run: start = stop đầu có giờ; end = giờ ở trường (AM là stop cuối); không có giờ trường → FE gửi ước tính road-time
  trong end_time, else giờ đón cuối + 10 phút (`school_time_estimated`); pax = số học sinh. AM: stop đón, trường trả; PM ngược lại.
- Calendar: Late Arrival dời run AM, Early Dismissal dời run PM (theo `session`).
- Giá tháng: tháng đã trả 1; `some` tháng không tick 0; `part` tháng không tick theo %; Charge for No School Days tắt → nhân
  ngày chạy / (ngày chạy + ngày No School). `GET /trips/:id/school_run_bill?from=` = Next 12 Months (tháng không có run vẫn tính giá tháng).

## Import Route List
1. `POST /document_reads { kind: route_list, file }` (Claude; PDF / xlsx / CSV / ảnh; bỏ cột xe / driver).
2. `POST /route_lists/review { document_read_id, joins[], trip_id }` → `stops` (gom: cùng giờ và cùng điểm / cùng postal /
   cùng Saved Pick-up Point; `joins` = Join Stop Above / Separate Stop), cờ mỗi dòng (No time, Earlier than the row above,
   No parent phone, No postal code, Also on <School Run khác>), `changes` so với list hiện tại (added, removed, changed time / stop / phone),
   `trip_attributes` sẵn cho `POST /trips`. Kiểm tra postal trên OneMap do FE làm.
3. Trip mới: FE gửi `trip_attributes`. Trip đã có: `POST /trips/:id/route_list { document_read_id, joins, apply_from }` →
   list cũ thành Earlier List tới hôm trước, stops + students thay mới, học sinh trùng tên giữ key.
- `GET /trips/:id/route_list_versions`; `GET/POST/PATCH/DELETE /pickup_points` (postal_codes list hoặc text có dấu phẩy, 6 số).

## Passenger List
`GET /occurrences/:id/passengers` (list đang áp dụng ngày đó: Earlier List hoặc hiện tại; status not_marked / boarded / alighted / absent),
`PATCH /occurrences/:id/passengers/:key { mark: boarded | alighted | absent | clear }`.

## Giữ dữ liệu 7 năm
`SchoolRuns::Purge` (trong OccurrenceDailyJob): School Run đã kết thúc quá 7 năm + 2 ngày → xoá students, Earlier Lists, attendance; pax 0;
trip Never giữ nguyên.

## Seeds `44_school_runs`
Red Swastika AM 13 cho Eastern Coaches (3 stop, 5 học sinh, MOE calendar, giá tháng 2.400, tháng 6 và 12 một nửa, No School không tính),
Saved Pick-up Point Bedok Court, Passenger List ngày gần nhất (4 alighted, 1 absent).

## Specs
144 examples (thêm 8).
