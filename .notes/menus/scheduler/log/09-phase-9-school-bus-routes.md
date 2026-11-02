# Phase 9 — School Bus routes trên grid ✅ (30/10/2026)

Chỉ phần Scheduler hiển thị và thay đổi; plans / routes được tạo ở School Bus (routing engine, chưa làm) → seed.

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| schools | name, short_name, address, pin, calendar (school calendar), client (khi trường cũng là Managed Client) |
| school_plans | session am / pm / asa (CCA), days[], effective_from / to, in_use |
| school_routes | number, label (AM 1), start / end time, riders_count, attendant; title = "SSS AM 1" |
| school_route_stops | position, name, pin, giờ, riders_count |
| school_route_vehicle_changes | xe thường của route từ một ngày (vehicle trống = không có xe từ ngày đó) |
| school_route_replacements | xe thay theo ngày / khoảng ngày; arranged_by operator / us + daily_rate + deduct_from_operator |
| notices + school_id, notice_routes | notice cho School routes (tất cả route của trường hoặc một số) |

## Run của route nằm chung `trip_occurrences`
- Thêm `school_route_id`; `trip_id`, `client_id` thành nullable; CHECK đúng một nguồn (`num_nonnulls(trip_id, school_route_id) = 1`).
- Identity mới: (trip, school_route, date, run, slot, part) — `TripOccurrence#identity` và `Generator::Row#identity` 6 phần tử.
- → driver app vẫn 1 query (`for_driver(...).on(date)`) cho cả trip và route; cancel, issue, kéo thả, replacement dùng chung engine.
- `Occurrences::RouteGenerator` (kế thừa Generator): mỗi ngày học của plan (weekday của plan, in_use, không PH, không ngày nghỉ của calendar trường),
  giờ dời theo calendar (Late Arrival AM, Early Dismissal PM / CCA); xe = kéo tay trên run > replacement của route (xe thường thành ghost
  `original_vehicle_id`) > xe thường ngày đó; rồi replacement Scheduler (layer 4) như trip.
- `Occurrences::Sync.call(trips:, routes:)`; trigger: PH (mọi route đang chạy), calendar day (route của trường dùng calendar đó),
  daily / verify / seeds đều có routes. Run virtual sau horizon cũng có routes; `POST /occurrences { school_route_id, date }` materialize.

## Kéo thả route (`POST /occurrences/:id/move`)
`scope`: `one` (Just This Trip), `range` (`starts_on`, `ends_on`), `perm` (Permanent change / Make it the regular bus; không xe = Remove the bus from this date);
`arranged_by` operator / us, `daily_rate` (bắt buộc khi us), `deduct`, `reason`. Replacement chồng ngày bị cắt quanh cái mới;
kéo về xe thường = bỏ replacement ngày đó. Preview: `scopes`, `regular`, `operator` của route, `ask_who_arranges`, warnings.
Đổi giờ route từ Scheduler bị chặn ("School route times are set in School Bus") như HTML.

## Drawer route
`route`: school, plan (session), label, riders, xe thường, attendant, replacement đang áp, stops (giờ, riders). `trip` = null.
Notice banner theo school + route.

## Seeds `45_school_bus`
St. Stephen's School (SSS, MOE calendar), plan AM và PM Term 4, 3 route mỗi plan với stops / riders / attendant, xe thường,
replacement AM 1 tuần sau (PD1125G), đổi xe thường AM 1 từ đầu tháng sau. 414 run.

## Specs
151 examples (thêm 7).
