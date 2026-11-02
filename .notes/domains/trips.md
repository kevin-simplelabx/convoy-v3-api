# Trips — hiện trạng

Template của các run. Lưu qua một service duy nhất `Trips::Save` (nested + two-way + sync occurrence inline).

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| trips | kind `ad_hoc`, `corporate_shuttle`, `airport_transfer`, `disposal`, `school_run`; client (+ site); title / label; Trip ID; ngày giờ (phút), days int[] (0 = CN), end_mode none / never / date / count; calendar; pax, luggage; requestor, guest; airport; revenue (price, price_per, price_set, price_basis, hourly_rate); cost (trip_value*, operator_cost, operator_cancel_rule); sub-contract (end customer = Service For); two-way (pair, is_return, return_billing); shuttle (shuttle_return, shuttle_separate_return, price_by, trip_value_per, route_tags, color, rules); `no_fixed_bus`; School Run (session, paid months, No School); lock_version; discard |
| trip_stops (+ photos ≤3, students) | direction 1 / 2, position (DEFERRABLE unique), use pu / do / both / via, pin, note, Street View, client_site, scheduled_time, return_name |
| trip_route_vias | pin trên đường sau stop `from_position` |
| trip_vehicle_requirements | vehicle_type × count |
| trip_vehicle_slots | slot 1..N: xe + giá riêng |
| trip_standbys (+ photos) | `report_time` = start − minutes |
| trip_attachments | ≤10 file |
| trip_runs, trip_run_times, trip_run_slots, trip_run_groups | timetable shuttle; times theo thứ tự đi của direction; Vehicle for Each Run; Runs That Move Together (`group_key` g<id>) |
| trip_price_cells | price table shuttle (row all / d1 / d2 / run key × col all / slot) |
| trip_time_changes | Every Run From Today (effective_from, minutes, run) |
| trip_assignments (+ slots) | From This Date On: assignee own / operator / none, xe, pay run / day / month |

## Quy tắc
- Trip ID: `TID` + số; trip lặp giữ block số liên tiếp (1 số / ngày), Never = block 3653; nhiều xe thêm `-slot`.
- Shuttle chỉ dùng price table (bỏ field legacy HTML); đổi dạng bảng giữ tổng làm ở FE. Start/end = run đầu.
- Two-Way: chỉ Ad Hoc mới; return copy outbound, title "(Return)", pair 2 chiều, `return_billing` theo khoảng cách stop ≤ 200 m.
- Validation theo `schSaveTrip` / `schShPrep` của HTML (message tiếng Anh như prototype).
- Giá: `Pricing::TripPrice` (port pricing.js; route share, giá slot, giờ Disposal, M&G slot 1, per day / month, School Run paid months).
  `RateCards::Quote` cho Price From Rate Card.

## Rate cards (Trips > Rate Cards)
| Bảng | Ghi chú |
| --- | --- |
| rate_cards | name unique (lower), description, default_card (1 active / company), archived_at, waiting, M&G, distance / stop / disposal flags, lock_version |
| rate_card_vehicle_types | cột của card (vehicle type, position) |
| rate_card_periods (+ ranges, rates) | days mon..sun + ph, override; range phút, qua nửa đêm; trip_rate + hourly_rate theo loại xe |
| rate_card_distance_bands, rate_card_amounts | band (up_to_km null = cuối, per_km chỉ band cuối); amount kind distance_band / stop_fee / disposal_km theo loại xe |

- `RateCards::Form` → `Save` (thay toàn bộ con, kiểm lock trước), `Check` (overlaps / gaps, chỉ cảnh báo), `Standard` (card mẫu),
  `ChangeState` (default không archive; card có client không archive; còn ≥ 1 active; archived không làm default).
- Client dùng `clients.rate_card_id` (active) hoặc card default; chọn default = null.
- Fill from Message: reader `TripMessage` → `Trips::MessageForm` → `forms[]` đúng params `POST /trips`. Message Terms chỉ seed.
- Assign page: `Assignments::Board / Create / Remove`; cost của shuttle đi qua assignment.

## Bookings (Trips > Bookings)
| Bảng | Ghi chú |
| --- | --- |
| bookings | number `<code><YY><6 số>`, client (+ site, end customer / Service For), coordinator, PO, cost centre, notes, source, estimate_amount (bỏ trip rejected), lock_version |
| booking_days | date unique trong booking; ≤ 10 ngày, cách nhau ≤ 10 ngày |
| booking_trips | ≤ 10 / ngày; kind one_way / two_way / disposal / airport; status (aasm) pending / awaiting_ack / awaiting_client / approved / rejected / cancelled (3 cái cuối = locked); approval_*, acknowledged_*, rejected_*, cancelled_at; estimate_amount + estimate_lines (jsonb, lúc lưu) |
| booking_trip_changes | items text[] ("Pick-up time: 08:00 to 09:00"), changed_by |
| booking_cancel_requests | booking hoặc 1 trip, reason, requested_by_name, status open / accepted / declined |
| booking_events | kind new_booking / client_approved / client_declined / acknowledged / cancel_request — chuông (14 ngày) |
| user_notification_preferences, notification_emails | bật / tắt từng kind + email, seen_at; email chỉ ghi lại |
| trips.booking_trip_id | trip Scheduler sinh ra khi approve (Two Way: cả 2) |
| booking_trip_points / standbys / vehicles | leg out / back; way back mặc định = đảo way there; ≤ 5 stop; ≤ 10 xe |
| booking_attachments | ≤ 10 file |

- `Bookings::Save` (TripBuilder + luật form), `Bookings::Estimate` (qua `RateCards::Pricer`, dùng chung với `RateCards::Quote`).
- Luồng: `Bookings::Approve` (→ `Trips::Save`, run Unassigned), `TripAction` (reject, client steps), `CancelRequest`
  (accept → cancelled + huỷ run chưa chạy), `Notify` (event + email ghi lại), `Assignment.load!` (nhãn Unassigned / Assigned).
- Sửa trip chưa locked có thay đổi → awaiting_ack (client phải xác nhận, hoặc Approve Without Waiting kèm how).
- Tab: pending (có trip đang chờ) / rejected (không trip approved) / completed (mọi trip approved đã qua) / approved — `Booking.in_tab`, `#tab`.

## Seeds
`35_rate_cards` (Standard + Save), `46_bookings`, `40_trips`, `41_shuttles`, `42_assignments` (+ School Run ở `44_school_runs`).
