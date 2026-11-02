# Fleet — hiện trạng

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| vehicle_types | platform, preset yml, tyre layout; company tắt bằng `disabled_vehicle_types`; `custom` (tạo tay / từ request) mới xoá được |
| vehicle_type_requests | company xin type mới, Convoy Admin add / decline (không tenant scoped) |
| vehicle_teams | name, color |
| external_vehicle_share_links | Share Form: 1 link live / company, reset = link mới |
| external_vehicle_submissions | câu trả lời của tài xế thuê (pending / added / dismissed); add → `vehicles.source = share_form` |
| operators | managed / external, PayNow / bank (`bank_id`, branch tự tính `Banks::BranchFor`), managed bắt buộc có cách trả; external: cost per trip / day, `valid_until` (cảnh báo khi kéo thả) |
| banks, bank_branches | platform, ngân hàng SG + branch (UOB tra theo 3 số đầu tài khoản); seed `04_banks` |
| vehicles | ownership suy từ operator (nil = own, managed, external); `tags` varchar[] GIN; driver_name/phone chỉ cho external; photo; cột log card (chassis, engine, registered_on, COE, road tax); discard |
| drivers | own, status pending / active / declined / past (aasm, concern `InvitedDriver`); mobile E.164 unique khi pending / active; `last_vehicle`, display (tên + ảnh cho khách), discard |
| vehicle_driver_schedules | default driver từ ngày (`starts_on` mới nhất ≤ ngày), lên lịch trước được |
| operator_drivers | như drivers + operator, notes; tối đa 1 bus của operator mình (unique partial), gán = swap; đổi operator → rời xe |
| driver_invites | mỗi lần mời / gửi lại (polymorphic), SMS chỉ ghi lại |
| driver_kyc_profiles | driver chia sẻ từ app (polymorphic 1–1), NRIC mã hoá (AR Encryption) + bản che; chỉ seed |
| attendants | crew (School Bus) |
| vehicle_log_cards | 1 current / xe, plate_conflict chặn PATCH vehicle tới khi resolve |
| vehicle_insurance_policies (+ documents ≤5) | 1 current / xe, expiry_status, Renew → past + policy mới mang sẵn insurer, agent, HP, cover |
| fuel_companies | công ty xăng / sạc per company (fuel / elec / both), 9 mặc định SG khi dùng lần đầu |
| fuel_entries | đổ xăng / sạc xe own; cột tính sẵn `km_since`, `energy_km`, `efficiency`, `odometer_back`, `driver_id` (default driver ngày đó) — `FuelEntries::Recompute` |
| fuel_alerts | Needs a Look 90 ngày (eff, odo, dbl, big, price, trend), open / checked theo key — `FuelAlerts::Scan` |

## Quy tắc
- Lọc / sort xe: `VehicleSearch` (ownership, size band sedan ≤4 / mpv 5–7 / small 8–15 / medium 16–30 / large 31+, tags, VIP, team (id / `none`), q, sort) + facets (gồm `teams` theo ownership). Dùng chung cho `/vehicles` và `/scheduler`. Search: plate, make, model, team, operator, default driver hôm nay, operator driver, driver gõ tay.
- Manage Teams lưu cả lô: `VehicleTeams::Save`.
- Xoá xe: `Vehicles::Remove` (discard; chặn khi còn run / maintenance từ giờ; operator driver rời xe).
- Đổi operator driver: `OperatorDrivers::AssignPreview` (hiệu ứng) → `OperatorDriver#assign_vehicle!` (swap).
- Driver của xe theo ngày: `Occurrences::Fleet` (load 1 lần). Đổi lịch driver → `OccurrenceDriverJob`.
- External vehicle: `ExternalVehicles::Create` (match company theo tên, cap số slot của company, field company áp mọi xe, `submission_id` = Review and Add). Share Form public: `Public::ShareFormsController` (throttle rack-attack).
- Giấy tờ: `VehicleDocuments::*` + reader LogCard / Insurance; field trống mới được điền.
- Vòng đời invite: `Drivers::Invite`, `Drivers::Act` (remove own driver = schedule nil từ hôm nay + huỷ lịch tương lai).
- Fuel: `FuelEntries::Save` (receipt / read `fuel_receipt` điền field trống) → Recompute xe → `FuelAlerts::Scan` (cả company; hằng ngày `FuelAlertsScanJob`).
  Đổi lịch default driver → `FuelRecomputeJob`. Thống kê: `FuelVehicleStats` (thẻ xe, record xe), `FuelKpis`, `FuelUsage` (groupdate).
- Ghi fleet cần permission `vehicles`; New External Vehicle mọi user company.

## Seeds
`01_vehicle_types`, `30_fleet` (3 team, Hup Seng managed, Kallang external, 13 xe có ảnh, 10 driver, 2 operator driver, 3 attendant),
`31_vehicle_documents` (policy PC7475L từ PDF thật trong `uploads/`), `32_drivers` (đủ tab, invites, KYC, display),
`33_external_vehicles` (Share Form), `34_vehicle_type_requests`, `04_banks`, `55_fuel` (90 ngày, có ca bất thường).

## Chưa làm
Vehicle Financials (menu Finance, chi tiết ở `backlog.md`), Connected Operators, gửi SMS invite, Driver app (accept / KYC), Inspection.
