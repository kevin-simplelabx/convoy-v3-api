# Scope: menu Ops Control (rail `opsctl`, icon `desktop_windows`), rà 02/11/2026

Nguồn: `Ops Control.dc.html` (nhúng trong Convoy OS, prop `duty` = user đang trực). HTML chạy đồng hồ giả + 18 trip mẫu
có kịch bản; Rails dùng dữ liệu thật: run trong cửa sổ, driver app (đăng nhập, Start / End), vị trí cuối của xe (Live Map),
stop event của điểm đón đầu.

## Làm
| Phần | Tính năng | Phase |
| --- | --- | --- |
| Dữ liệu | `trip_occurrences.started_at` (driver bấm Start; `ended_at` có sẵn), `driver_app_sessions` (đăng nhập driver app), `ops_alerts` (cảnh báo đã raise: kind, mức, lúc raise / clear / acknowledge / escalate) | 1 |
| Dữ liệu | Service ghi Start / End của run; simulator Live Map thêm đăng nhập, Start và các kịch bản (chưa login, chưa start, trễ, mất GPS) | 1 |
| Luật | Driver chưa login 20 phút trước điểm đón đầu (10 phút = Action); chưa Start 15 phút trước (5 phút = Action, kèm "xe cách N m"); ETA trễ > 2 phút (> 5 = Action); chưa tới điểm đón 2 phút sau giờ (Action); tới trễ (Warning 10 phút sau khi tới); mất GPS 3 phút (6 = Action); Action không acknowledge trong 3 phút → Escalated | 2 |
| Engine | Tính trạng thái từng run + cảnh báo; đồng bộ `ops_alerts` (raise / clear / escalate) khi mở board và job mỗi phút | 2 |
| Board | Chỉ run đã có xe (run chưa có xe thuộc Scheduler / Unassigned). KPIs: Trips in Next 2 Hours, Running Now, Action Now (+ số chưa acknowledge), At Risk, On-Time Starts Today, Late Starts Today | 3 |
| Board | Tabs Needs Action / All / Not Started / Running / Ended có số; lọc client, search (plate, driver, trip, TID, client); sort giờ asc / desc | 3 |
| Board | Dòng: status (Action Now / At Risk / On Route / On the Way / Ready / Scheduled / Completed), giờ đón đầu, countdown, trip, client, route, plate, driver (+ phone), Driver App, GPS, ETA, timeline bar, issue (+N more), Acknowledge / đã acknowledge bởi ai lúc nào | 3 |
| Banner | Trip cần Action chưa acknowledge (3 trip đầu + "N more"), escalated, Call, Acknowledge | 3 |
| Alert Log | Cảnh báo hôm nay (60 mới nhất): giờ, nội dung, trạng thái Open / Acknowledged / Escalated / Cleared | 3 |
| Acknowledge | Acknowledge mọi cảnh báo đang mở của 1 run (người trực = user hiện tại); trip vẫn bị flag tới khi hết | 3 |
| Dashboard | Widget "Open Ops Control Alerts" có dữ liệu thật | 3 |

## Không làm (backlog)
- Gửi thật escalation tới Ops Manager (chỉ ghi `escalated_at`), âm báo / full screen / How It Works = FE.
- Banner "Requests" (`rqs`) của Convoy OS trên trang Ops Control: thuộc School Bus.
- Endpoint driver app (login, Start, End, ping): làm cùng driver app (service đã có).
- Ngưỡng luật trong Company Settings: HTML cố định → hằng số.
