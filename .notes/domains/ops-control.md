# Ops Control — hiện trạng

| Bảng | Ghi chú |
| --- | --- |
| trip_occurrences.started_at | driver bấm Start (`Occurrences::DriverProgress` start / end; `ended_at` có sẵn) |
| driver_app_sessions | đăng nhập driver app: driver_id \| operator_driver_id (CHECK đúng 1), device, signed_in_at, signed_out_at, last_seen_at; chỉ seed / simulator |
| ops_alerts | cảnh báo trên run `(occurrence_id, occurrence_date)`: kind login / start / eta / miss / late / gps, severity 1 warning / 2 action, message lúc raise, raised / cleared / acknowledged (+ by) / escalated; unique mở theo (run, kind, severity) |

- `OpsControl` (module): hằng số luật như HTML (login 20 / 10, start 15 / 5, ETA > 2 / > 5, miss 2, late 2 (hiện 10 phút), GPS 3 / 6, escalate 3);
  `runs(now)` = run có xe, không cancelled / removed / skipped, đón đầu ≤ now + 2 h, kết thúc > now − 15 phút.
- `OpsControl::Check`: trạng thái 1 run (đón đầu = `starts_at`; arrived = stop event nhỏ nhất; started = `started_at` hoặc đã arrived; login = session chưa
  sign out; GPS / khoảng cách = `vehicle_live_positions`; ETA chim bay 30 km/h) + hits; luật login chỉ khi run có driver_id / operator_driver_id.
- `OpsControl::Sync` (advisory lock theo company): raise hit mới, clear alert không còn hit, escalate action chưa ack ≥ 3 phút. Gọi bởi
  `GET /ops_control`, widget Dashboard `alerts`, `OpsControlSyncJob` (recurring mỗi phút).
- `OpsControl::Board`: KPIs (On-Time Starts Today = run hôm nay có xe đã tới giờ, tới điểm đón đầu ≤ +2 phút), banner (action chưa ack), tabs, rows.
- `OpsControl::Acknowledge`: ack mọi alert mở của run (422 khi không còn gì). Quyền `OpsControlPolicy` (xem: convoy_admin / vehicles / plans; ack: company user vehicles / plans).
- Mẫu: `Telematics::Simulate` thêm session driver, Start, trễ 6 phút, mất GPS, xe đang tới điểm đón.
