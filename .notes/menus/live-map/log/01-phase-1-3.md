# Phase 1–3 — Live Map (02/11/2026)

- Bảng `tracking_devices` (driver_app / gps_tracker, gắn xe) + `vehicle_live_positions` (1 dòng / xe, lần báo cuối + battery / GPS / GSM).
  `Telematics::Ping` ghi lần báo (bỏ qua ping cũ đến trễ) và thêm điểm vào `occurrence_positions` của run đang chạy.
- `LiveMap::Board` + `GET /live_map` (state on_trip / available / offline, counts, teams, run: points, next stop, ETA, trễ; next / last run),
  `GET /live_map/vehicles/:id` (device health, stops done / current / upcoming, On Board, ETA Last, học sinh School Run),
  `GET /live_map/vehicles/:id/runs?date=` (Replay), `GET /live_map/runs/:id/track?since=` (Trace / Replay, cùng format Trip History track).
- Tự quyết: offline 15 phút, khỏi map 72 h, ETA chim bay 30 km/h, mọi xe kept; HTML dùng đồng hồ giả → API dùng giờ server, FE poll.
- Mẫu: `Telematics::Simulate` (seed `98_live_map`, rake `live_map:simulate` `LOOP=`); chỉ có xe On Trip khi đang có run trong ngày.
- Backlog: Rain / Traffic, Road, nút Check, ingest endpoint, màn thiết bị, ETA routing thật.
- Docs `.api-documents/live-map.md`, README, integration, screen-map, OpenAPI folder Live Map (probe: id = Vehicle). Spec `live_map_spec.rb` (4).
- Sau review (user chốt): bỏ "khỏi map 72 h" — xe offline vẫn hiện ở vị trí cuối; bỏ `meta.hide_after_hours`.
