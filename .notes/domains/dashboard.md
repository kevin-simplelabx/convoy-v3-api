# Dashboard — hiện trạng

- `Dashboard::Catalogue`: 19 widget (section, title, icon, page, size, quyền), default layout 1 trang Overview.
- `dashboard_layouts` (1 / user / company, `pages` jsonb = bản chụp giao diện); lưu bỏ widget không có quyền.
- `Dashboard::Widgets`: kỳ today / d7 / d30 / month / last_month + kỳ so sánh; on-time = `max_delay_minutes` ≤ `companies.on_time_minutes`;
  util = phút chạy / (xe own × 12 h × ngày); Money dùng Finance (VehicleReport, LoanSchedule, OperatorPay); `noshow`, `coll` = available false; `alerts` = run đang bị flag từ `OpsControl::Sync` (live).
- Ai cũng xem; Money theo quyền (rev: finance / finview / vehfin; profit / topbot / loans: vehfin; coll / opp: finance / finview).
