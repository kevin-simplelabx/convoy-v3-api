# Operations — Maintenance, Notices, Tracking, Clients — hiện trạng

## Maintenance
| Bảng | Ghi chú |
| --- | --- |
| workshops | name unique; có visit thì không xoá |
| maintenance_visits | own vehicle, driver, date + giờ, workshop, kind service / repair / tyres / inspection / other, status scheduled / completed / cancelled, odometer, GST, driver_notified_at |
| maintenance_lines | part / tyre / labour / other, tyre_position, qty, unit price trước GST |
| maintenance_invoices | file |

- `Maintenance::Save`: New Workshop theo tên, Record the Work cần odometer + line hợp lệ; hoá đơn qua reader MaintenanceInvoice (warnings plate / odometer).
- Vị trí lốp: `Vehicle#tyre_positions` theo tyre layout vehicle type.
- Không sync occurrence; Scheduler vẽ block + move preview cảnh báo clash.

## Notices
| Bảng | Ghi chú |
| --- | --- |
| notice_templates | 6 mặc định mỗi company (preset yml), `{min}` / `{time}`; CRUD ở Notices page, tên unique, message được rỗng, luôn còn ≥ 1 |
| notices | audience trip / school, trip | school, all_runs, to_riders / to_parents, banner / push / sms, starts_at / ends_at, message ≤300 |
| notice_runs, notice_routes | run keys / route ids |
| notice_deliveries | push / sms **ghi lại, chưa gửi** |

`Notices::Save`; WhatsApp chặn; chỉ sửa notice scheduled; End Now chỉ active; không xoá notice active.
Notices page: `GET /notices?state&q` + `meta.counts` (scope `in_state`, `search`).

## Tracking link
`tracking_links`: token, run identity, snapshot jsonb, hết hạn = kết thúc + 24 h; share lại = token mới; public `GET /public/tracking/:token`; daily job xoá link đóng > 7 ngày.

## Clients
| Bảng | Ghi chú |
| --- | --- |
| clients | company / individual / transport_company, code CL00001, on_time_allowance, rate_card_id |
| client_sites, client_end_customers, client_pickup_points | lồng dưới client |

Chưa làm: billing, portal users, bookable vehicles, approval flow, Connected Clients.

## Seeds
`20_clients`, `50_maintenance`, `51_notices`.

## Trang Fleet > Maintenance
`MaintenancePage` (app/queries): tab + counts + search, KPI, spend 12 tháng (gồm GST, groupdate by month), tyre changes. `GET /maintenance_visits?tab=`, `GET /maintenance_visits/summary`.
