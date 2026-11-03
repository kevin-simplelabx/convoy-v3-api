# Scope: menu Convoy Admin (chỉ super admin), rà 02/11/2026

Nguồn: `Convoy OS.dc.html` 4067–4500, `logic/mixins/admin.js` (`saVals_companies`), `logic/mixins/trip-ai.js` (`taTermsVals`),
`logic/mixins/discover.js`, `logic/mixins/leads.js`. Trang: Transport Companies, Message Terms, Discover, Company Leads.

## Làm
| Trang | Tính năng |
| --- | --- |
| Transport Companies | List (admin email, schools, users, created, cap External Vehicles sửa tại chỗ, add-on School Run / Route List Import, Open = chọn company); New Company + admin (name, email, password ≥ 8) |
| Message Terms | CRUD (term, means, kind veh / svc / place / oth, trùng tên = lỗi, by / at), sắp theo kind |
| Discover | Advertisers (name, kind tc / attr / prog / brand, phí listing / tháng, % commission, email, Premier Partner); Placements (kind trip / prog / ad / news, kicker, title, sub, màu, ảnh CarrierWave, CTA, giá người lớn / trẻ em, seats, ngày, pick-up points, transport company, bus, bán public, link, promo code, vị trí home / discover / push, from / to, slot std / featured, đối tượng parents / staff / bookers / public, khu vực, cấp học, phí, %); trạng thái draft / scheduled / live / paused / ended; Pause / Resume / End now / Duplicate / Delete draft; KPIs (live, views, taps, sold, revenue = phí + commission); tabs + search |
| Company Leads | Ask từ Convoy App (domain, tên công ty, contact, người đồng ý ghi tên, nguồn); gom theo domain; status new / contacted / demo / signed / lost + note (by / at); tabs Open / Signed Up / Not Interested |

## Chốt với user (02/11/2026)
- Discover + Leads: làm phía Convoy Admin (bảng + CRUD). Số view / tap / sold và ask đến từ Convoy App: có bảng / cột, dữ liệu seed;
  endpoint cho Convoy App làm cùng app.

## Tự quyết
- Chỉ Convoy Admin (role `convoy_admin`) đọc / ghi các trang này (dữ liệu platform, không theo tenant). Company user → 403.
