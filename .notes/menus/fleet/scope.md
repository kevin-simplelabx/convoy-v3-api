# Scope: menu Fleet (rail `fleet`, icon `directions_bus`), rà 31/10/2026

Nguồn: `Convoy OS.dc.html` (Vehicles ~14712, Drivers ~14012, Operator Drivers ~14120, Connected Operators ~14244,
Managed Operators ~14553, External Vehicles ~14642, Bus Attendants ~15209, Fuel ~11893, Maintenance ~11479, Vehicle Types ~3903),
`logic/mixins/fleet.js` (drvVals, opdVals, odaVals, kycView, xvVals, pubVals, vtVals, vdsVals), `fuel.js`, `maint.js`,
`admin.js` (`saVals_vehicles`, `fleetIt` / `opsIt`).
Submenu: **Fleet**: Vehicles, Drivers, Bus Attendants, External Vehicles, Fuel & Energy, Maintenance, Vehicle Types ·
**Transport Operators**: Managed Operators, Operator Vehicles, Operator Drivers, Connected Operators.
Quy tắc scope giữ như Scheduler: mở / dùng được từ các trang này thì làm hết.

## Đã có từ Scheduler (chỉ bổ sung)
CRUD vehicles (form, ảnh, log card, insurance + renew, reader AI), `vehicle_driver_schedules`, `vehicle_teams`, `operators`,
`drivers` (index / show / create / update), `operator_drivers` (+ assign_vehicle), `attendants`, `workshops`, `maintenance_visits`,
`vehicle_types` (+ toggle), External Vehicle (`POST /vehicles/external`, cap `companies.external_vehicle_cap`).

## Làm
| Trang | Tính năng | Phase |
| --- | --- | --- |
| Vehicles | List xe của mình (không operator): chip team có số đếm (All / từng team / No Team), search plate, driver, team, make, model, type; cột plate + insurance text, type, team, default driver, owner | 1 |
| Vehicles | Manage Teams: đổi tên (xe đi theo), màu (10 màu), thêm, xoá (xe còn lại không team), lưu cả lô; trùng tên / tên trống = lỗi | 1 |
| Vehicles | Record modal: chi tiết, badges, Default Driver (đã có) + lịch sử, Log Card, Insurance (status), tóm tắt Fuel (Phase 7), Financials = trạng thái "chưa làm" (Finance) | 1 |
| Vehicles | Delete Vehicle (discard; quy tắc với run tương lai giống External remove) | 1 |
| Operator Vehicles | Cùng list, lọc xe của managed operator; cột Usual Driver; Change Driver (dialog swap: chọn driver của operator, xem hiệu ứng trước khi xác nhận) | 1 |
| Drivers | Tab Active / Pending Invites / Declined / Past Drivers có số đếm; cột bus (Default driver of / Not on a bus, "Starts on" lịch tương lai) | 2 |
| Drivers | Invite (tên, mobile chuẩn hoá +65, ảnh); không trùng số với driver active / pending; sửa (mobile khoá khi đã accept); SMS chỉ ghi lại | 2 |
| Drivers | Resend, Mark Accepted / Mark Declined (admin ghi thay app), Invite Again, Remove (→ Past, bỏ default driver từ hôm nay, giữ last vehicle), Cancel invite / Delete | 2 |
| Drivers | View Details: KYC (contact, personal, NRIC/FIN che + xem, licence class, BDVL hết hạn ≤ 90 ngày cảnh báo) — dữ liệu seed; "Shown to Your Customers" (display name + ảnh, by, at) | 2 |
| Operator Drivers | Như Drivers + operator bắt buộc, notes, nội dung SMS mẫu; Assign / Swap Bus (dialog hiệu ứng); đổi operator → rời bus của operator cũ | 2 |
| Managed Operators | Form: tên, UEN, contact, phone, email; payment PayNow và / hoặc bank (bank + branch theo danh sách SG, account, account name), method mặc định; external: cost per trip / day, valid until | 3 |
| Managed Operators | List: pays by, routes đếm; xoá (chặn khi còn xe) | 3 |
| External Vehicles | List (plate, seats, driver, company, PayNow), cap dùng / còn, Edit / Remove | 4 |
| External Vehicles | Share Form: link public theo token, Copy / WhatsApp / Preview = FE; New link (link cũ ngừng, câu trả lời giữ); câu trả lời của tài xế (plate, seats, driver, mobile, company, phone, PayNow) chờ Review and Add / Dismiss; xe tạo từ form ghi "Filled in by driver" | 4 |
| Vehicle Types | Bảng: Offered (toggle có sẵn), seats, số xe own / operators (khớp theo seats), tyre layout (Convoy Admin sửa), xoá type custom (Convoy Admin) | 5 |
| Vehicle Types | Request a New Type (tên, seats, lý do) → Convoy Admin: Add Type / Decline; công ty thấy request của mình | 5 |
| Bus Attendants | Rà lại list / form / xoá (đã có) | 5 |
| Maintenance | KPI (Next 30 Days, To Record, Spend tháng này, Last 12 Months); tab Upcoming / To Record / Completed / Cancelled có số; search plate / workshop / work; lọc xe | 6 |
| Maintenance | Spend 12 tháng theo type / vehicle / workshop (%); Tyre Changes 12 tháng (ngày, xe, vị trí, tyre, odometer, cost, workshop) | 6 |
| Fuel & Energy | Fuel Companies (tên, loại fuel / elec / both, mặc định SG, không xoá khi đang dùng) | 7 |
| Fuel & Energy | Entry: xe (own), ngày, giờ, loại diesel / petrol / def / elec, qty (L / kWh), cost, odometer, full, company, station, note, receipt (CarrierWave + Claude đọc, plate khớp xe), driver = default driver ngày đó | 7 |
| Fuel & Energy | Log theo tháng (lọc loại, xe), km since, hiệu suất (km/L, kWh/100km) giữa 2 lần full, giá / đơn vị; vehicle cards (tháng này, eff, cost/km, lần cuối); tóm tắt trên record xe | 7 |
| Fuel & Energy | Needs a Look 90 ngày: eff lệch, 2 lần đổ gần nhau, đổ quá cỡ, giá cao, odometer lùi, use / km tăng; Open / Checked tab, Mark Checked / Undo | 8 |
| Fuel & Energy | KPI (spend tháng vs tháng trước, eff, cost/km, alerts); Usage: view all / vehicle / driver / company, measure (spend, qty, km, km/L, cost/km), period 30 ngày / 12 tuần / 12 tháng + zoom, so kỳ trước, breakdown + driver so với "usual" của bus | 8 |

## Không làm
- **Connected Operators**: HTML "Coming Soon".
- **Vehicle Financials** (Finance): để cho menu Finance, các phần còn thiếu ghi ở `backlog.md`.
- Get from Corppass (log card): HTML disabled "Coming soon".
- How It Works (Fuel, Maintenance): nội dung tĩnh, FE.
- Gửi SMS invite thật, Driver app (accept / KYC từ app): backlog.
