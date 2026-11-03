# Phase 7 — Thông báo (03/11/2026)

- `BusRequests.needs` (port requests.js needs): end (End Rider / Remove, rank 1), adr / stop / svc (không adds) chưa mở (rank 2), mid-year clock
  (ack; answer khi soon / over) → rank 0 overdue / 1 soon / 2. `deadline_text` như reqDl.
- `BusRequests::Alerts` (reqAlerts): mọi trường user mở được, sắp xếp rank rồi hạn; mỗi item: request, trường, tab, what (New bus request / Answer due /
  Renewal / Change of service / Change of address / Stop service / Leaving / Offer lapsed …), text, tone. `summary` (parts: to acknowledge, answers due,
  changes of address, to take off the rider list, overdue) cho chuông và strip (Ops Control / School Live Ops dùng cùng endpoint).
- Email 08:00 (`BusRequests::Digest` + `BusRequestsDigestJob` 8:00am): người nhận = owner / admin / quyền schools mở được trường đó, active; ghi
  `notification_emails` (chưa gửi) một lần / ngày / người; ngày không có gì thì không ghi. Preview `GET /bus_requests/digest`.
- Registration: `POST /academic_years/:id/registration/release { key }` — Release Now cho tin gửi tay (welcome), ghi released_at.
- API: `GET /bus_requests/alerts`, `GET /bus_requests/digest`. Seed ghi digest hôm nay. Spec 1.
