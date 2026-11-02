# Phase 2 — Notices page (30/10/2026)

- `GET /notices`: thêm `q` (scope `Notice.search`: message, trip title, Service For, client, school), `meta.counts` 3 tab
  (search áp, tab không), sort: active / scheduled theo starts_at tăng, ended theo COALESCE(ended_at, ends_at) giảm.
  Scope mới `scheduled_at`, `ended_at_time`, `in_state`.
- Blueprint notice thêm `client_name`, `service_for`, `school_name`, `run_times`, `ended_by` (dòng Audience + By trên card).
- Quy tắc server (HTML chỉ ẩn nút): End Now chỉ khi active (422); xoá notice active → 422 (`before_destroy`, prepend).
- `notice_templates`: create / update / destroy. Khác HTML: Add Template tự đặt tên "New Template", "New Template 2"... (tên unique);
  xoá template cuối → 422 "Keep at least one template" (HTML tự thay bằng "Blank"); message được rỗng (≤ 300); xoá template → notice nullify.
- Seed `51_notices`: thêm notice active (hôm nay) + ended (hôm qua) để đủ 3 tab.
- Spec `notices_page_spec.rb` (2). Tổng 160 specs.
