# Clients — hiện trạng

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| clients | kind company / individual / transport_company (Main Contractor), code CLxxxxx, UEN (`Uen`), on_time_allowance 0–15, discard |
| client_sites | name (unique không phân biệt hoa thường theo client), address + lat/lng (FE OneMap), `school_id` (unique), own_billing + billing_name / uen / address, created_by |
| client_billing_contacts | polymorphic billable (client / site): name, email (nullable khi chỉ Attention), send_as to / cc, attention, position. Hiện site dùng; client (cbill) để Finance |
| client_end_customers | Their Customers của Main Contractor (Service For) |
| client_bookable_vehicle_types | type client đặt được trong Portal; rỗng = mọi type đang offer |
| client_pickup_points | Saved Pick-up Points, created_by |
| client_users, client_user_sites | người của client dùng Client Portal: role 7 loại (`ClientUser::ROLES`, wide = super / adm / fin), site access; discard |
| portal_accounts | 1 người / email (mọi client, mọi company): password, password_set_at, last_sign_in_at |
| portal_jwts, portal_sign_in_codes | xem `platform.md` (Client Portal sign-in) |
| schools.client_id (unique) | client là school; School Calendar = `schools.calendar_id` (đổi → resync route) |

## Quy tắc
- Xoá client: chặn khi còn trip kept đang chạy (`Trip.running_on`) hoặc booking pending / approved (`Client#delete_blockers`).
- Xoá site: chặn khi trip kept gắn site (trip hoặc stop); trip đã xoá / booking → nullify.
- 1 school chỉ gắn 1 client hoặc 1 site (`Clients::Save`, `ClientSite#school_free`).
- Client user: email không trùng user Convoy OS của company; site role cần ≥ 1 site khi client có site; luôn còn Super Admin.
- Ai ghi: mọi company user (giống trip form Add New Client); Convoy Admin chỉ xem.

## Seeds
`20_clients` (client, site, point, end customer), `47_client_records` (St. Stephen's là school, Google billing riêng + người nhận,
bookable types, client users + portal account).
