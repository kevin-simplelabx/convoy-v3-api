# Scope: menu Live Map (rail `livemap`, icon `map`), rà 02/11/2026

Nguồn: `Live Map.dc.html` (component nhúng trong Convoy OS). HTML chạy bằng đồng hồ giả + `data/liveops.json`
("Simulated positions until the Driver app and GPS trackers send live data"). Rails dùng dữ liệu thật: thiết bị + vị trí
mới nhất của từng xe, run đang chạy, stop events, GPS của run.

## Làm
| Phần | Tính năng | Phase |
| --- | --- | --- |
| Dữ liệu | `tracking_devices` (driver app / GPS tracker gắn xe), `vehicle_live_positions` (1 dòng / xe: vị trí + sức khoẻ thiết bị lần báo cuối); `Telematics::Ping` (lõi mà endpoint ingest sau này gọi) | 1 |
| Dữ liệu | Seed: thiết bị cho xe SD, ảnh chụp "bây giờ" (run đang chạy → GPS + stop events tới hiện tại; xe rảnh; 2 xe offline 1 / 5 ngày); rake `live_map:simulate` làm mới ảnh chụp (dev / staging) | 1 |
| Fleet panel | Mọi xe (own + operator): trạng thái On Trip / Available / Offline có số đếm; search plate / driver; group by team (màu team); dòng: plate, make / model, driver, seats, trip (client, title, point k / n), ETA điểm tới / Arrived / offline bao lâu | 2 |
| Map | Vị trí, tốc độ, hướng; xe offline vẫn hiện ở vị trí cuối (user chốt 02/11/2026; `on_map: false` chỉ khi chưa báo lần nào); route line = các stop của run (lat / lng) | 2 |
| Vehicle and Device | Vehicle, Current Driver, Speed, Current Trip, Timestamp / Last Online, Device, GPS Signal, GSM Signal, Battery; Location Sharing (enabled, kiểu báo: tracker mỗi N s / driver app) | 2 |
| Trip drawer | TID, title, kind, client; Points done / tổng, On Board, ETA Last; next point; stops done / current / upcoming (giờ kế hoạch, giờ đến thực); học sinh từng stop (School Run: picked up / absent / waiting / on board / dropped off) | 2 |
| Trace | GPS của run đang chạy từ lúc bắt đầu (màu theo tốc độ = FE), `since` để lấy phần mới | 2 |
| Replay | Chọn ngày + xe → run có GPS của ngày đó → track (cùng format Trip History) | 2 |
| Map controls | Theme, Plates / Drivers / Route lines, Fit, panel: FE | — |

## Không làm (backlog)
- Rain (radar mẫu + NEA 2-hour forecast), Traffic (LTA Speed Bands): đã có dòng backlog thời tiết / giao thông.
- Nút "Check" location sharing (hỏi thiết bị ngay): cần push tới driver app / tracker → làm cùng driver app. API trả trạng thái lần báo cuối.
- Tên đường (Road) hiện tại: cần reverse geocode / map matching (đã có backlog) → `road: null`.
- Endpoint ingest GPS từ driver app / tracker (đã có backlog); màn quản lý thiết bị (HTML không có).
- ETA theo routing thật: tạm ước tính đường chim bay 30 km/h (như HTML Ops Control).
