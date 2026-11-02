# Platform — tenant, auth, file, audit, Claude

## Tenant & quyền
- Tenant = `companies`. Model công ty `include TenantScoped` (`acts_as_tenant :company, optional: true` + validate `company_id`).
  Mỗi request chạy trong tenant + timezone của company (`around_action`). DB lưu UTC, `config.time_zone = "Singapore"`.
- Bảng platform (không company): `vehicle_types`, `message_terms`, `public_holidays` preset (yml trong `config/presets/`).
- Roles: `convoy_admin` (không company, chọn company qua `PATCH /session`, **chỉ xem** → 403), `admin`, `member` (`permissions[]`), cờ `owner` (Super Admin).
  10 permission (`User::PERMISSIONS`); `admin` = owner hoặc đủ 10 quyền (do `Users::Save` set). Tên role hiển thị tính từ quyền (`User::ROLE_PRESETS`, không lưu).
  Pundit: `authorize` mọi action, `policy_scope`, `permitted_attributes`.
- Users (Settings > Users): quyền `users`; soft delete (`discarded_at`, email unique chỉ trong user chưa xoá); suspend / xoá → xoá mọi `allowlisted_jwts`.
  Luật: chỉ Super Admin đụng / tạo Super Admin, không tự suspend / xoá / bỏ quyền `users`, luôn ≥ 1 Super Admin active (`Users::Guard`).
  Trường: `all_schools` hoặc `user_schools` (admin luôn mọi trường) — chưa áp vào dữ liệu School Bus.
- Auth: Devise (mật khẩu) + **devise-jwt Bearer**, không cookie / session. `POST /session` → `Auth::IssueToken` trả JWT 30 ngày
  và ghi 1 row `allowlisted_jwts` (jti, exp, `name` thiết bị, `last_used_at`, `company_id` = company Convoy Admin chọn cho lần đăng nhập đó).
  `BaseController#current_jwt` → `Auth::FindToken` (chữ ký + exp + còn row). Sign out = xoá row (chỉ thiết bị đó); suspended → 401.
  Không tự gia hạn; job `clear_expired_sign_ins` xoá row hết hạn hằng ngày.

## Client Portal sign-in (02/11/2026)
- Token riêng scope `portal_account` (`PortalAccount`, devise-jwt, allowlist `portal_jwts` kèm `client_user_id` đã chọn); Convoy OS chỉ nhận scope `user`.
- Lần đầu / quên mật khẩu: mã 6 số (`portal_sign_in_codes`, HMAC, 15 phút, 5 lần thử, 5 mã / giờ) qua `PortalMailer` (deliver_later) →
  `set_password_token` (MessageVerifier, 1 lần) → `POST /portal/password`. Chưa SMTP: `dev_code` khi ENV `PORTAL_SHOW_CODE=1` (staging).
- Controller `Api::V1::Portal::*` (không Pundit / tenant; dữ liệu Portal sau này chạy trong tenant của client_user đã chọn).

## API
- `/api/v1`, snake_case; `{ data }`, `{ data, meta }` (pagy 9), lỗi `{ error: { code, message, details } }`.
- Render: decorator (Draper) → blueprint (Blueprinter + Oj) qua `render_data`, `render_page`, `render_list`.
- Ransack allowlist mỗi model. Doc cho FE: `.api-documents/`.

## File
- CarrierWave, private `storage/<model>/<mount>/<id>`. `ImageUploader` (1280 px + thumb 320), `DocumentUploader` (10 MB).
- Tải: link ký `GET /api/v1/downloads/:token` (1 giờ, **không cần header** vì `<img src>`; token mang company để tra trong đúng tenant), `file_info` trong ApplicationDecorator.

## Audit
- `audited` (jsonb), mỗi model tự khai; con của trip `associated_with: :trip` → "Changes to This Trip" / lịch sử run.

## Đọc tài liệu bằng Claude
- `document_reads` (kind, file | input_text, status, `result` jsonb, error, model, tokens) → `DocumentReadJob` → FE poll.
  Form gửi `document_read_id` để gắn đúng file đó.
- `Ai::Extract`: `client.beta.messages.create`, `claude-opus-5-5` (ENV `CLAUDE_MODEL`), structured outputs strict,
  server-side fallback (`server-side-fallback-2026-07-01`). `Ai::Attachment`: PDF / ảnh / xlsx-csv (roo) / txt.
- Readers (`app/services/ai/readers`): LogCard, Insurance, TripMessage, MaintenanceInvoice, RouteList. Thêm reader = 1 class + `DocumentRead::READERS`.
- Key: credentials `anthropic.api_key` hoặc ENV `ANTHROPIC_API_KEY` (user thêm sau). Spec dùng `FakeClaude`.

## Khác
- `CompanySequence.next!/next_block!` (row lock): client code, Trip ID.
- Giờ = phút (`MinuteTime`, `_hm`), tiền decimal(12,2), `TagList` cho cột array, soft delete bằng `discard`.
- Seeds `db/seeds/NN_*.rb` idempotent; `SEED=00_platform bin/rails db:seed` chạy 1 file.
