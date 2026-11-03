# Phase 7–8 — Feasibility Studies, seed, docs (02/11/2026)

- `feasibility_studies` + rows / bus_prices / fare_tiers / scenarios (result jsonb). `Feasibility.parse` (port fzParse), `Feasibility::Run` (OneMap,
  door / PUDO thư viện ≤ walk, AM + PM qua service, served + sv), `Cost` (port fzCost), `Fares` (port fzFare: tier theo km chim bay +0.05 làm tròn 0.1,
  fare gợi ý), `FeasibilityRunJob`. API studies CRUD, rows (paste / clear), scenarios (add / copy / patch / delete / run / use suggested fares),
  fare_source (fare thật của trường / 12).
- Seed `53_school_routing`; doc `.api-documents/school-bus-routes.md`; index + OpenAPI; deploy.md (accessory routing).
- Spec feasibility (1). Tổng spec sub-menu 4: routing 3, plans 1, edits 2, adopt 2, money 2, feasibility 1; routing-service 2 (node --test).
