# Phase 9 — Rà tài liệu API cho FE (31/10/2026)

- So route thật (`bin/rails routes`) với `.api-documents/trips.md`: mọi endpoint của menu đều có mục.
- Gọi thật mọi GET trên dữ liệu seed (script tạm, integration session) và so key với doc: Trips list dựa vào "mọi field của
  run Scheduler" (scheduler.md — thêm `issue_raised_at` vào ví dụ), booking detail + phần Approve / Cancellation đủ,
  Trip History đủ (thêm shape `vehicle.photo` có `thumb_url`).
- Intro bỏ "Sections are added as each part is built"; thêm § 6 "Not built yet" (khớp backlog); README của
  `.api-documents` bỏ "(in progress)".
- Rà lại `scope.md`: còn sót passenger list cho run School Bus (rider chỉ có riders_count) → doc § 6 + backlog.
