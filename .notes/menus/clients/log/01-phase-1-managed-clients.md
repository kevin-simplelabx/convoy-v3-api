# Phase 1 — Managed Clients: list, form, record, delete (02/11/2026)

- `app/lib/uen.rb` (FORMAT, HINT, MESSAGE, normalize) dùng chung; `Operator::UEN` trỏ về đó. Client: normalize + validate UEN, squish name.
- `Clients::Save`: field client + `school_id` (company: gắn `schools.client_id`, bỏ gắn school cũ; school đã thuộc client khác → 422)
  + `school_calendar_id` (calendar kind school → `schools.calendar_id`). Đổi kind khỏi company → bỏ gắn school.
- Migration: `schools.client_id` unique (partial, concurrently); `School` validate unique client, `after_update_commit` đổi calendar →
  resync route đang chạy của school (`SyncsOccurrences`).
- `Client#delete_blockers`: trip kept còn chạy (`Trip.running_on` mới: never hoặc COALESCE(ends_on, starts_on) ≥ hôm nay) + booking tab
  pending / approved. `DELETE` → 422 "<name> has … End or delete them first", không thì discard.
- `GET /clients/:id` thêm `school`, `school_calendar`. Policy giữ nguyên (mọi company user ghi được: trip form Add New Client).
- Seed `47_client_records`: client St. Stephen's School gắn school. Spec `clients_managed_spec.rb` (2).
