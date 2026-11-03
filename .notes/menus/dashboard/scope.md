# Scope: menu Dashboard (rail `codash`, icon `dashboard`), rà 02/11/2026

Nguồn: `Company Dashboard.dc.html` (component: 19 widget, 4 nhóm, kỳ, layout nhiều trang kéo thả / resize, localStorage theo user),
`logic/mixins/admin.js` `codashVals` (dữ liệu thật cho Money + giấy tờ xe). Còn lại HTML dùng số mẫu.

## Widget (Rails)
| Nhóm | Widget | Nguồn |
| --- | --- | --- |
| Operations | otp On-Time Starts, late Late Starts and Missed Pick-ups, today Trips, unas Unassigned Trips (7 ngày tới), compl Complaints and Incidents | trip_occurrences (status, max_delay_minutes vs companies.on_time_minutes, issue_raised_at, vehicle_id), stop events |
| Operations | alerts Open Ops Control Alerts | **available: false** (Ops Control) |
| Fleet | util Fleet Utilisation (giờ chạy / giờ sẵn có: 12 h / xe / ngày), off Vehicles Off the Road (hôm nay), docs Documents Expiring (60 ngày), duty Drivers | runs, maintenance_visits, replacements, vehicles (COE, road tax), insurance, drivers |
| Fleet | noshow Driver No-Shows | **available: false** (driver app) |
| Money | rev Revenue (finance / finview / vehfin), profit Fleet Profit + topbot Vehicles by Profit + loans Loan Instalments (vehfin), opp Operator Payments (finance / finview) | runs price, Finance::VehicleReport, LoanSchedule, OperatorPay |
| Money | coll Collections | **available: false** (School Bus) |
| Clients | clotp On-Time Starts by Client, clrisk Clients at Risk (on-time < 95 % hoặc hóa đơn quá hạn) | runs, client_invoices |

## Chốt với user (02/11/2026)
- Layout lưu server (`dashboard_layouts`, 1 / user, jsonb — bản chụp giao diện). Widget chưa có nguồn: `available: false` + lý do.

## Tự quyết
- Kỳ: today, d7, d30, month (month to date), last_month; so với kỳ trước như HTML. Widget "live / ahead / this month" ghi `note`.
- Ai cũng xem Dashboard; widget Money theo quyền như HTML.
