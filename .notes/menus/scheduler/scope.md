# Scope: những gì mở / dùng được từ Scheduler (rà lại 30/10/2026)

Quy tắc (user, 30/10/2026): **tính năng nào mở hoặc dùng được từ Scheduler thì làm hết; không có trong Scheduler thì chưa làm.**
Data mà Scheduler chỉ *đọc* nhưng được tạo ở page khác → có bảng + seed, chưa làm màn sửa.

## Làm (mở được từ Scheduler)
| Mở từ | Tính năng | Phase |
| --- | --- | --- |
| Toolbar | View, layout, zoom, filter / sort xe, search | 4 (grid API), 1 (filter xe ✅) |
| Toolbar | New Trip → trip form | 2, 2b, 3 |
| Toolbar | External Vehicle (New External Vehicle) | 1 ✅ |
| Toolbar | Assign Trips → Assign page | 5 |
| Toolbar | Replacements list | 6 |
| Toolbar | Change a Day | 1 ✅ |
| Toolbar | Maintenance → dialog Plan the Visit / Record the Work, Workshops window, đọc hoá đơn bằng Claude | 7 |
| Vehicle panel | Driver Away, Vehicle Down, danh sách replacement của xe | 6 |
| Vehicle panel | **Edit Vehicle** → form xe đầy đủ: chi tiết, ảnh, team, operator, operator driver, tags, default driver schedule, **log card** (file + Claude đọc, plate khác chặn lưu, Past Log Cards), **insurance** (fields, ≤5 file có kind, Claude đọc, Renew Policy → Past Policies) | 1b |
| Empty slot | New Trip, Maintenance (Inspection: coming soon → không làm) | 2, 7 |
| Trip form | Mọi kind, route + stop details + ảnh, vias, Two-Way, standby, vehicles, revenue/cost, attachments, BU/Project, sub-contractor + Service For, New Client ✅ | 2, 3 |
| Trip form | Saved Pick-up Points (company), client pickup points ✅ | 2 |
| Trip form | Corporate Shuttle Price From Rate Card → cần rate cards (đọc + tính giá; sửa rate card ở page Rates: chưa làm, chỉ seed) | 3 |
| Trip form | **Fill from Message** (Claude; đọc Message Terms — sửa terms ở Convoy Admin: chưa làm, seed) | 2b |
| Trip form | School Run: Stops and Students, Paid Months, No School charge, **Import Route List** (PDF / Excel / CSV / ảnh → Claude), Saved Pick-up Points, Earlier Lists | 8 |
| Trip drawer | Edit Trip, Delete, Cancel / Restore, quick time (Today Only / Every Run From Today), Change Vehicle, Assign External Vehicle | 4, 5 |
| Trip drawer | Replace (4 kiểu, notify), Replace Driver tạm (Save Driver / Use Regular Driver), Remove Replacement, Open Replacement Trip | 6 |
| Trip drawer | No Fixed Bus / Back to Regular Bus (shuttle run), Runs That Move Together | 5 |
| Trip drawer | Raise / Clear Issue | 4 |
| Trip drawer | Passenger List (Boarded, Alighted, Absent) | 8 |
| Trip drawer | Stop photos (≤3 / stop) | 7 |
| Trip drawer | Send Notice → Notice form (templates seed), banner notice đang chạy | 7 |
| Trip drawer | Share Tracking Link (token, endpoint public cho trang Trip Tracking) | 7 |
| Grid | School Bus routes của plans (đọc), xe trường khác (fleet index), block maintenance | 9, 7 |

## Không làm (không mở từ Scheduler)
Sample fleet toggle (thay bằng seeds), Inspection, Vehicle Financials, Fuel, KYC driver details, yêu cầu vehicle type mới,
sửa rate card, sửa Message Terms, trang danh sách Notices + bật/tắt templates, share form External Vehicles,
users company, billing / portal client, Bookings (trip có thể mang link booking: chỉ lưu `booking_ref`, không làm module).
School Bus plans / routing engine: chỉ seed dữ liệu plan để grid đọc.
