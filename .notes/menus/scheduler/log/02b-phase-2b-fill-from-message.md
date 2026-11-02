# Phase 2b — Fill from Message ✅ (30/10/2026)

Dán một yêu cầu đặt xe (WhatsApp, email, ghi chú) vào trip form → Claude đọc ra từng trip → FE điền form (chọn trip bằng pills,
Undo Fill ở FE). Không lưu gì cho tới khi user bấm Save như bình thường.

## Luồng
1. `POST /api/v1/document_reads { kind: "trip_message", input_text }` → 202 (job nền, chạy trong company + timezone của company).
2. Poll `GET /api/v1/document_reads/:id` tới `done`.
3. `result`:
   - `client_id`, `client_name` (khớp Managed Client: đúng tên, else tên này chứa tên kia), `client_raw` (như trong tin nhắn — FE hiện "client not on the list"),
   - `contact {name, phone, email, org}`, `notes`, `assume` (Read As), `miss` (Not in the Message),
   - `trips[]` (đã làm sạch: type, date, time, return_time, hours, direction, terminal, flight, flight_time, pickup, stops, dropoff, pax, bags, luggage, vehicles, guest, signboard, label, price, price_for, mg_fee, notes),
   - `forms[]`: mỗi trip một `{ trip, return_trip, filled, notes }` — `trip` / `return_trip` đúng tên params của `POST /trips`.
4. FE gửi `POST /trips { trip: form.trip + phần user sửa (end_time...), return_trip: form.return_trip }`.

## Quy tắc chuyển (port taNf)
- adhoc / twoway → `ad_hoc` (twoway có `return_trip`: start = return_time, stops đảo ngược); disposal; airport → `airport_transfer`.
- Airport: arrival → pick-up "Changi Airport T#"; departure → drop-off; signboard → meet_and_greet; mg_fee (arrival) → meet_and_greet_fee.
- Giá: Disposal → `hourly_rate`, giá cả gói chia số giờ; twoway "both" → chia 2; 2+ xe → `price_per` route / vehicle, `price_set` same; `notes` giải thích cách đọc.
- Vehicles: chỉ các type đang bật của company (`vehicle_type_id`); `vehicles_count` = tổng.
- Guest trùng contact (tên bỏ Mr/Ms/Dr, hoặc số điện thoại) → bỏ, giữ Guest = Requestor.
- `end_time` không có trong tin nhắn → FE tính từ route như khi nhập tay.

## Prompt
Hôm nay (timezone company), Clients (≤300 tên), Vehicle Types (`key = Name | N seats`), Message Terms; tin nhắn ≤12.000 ký tự.
Structured outputs (schema strict), effort `medium`, server-side fallback.

## Message Terms
Bảng platform `message_terms` (term, means, kind veh / svc / place / oth), seed 11 term mặc định từ `config/presets/message_terms.yml`.
Màn sửa (Convoy Admin) chưa làm — không mở từ Scheduler.

## Specs
89 examples (thêm 7): prompt chứa đủ ngữ cảnh, khớp client, làm sạch, bỏ guest trùng, giá theo xe / route / 2 chiều / theo giờ,
airport arrival + M&G, không có trip, và end-to-end: document read → forms → `POST /trips` tạo được trip.
