# Phase 5 — Vehicle Types + requests + Bus Attendants (31/10/2026)

- `GET /vehicle_types`: `own_count`, `operator_count` (xe kept của company khớp đúng seats, 1 query group by seats + own),
  `tyre_text`, `custom`; `meta.tyre_layouts`. Không có company (Convoy Admin chưa chọn) → đếm 0.
- Cột `vehicle_types.custom`: type tạo tay / từ request = true; chỉ xoá được type custom (built-in → 422) và không có trip dùng.
- Bảng `vehicle_type_requests` (company, name, seats, reason, status pending / added / declined, requested_by, decided_by / at,
  vehicle_type). **Không TenantScoped** (Convoy Admin xem mọi company); policy scope theo `user.company_id`.
  Approve: dùng type trùng tên + seats nếu có, không thì tạo custom (`VehicleType.free_key`, tyre theo seats nếu không gửi).
  Request trùng type có sẵn → 422.
- Bus Attendants: API có sẵn đủ (list / add / edit / delete-discard); thêm spec.
- Seed `34_vehicle_type_requests` (1 pending, 1 declined).
- Spec `fleet_vehicle_types_spec.rb` (3). Tổng 205 specs.
