# Settings menu API — Plan

> Bắt đầu 02/11/2026. Inventory: `scope.md`. Hiện trạng đúng nằm ở `../../domains/platform.md` (+ `calendars.md`) khi phase xong.
> Mỗi phase: migration + model + policy + decorator + blueprint + controller + request spec + seed + `.api-documents/settings.md`.
> Gem mới: không cần (dùng discard, phonelib, CarrierWave, devise-jwt có sẵn).

## Phase 0 — Scope & plan ✅ (02/11/2026)
Rà HTML, chốt: không làm auth ngoài HTML (đổi / quên mật khẩu, thiết bị, refresh); On Time / Speed Limit để sau;
xoá user = soft delete, email dùng lại được.

## Phase 1 — Users ✅ (02/11/2026, xem log/)
- Migration `users`: `discarded_at` (index), thay unique `email` bằng partial unique `WHERE discarded_at IS NULL` (concurrently),
  `all_schools boolean default true`, `display_name` (dùng ở Phase 2), `created_by_id`.
- Bảng `user_schools` (user, school, unique cặp, FK) — quyền theo trường, query được.
- `User`: `include Discard::Model`; `ROLE_PRESETS` (owner, admin, opsmgr, planner, opsexec, libmgr, fleet, finmgr, finops, viewer: name, tag, permissions);
  `role_label` (Super Admin / Admin / preset khớp đúng quyền / Custom); role `admin` khi đủ 10 quyền, ngược lại `member` (tự set).
  Đăng nhập chặn user đã xoá (`active_for_authentication?`).
- `Users::Save` (create / update): validate quy tắc owner, quyền `users` của chính mình, ≥ 1 owner active, schools thuộc company.
  `Users::SetStatus` (suspend / activate), `Users::Remove` (discard): chặn tự làm với mình, bảo vệ owner, thu hồi `allowlisted_jwts`.
- `GET /users` (ransack q, status; `meta.counts`), `GET /users/:id`, `POST`, `PATCH`, `POST /users/:id/suspend|activate`, `DELETE`,
  `GET /users/roles` (presets + danh sách quyền). Policy: quyền `users`; Convoy Admin chỉ xem.
- Seed `NN_users`: mỗi company vài user theo preset, 1 suspended, 1 đã xoá, user giới hạn trường.

## Phase 2 — Profile ✅ (02/11/2026, xem log/)
- `GET / PATCH /api/v1/profile` (multipart: `display_name`, `mobile` (phonelib), `avatar`, `remove_avatar`); name / email chỉ đọc.
- `UserBlueprint` thêm `display_name`, `avatar_url` (link ký); session trả về cùng.

## Phase 3 — Company Settings ✅ (02/11/2026, xem log/)
- Policy `CompanyPolicy#update?` = Convoy Admin hoặc company của mình + `can?(:users)`; response `can_edit`.
- Logo: rà upload multipart + `remove_logo`; trả `logo_url`.
- Country: cột `country_set_at`, `country_set_by_id`; company chỉ chọn khi chưa set (sau đó khoá); `config/presets/countries.yml`
  (từ `logic/country.js`: code, name, live, tz, currency, phone, map, weather, traffic) + `GET /countries`.
- Bảng `company_country_requests` (company, from_country, to_country, reason, status pending / approved / declined / withdrawn (aasm),
  requested_by, decided_by, decided_at; partial unique 1 pending / company).
  `POST /company/country_requests`, `POST .../:id/withdraw`; Convoy Admin `GET /country_requests`, `approve` (đổi country + set_at / by), `decline`.
- Seed: 1 request pending (company mẫu khác), 1 đã decline.

## Phase 4 — Calendars page ✅ (02/11/2026, xem log/)
- `GET /public_holidays?year=` thêm `saturday`; rà observed / import MOM theo năm.
- `GET /calendars/:id?year=` lọc days theo năm (range chạm năm); `GET /calendars/:id/trips?year=` (và cho Public Holidays:
  `GET /public_holidays/trips?year=` — trip không calendar, skip PH): trip, kind, ngày chạy, giờ, `runs_skipped` trong năm (`Calendars::Context`).
- Rà policy: Calendars cần `vehicles` hoặc quyền finance (HTML `holOk`).

## Phase 5 — Docs & kiểm tra ✅ (02/11/2026, xem log/)
- `.api-documents/settings.md`, `integration.md`, `screen-map.md`; `bin/rails api_docs:all` (convoy-v3-api.openapi.json, folder Settings).
- `domains/platform.md`, `calendars.md`, `data-ownership.md`, `README.md`, backlog; rspec, rubocop, seed ×2, `occurrences:verify`.
