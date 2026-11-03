# Convoy Admin — hiện trạng

- Chỉ role `convoy_admin` (`PlatformPolicy`); dữ liệu platform, không tenant (controller `skip_before_action :assign_tenant`).
- Transport Companies: `Companies::Create` (company + admin owner đủ quyền, code tự sinh từ tên); list có admin, schools / users, `is_current`.
- `message_terms` CRUD (term unique không phân biệt hoa thường).
- Discover: `discover_advertisers` (kind, premier, phí, %), `discover_placements` (kind trip / prog / ad / news, ảnh CarrierWave, vị trí,
  audiences string[], area, level, từ / đến, status draft / live / paused + ended_at → `status_on` draft / scheduled / live / paused / ended,
  views / taps / sold do Convoy App đếm). Kiểm khi publish như HTML.
- Company Leads: `company_leads` (ask từ app), `company_lead_domains` (status, note theo domain).
- Endpoint cho Convoy App (hiển thị Discover, đếm, gửi lead) làm cùng app (backlog).
