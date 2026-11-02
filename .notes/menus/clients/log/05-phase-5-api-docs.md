# Phase 5 — Docs & kiểm tra (02/11/2026)

- `.api-documents/clients.md` (§ 1 Managed Clients, § 2 sites / customers / bookable / points, § 3 Client Users, § 4 roles,
  § 5 Client Portal sign-in, § 6 thay đổi endpoint cũ, § 7 chưa làm); `README.md` bảng menu; `integration.md` (file list, page id
  `clients`, tài khoản Portal mẫu); `screen-map.md` (mục Clients thay "pickers only", Portal sign-in trong Public pages).
- OpenAPI: `clients.md` vào `MENUS`; folder Clients thêm `client_users`; folder mới "Client Portal" (portal/sessions, portal/passwords),
  các action đăng nhập Portal không cần token (`PUBLIC`).
- Kiểm tra: 252 specs, rubocop sạch, seed ×2, `occurrences:verify`, link anchor doc không hỏng.
