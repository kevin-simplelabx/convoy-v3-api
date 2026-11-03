# School — School Run (trip) và School Bus (route) — hiện trạng

Hai khái niệm khác nhau:
- **School Run** = trip `kind: school_run` của một Managed Client (vd. sub-contract cho Eastern Coaches), học sinh theo stop.
- **School Bus** = plan / route của trường do routing engine tạo; run nằm chung `trip_occurrences`. Menu chia 7 sub-menu
  (`menus/school-bus/overview.md`); sub-menu 1 (Schools & Year Setup) xong — xem mục "School Bus — Year Setup" dưới.

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

## School Bus — Schools & Year Setup (sub-menu 1)
| Bảng | Ghi chú |
| --- | --- |
| schools + `postal` | New School: postal → OneMap (lat / lng, address mặc định); `calendar_id` chỉ còn cho Clients (không dùng cho run) |
| school_route_labels | AM / PM / ASA: prefix, start ≥ 0, digits 0–4, suffix; chưa lưu = mặc định "AM " / "PM " / "CCA " |
| postal_geocodes | cache OneMap (dùng chung, không tenant), "không thấy" thử lại sau 7 ngày; `Geo::OneMap` (spec: `FakeOneMap`) |
| rider_datasets | file CarrierWave, effective_from; list dùng ngày D = mới nhất có effective_from ≤ D; status locating → ready (`SchoolRidersLocateJob`) |
| school_riders | rid (Student ID), tên, grade, address, postal, lat / lng, am / pm, cca_days (ISO), starts_on / ends_on, parent; `rider_dataset_id` null = thêm tay (`M-0001`) |
| academic_years | key `2026` / `2026/27`, 12 tháng từ start_month, structure semester (2) / term (3 / 4), operating_days (ISO), cca_same_as_terms |
| academic_terms | position, starts_on / ends_on, cca_starts_on / cca_ends_on (khi CCA riêng) |
| school_holidays, school_special_days | theo năm học, luôn sửa được (Save Changes = thay cả list); special day: kind + time + description |
| setup_locks | (school, năm học hoặc null, section) — Save & Lock; section: calendar, sessions (năm học), levels, attendants (trường) |
| school_levels | theo trường, thứ tự, tên unique (không phân biệt hoa thường), section, final |
| bus_sessions (+ variants) | theo năm học: to_school / to_home, cca, d2d / p2p, max journey, days (operating days), arrive_from / to, dismissal, depart (phút) |
| school_attendant_policies | theo trường: needs statutory / all / selected (size luật luôn có), provided_by operator / us; bus types = `SchoolBus::BUS_TYPES` (engine) |

- Ngày học = operating day, trong term, không holiday (`AcademicYear#school_day?`). **`Occurrences::RouteGenerator` dùng lịch năm học**
  (không còn Settings › Calendars); không có năm học → T2–T6 trừ public holiday; special day không dời giờ (như HTML).
  Sửa calendar / holidays / xoá năm → `AcademicYears.resync` (job sync route của trường).
- File rider: `SchoolRiders::FileReader` (roo, cột theo tên như HTML, dòng lỗi bỏ qua + báo dòng, rid trùng giữ dòng đầu, postal đệm 0).
- Quyền: `SchoolPolicy` — xem: mọi user (scope `user_schools` nếu không every_school); schools: thêm trường, labels, riders; plans | schools: Year Setup;
  users: Delete Year.

## School Bus — tiền của Year Setup (sub-menu 2)
| Bảng | Ghi chú |
| --- | --- |
| fare_tables (1 / năm học) | payer parents / school / bus (+ bill_to), basis, trip, cycle + months, distribution, 1-way, by_size, small / express, CCA (+ rider rules), bus_count; `period_snapshot` jsonb = [ngày học, ngày CCA] mỗi kỳ khi lock |
| fare_tiers (+ fare_tier_sizes, fare_size_columns) | km hoặc zone (sectors[], area jsonb), fare / pm / 1-way, period_fares[] (custom), small / express / cca fare |
| fare_surcharges, fare_bus_rates | surcharge theo khu vực; giá per bus theo `SchoolBus::BUS_TYPES` + booked runs |
| fare_adjustments | Extra Charges: pct / amt / once, from_month / to_month (null = sang năm sau), targets (tier id / `bus:<type>`) |
| school_policy_versions (+ policy_reminders) | version theo effective_on; publish thay version chưa bắt đầu |
| school_payment_methods | bank / paynow / card + fee; tài khoản riêng hoặc FinanceSetting |
| school_operator_pays, school_bus_size_rates | scheme, part, break months, earned (terms / days); giá theo cỡ xe + BA their / our |

- `FareTables.periods` (term hoặc tháng; snapshot khi lock), `FareTables::Check` (luật wizard), `FareTables::Calc` (port `fareCalc`, BigDecimal,
  fdist: kỳ cuối nhận phần làm tròn), `FareTables.adjusted` / `one_offs` (Extra Charges trên bill), `OperatorPays::Earned` (servicePeriod: term gần nhất
  + term trước cách < 21 ngày) + `Calculator`. Lock section: fares (năm học), operator_pay (trường); Policy done = có version.
- Quyền: sửa = `finance` (`SchoolPolicy#money_setup?`), Operator Pay xem = finance / finview (`money_view?`).

## School Bus — Stop Library & Stop Assignment (sub-menu 3)
| Bảng | Ghi chú |
| --- | --- |
| ura_subzones (platform) | 332 subzone URA MP2019 (code, name, planning area, rings jsonb, bbox); `UraSubzone.at(lat, lng)` (bbox rồi `Geo.inside?`); seed `05_ura_subzones` từ `db/seeds/files/ura_subzones.json` |
| stops | thư viện company (discard): code `<subzone>-NNNN` (số trống đầu tiên), library_status approved / school / pending, owner_school, requested_by / at, former_codes |
| stop_points | chữ A–P (retired giữ chữ), usage, sizes S / M / L, primary, lat / lng, subzone, Street View, photo + photo_original + annotations jsonb + credit |
| school_stops | catchment của trường: postal_codes[] (GIN), areas jsonb (latlngs, exclude, how), off_point_ids[]; after_commit → `schools.stops_changed_at` |
| rider_point_links | liên kết tay theo rid hoặc postal: alternative / disconnected |
| stop_photo_requests (+ submissions) | audience parents / driver / both / parent (+ rider), max 1–12, open / closed, auto; submission pending / accepted / rejected (từ app = seed) |
| companies.stop_photo_auto_driver / _parent | auto request |

- `Stops::Save`: luật editor HTML, chữ cái mới / retired, primary đúng 1, code theo subzone primary khi tạo; đổi vật lý stop trường khác dùng
  → 422 `confirm_required` + details schools (gửi lại `confirmed: true`). Tạo từ trường → status school + link trường; `Stops::Library` ask / review.
- `SchoolStops::Assignment`: candidates = catchment (postal / area − exclude) − point off − disconnected + alternative; status none / one / conflict.
- `ApplicationService::Error` nhận `code:` / `details:` (render vào `error`).
- Quyền `StopPolicy`: sửa = plans; review = library. Không có school_id = toàn thư viện company.

## School Bus — Route Plans & Feasibility (sub-menu 4)
- **routing-service** (`routing-service/`, Node): engine Convoy Pathfinder nguyên bản; /solve /retime /diff /meta /health; OSRM `router.project-osrm.org`;
  Kamal accessory `routing`, Rails `ROUTING_URL` + `ROUTING_SECRET`; `Routing::Client` (spec `FakeRouting`).
| Bảng | Ghi chú |
| --- | --- |
| routing_settings | params jsonb engine (company) |
| routing_runs | input / params / result jsonb, kind new / again (+ target_plan), no_stop / conflict rids, status |
| school_plans (+ cột) | source engine / manual / seed, priority, params, summary, unassigned jsonb, stale, adopted_at / by; state draft / scheduled / current / replaced từ in_use + ngày |
| school_routes (+ cột) | route_key, bus_type, seats, capacity, floor, fill, span, ride_minutes, badges, locked / hidden / edited / manual, vias, engine_route jsonb |
| school_route_stops (+ cột), school_route_riders | stop / stop_point / dwell; rider (rid) từng stop |
| plan_comments, rider_assignments | comment; rid → PUDO (từ AM adopt hoặc tay), notified_at |
| school_route_prices, route_charges | giá operator theo ngày (fixed / rider); route charge amt / pct từ ngày, status ok / check, carried_from |
| feasibility_studies (+ rows, bus_prices, fare_tiers, scenarios) | sandbox; scenario result jsonb snapshot |

- `Routing::Input` (port engInput), `RoutingRunJob` → `Plans::FromResult` / `Plans::MergeAgain`; `Plans::Edit` (retime qua service), `Plans::Adopt` (+ cancel,
  `RouteCharges.carry`, rider assignments), `Plans::Destroy`, `Plans::EngineShape`, `Plans.summary`, `Plans.resync`; `Feasibility::Run` / `Cost` / `Fares`
  (port fzRun / fzCost / fzFare), `FeasibilityRunJob`. Out of Date = stale hoặc `schools.stops_changed_at` > plan.created_at.

## School Bus — Phụ huynh (sub-menu 5)

- **Families** (`families`, `family_guardians`, `family_riders`): một rider / một family / trường; code FAM-0001; tên auto theo họ guardian.
- **Registration** (`school_registrations` 1 / năm học + 12 `registration_messages`, preset `config/presets/registration_messages.yml`): windows
  renew / general, confirm hours, mid-year (ack_days, plan_weeks), levels / sessions, auto-accept rules, form asks; Schedule cần calendar /
  sessions / fares lock + policy đang dùng.
- **Bus requests** (`bus_requests` + events / answer moves / places): New Service theo năm học, adr / svc / stop theo rider. Mid-year clock theo ngày làm
  việc (public holidays công ty). Check = `RouteFit` trên plan đang chạy ngày bắt đầu (`RouteFit::Routes`: ghế trống − ghế giữ + rider đã nghỉ).
  Accept → quote (`BusRequests::Fare`), places, first bill (`school_bills`), rider + family (`BusRequests::Link`); Lapsed = quá offer_by chưa trả.
  Active / Stopping / Stopped → `BusRequests::PlanSync` → `Plans::ApplyChange` (version plan từ ngày, `school_plan_changes`, resync).
  End Rider bằng tay (`BusRequests.end_of`); `BusRequestsDailyJob` 12:30am sửa rider tới ngày + lên level; `BusRequestsDigestJob` 8:00am ghi email.
- **CCA Rides** (`cca_ride_settings`, `cca_bookings`, `cca_off_days`, `cca_credits`): cut-off thứ Bảy 23:59, late add khi còn ghế, Bus Not Running → credit,
  bill `kind: cca` có lines + credit_used.

## Seeds
`44_school_runs` (Red Swastika AM 13), `45_school_bus` (St. Stephen's, plan AM / PM Term 4, 3 route mỗi plan),
`48_school_setup` (SSS: AY 2026 lock + holidays + special day, AY 2027, levels P1–P6, 3 sessions, BA statutory, 65 rider từ stop),
`49_school_money` (SSS AY 2026 fares lock 4 tier, fuel surcharge, policy v1, payment methods, operator pay + giá 4 cỡ xe),
`52_school_stops` (7 stop thư viện từ stop AM + catchment postal rider, 1 stop chờ duyệt, 1 photo request 2 ảnh),
`53_school_routing` (routing settings Balanced, 1 feasibility study 2 scenario chưa chạy). Plan seed cũ của SSS giữ nguyên (source manual).
`54_school_parents` (registration AY 2027 draft; 18 request mới / renewal / mid-year, 3 accept (Active / Accepted / Lapsed) có first bill; adr, adr chờ phụ
huynh, svc, stop; CCA Rides S$8 Thứ 3 / 5 với tuần trước có ngày không chạy → credit; digest 08:00 hôm nay).

## Chưa làm
Page School Bus (plans, routing engine, sửa route), Parent app (push thật), OneMap check ở server.
