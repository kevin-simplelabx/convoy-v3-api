# Live Map — hiện trạng

| Bảng | Ghi chú |
| --- | --- |
| tracking_devices | thiết bị báo vị trí: kind `driver_app` / `gps_tracker`, name, identifier (unique / company), vehicle_id, report_interval_seconds, sharing_enabled; audited; chỉ seed (chưa có màn) |
| vehicle_live_positions | 1 dòng / xe (unique vehicle_id): lần báo cuối — lat, lng, speed, heading, battery, gps_signal good / fair / poor / none, gsm_bars 0–4, device, run lúc đó (occurrence_id, occurrence_date); ghi đè mỗi ping, không audit |

- `Telematics::Ping(device:, at:, lat, lng, …)`: tìm run đang chạy của xe → thêm `occurrence_positions` (đảm bảo partition), upsert
  `vehicle_live_positions` (ping cũ đến trễ không ghi đè: `WHERE recorded_at <= EXCLUDED.recorded_at`). Endpoint ingest sau này gọi service này.
- `LiveMap` (module): `OFFLINE_AFTER` 15 phút, ETA = đường chim bay 30 km/h; run đang chạy = `(started_at || starts_at) <= now < ends_at`, `ended_at` nil,
  không cancelled / removed / skipped (hôm qua + hôm nay).
- `LiveMap::Board`: state `on_trip` (có run đang chạy) > `available` (báo trong 15 phút) > `offline`; `on_map` = đã từng báo (offline vẫn hiện ở vị trí cuối). Run: points done
  (stop đã arrived / skipped), next stop (đang đứng = arrived chưa departed; điểm cuối arrived = rời), ETA, trễ; `detail`: device health, stops
  done / current / upcoming, On Board (boarded − alighted), ETA Last (trễ hiện tại cộng vào giờ kế hoạch điểm cuối), học sinh School Run
  (`SchoolRuns::Passengers`, khớp theo tên stop).
- API `LiveMapController` (quyền `LiveMapPolicy`: convoy_admin / vehicles / plans): board, 1 xe, runs của xe theo ngày + số điểm GPS, track run (`since`).
- Mẫu: `Telematics::Simulate` (không chạy ở production) — seed `98_live_map`, rake `live_map:simulate` (`COMPANY`, `LOOP=giây`).
