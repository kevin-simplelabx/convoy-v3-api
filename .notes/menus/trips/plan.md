# Trips menu API — Plan

> Bắt đầu 30/10/2026. Inventory: `scope.md`. Hiện trạng đúng nằm ở `../../domains/` khi phase xong.
> Mỗi phase: migration + model + policy + decorator + blueprint + controller + request spec + seed + `.api-documents/trips.md`.

## Phase 0 — Scope & plan ✅ (30/10/2026)
Rà HTML, chốt 4 quyết định (xem `decisions.md`): telematics làm bảng + seed; run skipped lưu row; Bookings đủ backend (admin ghi thay
phía client); chuông booking làm, email chỉ ghi lại.

## Phase 1 — Trips list ✅ (30/10/2026, xem log/01-phase-1-trips-list.md)
> Thực tế: endpoint là `GET /occurrences/list` (không phải `/trip_runs`, tránh trùng tên model `TripRun`).
- `GET /api/v1/trip_runs` (query object `Occurrences::ListQuery` đọc `trip_occurrences`, không ghost / removed / skipped):
  from, to (≤ 183 ngày), q, kind, operator (`own` / id / `none`), status group (`unassigned`, `assigned`, `live`, `completed`, `cancelled`), sort.
- `meta`: page + `counts` theo status group (áp mọi filter trừ status) + options kind / operator trong khoảng.
- Status group tính bằng SQL (giống `schSt`: live = đang trong giờ chạy). Index cần thêm nếu EXPLAIN chậm (vd. `(company_id, date, start_time)`).
- Search: `ILIKE` trên TID / title / plate / driver / operator / customer (không pg_trgm; tối ưu khi chậm).

## Phase 2 — Notices page ✅ (30/10/2026, xem log/02-phase-2-notices.md)
- `GET /notices`: thêm `q`, `meta.counts` (active / scheduled / ended).
- `notice_templates`: create / update / destroy (không xoá template cuối; notice giữ `message` riêng nên xoá template an toàn).

## Phase 3 — Rate Cards ✅ (30/10/2026, xem log/03-phase-3-rate-cards.md)
- CRUD `rate_cards` nested (periods → ranges, rates; distance bands → amounts; stop / disposal / M&G amounts) qua `RateCards::Save`.
- Archive / restore, set default (unique index có sẵn), `POST /rate_cards/standard` (card mẫu Off Peak / Peak / Night / Weekend & PH).
- `RateCards::Overlaps`, `RateCards::Gaps` → trả trong `show` + 422 khi lưu? (HTML chỉ cảnh báo → trả `warnings`, không chặn).
- Gán client: `clients.rate_card_id` (đã có) — `PATCH /rate_cards/:id/clients`.
- Bảng đã có; chỉ thêm cột nếu thiếu khi so với HTML.

## Phase 4 — Bookings (dữ liệu + form) ✅ (30/10/2026, xem log/04-phase-4-bookings.md)
> Thực tế: status `changed` → `awaiting_ack`; estimate dùng `RateCards::Pricer` (tách từ Quote); không dùng `RateCards::Quote` mở rộng.
Bảng (đều tenant + audited):
- `bookings`: number (company_sequences `booking`), client, client_site, coordinator_* , po_number, cost_centre, notes, source (console / portal / app), created_by, lock_version.
- `booking_attachments` (CarrierWave).
- `booking_days`: date (unique trong booking), position.
- `booking_trips`: kind one_way / two_way / disposal / airport, airport_direction, flight_no, start_time, return_time, hours, pax, luggage (cột theo size), contact_name / phone, note, distance_km, return_distance_km, status, estimate (decimal + breakdown jsonb snapshot).
- `booking_trip_points`: leg out / back, position, use pu / do / both / via, name, address, lat / lng, note.
- `booking_trip_standbys`: leg, location, minutes, lat / lng, note.
- `booking_trip_vehicles`: vehicle_type × count.
- `Bookings::Save` (giới hạn 10 / 10 / 10, ngày ≤ 10 ngày), `Bookings::Estimate` (dùng rate card + `RateCards::Quote` mở rộng), `Bookings::Status`.
- `GET /bookings` tab + q + counts; `show` (days → trips → estimate breakdown).

## Phase 5 — Bookings flow + thông báo ✅ (30/10/2026, xem log/05-phase-5-booking-flow.md)
> Thực tế: thêm trạng thái `cancelled`; changes items là text[]; preference cột theo kind.
- State trip: `pending` → (`changed` → ack → `pending`) → `approved` | `rejected`; `awaiting_client`. Gem `aasm` (đã duyệt).
- `Bookings::Approve`: tạo trip qua `Trips::Save` (Unassigned, Two Way → pair), trip value nhập tay, `trips.booking_trip_id` FK (thay `booking_ref`).
- `booking_trip_changes` (+ items) lịch sử sửa; ack / approve without waiting lưu `how` + note + by + at.
- `booking_cancel_requests` (booking hoặc trip, why, by, at, resolved).
- `booking_events` (kind new / client_approved / client_declined / acknowledged / cancel_request, booking, trip, text, actor) — feed chuông, query được.
- `user_notification_preferences` (user, kind bật / tắt, email, seen_at) + `notification_emails` (ghi lại, chưa gửi).

## Phase 6 — Trip History (list + chi tiết) ✅ (30/10/2026, xem log/06-phase-6-trip-history.md)
> Thực tế: on_time_minutes là cột trên companies; School Bus route không sinh skipped; outcome incomplete để Phase 7–8.
- Occurrence: status mới `skipped` — Generator tạo row cho ngày lịch bỏ qua (calendar / PH / day off); Scheduler, invoice, pay, `trip_runs` lọc bỏ.
  Sửa digest + verify + spec. Cột `cancelled_by` (client / company) nếu chưa có.
- `company_settings.on_time_minutes` (mặc định 5) hoặc cột trên companies.
- `GET /trip_history` (`TripHistory::Query`): outcome, on_time, worth_review, filter chip, sort, counts; `GET /trip_history/:occurrence_id?date=` chi tiết.
- `occurrence_notes` (occurrence_id, occurrence_date, body, author).
- Driver's report: `occurrence_driver_reports` (note) + `occurrence_report_photos` (CarrierWave) — seed (driver app ghi sau).
- Changes / trip log = audits của trip + run.

## Phase 7 — Correct Record ✅ (31/10/2026, xem log/07-phase-7-correct-record.md)
- `occurrence_corrections` (run, reason, author, outcome, vehicle_id, driver_id) + `occurrence_correction_stops` (stop, arrived_at, departed_at, boarded, alighted).
- Bản ghi gốc giữ nguyên; detail trả cả gốc + corrected, badge "Corrected". Run quá khứ không đi qua Sync.

## Phase 8 — Telematics (bảng + seed) ✅ (31/10/2026, xem log/08-phase-8-telematics.md)
- `occurrence_positions`: partition tháng (job tạo như trip_occurrences), (occurrence_id, occurrence_date, recorded_at, lat, lng, speed_kmh, heading). BRIN index trên recorded_at.
- `occurrence_stop_events`: stop, arrived_at, departed_at, boarded, alighted (nguồn thực tế cho On Time).
- `occurrence_trip_summaries`: distance_km, odometer_start / end, idle_minutes, max_speed, overspeed_count, harsh_brake / accel / corner.
- Seed GPS mẫu theo route các run đã qua (ít run để seed nhanh). Endpoint ingest: backlog (driver app).

## Phase 9 — Tài liệu API cho FE ✅ (31/10/2026, xem log/09-phase-9-api-docs.md)
`.api-documents/trips.md` (viết dần từng phase, phase này rà lại toàn bộ).
