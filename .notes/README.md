# .notes — đọc file này trước

## Trạng thái menu
| Menu | Trạng thái | Thư mục | Doc cho FE |
| --- | --- | --- | --- |
| Scheduler | ✅ Phase 0–11 xong (30/10/2026), 154 specs | `menus/scheduler/` | `../.api-documents/scheduler.md` |
| Trips | ✅ Xong Phase 0–9 (31/10/2026) | `menus/trips/` | `../.api-documents/trips.md` |
| Fleet (+ Transport Operators) | ✅ Phase 0–9 xong (31/10/2026), 217 specs | `menus/fleet/` | `../.api-documents/fleet.md` |

## Đọc gì cho việc gì
| Việc | Đọc |
| --- | --- |
| Hiểu hệ thống đang chạy thế nào | `domains/*.md` (luôn đúng hiện trạng) |
| Bắt đầu menu mới | `data-ownership.md` (bảng nào menu đó phải làm màn sửa) → `backlog.md` → `decisions.md` |
| Đụng vào run / occurrence | `domains/occurrences.md` (layer model, quy tắc, trigger sync) |
| Tại sao chốt một cách làm | `decisions.md`, rồi `menus/<menu>/log/` của phase đó |
| Menu có những tính năng nào | `menus/<menu>/scope.md`, `plan.md` |

## Cấu trúc
```
README.md            trạng thái + chỉ đường (file này)
decisions.md         mọi quyết định: ngày · menu · quyết định (chỉ thêm, không xoá)
backlog.md           việc đã hoãn
data-ownership.md    bảng → domain → ai ghi → menu sẽ làm màn sửa
domains/             TÀI LIỆU SỐNG theo nghiệp vụ: platform, occurrences, trips, fleet, school, replacements, calendars, operations
menus/<menu>/        scope.md, plan.md, log/NN-phase-*.md (NHẬT KÝ: ghi lúc xong phase, không sửa lại)
```

## Quy tắc cập nhật
1. Bắt đầu menu: tạo `menus/<menu>/scope.md` + `plan.md` (đánh số phase từ 0), thêm dòng vào bảng trạng thái trên, xem `data-ownership.md`.
2. Xong một phase: viết `menus/<menu>/log/NN-phase-*.md` **và** sửa `domains/` cho đúng hiện trạng; bảng mới → `data-ownership.md`.
3. Chốt quyết định → 1 dòng `decisions.md`. Hoãn việc → 1 dòng `backlog.md`.
4. Đổi API → sửa `.api-documents/<menu>.md` cùng lúc.
5. Log cũ có thể lỗi thời (vd. `log/00b` là quy tắc occurrence ban đầu); khi lệch, **`domains/` và code là đúng**.
