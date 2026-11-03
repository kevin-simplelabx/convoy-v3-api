# Scope: School Bus 4 — Route Plans & Feasibility Studies (rà 02/11/2026)

Nguồn: `convoy-pathfinder-cf.js` (engine: solve, retime, diff, summarize, PRESETS, EFFORT, TYPES), `node-app/server.js` + `solver-worker.js`
(service mẫu), `logic/mixins/vs-engine.js` (engInput ~61, solveAsync ~287, promotePlan ~1330, drawerVals ~1817, engVals ~1976, setVehicle ~2418,
exportRoutes ~2461), `logic/mixins/vs-map.js`, `logic/mixins/school-finance.js` (priceVals ~168, promoVals ~1679, carryChgs ~1579, rchVals ~1705,
runChg), `logic/mixins/school.js` (feasibility fz* ~8–720, setAttendant ~1031), `logic/plan-changes.js`, `logic/route-fit.js`, `scheduler.js` schTrips.

## Chốt với user (02/11/2026)
- Service Node mới `convoy-v3/routing-service`, Rails gọi qua job; deploy accessory Kamal.
- OSRM `router.project-osrm.org` (cả production, như HTML); self-host vào backlog.

## Làm (phase ở plan.md)
- **routing-service**: POST /solve (OSRM table phía service + cache), /retime, /diff, /health; worker threads, concurrency, secret; Dockerfile.
- **Routing settings**: tham số engine theo company (Priority preset, time / dwell / penalties / route rules, bus types, headroom, stability, effort ≤ giới hạn); snapshot mỗi lần chạy.
- **Routing runs**: Run Routing (AM / PM / ASA) → input (rider có đúng 1 stop trong ngày Plan For, theo session; no stop / conflict báo riêng; current plan cho Keep Current) → job → kết quả; lỗi / blocked.
- **Plans**: plan nháp từ kết quả (routes, stops, riders, badges, KPIs, unassigned + lý do), Draw Routes (plan trống), danh sách theo session + badges (Current / Draft / Scheduled / Out of Date / unassigned / comments), đổi tên, khoảng ngày chạy, comments, xoá nháp, Compare (diff).
- **Sửa tay**: route mới từ stop, chuyển / sắp xếp stop, bỏ rider, thêm rider (chèn rẻ nhất), đổi bus type, lock / hide, via points, reset; re-time ở service; Route Again (giải lại phần không lock).
- **Adopt**: ngày hiệu lực (≥ đầu tháng này, ≥ ngày bắt đầu plan hiện tại); hôm nay / quá khứ → current (plan cũ kết thúc hôm trước); tương lai → scheduled (job tự chuyển, huỷ được); run trên Scheduler theo plan; assignment rider → PUDO cho Stop Assignment (Set as assigned, Move All Riders Here, Notify = ghi lại), plan Out of Date khi stop / rider đổi.
- **Route**: xe thường theo ngày (có sẵn), replacement (có sẵn), attendant, giá operator theo route (Fixed / Per Rider, lịch sử giá), Route Charges (school pays per bus) + chuyển sang plan mới khi adopt (`status check`).
- **Feasibility Studies**: study (trường có sẵn hoặc trường dự kiến + postal), danh sách postal × số rider × session, door-to-door / PUDO trong thư viện ≤ walk m, giá theo bus type + BA, fare tiers; scenario (bus sizes, attendant, giới hạn ride, margin, buffer buses, tham số); chạy qua service; chi phí, break-even, fare gợi ý, so sánh scenario.

## Không làm
- Vẽ lasso / kéo via point / bản đồ / route geometry hiển thị (FE gọi OSRM route như HTML), export route sheet xlsx (FE từ dữ liệu), Convoy AI, collaborator presence.
- Route Fit tự áp thay đổi giữa năm vào plan: sub-menu 5 (Requests).
