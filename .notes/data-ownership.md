# Data ownership — bảng nào, ai ghi, menu nào sẽ làm màn sửa

Menu theo rail của Convoy OS (`logic/mixins/admin.js` `railItems`): Dashboard, Ops Control, Live Map, **Scheduler** ✅, Trips ✅,
School Bus, Fleet ✅, Clients, Reports, Finance, HR, Settings; Convoy Admin: Discover, Company Leads, Transport Companies.

Cột **Hiện tại**: `ghi` = đã có API ghi đầy đủ · `một phần` = ghi được phần Scheduler cần · `seed` = chỉ đọc + seed, chưa có màn sửa.
Bắt đầu menu mới: lọc theo cột **Màn sửa sẽ ở**, những dòng `seed` / `một phần` là việc của menu đó.

| Domain | Bảng | Hiện tại | Ghi từ (đã có) | Màn sửa sẽ ở |
| --- | --- | --- | --- | --- |
| platform | companies | một phần | session (chọn company) | Settings, Transport Companies |
| platform | users | seed | — | Settings |
| platform | allowlisted_jwts | ghi | session (đăng nhập / đăng xuất, Convoy Admin chọn company) | Settings (thiết bị đang đăng nhập, đăng xuất từ xa) |
| platform | vehicle_types, disabled_vehicle_types | ghi | Convoy Admin CRUD, company toggle, Fleet > Vehicle Types | — |
| platform | vehicle_type_requests | ghi | Fleet > Vehicle Types (company gửi, Convoy Admin duyệt) | — |
| platform | message_terms | seed | — | Convoy Admin |
| platform | banks, bank_branches | seed (tham chiếu ACH) | — | — |
| platform | document_reads | ghi | mọi form có Claude | — |
| calendars | public_holidays, calendars, calendar_days | ghi | Change a Day | Settings (lịch) |
| clients | clients, client_sites, client_end_customers, client_pickup_points | một phần (CRUD cơ bản) | trip form (Add New Client / Customer) | Clients |
| clients | rate_cards (+ vehicle_types, periods, ranges, rates, distance_bands, amounts) | ghi | Trips > Rate Cards | — |
| fleet | vehicles, vehicle_teams, operators, drivers, operator_drivers, attendants, vehicle_driver_schedules | ghi | Edit Vehicle, External Vehicle, Fleet (mọi trang) | — |
| fleet | fuel_companies, fuel_entries, fuel_alerts | ghi | Fleet > Fuel & Energy | Finance (Vehicle Financials đọc chi phí) |
| fleet | vehicle_log_cards, vehicle_insurance_policies, vehicle_insurance_documents | ghi | Edit Vehicle | Fleet |
| fleet | external_vehicle_share_links, external_vehicle_submissions | ghi | Fleet > External Vehicles, trang Share Form public | — |
| fleet | driver_invites | ghi (SMS chỉ ghi lại) | Fleet > Drivers, Operator Drivers | — |
| fleet | driver_kyc_profiles | seed | — | Driver app (driver chia sẻ) |
| trips | trips + mọi bảng con (stops, vias, slots, standby, attachments, runs, price cells, time changes) | ghi | trip form, drawer | Trips (danh sách, Trip History) |
| trips | trip_assignments (+ slots) | ghi | Assign page, kéo thả | — |
| bookings | bookings, booking_days, booking_trips (+ points, standbys, vehicles, changes), booking_attachments, booking_cancel_requests, booking_events | ghi | Trips > Bookings | Client Portal / Convoy App (đặt từ phía client: chưa) |
| occurrences | occurrence_notes | ghi | Trip History (Add Note) | — |
| occurrences | occurrence_corrections, occurrence_correction_stops, occurrence_correction_logs | ghi | Trip History (Correct Record) | — |
| occurrences | occurrence_driver_reports, occurrence_report_photos | seed | — | Driver app |
| occurrences | occurrence_positions, occurrence_stop_events, occurrence_trip_summaries | seed | — | Driver app / telematics |
| companies | on_time_minutes, speed_limit_kmh | seed (mặc định) | — | Settings |
| occurrences | trip_occurrences | ghi (chỉ qua service) | grid, drawer | Ops Control, Live Map, Reports, Finance, HR đọc |
| replacements | replacements, replacement_notifications | ghi | Replace dialog | — |
| school | trip_stop_students, route_list_versions, student_attendances, pickup_points | ghi | trip form School Run, Passenger List | School Bus |
| school | schools, school_plans, school_routes, school_route_stops | seed | — | **School Bus** |
| school | school_route_vehicle_changes, school_route_replacements | ghi | kéo thả route | School Bus |
| operations | workshops, maintenance_visits, maintenance_lines, maintenance_invoices | ghi | Maintenance dialog, Fleet > Maintenance | Finance (Vehicle Financials đọc chi phí) |
| operations | notice_templates | ghi | Trips > Notices (Templates) | — |
| operations | notices, notice_runs, notice_routes, notice_deliveries | ghi | Notice form, Trips > Notices | — |
| operations | tracking_links | ghi | Share Tracking Link | — |
| platform | user_notification_preferences, notification_emails | ghi | chuông Bookings | Settings (thông báo khác sau) |

Người dùng của dữ liệu `trip_occurrences` (đọc): Ops Control, Live Map, Reports, Finance (invoice), HR (driver pay), driver app.
Thêm bảng mới → thêm 1 dòng ở đây.
