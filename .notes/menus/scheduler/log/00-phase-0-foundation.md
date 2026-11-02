# Phase 0 — Foundation ✅ (30/10/2026)

## Đã làm
- Xoá code cũ: migrations, schema, models, controllers, blueprints, services, seeds, PLAN.md (còn trong git history, branch v3).
- Bỏ Active Storage, Action Mailbox, Action Text (upload dùng CarrierWave).
- Gems: acts_as_tenant, pundit, draper, blueprinter, carrierwave 3.1, pagy 9.4, ransack 6, audited 5.8, rspec-rails, factory_bot_rails, faker (dev/test).
- `config.time_zone = "Singapore"`, DB lưu UTC; mỗi request chạy trong timezone của company (`around_action`).
- Models: `Company` (tenant), `User` (Devise). Concern `TenantScoped` (acts_as_tenant + audited) cho mọi model của company từ Phase 1.
- Uploaders: `ApplicationUploader` (private, `storage/<model>/<mount>/<id>`), `ImageUploader` (≤1280 px + thumb 320, MiniMagick), `DocumentUploader`.
- Download file private: decorator tạo link ký `GET /api/v1/downloads/:token` (MessageVerifier, hết hạn 1 giờ, cần đăng nhập).
- Seeds: `db/seeds.rb` chạy `db/seeds/*.rb` theo thứ tự, idempotent; `SEED=00_platform bin/rails db:seed` chạy 1 file.
- Specs: 19 examples (User model, session, companies). Rubocop sạch.

## Quy ước API (áp dụng mọi phase)
- `namespace :api, defaults: { format: :json }` → `/api/v1/...`. JSON key **snake_case**.
- Thành công: `{ data: ... }`; list: `{ data: [...], meta: { page, limit, count, pages } }` (pagy, `?page=&limit=`).
- Filter list: ransack `?q[name_i_cont]=...`; mỗi model khai báo `ransackable_attributes` (allowlist).
- Lỗi: `{ error: { code, message, details? } }` — 401 unauthorized, 403 forbidden, 404 not_found, 409 conflict (`lock_version`),
  422 invalid (`details` = lỗi theo field), 400 bad_request. Convoy Admin ghi dữ liệu → 403 "View only...".
- Controller: `authorize` mọi action (Pundit `verify_authorized`), `policy_scope` cho index, `permitted_attributes` từ policy.
- Render: `render_data(record, Blueprint)` / `render_page(scope, Blueprint)`; object luôn qua decorator trước blueprint.
- File trong JSON: `{ url, thumb_url, name, size, content_type }` (`file_info` trong ApplicationDecorator). Upload = multipart.

## Auth
- Devise + cookie session (`_convoy_session`, SameSite=Lax). Endpoints:
  `POST /api/v1/session` (email, password), `GET /api/v1/session`, `DELETE /api/v1/session`,
  `PATCH /api/v1/session` (company_id — Convoy Admin chọn company để xem).
- Roles: `convoy_admin` (platform, không có company, chỉ xem), `admin` (mọi quyền), `member` (permissions[]); `owner` = Super Admin của company.
  Đổi tên từ HTML: `super` → `convoy_admin`.
- Driver app (mobile) sẽ cần token auth — quyết định khi tới phần driver app.

## Sample accounts (seed)
| Email | Password | Role |
| --- | --- | --- |
| admin@convoy.sg | Convoy123! | Convoy Admin |
| ops@simpledrive.sg | Simple123! | Admin, owner (SimpleDrive, code SD) |
| dispatch@simpledrive.sg | Simple123! | Member: vehicles |
| finance@simpledrive.sg | Simple123! | Member: finance, finview, vehfin |

## Gợi ý gem cho các phase sau (chưa cài, cần duyệt)
- `strong_migrations` — chặn migration nguy hiểm khi bảng lớn (trip_occurrences).
- `annotaterb` — ghi schema lên đầu model/factory.
- `bullet` (dev) — bắt N+1 ở Scheduler/occurrence.
- `oj` — JSON nhanh hơn cho response lớn (grid tuần).
- `shoulda-matchers` — spec association/validation ngắn gọn.
- `discard` — soft delete trip/vehicle (giữ quá khứ cho occurrence).
