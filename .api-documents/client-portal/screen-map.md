# Client Portal — screen map

Every screen and button → the call → the section that explains it. Grows phase by phase.

| Screen / button | Call | Doc |
| --- | --- | --- |
| Sign in, one-time code, set password, sign out | `/portal/session`, `/portal/password` | [auth.md § 1](auth.md#1-the-screens) |
| User menu › Your organisations (switch) | `GET /portal/session`, `PATCH /portal/session { client_user_id }` | [auth.md § 2](auth.md#2-session) |
| Shell: top bar, rail, buttons by role | `GET /portal/me` | [shell.md § 1](shell.md#1-get-portalme) |
| Role Permissions window (Settings › Users, "See what each role can do") | `GET /portal/roles` | [shell.md § 2](shell.md#2-get-portalroles--role-permissions) |
| Settings › Users: list, Add User, Edit, Remove from Portal | `/portal/users` | [settings.md § 1](settings.md#1-users) |
| Settings › Users › Teams: list, Add / Edit Team, Delete Team | `/portal/teams` | [settings.md § 2](settings.md#2-teams) |
| Settings › Logo and Colour: Save Changes | `PATCH /portal/settings/brand` | [settings.md § 3](settings.md#3-logo-and-colour) |
| Settings › Sites | `GET /portal/settings/sites` | [settings.md § 4](settings.md#4-sites-read-only) |
| Settings › Billing Details: list, Edit (organisation / site) | `/portal/settings/billing` | [settings.md § 5](settings.md#5-billing-details-canbilling) |
| Settings › Approval Flows: Flow For pills, drawing | `GET /portal/approval_flows` | [approval-flows.md § 1](approval-flows.md#1-the-flows) |
| Approvals On / Own Flow, Add / Edit / Delete Rule, move, Otherwise | `/portal/approval_flows/:for/...` | [approval-flows.md § 2](approval-flows.md#2-change-a-flow) |
| Try a Booking | `POST /portal/approval_flows/try` | [approval-flows.md § 3](approval-flows.md#3-try-a-booking) |
| Bookings: tabs Upcoming / Awaiting Approval / Past | `GET /portal/bookings?tab=` | [bookings.md § 2](bookings.md#2-list) |
| Booking detail (from Bookings, Approvals, Map › Open Booking) | `GET /portal/bookings/:id` | [bookings.md § 3](bookings.md#3-booking-detail) |
| New Booking: form, estimate + approval preview, Add New Customer, Submit | `/portal/bookings/form`, `/portal/bookings/estimate`, `/portal/end_customers`, `POST /portal/bookings` | [bookings.md § 4](bookings.md#4-new-booking) |
| Booking detail › Accept Changes | `PATCH /portal/booking_trips/:id/accept_changes` | [bookings.md § 5](bookings.md#5-accept-changes) |
| Approvals: Waiting for You, Waiting for Others | `GET /portal/approvals` | [approvals.md § 2](approvals.md#2-approvals-page) |
| Approve / Decline (Approvals, booking detail) | `POST /portal/bookings/:id/approve`, `/decline` | [approvals.md § 3](approvals.md#3-approve--decline) |
| Booking detail › approval progress (stepper) | `approval` on `GET /portal/bookings/:id` | [approvals.md § 4](approvals.md#4-the-approval-on-a-booking) |
| Home: tiles, Upcoming Trips, Today's Shuttles, Notices to Riders | `GET /portal/home` | [home.md](home.md) |
| Shuttles: routes by site, Full Timetable | `GET /portal/shuttles` | [shuttles.md](shuttles.md) |
| Notices | `GET /portal/notices` | [notices.md](notices.md) |
| Invoices: KPIs, filters, search | `GET /portal/invoices` | [invoices.md](invoices.md) |
| Map: site / activity pills, Trip States, run list, map | `GET /portal/map` | [map.md § 1](map.md#1-get-portalmapactivitysite_id) |
| Map › trip card (stops, students) | `GET /portal/map/runs/:id` | [map.md § 2](map.md#2-get-portalmaprunsid--the-trip-card) |
| Map › search a student | `GET /portal/map/students?q=` | [map.md § 3](map.md#3-get-portalmapstudentsq--find-a-student) |
