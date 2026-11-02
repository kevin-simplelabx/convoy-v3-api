# School — School Run (trip) và School Bus (route) — hiện trạng

Hai khái niệm khác nhau:
- **School Run** = trip `kind: school_run` của một Managed Client (vd. sub-contract cho Eastern Coaches), học sinh theo stop.
- **School Bus** = plan / route của trường do routing engine tạo (page School Bus, chưa làm) → hiện chỉ seed; run nằm chung `trip_occurrences`.

## School Run
| Bảng | Ghi chú |
| --- | --- |
| trips + | session am / pm, paid_months_mode all / some / part, unpaid_months, unpaid_month_share, charge_no_school_days, school_time_estimated, route_list_name / imported_at, students_purged_at |
| trip_stop_students | `key` uuid giữ qua các lần import |
| route_list_versions (+ stops, students) | Earlier Lists, `valid_until` |
| student_attendances | run identity + student_key; boarded / alighted / absent |
| pickup_points | Saved Pick-up Points của company, postal_codes[] |

- AM: đón → trường cuối; PM ngược lại. End không có giờ trường → ước tính FE hoặc đón cuối + 10'.
- Calendar: Late Arrival dời AM, Early Dismissal dời PM.
- Giá tháng: paid months + No School (`Pricing::TripPrice`, `SchoolRuns::BillPreview` = Next 12 Months).
- Import: reader RouteList → `SchoolRuns::RouteListReview` (gom stop, cờ, changes) → `POST /trips` hoặc `SchoolRuns::ApplyRouteList` (apply_from).
- Giữ dữ liệu học sinh 7 năm: `SchoolRuns::Purge` trong daily job.

## School Bus
| Bảng | Ghi chú |
| --- | --- |
| schools | calendar trường, client (nếu là Managed Client) |
| school_plans | session am / pm / asa (CCA), days, effective_from / to, in_use |
| school_routes (+ stops) | number, label, giờ, riders, attendant |
| school_route_vehicle_changes | xe thường từ một ngày (trống = không xe) |
| school_route_replacements | xe thay theo khoảng ngày; arranged_by, daily_rate, deduct_from_operator |
| notices.school_id, notice_routes | notice cho route |

- `Occurrences::RouteGenerator`: ngày học của plan (không PH, không ngày nghỉ calendar trường), giờ dời theo calendar;
  xe = sửa tay > route replacement (ghost) > xe thường; rồi replacement Scheduler.
- Kéo thả route: `SchoolRoutes::Move` (scope one / range / perm). Đổi giờ route từ Scheduler bị chặn.

## Seeds
`44_school_runs` (Red Swastika AM 13), `45_school_bus` (St. Stephen's, plan AM / PM Term 4, 3 route mỗi plan).

## Chưa làm
Page School Bus (plans, routing engine, sửa route), Parent app (push thật), OneMap check ở server.
