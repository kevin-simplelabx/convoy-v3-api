# Phase 3 — Drivers (pay assignments) (02/11/2026)

- Bảng `driver_pay_schemes`, `driver_vehicle_types` (company, driver, scheme / type, starts_on unique theo driver, ends_on).
  Concern `DatedAssignment`: lùi tối đa 1 tháng, end ≥ start, `recut!` (mỗi dòng kết thúc ngày trước dòng sau), `tag`, scope `on(date)`; audited associated_with driver.
- `Pay::DriverTerms` (scheme theo ngày: không có dòng nào → default; có dòng nhưng không phủ ngày → nil; type theo dòng hoặc nil = type của xe job).
- `Pay::DriverList` (driver active, xe hôm nay qua `vehicle_driver_schedules`, age KYC, scheme / type hôm nay, cảnh báo rate trống).
  `VehicleType.for_seats` (cùng seats, không thì nhỏ nhất lớn hơn) vì `vehicles` chỉ có seats.
- `PayDriversController` (index / show + create / update / destroy assignment theo `:kind` schemes | vehicle_types). Policy headless `:pay`.
- Seed: driver thứ 2 Basic → Monthly 2,400 từ đầu tháng; driver thứ 3 type Coach. Spec `hr_drivers_spec.rb` (2).
