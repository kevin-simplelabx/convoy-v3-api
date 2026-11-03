# Phase 1–3 — Dashboard (02/11/2026)

- Layout lưu server (user chốt): `dashboard_layouts` + `GET / PUT / DELETE /dashboard/layout` (ép x / y / cols / rows về số, lọc widget không có quyền, validate lưới).
- `GET /dashboard/widgets` (catalogue theo quyền), `GET /dashboard?period=&widgets[]=` (`Dashboard::Widgets`, dữ liệu thật; widget chưa có nguồn
  trả `available: false` + lý do — user chốt). Tự quyết: giờ sẵn có 12 h / xe / ngày; Clients at Risk = on-time < 95 % hoặc hóa đơn quá hạn.
- Docs `.api-documents/dashboard.md`, README, integration, screen-map, OpenAPI folder Dashboard. Spec `dashboard_spec.rb` (2).
