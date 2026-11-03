# Phase 4 — Accept, Route Fit, first invoice (03/11/2026)

- **Route Fit** (`RouteFit`, port `logic/route-fit.js` nguyên công thức: ROAD 1.3, dwell (base + per child) / 60, tốc độ từ timetable 0.2–0.9 km/phút,
  insert AM / PM, impact text, fit → fits / new / full / area). `RouteFit::Routes` (rfRoutes): plan của session đang chạy ngày đó (không có thì plan mới nhất
  có route), route không ẩn, stop có rider + giờ + toạ độ, postal theo rider; free = student_seats (seats / capacity) − load − ghế giữ cho request
  Accepted / Active chưa có trong plan + rider đã nghỉ (ends_on < ngày). Arrival window / max journey từ Bus Sessions của năm (to_school / to_home,
  không CCA), không có thì params plan (amWin / pmWin / hardCap); baseDwell / perStudent từ params plan.
- `BusRequests::Check` (rfCk): mỗi session request xin; session xấu nhất (Fits < New Stop < Not Checked < Bus Full < New Area), "(part)" khi một session
  chưa có plan; renewal có rider đang đi = Covered (current route); Accepted / Active có chỗ giữ = Seat held. `seat?` (free > buffer hoặc current).
  List có `check` (filter `check=covered|change|new|none`), detail có `route_fit` theo session.
- **Giá** `BusRequests::Fare` (reqBase): bảng Bus Fares đã lock của năm (không có thì năm lock gần nhất trước đó), tier theo km đường chim bay từ trường,
  số tiền của kỳ bill chứa ngày bắt đầu từ `FareTables::Calc` (2 chiều; 1 chiều khi chỉ AM / PM; ampm → am / pm), đơn vị month / term / semester.
  Không có bảng → estimate của app. (HTML chia năm / số tháng và luôn ghi "a month"; Rails dùng đúng kỳ bill.)
- **Accept** (`BusRequests::Accept`): Requested / Under Review / Waitlisted (Lapsed chỉ qua Re-offer); 1 request có quote (amount, note, start_on — kiểm
  fixed start, note bắt buộc khi khác giá / trễ hơn yêu cầu), nhiều request lấy giá Bus Fares. offer_by = giờ + confirm_hours (registration, mặc định 48).
  `bus_request_places` (AM / PM: route, fits / new, stop, +phút) giữ ghế. First invoice = `school_bills` (kind first, INV theo Finance Settings, GST
  excl / incl, kỳ bill chứa ngày bắt đầu, hạn = offer_by). Re-offer giữ quote + số INV. `BusRequests::Link` (reqLink): request mới (không renewal)
  → rider (SchoolRiders::Add, from start, remarks code) + family (guardian trùng 8 số cuối phone / email trong trường, không thì family mới
  "<HỌ> Family" + guardian Parent), bill gắn family / rider.
- **Lapsed** = Accepted + quá offer_by + bill chưa trả (tính, không lưu). **Record First Invoice Paid** → bill paid (method), Active.
- Banner `meta.auto_accept` (luật registration đã schedule: app = renew + same; rider renewing + cùng postal / session; sibling theo 8 số phone rider
  hiện tại; near km; cover = seat ngoài buffer) và `meta.cover` (Waitlisted nay Covered) + `POST /schools/:id/bus_requests/accept { ids }`.
  Tự nhận khi phụ huynh gửi là việc của Convoy App → backlog.
- API: `POST /bus_requests/:id/accept|reoffer|record_payment`, `POST /schools/:id/bus_requests/accept`. Spec 2. Seed: 1 Active (PayNow), 1 Accepted, 1 Lapsed.
