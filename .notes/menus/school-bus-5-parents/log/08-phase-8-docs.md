# Phase 8 — Docs, kiểm tra (03/11/2026)

- `.api-documents/school-bus-parents.md` (Families, Registration, Bus Requests, Route Fit / accept / first invoice, changes + plan versions, alerts /
  08:00 email, CCA Rides, phần chưa làm); README, integration, screen-map cập nhật. OpenAPI: `families`, `school_registrations`, `bus_requests`,
  `cca_rides` vào folder School Bus (probe `cca_rides` → CcaRideSetting) → 543 operations.
- Notes: README, CLAUDE.md, overview, decisions, data-ownership, domains/school.md, backlog (endpoint Convoy App).
- Kiểm tra: rspec 358 / 0 failures, rubocop sạch, `db:seed` 2 lần, `occurrences:verify` SD: all match.
