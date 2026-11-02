# Phase 7 — Fuel & Energy: dữ liệu (31/10/2026)

- Bảng `fuel_companies` (per company, kind fuel / elec / both, position; 9 mặc định SG thêm lần đầu dùng — `ensure_defaults!`)
  và `fuel_entries` (vehicle own, driver, date, time phút, kind diesel / petrol / def / elec, quantity, cost, odometer, full,
  fuel_company, station, note, receipt CarrierWave, document_read, created_by; **cột tính sẵn** `km_since`, `efficiency`,
  `odometer_back`). Index `(company_id, date)`, `(vehicle_id, date)`; check constraint kind và số lượng.
- `FuelEntries::Recompute` (port `flStats`): chạy cả lịch sử 1 xe, chỉ ghi row đổi; driver = default driver ngày đó, chạy lại khi
  lịch default driver đổi (`FuelRecomputeJob` từ `VehicleDriverSchedule` after_commit). Gọi sau save / delete.
  Cờ "lệch > 30% so với median" của HTML để Phase 8 (alerts).
- `FuelEntries::Save`: receipt file hoặc `document_read_id` (reader mới `Ai::Readers::FuelReceipt`, kind `fuel_receipt`) → điền
  field trống, khớp company (`FuelCompany.named_in`), xe theo plate; warnings plate khác, company chưa có, odometer lùi.
- `FuelVehicleStats` (1 query group by + DISTINCT ON last) + `FuelStatsPresenter` (thư mục mới `app/presenters`):
  thẻ xe `GET /fuel_entries/vehicles`, `fuel` trên record xe (thay null của Phase 1).
- Endpoints: `fuel_entries` CRUD + `new`, `vehicles`; `GET /fuel_companies`, `PUT /fuel_companies/bulk`
  (`FuelCompanies::Save`, không xoá company đang dùng; bỏ `dependent: :restrict_with_error` để tránh N+1, FK vẫn chặn).
- Seed `55_fuel`: 90 ngày mỗi xe own (PD5126A điện), AdBlue cho coach, vài lần đổ bất thường + PD4472H tốn hơn 15% 60 ngày cuối.
- Spec `fleet_fuel_spec.rb` (6). Tổng 213 specs.
