# Phase 1–4 — Convoy Admin (02/11/2026)

- Transport Companies: `POST /companies` cần `admin {name, email, password}` (đổi hành vi, spec companies cập nhật) → `Companies::Create`;
  list Convoy Admin có admin / schools_count / users_count / is_current.
- Message Terms CRUD (`PlatformPolicy`). Discover (advertisers, placements, pause / resume / end / duplicate / delete draft, KPIs).
  Company Leads (gom domain, PATCH /leads/:id = domain — tham số `domain:` trùng option host của url helper nên đặt `:id`).
- Seed `97_convoy_admin` (4 advertisers, 4 placements, 11 leads / 3 domain). Spec `convoy_admin_spec.rb` (4), `discover_spec.rb` (2).
- Docs `.api-documents/convoy-admin.md`, README, integration, screen-map, OpenAPI folder "Convoy Admin".
