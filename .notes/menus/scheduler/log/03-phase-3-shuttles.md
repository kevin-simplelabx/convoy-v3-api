# Phase 3 — Shuttle + Rate cards ✅ (30/10/2026)

## Quyết định
- Rails là app mới, không có trip cũ → **chỉ dùng price table** cho shuttle; bỏ các field legacy của HTML
  (pBy/pRun/price2/opc2/oEach/opcRun/oBasis/om). Cost của shuttle đi qua assignment (Phase 5), không có cost table.
- Đổi dạng bảng giá (Is For / By) giữ nguyên tổng: FE đang có `tableConvert` trong pricing.js → làm ở FE; server chỉ lưu và tính.
- Index / foreign key trên bảng có sẵn: migration riêng `concurrently` / `validate: false` + validate (strong_migrations).

## Bảng
| Bảng / cột | Ghi chú |
| --- | --- |
| trips + | shuttle_return (Direction 2), shuttle_separate_return (return dùng stops riêng), price_by all / direction / run, trip_value_per run / day, trip_value_return, route_tags (GIN), color, approved_riders_only, seat_reservation, head_count |
| trip_stops + | return_name (tên stop khi chạy chiều về, dùng chung stops) |
| trip_runs | direction, position (timing), start/end (từ times), trip_value (riêng run), standby_needed |
| trip_run_times | run × stop → giờ (bỏ trống = run không dừng ở stop đó) |
| trip_run_slots | Vehicle for Each Run: run × slot → xe, `unassigned`, group |
| trip_run_groups | Runs That Move Together |
| trip_price_cells | dòng (tất cả / direction / run) × cột (whole route / slot) → amount; unique theo COALESCE |
| rate_cards (+ periods, ranges, rates, distance_bands, amounts) | periods (days + ph, ranges qua nửa đêm, override), trip/hourly rate theo vehicle type, waiting, distance bands, stop fee, disposal, meet & greet |
| clients + | rate_card_id (rcAssign) |

## API (thêm vào `POST/PATCH /trips`)
- `runs_attributes: [{ id, direction, position, times: ["07:30", "", "07:55"], trip_value, standby_needed,
  slots_attributes: [{ slot_no, vehicle_id, unassigned, group_key }] }]`
  - `times` theo **thứ tự đi** của direction: Direction 1 = stops direction 1; Direction 2 = stops direction 2 khi
    `shuttle_separate_return`, else stops chiều đi đảo ngược.
  - `group_key` ("g1", "am"...): các slot cùng key thành một nhóm; trả về `group_key: "g<id>"`.
- `price_table: [{ row: "all"|"d1"|"d2"|"d1r0", col: "all"|"1".."N", amount }]` (thay toàn bộ bảng mỗi lần gửi).
- `route_tags`: list hoặc text có dấu phẩy.
- Kiểm tra như `schShPrep`: ít nhất 1 run, giờ ở stop đầu, giờ tăng dần, số giờ = số stop, return stops ≥ 2.
- Start / end của shuttle = run đầu tiên (Direction 1, timing 1).
- `GET /trips/:id/prices?date=` → mỗi slot (và mỗi run của shuttle) được bao nhiêu tiền ngày đó, kèm tổng.
- `POST /rate_cards/quote { client_id, date, start_time, vehicle_type_id, km, extra_stops }` → Price From Rate Card
  (card của client, else default; period theo giờ đón; distance band theo km FE gửi từ OSRM; phí stop thêm).

## Pricing (`Pricing::TripPrice`, port pricing.js runPrice)
- Shuttle: ô bảng giá; whole route chia số xe; per day / month chia số run của dòng, month chia thêm số ngày chạy trong tháng (Calendars::Context#trip_dates).
- Trip khác: giá slot (whole route chia xe / giá riêng từng slot), Disposal giá giờ × số giờ, slot 1 cộng phí Meet & Greet, per day / month cho trip lặp lại.
- School Run (paid months, No School) → Phase 8.

## Seeds
`35_rate_cards`: Standard Rates (default), Corporate Contract Rates (Google, DBS) — 4 period, 3 distance band, stop fee.
`41_shuttles`: MBC Campus Shuttle (3 stops, 2 hướng, 5 run, 2 xe, nhóm "am", giá theo tháng / direction, standby, Google Office Calendar);
Cross-site Shuttle (return stops riêng, giá mỗi run).

## Specs
100 examples (thêm 11): timetable + slot + group + bảng giá, giá theo run, return stops riêng, lỗi timetable, xoá run,
TripPrice (route share + M&G, giá riêng + disposal, giá tháng / ngày chạy trừ PH), rate card quote (period, qua nửa đêm, override PH, band, stop, card của client).

## Còn lại cho phase sau
- No Fixed Bus / Back to Regular Bus của run (drawer) → Phase 5.
- Assign page (trip_assignments theo run slot) → Phase 5.
- Occurrence: mỗi run × slot × ngày → Phase 4.
