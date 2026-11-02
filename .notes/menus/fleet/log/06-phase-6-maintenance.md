# Phase 6 — Maintenance page (31/10/2026)

- Query object `MaintenancePage`: list theo tab (upcoming / to_record / completed / cancelled; 2 tab đầu sớm trước, 2 tab sau mới trước),
  search (plate, workshop, work_to_do, tên loại), lọc xe, `counts` 4 tab; `kpis` (next 30 days, to record, spend tháng này,
  12 tháng + số visit); `spend` 12 tháng (tổng, by type / vehicle / workshop top 8 + %, by month qua **groupdate** đủ 12 tháng,
  tyre changes). Số tiền gồm GST theo visit (SQL `qty * unit * (1 + rate)`), cùng cách HTML (`mtTot`).
- `GET /maintenance_visits` không có `from/to` → dùng `MaintenancePage` (`meta.counts`); có `from/to` giữ hành vi cũ (Scheduler).
  `GET /maintenance_visits/summary`. Blueprint thêm `items_count`, `has_invoice`. Scheduler preload lines / invoices / driver.
- Seed `50_maintenance` thêm: 3 visit đã ghi (2, 4, 7 tháng trước; có 2 dòng lốp), 1 To Record, 1 cancelled.
- Spec `fleet_maintenance_spec.rb` (2). Tổng 207 specs.
