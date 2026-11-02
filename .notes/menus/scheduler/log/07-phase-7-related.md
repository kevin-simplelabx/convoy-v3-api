# Phase 7 — Các phần liên quan trên Scheduler ✅ (30/10/2026)

## Maintenance (toolbar Maintenance, empty slot, Fleet > Maintenance)
- Bảng: `workshops` (name unique, address, phone; có visit thì không xoá), `maintenance_visits` (own vehicle, driver, date + giờ,
  workshop, address, kind service / repair / tyres / inspection / other, work_to_do, status scheduled / completed / cancelled, odometer,
  gst_on + gst_rate, driver_notified_at, completed_by/at), `maintenance_lines` (part / tyre / labour / other, mô tả, part no., brand,
  model, tyre_position, qty, unit price trước GST), `maintenance_invoices` (file).
- Vị trí lốp: `Vehicle#tyre_positions` theo tyre layout của vehicle type cùng số ghế (Front Left ... Rear 2 Right Outer, Spare).
- `GET /maintenance_visits/new?vehicle_id&date&start_time` (form trống: driver mặc định ngày đó, 2 giờ, GST 9%, tyre positions),
  `GET /maintenance_visits?tab=upcoming|to_record|completed|cancelled&from&to&vehicle_id`, `GET :id` (full: lines, invoices, last_odometer),
  `POST / PATCH { maintenance_visit, workshop_name + workshop_address (New Workshop), invoice | document_read_id }`, `PATCH :id/cancel`.
- Record the Work (status completed) cần odometer, line items, mô tả, vị trí lốp hợp lệ. Driver được báo (ghi lại) khi visit mới
  hoặc đổi driver / ngày / giờ / workshop.
- Hoá đơn: `document_reads` kind `maintenance_invoice` (Claude) → điền workshop, address, odometer, line items còn trống, GST;
  `meta.warnings`: plate khác, odometer thấp hơn lần trước.
- Scheduler: `data.maintenance` = block trên xe; move preview cảnh báo "PD3318K is at Ah Huat Motor 08:30–10:30".
- `GET/POST/PATCH/DELETE /workshops`.

## Notices (Send Notice trong drawer)
- Bảng: `notice_templates` (6 mặc định, `config/presets/notice_templates.yml`, seed mỗi company), `notices` (trip, all_runs / `notice_runs`,
  to_riders / to_parents, banner / push / sms, starts_at, ends_at, template, message ≤ 300, ended_at/by), `notice_deliveries` (push / sms ghi lại).
- `POST /notices { notice, start: now | at, period_minutes, run_keys }`; `GET /notices?state=active|scheduled|ended&trip_id`;
  `PATCH` (chỉ scheduled), `PATCH :id/end_now`, `POST :id/duplicate`, `DELETE`; `GET /notice_templates`.
- Chặn: WhatsApp (chưa có), message còn `{min}` / `{time}`, không chọn người nhận / kênh, end ≤ start.
- Drawer: `notice` = banner đang chạy cho run đó.
- Audience School routes chờ Phase 9 (cột `audience` đã có).

## Share Tracking Link
- `tracking_links` (token 24 ký tự, run identity, snapshot JSON: company, ngày, giờ, Trip ID, title, kind, stops có pin + giờ, xe, tên driver; expires_at = kết thúc + 24 h).
- `POST /occurrences/:id/tracking_link` (mỗi lần share đổi token), public `GET /api/v1/public/tracking/:token` (không đăng nhập; state upcoming / live / done; 410 khi đã đóng).
- Daily job xoá link đã đóng quá 7 ngày.

## Ảnh stop từ drawer
`POST /trips/:trip_id/stops/:stop_id/photos { photo }` (≤ 3, 1280 px), `DELETE .../photos/:id` — cùng ảnh trip form dùng.

## Sửa thêm
- `OccurrencesController#show` thiếu `authorize` từ Phase 4 (verify_authorized bắt được khi có spec gọi tới).
- Reader đọc số "84,210" thành 84210.

## Seeds
`50_maintenance` (2 workshop, visit ngày mai PD1125G, visit tháng trước PD2185B có 4 line = 953,75 S$ gồm GST),
`51_notices` (templates mọi company, notice Route Change cho 2 timing của MBC Shuttle thứ Hai tới).

## Specs
136 examples (thêm 6).
