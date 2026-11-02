# Phase 1 — Reference data ✅ (30/10/2026)

Gems thêm (duyệt 30/10/2026): discard, strong_migrations, oj, annotaterb (dev), bullet (dev/test, raise on N+1 trong test), shoulda-matchers (test).
Audits lưu `audited_changes` dạng **jsonb** (query được).
Dev DB queue tách riêng: `convoy_v3_development_queue` (trước dùng chung DB primary).

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| company_sequences | số chạy theo company (`CompanySequence.next!(:client_code)`, row lock) — dùng cho Trip ID ở Phase 2 |
| public_holidays | unique (company, date); `observed`; preset MOM 2026–2027 ở `config/presets/public_holidays.yml` |
| calendars | school / general, `observed_holidays` off/work, soft delete |
| calendar_days | kind hol ns early late (school) / off shift oil work (general); range `starts_on..ends_on`; giờ = phút (nhận "HH:MM") |
| clients | company / individual / transport_company (main contractor); `code` CL00001; `on_time_allowance` |
| client_sites, client_end_customers, client_pickup_points | lồng dưới client |
| vehicle_types | platform (không company), preset `config/presets/vehicle_types.yml`, tyre layout |
| disabled_vehicle_types | company tắt type |
| vehicle_teams | name, color |
| operators | managed / external, thông tin trả tiền (PayNow / bank), `valid_until` |
| vehicles | ownership suy từ operator (nil = own); `tags` varchar[] (GIN); `driver_name/phone` chỉ cho external; soft delete |
| drivers | own drivers, status pending/active/declined/past |
| vehicle_driver_schedules | default driver từ ngày (lên lịch trước được); entry hiệu lực = `starts_on` mới nhất ≤ ngày |
| operator_drivers | 1 bus tối đa (unique partial index), swap khi gán |
| attendants | crew |

## Endpoints (`/api/v1`)
- `public_holidays` index (`?year=`), create, update, destroy, `POST import { year }`.
- `calendars` CRUD (`start_from: moe | blank | <id>`; xoá bị chặn khi có trip dùng), `calendars/:id/days` create/update/destroy (= Change a Day).
- `clients` CRUD (ransack `q[name_i_cont]`), `clients/:id/sites|end_customers|pickup_points`.
- `vehicle_types` index (kèm `enabled`), `PATCH :id/toggle { enabled }` (company admin), create/update/destroy (Convoy Admin).
- `vehicle_teams`, `operators`, `attendants` CRUD.
- `vehicles` index: `ownership[]`, `size[]` (sedan mpv small medium large), `tags[]`, `vip`, `team_id`, `q`, `sort` (type | smallest | largest);
  `meta.facets` = số đếm cho filter chips. `POST vehicles/external` (New External Vehicle: match company theo tên, cap).
  Mỗi vehicle trả `driver` hôm nay (own / operator / external), `default_picture`, `photo` (CarrierWave).
- `vehicles/:id/driver_schedules` index (kèm `ends_on`), create (cùng ngày = thay), destroy (chỉ entry chưa bắt đầu).
- `drivers` index (`?status=`, `meta.counts`), create (invite = pending), update.
- `operator_drivers` index/create/update, `PATCH :id/assign_vehicle` (swap).

## Quyền
- Fleet (vehicles, drivers, operators, teams, attendants, driver schedules): ghi cần permission `vehicles`.
- New External Vehicle (Scheduler), calendars, holidays, clients: mọi user company (không phải Convoy Admin).
- Vehicle types: Convoy Admin CRUD; company admin bật/tắt.

## Ngoài scope Scheduler (để lại cho Fleet / Finance / Clients pages)
Log card, insurance, Vehicle Financials, Fuel, share form External Vehicles (xshare), KYC driver, yêu cầu vehicle type mới,
quản lý user company, Connected Clients/Operators, billing / portal users / bookable vehicles / approval flow của client.

## Hook cần nối ở Phase 4 (occurrence sync)
- Đổi default driver schedule → sync `driver_id` occurrence tương lai của xe.
- Public holiday / calendar day / calendar.observed_holidays / company.observed_holidays → sync trips liên quan.
- Vehicle discard → occurrence tương lai thành unassigned.

## Seeds
`01_vehicle_types`, `10_calendars` (PH 2026–27, MOE School Calendar, Google Office Calendar), `20_clients` (Google + sites/points,
DBS, MBS, Tan Family, Dr Rachel Lim, Eastern Coaches + end customers), `30_fleet` (3 teams, Hup Seng managed, Kallang external,
13 xe có ảnh CarrierWave, 10 drivers + lịch default driver, 2 operator drivers, 3 attendants). Chạy lại nhiều lần không nhân bản.

## Specs
49 examples (model + request): filters/facets/sort, CarrierWave upload + download, external cap, tenant isolation, quyền,
Convoy Admin view-only, driver schedule history, operator driver swap, calendar presets, HH:MM, holidays import, clients nested.
