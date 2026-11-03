# Phase 3 — Bus Service Requests (03/11/2026)

- `bus_requests` (code REQ-0001 theo `CompanySequence :bus_request`): kind new / adr / svc / stop, source app / console / sample, status theo chữ của app
  (Requested, Under Review, Accepted, Active, Waitlisted, Declined, Withdrawn, Not Agreed, Stopping; Lapsed / Stopped tính — Phase 4/5), renew / same /
  mid (cờ từ app), tags[] (Renewing, Final Level), child / level / class / student no / dob / medical / cca_days, parent name / phone / email, am / pm / cca,
  address / postal / lat / lng / km / estimate, start_when (asap / first / pref / fixed) + start_on + fix_why / fix_note, fee_paid, policy_version,
  ack (acked_at / by, answer_by, ack_note, ack_plan_weeks), reason. New Service gắn `academic_year_id`; school_rider / family khi có.
- `bus_request_events` (lịch sử: at, by_name Parent / user, text), `bus_request_answer_moves` (from, to, reason, at, by).
- `BusRequests`: Days (ngày làm việc trừ T7 / CN / public holidays công ty), mid_settings (registration hoặc ngày học đầu, 3, 3), mid?, clock
  (ack: +ack_days working days, soon khi còn 0; answer: answer_by hoặc ack + plan_weeks, soon ≤ 3), answer_default, start_text / start_late? /
  start_error (Phase 4), tags (+ New, Mid-Year, Fixed Start, From the App / Sample), default_year (năm sau năm hiện tại), row / detail.
- `BusRequests::Board`: New Service theo AY (sort: overdue → soon → mid → còn lại; Renewing trước; cũ trước), tab khác mới nhất trước; filter status
  (`Accepted+`), tag, level, session, deadline, q (tên, code, postal, email, địa chỉ; ≥ 3 số theo phone); meta tiles (Mid-Year / Overdue chỉ khi có),
  tabs (số đang mở), windows (registration hoặc mặc định), years (This / Next Year / Later / Past, to_review), levels. Trang 150 / tối đa 500.
- Hành động: Add (kiểm như HTML, OneMap), open (Requested → Under Review, mid-year phải Acknowledge), Acknowledge, MoveAnswer, Decide (bulk;
  lý do trong list HTML), Message (bulk, chỉ ghi log). `BusRequestPolicy`: xem plans / schools / finance, sửa plans / schools.
- API: `GET/POST /schools/:id/bus_requests`, `POST …/decide`, `POST …/message`, `GET /bus_requests/:id`, `POST /bus_requests/:id/open|acknowledge|move_answer`.
- Seed `54_school_parents`: 12 renewal + 4 new (2 waitlisted) AY 2027, 2 mid-year AY 2026. Spec 2.
