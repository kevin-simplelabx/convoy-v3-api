# Clients menu API — Plan

> Bắt đầu 02/11/2026. Inventory: `scope.md`. Hiện trạng đúng ở `../../domains/clients.md` (tạo mới) + `platform.md` khi phase xong.
> Mỗi phase: migration + model + policy + decorator + blueprint + controller + request spec + seed + `.api-documents/clients.md`.
> Gem mới: không (devise, devise-jwt, solid_queue, ActionMailer có sẵn).

## Phase 0 — Scope & plan ✅ (02/11/2026)
Chốt với user: làm luôn đăng nhập Client Portal; xoá client chặn khi còn trip / booking đang chạy; billing contacts là bảng;
mã một lần qua mailer, dev / staging trả `dev_code` khi `PORTAL_SHOW_CODE=1`.

## Phase 1 — Managed Clients: list, form, record, delete ✅ (02/11/2026, xem log/)
- Rà `ClientsController` / policy (quyền ghi: `vehicles`? xem HTML `clIt`: sup / vehicles / users / finance) + blueprint view list (users_count) / detail.
- Form: kiểm UEN (dùng lại validator của operators), `school_id` (client là school: `schools.client_id`), `school_calendar_id` (→ `schools.calendar_id`, resync route).
- `DELETE`: chặn khi còn trip kept hoặc booking chưa xong; discard.
- On-Time Allowance: `PATCH` field có sẵn.

## Phase 2 — Sites, billing, customers, bookable vehicles, pick-up points ✅ (02/11/2026, xem log/)
- `client_sites`: `school_id` (unique khi có), `own_billing` bool, `billing_name`, `billing_uen`, `billing_address`, `created_by_id`.
- Bảng `client_billing_contacts` (polymorphic `billable` client / site, name, email, send_as to / cc, attention, position).
- Xoá site: chặn khi trip shuttle dùng site (stop gắn site) — rà cột trên trip stops.
- Bảng `client_bookable_vehicle_types` (client, vehicle_type, unique); rỗng = mọi type.
- `client_pickup_points.created_by_id`.

## Phase 3 — Client Users ✅ (02/11/2026, xem log/)
- `portal_accounts` (email unique, encrypted_password, name, last_sign_in_at; 1 người / email dùng cho mọi client).
- `client_users` (company, client, portal_account, name, title, email, role enum 7, created_by, discarded_at; unique (client, email) kept)
  + `client_user_sites`. Luật trong `ClientUsers::Save` / `Remove`. `GET /client_users/roles`.

## Phase 4 — Client Portal sign-in ✅ (02/11/2026, xem log/)
- Devise + devise-jwt cho `PortalAccount` (scope riêng, allowlist `portal_jwts`, chọn `client_user_id` cho token).
- `portal_sign_in_codes` (portal_account, purpose first / reset, code_digest, expires_at 15', attempts, used_at).
- `/api/v1/portal/session`: lookup (email → `password` / `code`), code (gửi lại / quên), verify (→ set_password_token), password (đặt + token),
  create (email + password), show, update (chọn account), destroy. Rate limit Rails 8. `PortalMailer.sign_in_code`.

## Phase 5 — Docs & kiểm tra ✅ (02/11/2026, xem log/)
- `.api-documents/clients.md` (+ phần Client Portal sign-in), integration, screen-map, README; `api_docs:all`.
- domains, data-ownership, backlog; rspec, rubocop, seed ×2, `occurrences:verify`.
