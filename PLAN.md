# Convoy v3 — Rails Migration Plan

Chuyển từ Node.js (`node-app/`) sang Rails 8.1 + PostgreSQL.
Frontend (`.dc.html` files) giữ nguyên, serve từ `public/`.

---

## Stack

- **Ruby** 3.4.2
- **Rails** 8.1.3 (API mode)
- **PostgreSQL**
- **Devise** — auth
- **Blueprinter** — JSON serialization
- **Faraday** — HTTP client cho OSRM proxy
- **Rack::Attack** — rate limiting
- **Rack::Cors** — CORS
- **Dotenv** — env vars (development)

---

## Phase 1 — Skeleton ✅

- [x] Rails app tạo xong (`convoy-v3/`)
- [x] Gems install: devise, blueprinter, faraday, rack-attack, rack-cors, dotenv-rails
- [x] Devise install
- [x] Setup CORS (`config/initializers/cors.rb`)
- [x] Setup Rack::Attack (`config/initializers/rack_attack.rb`)
- [x] Tạo `.env` file
- [x] Setup database (`database.yml` + `rails db:create`)
- [x] Health check endpoint (`GET /api/v1/health`)
- [x] Copy static assets vào `public/` (`.dc.html`, `_ds/`, `data/`, `support.js`, etc.)
- [x] Route `GET /config.js` trả về config cho browser

---

## Phase 2 — Auth & Users

- [x] Generate Devise `User` model
- [x] `Company` model
- [x] Custom Devise sessions controller (trả JSON, không redirect)
- [x] `GET  /api/v1/session` — trả current user + company + school context
- [x] `POST /api/v1/login`
- [x] `DELETE /api/v1/logout`
- [x] `POST /api/v1/login-as` (demo mode, `DEMO_LOGIN=true`)
- [x] `POST /api/v1/context` — set companyId, schoolId, date vào session
- [x] Auth middleware (`current_user`, `require_auth`, `require_company`)
- [x] Permission system (users, schools, plans, library, vehicles)
- [x] `GET  /api/v1/companies`
- [x] `POST /api/v1/companies` (Convoy Admin only)
- [x] `PUT  /api/v1/company/logo`
- [x] `GET  /api/v1/users`
- [x] `POST /api/v1/users`
- [x] `PUT  /api/v1/users/:id`
- [x] UserBlueprint, CompanyBlueprint
- [x] Seed: Convoy Admin + SimpleDrive company

---

## Phase 3 — Schools & Students

- [x] `School` model
- [x] `Dataset` model (student rosters)
- [x] `Rider` model (manual riders)
- [x] `GET  /api/v1/schools`
- [x] `POST /api/v1/schools`
- [x] `GET  /api/v1/schools/:id/datasets`
- [x] `POST /api/v1/schools/:id/datasets` (CSV upload)
- [x] `DELETE /api/v1/datasets/:id`
- [x] `GET  /api/v1/schools/:id/riders`
- [x] `POST /api/v1/schools/:id/riders` (manual add)
- [x] `GET  /api/v1/schools/:id/rider-events`
- [x] `GET/PUT /api/v1/schools/:id/labels`
- [x] SchoolBlueprint, DatasetBlueprint, RiderBlueprint

---

## Phase 4 — Stops, Plans & Drafts

- [x] `StopLibrary` model (per company, JSONB)
- [x] `Plan` model (per school, JSONB)
- [x] `Draft` model (per school, JSONB)
- [x] `GET/PUT /api/v1/stops`
- [x] `GET /api/v1/library/requests`
- [x] `POST /api/v1/library/:uid/status`
- [x] `GET/PUT /api/v1/schools/:id/plans`
- [x] `GET/PUT /api/v1/schools/:id/draft`

---

## Phase 5 — Vehicles & Attendants ✅

- [x] `Vehicle` model
- [x] `Attendant` model
- [x] `GET/POST/DELETE /api/v1/vehicles`
- [x] `GET/POST/DELETE /api/v1/attendants`
- [x] VehicleBlueprint, AttendantBlueprint

---

## Phase 6 — OSRM Proxy ✅

- [x] `GET /api/osrm/route/v1/driving/*` — proxy + cache
- [x] `GET /api/osrm/table/v1/driving/*` — proxy + cache
- [x] Cache bằng `Rails.cache` (memory store)

---

## Phase 7 — Node Solver Microservice ✅

- [x] Tách `convoy-pathfinder.js` + `solver-worker.js` ra `../solver/`
- [x] Wrap thành Express nhỏ, port 3001
- [x] `POST /api/solve` trong Rails → forward tới `http://localhost:3001/api/solve`
- [x] Rate limiting: `SOLVE_PER_HOUR` per company (busy-lock + hourly counter trong Rails.cache)

---

## Phase 8 — Deployment

- [ ] Dockerfile cho Rails
- [ ] Dockerfile cho Node solver
- [ ] `docker-compose.yml` — Rails + Solver + Nginx
- [ ] Nginx config (reverse proxy)
- [ ] `.env.production` template
- [ ] SSL với Certbot
- [ ] Migrate data: seed script đọc `standalone-db.json` → import vào PostgreSQL

---

## API prefix

Tất cả endpoints dùng prefix `/api/v1/` (giống node-app dùng `/api/v1`).
Browser config trỏ `window.CONVOY_CONFIG.api = '/api/v1'`.
