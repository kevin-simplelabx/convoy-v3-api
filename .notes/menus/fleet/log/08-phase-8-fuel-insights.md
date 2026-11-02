# Phase 8 — Fuel & Energy: alerts + KPI + usage (31/10/2026)

- Bảng `fuel_alerts` (vehicle, fuel_entry cascade, key unique theo company, kind eff / odo / dbl / big / price / trend, tone, metric,
  message, date, status open / checked, checked_by / at) + cột `fuel_entries.energy_km` (km từ lần đọc trước cùng loại năng lượng).
- `FuelAlerts::Scan` (port `flAlerts`): chạy cả company sau mỗi save / delete entry và hằng ngày (`FuelAlertsScanJob`, recurring 2:00);
  giữ status Checked theo key, xoá finding không còn đúng.
- `FuelKpis` (1 query / tháng, FILTER): spend vs tháng trước, lít, kWh, fills, eff, cost/km, số alert open.
- `FuelUsage` (port `flUsage`): view all / vehicle / driver / company + key, measure, range 30d / 12w / 12m + zoom; bucket bằng
  **groupdate** (`week_start: :monday` chỉ cho tuần); kỳ trước như HTML; rows breakdown + số alert; `drivers` (so với usual
  km/L của bus từ driver khác hoặc cùng size); `summary` (câu tóm tắt như HTML).
- Endpoints: `GET /fuel/kpis`, `GET /fuel/usage`, `GET /fuel_alerts`, `PATCH /fuel_alerts/:id/check|reopen`.
- Scope `FuelEntry.latest_first` (`.chronological.last` không đảo được vì NULLS FIRST).
- Seed `55_fuel`: chạy lại Recompute nếu thiếu energy_km, Scan, 1 alert price đã Checked.
- Spec `fleet_fuel_insights_spec.rb` (4). Tổng 217 specs.
