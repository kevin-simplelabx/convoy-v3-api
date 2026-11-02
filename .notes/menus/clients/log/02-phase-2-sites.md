# Phase 2 — Sites, billing, customers, bookable vehicles, pick-up points (02/11/2026)

- Migration `client_sites`: `school_id` (unique partial), `own_billing`, `billing_name`, `billing_uen`, `billing_address`, `created_by_id`;
  `client_pickup_points.created_by_id`. FK validate riêng.
- Bảng `client_billing_contacts` (polymorphic billable client / site, name, email nullable (chỉ Attention), send_as to / cc, attention,
  position; unique email theo billable khi có email). Hiện chỉ site dùng; billing của client (cbill) để Finance.
- Bảng `client_bookable_vehicle_types` (client, vehicle_type unique); `PUT /clients/:id/bookable_vehicle_types` thay cả list, chỉ type đang offer.
- `ClientSites::Save`: assign + school + billing; `own_billing: false` xoá billing + người; list người thay toàn bộ (≤ 6, bỏ dòng trống,
  ≥ 1 To khi có email). Model: name unique không phân biệt hoa thường, billing_name bắt buộc khi own, UEN check, school chưa gắn client.
  `Clients::Save` chặn school đã gắn site.
- Xoá site: chặn khi trip kept dùng site (trip.client_site hoặc stop) — `shuttle_trips_count`; trip đã xoá / booking → nullify.
- End customer: name unique không phân biệt hoa thường "is already on the list"; restrict khi trip / booking dùng.
- Pick-up point: `created_by` (blueprint + includes).
- Seed `47_client_records`: Google Pasir Panjang billed riêng + 2 người, bookable 3 type, created_by. Spec `clients_record_spec.rb` (3).
