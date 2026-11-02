# Phase 4 — External Vehicles + Share Form (31/10/2026)

- Bảng `external_vehicle_share_links` (token `has_secure_token` 24, 1 link live / company — partial unique, reset = revoke + tạo mới)
  và `external_vehicle_submissions` (plate, seats, driver, mobile, company, company phone, paynow, status pending / added / dismissed,
  vehicle, decided_by / at, submitted_ip). Cột `vehicles.source` (`console` / `share_form`) cho dòng "Filled in by driver".
- `GET /external_share_link` (tạo lần đầu), `POST /external_share_link/reset`; `GET /external_vehicle_submissions?status=`,
  `PATCH .../:id/dismiss`; Review and Add = `POST /vehicles/external` + `submission_id` (`ExternalVehicles::Create` đánh dấu added).
- `ExternalVehicles::Create` nhận thêm field company: `cost_per_trip`, `cost_per_day`, `valid_until` (áp mọi xe của company).
- `GET /vehicles` thêm `meta.external_cap { used, limit, left }`.
- Public `GET / POST /public/share_forms/:token` (không đăng nhập, tìm link ngoài tenant rồi ghi trong tenant của link); lỗi 422
  trả câu gốc ("Enter your name") thay vì full message. Throttle bằng **rack-attack có sẵn** (10 / giờ / IP) thay cho `rate_limit`.
- Seed `33_external_vehicles` (link + 2 câu trả lời chờ).
- Spec `fleet_external_vehicles_spec.rb` (2). Tổng 202 specs.
