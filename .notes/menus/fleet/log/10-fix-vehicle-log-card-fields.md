# Fix — Form xe nhận các trường log card (02/11/2026)

FE báo: Edit Vehicle (`Convoy OS.dc.html` ~14872) cho sửa Registration Date, Chassis Number, Engine Number, COE Expiry,
Road Tax Expiry nhưng `PATCH /vehicles/:id` / `POST /vehicles` không nhận (thiếu trong `VehiclePolicy::PERMITTED`, doc không ghi).
Cột, blueprint, seed đã có từ Phase 1b của Scheduler; trước đó chỉ upload log card (Claude) ghi vào.

- `VehiclePolicy::PERMITTED` thêm 5 trường.
- `Vehicle`: `normalizes` chassis / engine (strip, upcase, rỗng → nil); `dates_readable` báo lỗi khi chuỗi ngày không đọc được.
- Spec: `vehicles_spec` tạo / sửa 5 trường, ngày sai → 422 (ví dụ cho OpenAPI).
- Doc: `scheduler.md` § 14.1 (body + bảng trường), `fleet.md` § 1.3; sinh lại `convoy-v3-api.openapi.json`.
