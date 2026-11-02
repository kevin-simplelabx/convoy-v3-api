# Scope: menu Trips (rail `assignment`) — rà 30/10/2026

Nguồn: `Convoy OS.dc.html` (Trips ~3973, Notices ~6842, Trip History = `Trip History.dc.html`, Bookings ~11081, Rate Cards ~11282),
`logic/mixins/scheduler.js` (`trpVals`), `notices.js`, `bookings.js` (bookings + rate cards), `logic/app-feed.js` (`bookingEvents`).
Submenu (`admin.js` `tripsIt` / `bkIt` / `rcIt`): **Trips**, **Trip History**, **Notices** · Bookings: **Bookings** · **Rate Cards**.
Quy tắc scope giữ như Scheduler: mở / dùng được từ các trang này thì làm hết.

## Làm
| Trang | Tính năng | Phase |
| --- | --- | --- |
| Trips | Danh sách run (không ghost): from–to ≤ 183 ngày, preset Today / Next 7 / Next 30 / Past 30; search TID, title, sub, kind, plate, driver, operator, customer; lọc kind, operator (Own fleet / tên / No vehicle); chip status (All / No Vehicle / Assigned / On the Road / Completed / Cancelled) có số đếm theo filter còn lại; sort ngày asc/desc; 50/trang | 1 |
| Trips | Cột: ngày, giờ, TID, title, sub, kind, plate (+ loại xe cần hoặc số ghế), driver, operator, pax, price, status. Open Scheduler / New Trip / mở run = FE dùng API có sẵn | 1 |
| Notices | Tab Active / Scheduled / Ended có số đếm, search message / audience; End Now, Edit (scheduled), Duplicate, Delete (không active) — đã có, bổ sung search + counts | 2 |
| Notices | Templates: thêm / sửa tên + message / xoá (luôn còn ≥ 1) | 2 |
| Rate Cards | List: tên, mô tả, loại xe, period, client đang dùng, default, archive / restore; View: bảng tóm tắt | 3 |
| Rate Cards | Edit: period (ngày mon..sun + ph, nhiều khung giờ, qua nửa đêm, override), trip rate + hourly rate theo loại xe; waiting time; distance bands; phí stop; disposal hourly / hourly + km; M&G; cảnh báo trùng (overlaps) và khoảng trống (gaps); card mẫu Standard; gán client | 3 |
| Bookings | Booking: client (+ site), coordinator (name, org, email, phone), PO, cost centre, notes, file đính kèm (CarrierWave); mã `<company code><YY><6 số>`; ≤ 10 ngày cách nhau ≤ 10 ngày, ≤ 10 trip / ngày, ≤ 10 xe / trip | 4 |
| Bookings | Trip của booking: One Way / Two Way / Disposal (giờ) / Airport (arr/dep, flight); giờ đi, giờ về; route giống trip form (pick-up, stops, drop-off, use, ghi chú điểm, pin), way back riêng, standby mỗi chiều; pax, luggage theo size, contact, note, xe (loại × số), cảnh báo ghế | 4 |
| Bookings | Ước giá theo rate card của client (hoặc default): period theo giờ, Two Way = đi + về, Disposal = giờ, distance / stop / disposal km, breakdown; tổng booking (bỏ trip rejected) | 4 |
| Bookings | Tab Pending / Approved / Rejected / Completed có số đếm, search (mã, coordinator, client); status booking tính từ trip | 4 |
| Bookings | Từng trip: Approve & Convert (nhập trip value, Two Way → 2 trip pair, Unassigned trên Scheduler); Edit → `changed` chờ client; client acknowledge (admin ghi thay + cách); Approve Without Waiting (how: Phone / Email / WhatsApp / In person + note); Reject (lý do bắt buộc); lịch sử thay đổi; Open in Scheduler | 5 |
| Bookings | Client approval (`awaiting client approval`), yêu cầu huỷ trip / booking (lý do, ai, lúc) — admin ghi thay; endpoint Portal làm sau | 5 |
| Bookings | Chuông: sự kiện new / client approved / declined / acknowledged / cancel request trong 14 ngày, đếm chưa xem; mỗi user chọn loại + email (email chỉ ghi lại) | 5 |
| Trip History | Run đã qua (+ skipped): outcome Completed / Incomplete / Cancelled by Client / Cancelled by Us / Skipped by Calendar; on-time (trễ > N phút, N trong company settings, mặc định 5); distance, pax; search; lọc ngày + chip (client, kind, xe, driver, outcome, on-time, "worth a second look" = có note / correction / breakdown / replacement); sort; table + split | 6 |
| Trip History | Chi tiết: xe + crew, trip info, standby, POC (requestor / guest), passenger list (School Run / School Bus), driver's report (note + ảnh), changes (audits trip), replacements, trip log | 6 |
| Trip History | Notes (thêm, giữ tên + giờ); Correct Record: outcome, xe (plate), driver, giờ đến / rời từng stop, boarded / alighted, lý do bắt buộc; badge "Corrected"; giữ bản gốc | 7 |
| Trip History | Telematics: GPS trail + replay, speed history, driving summary (km, odometer, idle, harsh events), stop record kế hoạch vs thực tế — bảng + seed mẫu | 8 |

## Không làm (ghi backlog)
- Thời tiết / giao thông (NEA, LTA DataMall) trong Trip History — HTML ghi "sample data".
- Endpoint nhận GPS / sự kiện từ driver app hoặc thiết bị — làm cùng driver app.
- Endpoint cho Client Portal / Convoy App (đặt booking, duyệt, xác nhận, xin huỷ) — làm cùng Portal.
- Gửi email thật cho thông báo booking.
- Bản đồ / geocode / OSRM: FE làm như trip form; Rails nhận km đã tính (lưu `distance_km` trên trip của booking).
