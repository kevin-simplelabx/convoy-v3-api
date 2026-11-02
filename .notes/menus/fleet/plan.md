# Fleet menu API — Plan

> Bắt đầu 31/10/2026. Inventory: `scope.md`. Hiện trạng đúng nằm ở `../../domains/fleet.md` (+ `operations.md`) khi phase xong.
> Mỗi phase: migration + model + policy + decorator + blueprint + controller + request spec + seed + `.api-documents/fleet.md`.
> Gems mới (đã duyệt 31/10/2026): `groupdate` (Phase 6, 8), `phonelib` (Phase 2).

## Phase 0 — Scope & plan ✅ (31/10/2026)
Rà HTML, chốt: Vehicle Financials để Finance (ghi backlog); invite admin ghi thay + KYC seed (NRIC mã hoá); gems groupdate, phonelib.

## Phase 1 — Vehicles & Operator Vehicles ✅ (31/10/2026, xem log/)
- `GET /vehicles?owner=own|managed` + `meta.teams` (đếm theo team, No Team) — mở rộng `VehicleSearch` facets.
- `PUT /vehicle_teams/bulk`: rows `{ id?, name, color }`, team không có trong rows = xoá (xe → nil); 1 transaction; lỗi tên trống / trùng.
- `GET /vehicles/:id` (record): thêm insurance status, driver hiện tại + upcoming, `fuel` (null tới Phase 7), `financials: null`.
- `DELETE /vehicles/:id`: rà quy tắc discard với run tương lai (dùng chung với External).
- Operator Vehicles: `GET /operator_drivers/assign_preview?vehicle_id|driver_id&pick=` → `effects[]`, `swap`; `assign_vehicle` đã có.

## Phase 2 — Drivers & Operator Drivers ✅ (31/10/2026, xem log/)
- Gem `phonelib`: chuẩn hoá mobile (`+65 XXXX XXXX`), unique số trong active + pending (partial index thay index cũ).
- Trạng thái bằng `aasm`: pending → active | declined; active → past; declined / past → pending (invite again).
  Endpoints member: `resend`, `accept`, `decline`, `reinvite`, `remove` (active → past); `DELETE` = cancel invite / delete.
- Remove driver: thêm `vehicle_driver_schedules` (driver nil từ hôm nay) + `last_vehicle_id`; operator driver: bỏ `vehicle_id`.
- `driver_invites` (polymorphic driver / operator_driver, phone, message, sent_at, kind invite / resend) — ghi lại, chưa gửi.
- `driver_kyc_profiles` (polymorphic, 1–1): email, address, dob, nationality, residential_status, id_number (**AR Encryption**,
  `id_number_masked` lưu riêng), licence_class, licence_since, vocational_no, vocational_expires_on, shared_at. Seed khi accept / seed.
  `GET /drivers/:id/details` (che NRIC), `GET .../details?reveal_id=1` (audited).
- Display cho khách: cột `display_name`, `display_photo` (CarrierWave), `display_set_by_id`, `display_set_at` trên drivers + operator_drivers.
- `GET /drivers?tab=` + `meta.counts`; cột bus / upcoming schedule.

## Phase 3 — Managed Operators + banks ✅ (31/10/2026, xem log/)
- Cột `operators`: `cost_per_trip`, `cost_per_day` decimal(12,2), `default_payment_method` (đã có `payment_method` — rà).
- Platform `banks` (code, name, swift) + `bank_branches` (bank, code, name): seed từ `Convoy Project/sg-banks.js`; `GET /banks`.
- Validate bank_code / branch_code theo bảng; list `routes_count` (school routes + trips gán xe operator), `vehicles_count`.
- Xoá operator khi còn xe → 422.

## Phase 4 — External Vehicles + Share Form ✅ (31/10/2026, xem log/)
- `GET /vehicles?owner=external` + `meta.cap { used, limit, left }`; Edit (cập nhật operator dùng chung), Remove.
- `external_vehicle_share_links` (company, token unique, active, created_by, revoked_at) — 1 active / company; `POST /share_link/reset`.
- `external_vehicle_submissions` (company, link, plate, seats, driver_name, driver_phone, company_name, company_phone, paynow,
  status pending / added / dismissed, vehicle_id, submitted_ip). Public `GET / POST /api/v1/public/share_forms/:token` (giới hạn bằng `rate_limit` có sẵn của Rails 8).
- `ExternalVehicles::Create` nhận `submission_id` → `vehicles.source = share_form`; dismiss.

## Phase 5 — Vehicle Types page + requests + Bus Attendants ✅ (31/10/2026, xem log/)
- `GET /vehicle_types` thêm `own_count`, `operator_count` (vehicles khớp seats, 1 query group by).
- `vehicle_type_requests` (company, name, seats, reason, status pending / added / declined, requested_by, decided_by, decided_at, vehicle_type_id).
  Company: create / list của mình; Convoy Admin: list tất cả, `approve` (tạo vehicle_type custom), `decline`.
- Tyre layout + xoá type custom: Convoy Admin (rà policy hiện có).
- Bus Attendants: rà list / CRUD / spec.

## Phase 6 — Maintenance page ✅ (31/10/2026, xem log/)
- Gem `groupdate`. `GET /maintenance_visits?tab=upcoming|to_record|completed|cancelled&q&vehicle_id` + `meta.counts`, `meta.kpis`.
- `GET /maintenance/summary`: spend 12 tháng (type, vehicle, workshop, %), tyre changes (lines `line_type = tyre`).

## Phase 7 — Fuel & Energy: dữ liệu ✅ (31/10/2026, xem log/)
- `fuel_companies` (company, name, kind fuel / elec / both, position; seed 9 mặc định SG); window CRUD (không xoá khi đang dùng).
- `fuel_entries` (company, vehicle, driver (default driver ngày đó), date, time (phút), kind, quantity decimal(10,2), cost decimal(12,2),
  odometer, full, fuel_company, station, note, receipt (CarrierWave), document_read, created_by;
  derived: `km_since`, `efficiency` (km/L hoặc kWh/100km, giữa 2 lần full cùng nhóm năng lượng), `unit_price`).
  `FuelEntries::Recompute` theo xe khi thêm / sửa / xoá. Index `(company_id, date)`, `(vehicle_id, date, time)`.
- Reader `Ai::Readers::FuelReceipt` (station, brand, qty, cost, date, time, plate) qua `document_reads`.
- `GET /fuel_entries?month&kind&vehicle_id`, CRUD; `GET /fuel/vehicles` (cards); record xe thêm `fuel` summary.
- Seed 90 ngày fill cho xe own (diesel / elec theo seats) + vài fill bất thường.

## Phase 8 — Fuel & Energy: alerts + usage ✅ (31/10/2026, xem log/)
- `fuel_alerts` (entry, vehicle, kind, message, status open / checked, checked_by, checked_at) — `FuelAlerts::Scan` chạy sau Recompute (90 ngày).
  `PATCH /fuel_alerts/:id/check|reopen`; `GET /fuel_alerts?status=` + counts.
- `GET /fuel/usage?view=all|vehicle|driver|company&measure&range=30d|12w|12m&from&to&key` (groupdate): series kỳ này / kỳ trước, totals, change,
  rows breakdown; driver so với usual km/L của bus (từ driver khác hoặc xe cùng size). `GET /fuel/kpis`.

## Phase 9 — Tài liệu API cho FE ✅ (31/10/2026, xem log/)
`.api-documents/fleet.md` (viết dần từng phase, phase này rà lại toàn bộ), thêm dòng vào `.api-documents/README.md`.
