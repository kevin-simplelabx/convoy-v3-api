# Decisions

| Ngày | Quyết định |
| --- | --- |
| 30/10/2026 | Viết lại convoy-v3-api từ đầu cho Scheduler (bỏ migrations/models/controllers/blueprints cũ; giữ Gemfile, config, Devise). |
| 30/10/2026 | Stack: Rails API, PG, Devise, Draper (decorator), Blueprinter (views), CarrierWave (mọi upload, không URL/data URL). |
| 30/10/2026 | Scope: mọi thứ Scheduler dùng — gồm School Run, School Bus routes trên grid, AI (Fill from Message, Route List Import) gọi Claude từ Rails, Maintenance, Notices. |
| 30/10/2026 | Occurrence storage: **B — Materialize** (`trip_occurrences`, partition theo tháng, horizon 90 ngày). Quy tắc và checklist sync: 03-occurrence-rules.md. |
| 30/10/2026 | Không dùng pg_partman: job tự tạo partition. |
| 30/10/2026 | Lịch sử thay đổi: **audited**. Gems chốt: acts_as_tenant, pundit, pagy, ransack, audited, rspec-rails, factory_bot_rails, faker. |
