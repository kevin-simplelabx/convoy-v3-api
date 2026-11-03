# Phase 1–4 — Ops Control (02/11/2026)

- Dữ liệu: `trip_occurrences.started_at`, `driver_app_sessions`, `ops_alerts`; `Occurrences::DriverProgress` (Start / End). Live Map coi run start sớm là đang chạy.
- Engine: `OpsControl::Check` (luật như HTML), `OpsControl::Sync` (raise / clear / escalate, advisory lock), `OpsControlSyncJob` mỗi phút.
- API: `GET /ops_control` (KPIs, banner, tabs, rows), `GET /ops_control/log`, `POST /ops_control/runs/:id/acknowledge`; widget Dashboard `alerts` có dữ liệu.
- Tự quyết: chỉ run có xe (run chưa xe = Unassigned của Scheduler); luật login chỉ khi driver có tài khoản; GPS chỉ khi đã start.
- Simulator: session driver (mỗi 4 driver có run sắp tới 1 người chưa login), Start, trễ 6 phút, mất GPS, xe đang tới điểm đón.
- Docs `.api-documents/ops-control.md` (+ dashboard `alerts`), README, integration, screen-map, OpenAPI folder Ops Control. Spec `ops_control_spec.rb` (4).
