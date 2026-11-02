# Data ownership — bảng nào, ai ghi, menu nào sẽ làm màn sửa

Menu theo rail của Convoy OS (`logic/mixins/admin.js` `railItems`): Dashboard, Ops Control, Live Map, **Scheduler** ✅, Trips ✅,
School Bus, Fleet ✅, Clients, Reports, Finance, HR, Settings; Convoy Admin: Discover, Company Leads, Transport Companies.

Cột **Hiện tại**: `ghi` = đã có API ghi đầy đủ · `một phần` = ghi được phần Scheduler cần · `seed` = chỉ đọc + seed, chưa có màn sửa.
Bắt đầu menu mới: lọc theo cột **Màn sửa sẽ ở**, những dòng `seed` / `một phần` là việc của menu đó.

| Domain | Bảng | Hiện tại | Ghi từ (đã có) | Màn sửa sẽ ở |
| --- | --- | --- | --- | --- |
| platform | companies | ghi (settings) | Settings > Company Settings (quyền `users`), session (chọn company) | Transport Companies (Convoy Admin: platform fields) |
| platform | company_country_requests | ghi | Company Settings (gửi / rút), Convoy Admin (duyệt / từ chối) | — |
| platform | users, user_schools | ghi | Settings > Users | — |
| platform | allowlisted_jwts | ghi | session (đăng nhập / đăng xuất, Convoy Admin chọn company) | Settings (thiết bị đang đăng nhập, đăng xuất từ xa) |
| platform | vehicle_types, disabled_vehicle_types | ghi | Convoy Admin CRUD, company toggle, Fleet > Vehicle Types | — |
| platform | vehicle_type_requests | ghi | Fleet > Vehicle Types (company gửi, Convoy Admin duyệt) | — |
| platform | message_terms | seed | — | Convoy Admin |
| platform | banks, bank_branches | seed (tham chiếu ACH) | — | — |
| platform | document_reads | ghi | mọi form có Claude | — |
| calendars | public_holidays, calendars, calendar_days | ghi | Change a Day, Settings > Calendars | — |
| clients | clients, client_sites, client_end_customers, client_pickup_points, client_billing_contacts, client_bookable_vehicle_types | ghi | Clients > Managed Clients, trip form (Add New Client / Customer) | Finance (billing của client) |
| clients | client_users, client_user_sites, portal_accounts | ghi | Clients > Client Users | Client Portal (quản lý người từ Portal) |
| platform | portal_jwts, portal_sign_in_codes | ghi | Client Portal sign-in | — |
| clients | rate_cards (+ vehicle_types, periods, ranges, rates, distance_bands, amounts) | ghi | Trips > Rate Cards | — |
| fleet | vehicles, vehicle_teams, operators, drivers, operator_drivers, attendants, vehicle_driver_schedules | ghi | Edit Vehicle, External Vehicle, Fleet (mọi trang) | — |
| fleet | fuel_companies, fuel_entries, fuel_alerts | ghi | Fleet > Fuel & Energy | — (Vehicle Financials đọc chi phí) |
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
| school | schools, school_plans, school_routes, school_route_stops | seed (`schools.client_id` / `calendar_id` ghi từ Managed Clients) | — | **School Bus** |
| school | school_route_vehicle_changes, school_route_replacements | ghi | kéo thả route | School Bus |
| operations | workshops, maintenance_visits, maintenance_lines, maintenance_invoices | ghi | Maintenance dialog, Fleet > Maintenance | Finance (Vehicle Financials đọc chi phí) |
| operations | notice_templates | ghi | Trips > Notices (Templates) | — |
| operations | notices, notice_runs, notice_routes, notice_deliveries | ghi | Notice form, Trips > Notices | — |
| operations | tracking_links | ghi | Share Tracking Link | — |
| platform | user_notification_preferences, notification_emails | ghi | chuông Bookings | Settings (thông báo khác sau) |

Người dùng của dữ liệu `trip_occurrences` (đọc): Ops Control, Live Map, Reports, Finance (invoice), HR (driver pay), driver app.
| pay | pay_rate_plans (+ con), pay_schemes (+ con), pay_bonuses (+ con), pay_rewards, pay_simulator_templates | ghi | HR | — |
| pay | driver_pay_schemes, driver_vehicle_types | ghi | HR > Drivers | — |
| pay | driver_pay_months (+ lines, runs) | ghi | HR > Earnings (Confirm / Reopen) | Finance (payroll sau) |
| pay | driver_point_lots, driver_point_deductions, driver_point_allocations | ghi | HR > Points, Confirm Month (bonus) | Driver app (đổi reward) |

| finance | finance_settings, finance_approvers | ghi | Finance > Finance Settings | — |
| finance | client_invoices (+ lines, line_runs, payments, sends) | ghi | Finance > Client Invoices | Client Portal (client xem / trả) |
| finance | operator_cost_overrides, operator_pay_items, operator_pay_batches (+ con) | ghi | Finance > Operator Payments | — |
| finance | vehicle_financials, vehicle_loan_payments, vehicle_finance_entries, vehicle_cost_spike_acks | ghi | Finance > Vehicle Financials | — |

Thêm bảng mới → thêm 1 dòng ở đây.
