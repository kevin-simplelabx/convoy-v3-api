# Phase 2–3 — Routing runs và Plans (02/11/2026)

- Bảng: `routing_settings` (params jsonb company), `routing_runs` (input / params / result jsonb snapshot, no_stop / conflict rids, status queued → running →
  done | failed), `plan_comments`, `school_route_riders`; cột mới `school_plans` (source engine / manual / seed, priority, params, summary, unassigned,
  stale, adopted_at / by, routing_run, created_by), `school_routes` (route_key, bus_type, seats, capacity, floor, fill, span, ride_minutes, badges,
  locked / hidden / edited / manual, vias, engine_route jsonb), `school_route_stops` (stop, stop_point, dwell). Plan state: draft (in_use false) /
  scheduled (effective_from > hôm nay) / current / replaced.
- Sự cố: rollback migration `disable_ddl_transaction!` hỏng giữa chừng → sửa tay schema_migrations + bỏ cột `scheduled_from` (dev / test); không ảnh hưởng.
- `Routing::Client` (Faraday, ROUTING_URL / ROUTING_SECRET, meta cache 1 h; spec `FakeRouting`), `Routing::Input` (port engInput: rider theo session,
  đúng 1 stop → group uid = stop id, pid = point id; no stop / conflict; current plan engine_route cho Keep Current; params company + session + BA),
  `RoutingRunJob` (FAILED → lỗi validation; service down → failed), `Plans::FromResult` (plan nháp, label theo Route Labels), `Plans.write_route`.
- API: `GET / PUT /routing/settings`, `POST /schools/:id/routing_runs` (202, 422 `routing_blocked`), `GET /routing_runs/:id`; plans: list theo session,
  show (routes / stops / riders / comments), Draw Routes (`POST /schools/:id/plans`), PATCH (name, ngày → resync khi in_use), DELETE nháp
  (`Plans::Destroy` xoá theo lô), comments, `GET /plans/:id/compare?with=` (`Plans::EngineShape` → service /diff). Out of Date = stale hoặc
  `schools.stops_changed_at` > plan.created_at.
- Spec: routing (3), plans (1). Helper `school_with_stops`.
