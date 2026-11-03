# .notes — đọc file này trước

## Trạng thái menu
| Menu | Trạng thái | Thư mục | Doc cho FE |
| --- | --- | --- | --- |
| Scheduler | ✅ Phase 0–11 xong (30/10/2026), 154 specs | `menus/scheduler/` | `../.api-documents/scheduler.md` |
| Trips | ✅ Xong Phase 0–9 (31/10/2026) | `menus/trips/` | `../.api-documents/trips.md` |
| Fleet (+ Transport Operators) | ✅ Phase 0–9 xong (31/10/2026), 217 specs | `menus/fleet/` | `../.api-documents/fleet.md` |
| Settings (Company Settings, Users, Calendars, Profile) | ✅ Phase 0–5 xong (02/11/2026), 240 specs | `menus/settings/` | `../.api-documents/settings.md` |
| Clients (Managed Clients, Client Portal sign-in) | ✅ Phase 0–5 xong (02/11/2026), 252 specs | `menus/clients/` | `../.api-documents/clients.md` |
| HR (driver pay) | ✅ Phase 0–9 xong (02/11/2026), 273 specs | `menus/hr/` | `../.api-documents/hr.md` |
| Finance | ✅ Phase 0–8 xong (02/11/2026), 288 specs (School Bus Collections để School Bus) | `menus/finance/` | `../.api-documents/finance.md` |
| Reports (Shuttle Report) | ✅ Phase 0–2 xong (02/11/2026), 292 specs | `menus/reports/` | `../.api-documents/reports.md` |
| Dashboard | ✅ Phase 0–3 xong (02/11/2026), 294 specs | `menus/dashboard/` | `../.api-documents/dashboard.md` |
| Convoy Admin | ✅ Phase 0–4 xong (02/11/2026), 300 specs | `menus/convoy-admin/` | `../.api-documents/convoy-admin.md` |
| Live Map | ✅ Phase 0–3 xong (02/11/2026), 304 specs | `menus/live-map/` | `../.api-documents/live-map.md` |
| Ops Control | ✅ Phase 0–4 xong (02/11/2026), 308 specs | `menus/ops-control/` | `../.api-documents/ops-control.md` |
| School Bus (7 sub-menu) | 🚧 Sub-menu 1 (Schools & Year Setup) ✅, 2 (Fares, Policy, Payment Methods, Operator Pay) ✅, 3 (Stop Library, Stop Assignment) ✅, 4 (Route Plans, Feasibility + routing-service) ✅ (02/11/2026), 5 (Families, Registration, Bus Requests + Route Fit / first invoice / plan versions, CCA Rides, alerts) ✅ (03/11/2026), 358 specs; tiếp: 6 (School Finance) | `menus/school-bus/overview.md`, `menus/school-bus-1-setup/` … `-5-parents/` | `../.api-documents/school-bus-setup.md`, `school-bus-money.md`, `school-bus-stops.md`, `school-bus-routes.md`, `school-bus-parents.md` |

## Đọc gì cho việc gì
| Việc | Đọc |
| --- | --- |
| Hiểu hệ thống đang chạy thế nào | `domains/*.md` (luôn đúng hiện trạng) |
| Bắt đầu menu mới | `data-ownership.md` (bảng nào menu đó phải làm màn sửa) → `backlog.md` → `decisions.md` |
| Đụng vào run / occurrence | `domains/occurrences.md` (layer model, quy tắc, trigger sync) |
| Deploy staging (Kamal) | `deploy.md` |
| Tại sao chốt một cách làm | `decisions.md`, rồi `menus/<menu>/log/` của phase đó |
| Menu có những tính năng nào | `menus/<menu>/scope.md`, `plan.md` |

## Cấu trúc
```
README.md            trạng thái + chỉ đường (file này)
decisions.md         mọi quyết định: ngày · menu · quyết định (chỉ thêm, không xoá)
backlog.md           việc đã hoãn
data-ownership.md    bảng → domain → ai ghi → menu sẽ làm màn sửa
domains/             TÀI LIỆU SỐNG theo nghiệp vụ: platform, occurrences, trips, fleet, clients, pay, finance, reports, dashboard, convoy-admin, live-map, ops-control, school, replacements, calendars, operations
menus/<menu>/        scope.md, plan.md, log/NN-phase-*.md (NHẬT KÝ: ghi lúc xong phase, không sửa lại)
```

## Quy tắc cập nhật
1. Bắt đầu menu: tạo `menus/<menu>/scope.md` + `plan.md` (đánh số phase từ 0), thêm dòng vào bảng trạng thái trên, xem `data-ownership.md`.
2. Xong một phase: viết `menus/<menu>/log/NN-phase-*.md` **và** sửa `domains/` cho đúng hiện trạng; bảng mới → `data-ownership.md`.
3. Chốt quyết định → 1 dòng `decisions.md`. Hoãn việc → 1 dòng `backlog.md`.
4. Đổi API → sửa `.api-documents/<menu>.md` cùng lúc.
5. Log cũ có thể lỗi thời (vd. `log/00b` là quy tắc occurrence ban đầu); khi lệch, **`domains/` và code là đúng**.
