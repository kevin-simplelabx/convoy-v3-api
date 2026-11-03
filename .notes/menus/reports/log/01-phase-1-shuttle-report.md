# Phase 1–2 — Shuttle Report + docs (02/11/2026)

- `Reports::ShuttleRuns`, `Reports::Shuttle` (summary, grid, options, range kỳ m / q / y), `ReportsController` (options, shuttle, grid), `ReportPolicy`.
- Dữ liệu thật (user chốt); Amend Record = Correct Record của Trip History; allowance = `clients.on_time_allowance` (PATCH client có sẵn).
- Seed `94_shuttle_report`: stop events (không GPS) cho run MBC Campus Shuttle 3 tháng, ngẫu nhiên cố định theo id run, + Punctuality.
- Docs: `.api-documents/reports.md`, README, integration, screen-map, OpenAPI folder "Reports". Spec `reports_shuttle_spec.rb` (3).
