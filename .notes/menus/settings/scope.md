# Scope: menu Settings (rail footer `set`, icon `settings`), rà 02/11/2026

Nguồn: `Convoy OS.dc.html` (Users ~4507, Roles matrix ~4600, Calendars ~10338, Company Settings ~13853, Profile dialog ~3866),
`logic/mixins/admin.js` (`csCtryVals`, `csFmtVals`, users ~1500–1700: ROLES, FEAT, `o.us`, `o.users`; `setIt`; `o.um` / `pf`),
`logic/country.js` (danh sách nước), HTML inline `pholVals` (~17900–18180).
Submenu: **Company Settings** (`coset`), **Users** (`users`), **Calendars** (`phol`). Thêm: dialog **Profile** (menu tài khoản trên top bar).

## Đã có (chỉ bổ sung)
- `companies`: short_name, theme_color, logo, timezone, date_format, time_format, observed_holidays, business_units_enabled, country;
  `PATCH /companies/:id` (policy hiện cho admin / owner).
- `users`: role (convoy_admin / admin / member), owner, permissions[] (10 quyền), status active / suspended, avatar, mobile; chỉ seed.
- Calendars: `public_holidays` (CRUD, `import` MOM), `calendars` + `calendar_days` (CRUD, start_from, notify_drivers), `companies.observed_holidays`.

## Làm
| Trang | Tính năng | Phase |
| --- | --- | --- |
| Users | List: name, added, email, role (Super Admin / Admin / tên preset / Custom, tính từ quyền), schools, status; Show Permissions (text quyền) | 1 |
| Users | Add User (name, email, password ≥ 8), Edit (quyền, owner, schools; name / email không sửa sau tạo); Start From a Role (10 preset), Select / Clear All | 1 |
| Users | Schools: All Schools (kể cả trường mới) / chọn từng trường; Admin / Super Admin luôn mọi trường | 1 |
| Users | Suspend / Turn back on, Delete (soft, tên giữ trên bản ghi cũ, email dùng lại được); suspend / delete → thu hồi mọi token | 1 |
| Users | Quy tắc: cần quyền `users`; không tự suspend / xoá mình; không bỏ quyền `users` của chính mình; chỉ Super Admin sửa / suspend / xoá Super Admin và cấp Super Admin; luôn còn ≥ 1 Super Admin active | 1 |
| Users | View Role Permissions: preset + quyền (API); chữ mô tả tính năng là nội dung tĩnh của FE | 1 |
| Profile | Ảnh (CarrierWave), Display Name (trống = name), Mobile (phonelib); name / email chỉ xem; session trả `display_name` | 2 |
| Company Settings | Quyền sửa = permission `users` (HTML), còn lại chỉ xem (`can_edit` trong response) | 3 |
| Company Settings | Logo upload / remove; Short Name; Theme Colour; Timezone; Date / Time Format; Business Units (rà, đã có cột) | 3 |
| Company Settings | Country: chọn 1 lần (chưa set) rồi khoá, ghi set_at / set_by; nước `live` mới chọn được (`GET /countries`) | 3 |
| Company Settings | Request a Change: chọn nước + lý do → Convoy Admin Approve / Decline, company Withdraw; 1 request pending / company; lịch sử | 3 |
| Calendars | Tabs: Public Holidays + calendar của company; năm ‹ ›; Observed Holidays (company / từng calendar); rà CRUD + MOM import đã có | 4 |
| Calendars | Holiday: cờ Observed, Saturday | 4 |
| Calendars | Trips Using This Calendar: trip, kind, ngày chạy, giờ, số run bị bỏ trong năm | 4 |

## Không làm (ghi backlog)
- Đổi mật khẩu, quên mật khẩu, thiết bị đang đăng nhập, refresh token: HTML không có màn (user chốt 02/11/2026).
- Card On Time / Speed Limit trong Company Settings: HTML không có, để sau (user chốt 02/11/2026).
- Cảnh báo maker-checker ("chỉ còn 1 user active") trên trang Users: cần Finance Settings.
- Áp giới hạn trường của user vào dữ liệu School Bus: làm cùng menu School Bus (Phase 1 chỉ lưu + trả).
- About Convoy: nội dung tĩnh, FE.
