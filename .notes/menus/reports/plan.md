# Reports menu API — Plan

> Bắt đầu 02/11/2026. Scope: `scope.md`. Hiện trạng ở `../../domains/reports.md` khi xong.

## Phase 0 — Scope & plan ✅ (02/11/2026)
## Phase 1 — Shuttle Report ✅ (02/11/2026, xem log/)
- `Reports::ShuttleRuns` (run của trip trong kỳ, stop record từ `TripHistory.stop_record`, trạng thái stop ok / early / late / edep / skip),
  `Reports::Shuttle` (KPIs + so kỳ trước, timings, stop activity, trend 12 tháng), `Reports::ShuttleGrid` (lưới riders / on-time của 1 tháng).
- `GET /reports/shuttle/options`, `GET /reports/shuttle`, `GET /reports/shuttle/grid`. Seed stop events. Spec.
## Phase 2 — Docs & kiểm tra ✅ (02/11/2026, xem log/)
