# Phase 1 — routing-service (02/11/2026)

- Thư mục `convoy-v3-api/routing-service/` (không đặt ở `convoy-v3/` vì thư mục cha không phải git repo → để version cùng API).
- Node 20 + Express; engine = `convoy-pathfinder-cf.js` của prototype copy nguyên vào `engine/convoy-pathfinder.js`.
- API: POST /solve (`input.matrix` thiếu → service lấy ma trận OSRM table 45×45 của engine, cache LRU 200 bộ điểm), /retime (ma trận cho trường + stop),
  /diff, GET /meta (DEFAULTS, TYPES, PRESETS, EFFORT, ENGINES), /health. Header `X-Routing-Secret`. Worker thread mỗi solve, `SOLVE_CONCURRENCY`, `MAX_EFFORT`.
- Engine **từ chối** khi không có ma trận đường (ROAD_TIMES_UNAVAILABLE) — test dùng ma trận giả; đã thử OSRM thật (`road: true`).
- Deploy: `bin/routing-image` (build amd64, push GHCR `convoy-routing`), Kamal accessory `routing` (SOLVE_CONCURRENCY 1 trên máy 2 CPU), Rails `ROUTING_URL`,
  secret `ROUTING_SECRET` ← `.kamal/routing_secret` (gitignored, đã sinh). `.dockerignore` loại `routing-service/` khỏi image Rails.
