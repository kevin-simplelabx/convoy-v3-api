# Scope: menu Reports (rail `reports`, icon `insert_chart`), rà 02/11/2026

Nguồn: `Convoy OS.dc.html` ~11549–11900, `logic/mixins/reports.js` (rpVals, rpModel, rpDwVals), `logic/reports.js` (month: số mẫu).
Một trang: **Shuttle Report** cho client — chọn client → route Corporate Shuttle → kỳ (12 tháng gần, 5 quý, 2 năm).

## Làm
| Phần | Nội dung |
| --- | --- |
| Lọc | Client (có route Corporate Shuttle), Shuttle Route, Period; chips Client / Period / Service Days / Bus / … |
| KPIs | Utilisation (riders / (seats × runs)), Total Riders, avg / ngày, On-Time Performance; thay đổi so với kỳ trước |
| Utilisation by Shuttle Timing | mỗi timing (run): direction, util, riders, avg, max, tag (busiest / quietest) |
| Stop Activity | boarding theo pick-up mỗi direction (route ≥ 3 stop), % |
| Monthly Trend | 12 tháng: riders, util, on-time |
| Riders per Timing per Day | lưới timing × ngày của 1 tháng (click → stop record) |
| On Time Report | đếm On Time / Early / Late / Left Early / Skipped, worst timing / day; lưới run × stop × ngày (giờ thực, trạng thái, amended) |
| Allowance | `clients.on_time_allowance` (−1 / +1, có sẵn); early = 5 phút |
| Stop record / Amend Record | dùng lại Trip History (`GET /trip_history/:id`, `POST /trip_history/:id/correction`) |
| Export | CSV / PDF = FE (từ dữ liệu) |

## Chốt với user (02/11/2026)
- **Dữ liệu thật** (không dùng số mẫu của HTML): `occurrence_stop_events` + Correct Record (`TripHistory.stop_record`). Run chưa có stop event = chưa có dữ liệu.

## Tự quyết
- Quyền xem: `vehicles`, `finance` hoặc `finview` (HTML: sup / vehicles / finOk). Chỉ đọc.
- Seed thêm stop events cho run MBC Campus Shuttle 3 tháng gần (không GPS) để report có số.
