# Phase 1b — Vehicle form (Edit Vehicle) ✅ (30/10/2026)

Gems: `anthropic` 2.3.0 (SDK chính thức), `roo` 4.0 (xlsx/csv → text cho Claude).

## Đọc tài liệu bằng Claude (dùng chung cho mọi phase)
- Bảng `document_reads` (kind, file CarrierWave hoặc input_text, status pending/done/failed, `result` jsonb = bản chụp câu trả lời, error, model, tokens).
- `POST /api/v1/document_reads { kind, file | input_text }` → **202**; `DocumentReadJob` đọc ở nền (dev: async, prod: solid_queue);
  FE poll `GET /api/v1/document_reads/:id` tới khi `done` / `failed`. Chỉ người tạo read mới xem được.
- Sau đó FE gửi form kèm `document_read_id` → server gắn **chính file đó** vào record (không upload lại) và điền field trống.
- `Ai::Extract`: 1 call `client.beta.messages.create`, model `claude-opus-5-5` (ENV `CLAUDE_MODEL`), structured outputs
  (`output_config.format` json_schema strict), effort theo reader (log card / insurance: `low`), server-side fallback
  (`betas: server-side-fallback-2026-07-01`, `fallbacks: :default`); xử lý refusal, max_tokens, lỗi API → `ApplicationService::Error` (422).
- `Ai::Attachment`: PDF → document, ảnh → image (HEIC... → JPEG bằng MiniMagick), xlsx/csv → text (roo, tối đa 2000 dòng), txt → text.
- Reader = prompt + schema + clean (`Ai::Readers::LogCard`, `Ai::Readers::Insurance`); thêm reader mới bằng 1 class + 1 dòng trong `DocumentRead::READERS`.
- API key: Rails credentials `anthropic.api_key` hoặc ENV `ANTHROPIC_API_KEY` (chưa set trong máy dev → read sẽ `failed` với "Reading with Claude is not set up").

## Log card
- Cột trên vehicles: chassis_number, engine_number, registered_on, coe_expires_on, road_tax_expires_on.
- `vehicle_log_cards`: file, current (1 / xe), plate_on_card, plate_conflict.
- `POST /vehicles/:id/log_cards { file | document_read_id }` → card mới current, card cũ sang Past Log Cards, điền field trống, `meta.filled`.
- Plate trên card khác xe → `plate_conflict`: **PATCH vehicle bị chặn (422)** tới khi `PATCH /vehicles/:id/log_cards/:card_id/resolve_plate { use: card | vehicle }`.
- `DELETE` chỉ cho past card.

## Insurance
- `vehicle_insurance_policies` (1 current / xe): insurer, policy_number, cover_type, starts_on, ends_on, excess, excess_third_party,
  hire_purchase_company, agent, holder, premium (trước GST), gst, total, debit_note_number, debit_note_date, paid_on, renewed_at;
  `expiry_status` (expired / due_soon ≤30 ngày / valid / none), `cover_months`.
- `vehicle_insurance_documents` (≤5 / policy): file, kind policy / certificate / invoice / other, plate_on_document, plate_differs (chỉ cảnh báo).
- `GET|POST /vehicles/:id/insurance_policies`, `PATCH :id` (chỉ current), `DELETE :id` (chỉ past), `POST insurance_policies/renew`
  (current → past; policy mới mang sẵn insurer, agent, HP, cover, starts_on = ngày sau hết hạn cũ).
- `POST /vehicles/:id/insurance_documents { file | document_read_id, kind }` (tạo current policy nếu chưa có, điền field trống, `meta.filled`),
  `PATCH :id { kind }`, `DELETE :id`.
- Vehicle list trả `insurance { insurer, ends_on, status }` và `plate_conflict`.

## Seeds
`31_vehicle_documents`: PC7475L policy từ PDF thật (Income Insurance, 27/06/2026–26/06/2027, premium 1,525.67 + GST 137.31),
PC7939R file scan (để Claude đọc), log card details cho PD3318K, PE1290S.

## Specs
63 examples (thêm 14): Ai::Extract request shape (fallback, strict schema, PDF block, CSV → text, refusal, lỗi API),
readers clean, document read async + poll + private, log card fill / past / plate conflict chặn lưu, insurance fill / ≤5 file / renew / list.
Claude được thay bằng `FakeClaude` trong mọi spec (không gọi mạng).
