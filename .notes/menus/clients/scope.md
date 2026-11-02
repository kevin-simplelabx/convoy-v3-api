# Scope: menu Clients (rail `cl`, icon `corporate_fare`), rà 02/11/2026

Nguồn: `Convoy OS.dc.html` (Managed Clients ~14249–14547, Connected Clients ~14548), `logic/mixins/admin.js` (`clientVals` 653–990,
`clPtsVals` 257, `billPplVals`), `logic/app-feed.js` (role Client Portal: ROLES, ROLE_LBL, ROLE_TAG, ROLE_FEAT, `userCan`, `rolesToGive`),
`Client Portal.dc.html` (đăng nhập: 56–105, 3150–3890).
Submenu: **Managed Clients**, **Connected Clients** (Coming Soon).

## Đã có (chỉ bổ sung)
`clients` (kind company / individual / transport_company, code, UEN, contact, phone, email, billing_address, on_time_allowance 0–15,
rate_card, discard), `client_sites` (name, address, lat/lng), `client_end_customers`, `client_pickup_points` (name, address,
postal, lat/lng, note); CRUD cơ bản + nested routes (dùng bởi trip form). `schools.client_id`, `schools.calendar_id` có sẵn.

## Làm
| Trang | Tính năng | Phase |
| --- | --- | --- |
| List | Client, badge Individual / Main Contractor, UEN, contact, phone, email, số user; search; Edit / Delete trên row | 1 |
| Form | Client Is (Company / Individual / Transport Company), tên, UEN (kiểm format), contact, billing address, phone, email; "This Client Is a School" (company) + School Calendar (calendar school) | 1 |
| Delete | Soft delete; **chặn khi còn trip chưa xoá / booking chưa xong** (422 kèm số) | 1 |
| Record | Details (Client Code, School, School Calendar…); On-Time Allowance −1 / +1 (0–15) | 1 |
| Sites | Thêm (tên unique theo client, địa chỉ + pin do FE lấy từ OneMap), sửa, xoá (chặn khi site đang là stop của shuttle trip, kèm số); "On N shuttle trips" | 2 |
| Edit Site | Site là School (School Bus, mỗi school chỉ gắn 1 client / site); billed as own legal entity (legal name, UEN, billing address); Send Invoices To (name, email, To / CC, Attention) | 2 |
| Their Customers | (Main Contractor) thêm / xoá, trùng tên = lỗi (đã có, rà) | 2 |
| Bookable Vehicles | All Vehicle Types hoặc chọn type (bảng nối), chỉ type company đang offer | 2 |
| Saved Pick-up Points | Thêm (tên, place, note), xoá; "Added by X on date" | 2 |
| Client Users | Thêm (name, title, email, role 7 loại, site access), sửa role / title / sites, xoá; luật: ≥ 1 Super Admin, role theo site phải chọn site (khi client có site), email không trùng user Convoy OS của company, không trùng trong client | 3 |
| Role Permissions | Bảng 7 role × tính năng: API trả role (label, tag, wide); chữ tính năng = FE tĩnh | 3 |
| Client Portal sign-in | Email → mật khẩu (đã đặt) hoặc mã 6 số (lần đầu / quên) → đặt mật khẩu (≥ 8) → token; email thuộc nhiều client → chọn account; sign out | 4 |
| Mã một lần | `PortalMailer` (deliver_later); chưa có SMTP: trả `dev_code` khi `PORTAL_SHOW_CODE=1` (không bao giờ ở production); hết hạn, giới hạn số lần thử, rate limit | 4 |

## Không làm (backlog)
- **Connected Clients**: HTML Coming Soon.
- Mọi tính năng bên trong Client Portal (booking, approval flow, invoices, live map…) và quản lý user từ phía Portal (`userCan`, `rolesToGive`): làm cùng menu / app Client Portal.
- Gửi email thật (SMTP): backlog có sẵn.
- Billing của chính client (cbill) và invoice: Finance.
