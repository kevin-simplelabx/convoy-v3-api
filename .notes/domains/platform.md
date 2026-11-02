# Platform — tenant, auth, file, audit, Claude

## Tenant & quyền
- Tenant = `companies`. Model công ty `include TenantScoped` (`acts_as_tenant :company, optional: true` + validate `company_id`).
  Mỗi request chạy trong tenant + timezone của company (`around_action`). DB lưu UTC, `config.time_zone = "Singapore"`.
- Bảng platform (không company): `vehicle_types`, `message_terms`, `public_holidays` preset (yml trong `config/presets/`).
- Roles: `convoy_admin` (không company, chọn company qua `PATCH /session`, **chỉ xem** → 403), `admin`, `member` (`permissions[]`), cờ `owner`.
  Permission đang dùng: `vehicles` (ghi fleet), `finance`... Pundit: `authorize` mọi action, `policy_scope`, `permitted_attributes`.
- Auth: Devise + cookie session (`_convoy_session`). Driver app (mobile) sẽ cần token — chưa quyết.

## API
- `/api/v1`, snake_case; `{ data }`, `{ data, meta }` (pagy 9), lỗi `{ error: { code, message, details } }`.
- Render: decorator (Draper) → blueprint (Blueprinter + Oj) qua `render_data`, `render_page`, `render_list`.
- Ransack allowlist mỗi model. Doc cho FE: `.api-documents/`.

## File
- CarrierWave, private `storage/<model>/<mount>/<id>`. `ImageUploader` (1280 px + thumb 320), `DocumentUploader` (10 MB).
- Tải: link ký `GET /api/v1/downloads/:token` (1 giờ, cần đăng nhập), `file_info` trong ApplicationDecorator.

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
