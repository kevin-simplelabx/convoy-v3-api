# Phase 5 — Bookings: duyệt, client, huỷ, chuông (30/10/2026)

- Gem `aasm` (đã duyệt): `BookingTrip` status thay enum Rails bằng aasm (column status, string): pending, awaiting_ack,
  awaiting_client, approved, rejected, cancelled; events mark_changed, acknowledge, approve, reject, client_approve, client_decline, cancel.
- Migrations `20261030180000` (cột approval / acknowledgement / rejection / cancelled_at trên booking_trips; bảng booking_trip_changes
  (items text[]), booking_cancel_requests, booking_events, user_notification_preferences, notification_emails),
  `…180100/180200` (`trips.booking_trip_id` index concurrently + FK validate sau).
- `Bookings::Approve`: tạo trip qua `Trips::Save` (no vehicle → run Unassigned; Two Way = pair qua return_attributes; giá từ estimate,
  Two Way chia đôi, M&G → meet_and_greet_fee; trip value nhập; notes như HTML; end = start + 1 h). awaiting_ack cần `how`.
- `Bookings::TripAction`: reject (reason bắt buộc), acknowledge / client_approve / client_decline (admin ghi thay, có event).
- Save: trip chưa locked có thay đổi (`TripSummary`) → awaiting_ack + change row, xoá acknowledgement.
- `Bookings::CancelRequest`: record (event) / accept (trip → cancelled; approved → huỷ run chưa chạy qua `Occurrences::Edit#cancel!`,
  chưa có run thì discard trip) / decline.
- `Bookings::Notify`: event + email ghi lại cho user active có quyền vehicles, theo preference (mặc định bật hết).
- `Bookings::Assignment.load!`: Unassigned = có run scheduled không xe (hoặc chưa có run và trip không có xe).
- API: `/booking_trips/:id/approve|reject|acknowledge|client_approve|client_decline`, `/bookings/:id/cancel_requests`,
  `/booking_notifications` (+ seen, preferences).
- Khác HTML: thêm trạng thái `cancelled` (HTML chỉ hiện chuông cancel request, không có xử lý); client approval nhiều bước
  (capr: steps / approvers) là việc của Client Portal → backlog; ở đây chỉ ghi kết quả done / declined.
- Seed `46_bookings` thêm: Google approved (2 trip Scheduler, Unassigned) + cancel request mở, Google completed (tuần trước),
  DBS portal awaiting_client + event new_booking, change history cho DBS.
- Spec `booking_flow_spec.rb` (5). Tổng 175 specs.
