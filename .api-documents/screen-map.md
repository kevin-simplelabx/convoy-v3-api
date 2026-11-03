# Screen Map — Convoy OS screen → API

A reverse index for front-end developers: find the screen and the button you are building in the Convoy OS prototype
(`Convoy OS.dc.html`), and this table gives the API call and the section that explains it (params, response, messages).

- Read [README.md](README.md#base-url-and-format) first (sign-in, errors, paging, files, background reads, runs).
- Paths start with `/api/v1`. **FE only** = no API call (the screen does it alone).
- Menus are in the order of the rail. A dialog opened from several screens (Trip form, Maintenance, Notice, Replace,
  Edit Vehicle, External Vehicle) is listed once under [Shared dialogs](#shared-dialogs); screens link to it.
- Menus with no API yet are listed at the end: [Not built yet](#not-built-yet).

## Contents

- [Sign-in and app shell](#sign-in-and-app-shell)
- [Scheduler](#scheduler)
- [Trips](#trips): Trips · Trip History · Notices · Bookings · Rate Cards
- [Fleet](#fleet): Vehicles · Drivers · Bus Attendants · External Vehicles · Fuel & Energy · Maintenance · Vehicle Types
- [Transport Operators](#transport-operators): Managed Operators · Operator Vehicles · Operator Drivers
- [Clients](#clients): Managed Clients · client record · Client Users
- [Convoy Admin](#convoy-admin): Transport Companies · Message Terms · Discover · Company Leads
- [Dashboard](#dashboard)
- [Reports](#reports): Shuttle Report
- [School Bus: Schools & Year Setup](#school-bus-schools--year-setup)
- [Ops Control](#ops-control)
- [Live Map](#live-map)
- [Finance](#finance): Client Invoices · Documents · Operator Payments · Vehicle Financials · Finance Settings
- [HR](#hr): Drivers · Earnings · Pay Schemes · Rate Plans · Bonuses · Points · Rewards · Salary Simulator · Audit Log
- [Settings](#settings): Company Settings · Users · Calendars
- [Shared dialogs](#shared-dialogs)
- [Public pages (no sign-in)](#public-pages-no-sign-in)
- [Not built yet](#not-built-yet)

---

## Sign-in and app shell

| Screen / element | API | Doc |
| --- | --- | --- |
| Sign-in page: Sign In | `POST /session` → `data.token`, then `Authorization: Bearer <token>` on every call | [README](README.md#signing-in-bearer-token) |
| Page load: who am I, company name / logo / theme colour, date and time formats, rail items by permission | `GET /session` | [README](README.md#signing-in-bearer-token) |
| Account menu: Profile (picture, Display Name, Mobile) | `GET` / `PATCH /profile` | [settings § 2](settings.md#2-profile) |
| Account menu: Company Settings | Opens Settings > Company Settings | [Settings](#settings) |
| Sign Out | `DELETE /session` | [README](README.md#signing-in-bearer-token) |
| Convoy Admin: pick the company to view | `PATCH /session` `{ company_id }` (company list: `GET /companies`) | [README](README.md#signing-in-bearer-token) |
| Any image or file (`<img src>`, open in a new tab) | The `url` / `thumb_url` already in the record (`GET /downloads/:token`, no header) | [README](README.md#files-uploads-and-downloads) |
| Any "Read with Claude" (log card, insurance, invoice, receipt, route list, trip message) | `POST /document_reads`, poll `GET /document_reads/:id` | [README](README.md#reading-documents-with-claude-background-reads) |

---

## Scheduler

Rail icon `calendar_view_week`.

### Grid and toolbar

| Screen / element | API | Doc |
| --- | --- | --- |
| Open the Scheduler (grid: vehicles, runs, maintenance blocks, unassigned tray, horizon) | `GET /scheduler?from=&to=` | [scheduler § 1](scheduler.md#get-scheduler) |
| Day / Week, ‹ ›, date picker, Today | `GET /scheduler?from=&to=` with the new range | [scheduler § 2](scheduler.md#2-toolbar) |
| Search, filter chips, Sort | `GET /scheduler` with filter params | [scheduler § 1](scheduler.md#get-scheduler) |
| Table view / a driver's day | `GET /occurrences?...` / `GET /occurrences?driver_id=&date=` | [scheduler § 1](scheduler.md#get-occurrences--runs-as-a-list-table-view-drivers-day) |
| Assign Trips (badge) | `GET /scheduler/assign_summary` → Assign page | [scheduler § 2](scheduler.md#get-schedulerassign_summary) |
| Replacements | `GET /replacements` | [Replace dialog](#replace-dialog-and-replacements-list) |
| Change a Day | Calendars | [Change a Day](#change-a-day-calendars) |
| Maintenance | `GET /maintenance_visits/new?vehicle_id=` | [Maintenance dialog](#maintenance-dialog-and-workshops) |
| External Vehicle | `POST /vehicles/external` | [External Vehicle](#new-external-vehicle) |
| New Trip | Trip form | [Trip form](#trip-form) |
| How It Works, Legend, Edit / View Only lock, zoom, link lines | FE only | [scheduler § 2](scheduler.md#2-toolbar) |

### Drag and drop, empty slot

| Screen / element | API | Doc |
| --- | --- | --- |
| Drop a run on another vehicle: the dialog (Today Only / From This Date On, warnings) | `GET /occurrences/:id/move_preview?vehicle_id=` | [scheduler § 3.1](scheduler.md#31-before-the-dialog-get-occurrencesidmove_previewvehicle_id) |
| Confirm the move | `POST /occurrences/:id/move` | [scheduler § 3.2](scheduler.md#32-confirm-post-occurrencesidmove) |
| Empty slot → New Trip | Trip form prefilled (vehicle, date, time) | [scheduler § 4](scheduler.md#4-empty-slot-menu) |
| Empty slot → Maintenance | `GET /maintenance_visits/new?vehicle_id=&date=&start_time=` | [scheduler § 4](scheduler.md#4-empty-slot-menu) |
| Empty slot → Inspection | Coming soon, no API | [scheduler § 4](scheduler.md#4-empty-slot-menu) |

### Trip drawer (click a run)

| Screen / element | API | Doc |
| --- | --- | --- |
| Open the drawer | `GET /occurrences/:id` | [scheduler § 5.1](scheduler.md#51-open-a-run-get-occurrencesid) |
| Cancel / Restore | `PATCH /occurrences/:id/cancel` / `restore` | [scheduler § 5.2](scheduler.md#52-drawer-actions) |
| More › Force End Trip (run on the road) | `PATCH /occurrences/:id/end` | [scheduler § 5.2](scheduler.md#52-drawer-actions) |
| Raise an Issue / Clear Issue | `POST` / `DELETE /occurrences/:id/issue` | [scheduler § 5.2](scheduler.md#52-drawer-actions) |
| Change the pick-up time (one-off: Save; recurring: Today Only / Every Run From Today; Undo) | `PATCH /occurrences/:id/time` | [scheduler § 5.2](scheduler.md#52-drawer-actions) |
| Change Vehicle | `move_preview` then `move` | [scheduler § 3](scheduler.md#3-drag-and-drop) |
| Back to Regular Bus | `PATCH /occurrences/:id/regular_bus` | [scheduler § 5.2](scheduler.md#52-drawer-actions) |
| Assign External Vehicle | `POST /vehicles/external`, then `move` | [External Vehicle](#new-external-vehicle) |
| Replace (Driver Unavailable, Vehicle Down, Crew Swap, Handover) | Replace dialog with `occurrence_id` | [Replace dialog](#replace-dialog-and-replacements-list) |
| Send Notice | Notice form prefilled with the trip | [Notice form](#notice-form) |
| Share Tracking Link | `POST /occurrences/:id/tracking_link` | [scheduler § 16](scheduler.md#16-public-trip-tracking-page) |
| Edit Trip | `GET /trips/:trip_id` → Trip form | [Trip form](#trip-form) |
| Delete trip | `DELETE /trips/:trip_id` | [scheduler § 5.2](scheduler.md#52-drawer-actions) |
| Passenger List (School Run): open / mark boarded, alighted, absent | `GET /occurrences/:id/passengers` / `PATCH /occurrences/:id/passengers/:key` | [scheduler § 5.3](scheduler.md#53-passenger-list-school-run) |
| Stops: add / remove a photo | `POST /trips/:trip_id/stops/:stop_id/photos` / `DELETE /trips/:trip_id/stops/:stop_id/photos/:id` | [scheduler § 5.4](scheduler.md#54-stop-photos-stops-section-of-the-drawer) |
| Runs That Move Together: group / ungroup | `POST /trips/:trip_id/run_groups` / `DELETE /trips/:trip_id/run_groups/:id` | [scheduler § 5.5](scheduler.md#55-runs-that-move-together-shuttles) |
| No Fixed Bus | `PATCH /trips/:trip_id` `{ trip: { no_fixed_bus } }` | [scheduler § 5.6](scheduler.md#56-no-fixed-bus) |
| Copy Info, Street View, call buttons | FE only | [scheduler § 5.2](scheduler.md#52-drawer-actions) |

### Vehicle panel (click a vehicle name)

| Screen / element | API | Doc |
| --- | --- | --- |
| Vehicle details, driver | The grid's `vehicles` row, or `GET /vehicles/:id` | [scheduler § 6](scheduler.md#6-vehicle-panel) |
| Replacements on this vehicle | `GET /replacements?vehicle_id=` | [scheduler § 6](scheduler.md#6-vehicle-panel) |
| Driver Away / Vehicle Down | `POST /replacements` (`kind: drv` / `veh`, `scope: range`) | [Replace dialog](#replace-dialog-and-replacements-list) |
| Edit Vehicle | Edit Vehicle screen | [Edit Vehicle](#edit-vehicle) |

### Assign page (Assign Trips → a shuttle)

| Screen / element | API | Doc |
| --- | --- | --- |
| Open the page (runs per day, history) | `GET /trips/:trip_id/assignments?from=` | [scheduler § 8](scheduler.md#8-assign-page) |
| Give ticked runs (own bus / operator / none, pay) | `POST /trips/:trip_id/assignments` | [scheduler § 8](scheduler.md#8-assign-page) |
| Remove a history entry | `DELETE /trips/:trip_id/assignments/:id` | [scheduler § 8](scheduler.md#8-assign-page) |
| If the Client Cancels a Run | `PATCH /trips/:trip_id` `{ trip: { operator_cancel_rule } }` | [scheduler § 8](scheduler.md#8-assign-page) |

---

## Trips

Rail icon `assignment`.

### Trips page

| Screen / element | API | Doc |
| --- | --- | --- |
| The list (dates, search, Type / Operator menus, status chips, paging) | `GET /occurrences/list?from=&to=` | [trips § 1](trips.md#1-trips-page) |
| Click a row | Opens the Scheduler on that date with the run selected (FE) | [trips § 1](trips.md#1-trips-page) |
| New Trip | Trip form | [Trip form](#trip-form) |

### Trip History

| Screen / element | API | Doc |
| --- | --- | --- |
| The list (past 30 days by default, filters, chips) | `GET /trip_history` | [trips § 5](trips.md#list--get-trip_history) |
| Open a record (timeline, stops, on-time, speed, passengers) | `GET /trip_history/:id` | [trips § 5](trips.md#record--get-trip_historyid) |
| Speed chart / route replay | `GET /trip_history/:id/track` | [trips § 5](trips.md#gps-track--get-trip_historyidtrack) |
| Add Note | `POST /trip_history/:id/notes` | [trips § 5](trips.md#add-note--post-trip_historyidnotes) |
| Correct Record | `POST /trip_history/:id/correction` | [trips § 5](trips.md#correct-record--post-trip_historyidcorrection) |
| Cancelled by Client / by Us | Set when cancelling in the drawer (`by_client`) | [trips § 5](trips.md#cancelled-by-client--by-us) |

### Notices

| Screen / element | API | Doc |
| --- | --- | --- |
| Tabs Active / Scheduled / Ended, search | `GET /notices?state=&q=` | [trips § 2](trips.md#get-notices) |
| End Now / Edit / Duplicate / Delete | `PATCH /notices/:id/end_now` / `PATCH /notices/:id` / `POST /notices/:id/duplicate` / `DELETE /notices/:id` | [trips § 2](trips.md#get-notices) |
| New Notice | Notice form (no trip picked) | [Notice form](#notice-form) |
| Templates card: list / Add Template / edit / remove | `GET` / `POST /notice_templates`, `PATCH` / `DELETE /notice_templates/:id` | [trips § 2](trips.md#templates-card) |

### Bookings

| Screen / element | API | Doc |
| --- | --- | --- |
| The list | `GET /bookings` | [trips § 4](trips.md#list--get-bookings) |
| Booking details | `GET /bookings/:id` | [trips § 4](trips.md#booking-details--get-bookingsid) |
| Record Booking / Save Changes | `POST /bookings` / `PATCH /bookings/:id` | [trips § 4](trips.md#record-booking--save-changes--post-bookings--patch-bookingsid) |
| Price estimate while editing | `POST /bookings/estimate` | [trips § 4](trips.md#estimate-while-editing--post-bookingsestimate) |
| Approve & Convert to Trip / Approve Without Waiting | `POST /booking_trips/:id/approve` | [trips § 4](trips.md#approve-reject-and-the-clients-steps) |
| Reject | `PATCH /booking_trips/:id/reject` | [trips § 4](trips.md#approve-reject-and-the-clients-steps) |
| Client Acknowledged / client approval done / declined | `PATCH /booking_trips/:id/acknowledge` / `client_approve` / `client_decline` | [trips § 4](trips.md#approve-reject-and-the-clients-steps) |
| Open in Scheduler | FE (uses `scheduler_trips`) | [trips § 4](trips.md#approve-reject-and-the-clients-steps) |
| Cancellation requests: record / accept / decline | `POST /bookings/:booking_id/cancel_requests`, `PATCH .../cancel_requests/:id` | [trips § 4](trips.md#cancellation-requests) |
| The bell: list, badge, mark seen | `GET /booking_notifications`, `PATCH /booking_notifications/seen` | [trips § 4](trips.md#notifications-the-bell) |
| The bell: Settings dialog | `GET` / `PATCH /booking_notifications/preferences` | [trips § 4](trips.md#notifications-the-bell) |
| Files: add / remove | `POST /bookings/:booking_id/attachments` / `DELETE /bookings/:booking_id/attachments/:id` | [trips § 4](trips.md#files--post-bookingsbooking_idattachments--delete-bookingsbooking_idattachmentsid) |

### Rate Cards

| Screen / element | API | Doc |
| --- | --- | --- |
| The list | `GET /rate_cards` | [trips § 3](trips.md#list--get-rate_cards) |
| View / Edit | `GET /rate_cards/:id`, then `PATCH /rate_cards/:id` | [trips § 3](trips.md#view--edit--get-rate_cardsid) |
| New Rate Card | `GET /rate_cards/new` | [trips § 3](trips.md#new-rate-card--get-rate_cardsnew) |
| Save | `POST /rate_cards` / `PATCH /rate_cards/:id` | [trips § 3](trips.md#save--post-rate_cards--patch-rate_cardsid) |
| Duplicate | `GET /rate_cards/:id`, then `POST /rate_cards` | [trips § 3](trips.md#list--get-rate_cards) |
| Make Default / Archive / Unarchive | `PATCH /rate_cards/:id/make_default` / `archive` / `unarchive` | [trips § 3](trips.md#list--get-rate_cards) |
| Live warnings while editing | `POST /rate_cards/check` | [trips § 3](trips.md#live-warnings-while-editing--post-rate_cardscheck) |
| Client Rate Cards: list / change a client's card | `GET /rate_card_assignments` / `PATCH /rate_card_assignments/:client_id` | [trips § 3](trips.md#client-rate-cards--get-rate_card_assignments) |

---

## Fleet

Rail icon `directions_bus`. Writing needs the `vehicles` permission.

### Vehicles

| Screen / element | API | Doc |
| --- | --- | --- |
| The list, team chips, search, sort | `GET /vehicles?ownership[]=own` | [fleet § 1.1](fleet.md#11-list-get-vehicles) |
| Manage Teams | `PUT /vehicle_teams/bulk` | [fleet § 1.2](fleet.md#12-manage-teams-put-vehicle_teamsbulk) |
| Vehicle record (with upcoming drivers, fuel summary) | `GET /vehicles/:id` | [fleet § 1.3](fleet.md#13-vehicle-record-get-vehiclesid) |
| Record: Log Card / Insurance sections | `GET /vehicles/:vehicle_id/log_cards` / `insurance_policies` | [Edit Vehicle](#edit-vehicle) |
| Add Vehicle / Edit | Edit Vehicle screen | [Edit Vehicle](#edit-vehicle) |
| Delete Vehicle | `DELETE /vehicles/:id` | [fleet § 1.4](fleet.md#14-delete-vehicle-delete-vehiclesid) |
| Record: Financials section | Not built (Finance menu): hide it | [fleet § 10](fleet.md#10-not-built-yet) |

### Drivers

| Screen / element | API | Doc |
| --- | --- | --- |
| Tabs Active / Pending Invites / Declined / Past Drivers, search | `GET /drivers?status=&q=` | [fleet § 2.1](fleet.md#21-tabs-get-driversstatusactive) |
| Invite Driver / Edit | `POST /drivers` / `PATCH /drivers/:id` | [fleet § 2.2](fleet.md#22-invite-and-edit) |
| Resend / Mark Accepted / Mark Declined / Remove driver / Invite Again | `PATCH /drivers/:id/resend` / `accept` / `decline` / `remove` / `reinvite` | [fleet § 2.3](fleet.md#23-row-buttons) |
| Cancel invite / Delete | `DELETE /drivers/:id` | [fleet § 2.3](fleet.md#23-row-buttons) |
| View Details | `GET /drivers/:id/details` | [fleet § 2.4](fleet.md#24-view-details-get-driversiddetails) |
| Shown to Your Customers | `PATCH /drivers/:id/display` (multipart) | [fleet § 2.5](fleet.md#25-shown-to-your-customers-patch-driversiddisplay) |

### Bus Attendants

| Screen / element | API | Doc |
| --- | --- | --- |
| List, search / Add Attendant / Edit / Delete | `GET` / `POST /attendants`, `PATCH` / `DELETE /attendants/:id` | [fleet § 6](fleet.md#6-bus-attendants) |

### External Vehicles

| Screen / element | API | Doc |
| --- | --- | --- |
| The list, "3 of 10 external vehicles" | `GET /vehicles?ownership[]=external` (`meta.external_cap`) | [fleet § 4.1](fleet.md#41-list-and-slots) |
| Add External Vehicle / Edit | `POST /vehicles/external` (Edit: with `vehicle_id`) | [fleet § 4.2](fleet.md#42-add--edit--remove) |
| Remove | `DELETE /vehicles/:id` | [fleet § 4.2](fleet.md#42-add--edit--remove) |
| Share Form link / New link | `GET /external_share_link` / `POST /external_share_link/reset` | [fleet § 4.3](fleet.md#43-share-form-link) |
| Answers waiting: list / Review and Add / Dismiss | `GET /external_vehicle_submissions`, `POST /vehicles/external` with `submission_id`, `PATCH /external_vehicle_submissions/:id/dismiss` | [fleet § 4.5](fleet.md#45-answers-waiting) |

### Fuel & Energy

| Screen / element | API | Doc |
| --- | --- | --- |
| The month's log | `GET /fuel_entries?month=` | [fleet § 8.1](fleet.md#81-the-months-log-get-fuel_entriesmonth2026-11) |
| Add Entry (blank form) / Save Entry / Delete | `GET /fuel_entries/new?vehicle_id=`, `POST /fuel_entries`, `PATCH` / `DELETE /fuel_entries/:id` | [fleet § 8.2](fleet.md#82-add--edit--delete-an-entry) |
| Drop a Receipt / read a receipt | `POST /document_reads` `kind: fuel_receipt`, then save with `document_read_id` | [fleet § 8.3](fleet.md#83-reading-a-receipt) |
| Vehicle cards | `GET /fuel_entries/vehicles?month=` | [fleet § 8.4](fleet.md#84-vehicle-cards-get-fuel_entriesvehiclesmonth2026-11) |
| Fuel Companies window | `GET /fuel_companies`, `PUT /fuel_companies/bulk` | [fleet § 8.6](fleet.md#86-fuel-companies-window) |
| KPI row | `GET /fuel/kpis?month=&vehicle_id=` | [fleet § 8.7](fleet.md#87-kpi-row-get-fuelkpismonth2026-11vehicle_id) |
| Needs a Look: tabs / Mark Checked / Undo | `GET /fuel_alerts?status=`, `PATCH /fuel_alerts/:id/check` / `reopen` | [fleet § 8.8](fleet.md#88-needs-a-look) |
| Usage card | `GET /fuel/usage` | [fleet § 8.9](fleet.md#89-usage-card-get-fuelusage) |
| How It Works | FE only | [fleet § 10](fleet.md#10-not-built-yet) |

### Maintenance

| Screen / element | API | Doc |
| --- | --- | --- |
| Tabs Upcoming / To Record / Completed / Cancelled | `GET /maintenance_visits?tab=&from=&to=&vehicle_id=` | [fleet § 7.1](fleet.md#71-list-get-maintenance_visitstabupcoming) |
| KPI tiles, spend, tyre changes | `GET /maintenance_visits/summary?vehicle_id=` | [fleet § 7.2](fleet.md#72-kpi-tiles-spend-and-tyre-changes-get-maintenance_visitssummaryvehicle_id) |
| Schedule Maintenance / open a visit / Workshops | Maintenance dialog | [Maintenance dialog](#maintenance-dialog-and-workshops) |

### Vehicle Types

| Screen / element | API | Doc |
| --- | --- | --- |
| The table | `GET /vehicle_types` | [fleet § 5.1](fleet.md#51-table-get-vehicle_types) |
| Offered switch | `PATCH /vehicle_types/:id/toggle` | [fleet § 5.1](fleet.md#51-table-get-vehicle_types) |
| Tyres / Remove (Convoy Admin) | `PATCH /vehicle_types/:id` / `DELETE /vehicle_types/:id` | [fleet § 5.1](fleet.md#51-table-get-vehicle_types) |
| Request a New Type: Send Request / Your Requests | `POST` / `GET /vehicle_type_requests` | [fleet § 5.2](fleet.md#52-request-a-new-type) |
| Requests From Companies (Convoy Admin): Add Type / Decline | `PATCH /vehicle_type_requests/:id/approve` / `decline` | [fleet § 5.2](fleet.md#52-request-a-new-type) |

---

## Transport Operators

In the Fleet menu, group Transport Operators.

| Screen / element | API | Doc |
| --- | --- | --- |
| Managed Operators: the list | `GET /operators?q[kind_eq]=managed` | [fleet § 3.1](fleet.md#31-list-get-operatorsqkind_eqmanaged) |
| Managed Operators: Add / Edit | `POST /operators` / `PATCH /operators/:id` | [fleet § 3.2](fleet.md#32-add--edit) |
| Managed Operators: bank picker, branch from account number | `GET /banks`, `GET /banks/:id/branch?account_number=` | [fleet § 3.3](fleet.md#33-banks) |
| Operator Vehicles: the list | `GET /vehicles?ownership[]=managed` | [fleet § 1](fleet.md#1-vehicles-and-operator-vehicles) |
| Operator Vehicles: Change Driver | `GET /operator_drivers/assign_preview`, then `PATCH /operator_drivers/:id/assign_vehicle` | [fleet § 1.5](fleet.md#15-operator-vehicles-change-driver--operator-drivers-assign-bus) |
| Operator Drivers: tabs, Invite Operator Driver, row buttons, View Details | Same as Drivers on `/operator_drivers` | [fleet § 2](fleet.md#2-drivers-and-operator-drivers) |
| Operator Drivers: Assign Bus / Swap Bus | Same as Change Driver | [fleet § 1.5](fleet.md#15-operator-vehicles-change-driver--operator-drivers-assign-bus) |
| Connected Operators | Coming Soon, no API | [fleet § 10](fleet.md#10-not-built-yet) |

---

## Clients

Rail icon `corporate_fare`. The trip form also uses `/clients` (Client picker, Add New Client, Add New Customer): [Trip form](#trip-form).

| Screen / element | API | Doc |
| --- | --- | --- |
| Managed Clients list, search | `GET /clients` | [clients § 1.1](clients.md#11-list-get-clients) |
| Add Managed Client / Edit Details (school, school calendar) | `POST /clients` / `PATCH /clients/:id` | [clients § 1.2](clients.md#12-add--edit-details) |
| Client record page, On-Time Allowance | `GET /clients/:id`, `PATCH /clients/:id` | [clients § 1.3](clients.md#13-record-page-get-clientsid) |
| Delete Client | `DELETE /clients/:id` | [clients § 1.4](clients.md#14-delete-client-delete-clientsid) |
| Sites: Add Site, Edit Site (school, own billing, Send Invoices To), remove | `/clients/:client_id/sites` | [clients § 2.1](clients.md#21-sites) |
| Their Customers | `/clients/:client_id/end_customers` | [clients § 2.2](clients.md#22-their-customers-main-contractor) |
| Bookable Vehicles | `PUT /clients/:id/bookable_vehicle_types` | [clients § 2.3](clients.md#23-bookable-vehicles-put-clientsidbookable_vehicle_types) |
| Saved Pick-up Points | `/clients/:client_id/pickup_points` | [clients § 2.4](clients.md#24-saved-pick-up-points) |
| Client Users: Add User, Edit, Remove | `/clients/:client_id/users` | [clients § 3](clients.md#3-client-users) |
| Role Permissions window, role select | `GET /client_users/roles` | [clients § 4](clients.md#4-values-reference) |
| Connected Clients | Coming Soon, no API | [clients § 7](clients.md#7-not-built-yet) |
| Lists other forms pick from (vehicle types, teams, operators, drivers, attendants...) | See the doc | [scheduler § 15](scheduler.md#15-lists-the-forms-pick-from) |

---

## Convoy Admin

Convoy staff only (rail items Discover, Company Leads, Transport Companies; Message Terms in the menu).

| Screen / element | API | Doc |
| --- | --- | --- |
| Transport Companies: list, New Company, External Vehicles limit, add-ons | `/companies` | [convoy-admin § 1](convoy-admin.md#1-transport-companies) |
| Transport Companies: Open | `PATCH /session { company_id }` | [convoy-admin § 1](convoy-admin.md#1-transport-companies) |
| Message Terms | `/message_terms` | [convoy-admin § 2](convoy-admin.md#2-message-terms) |
| Discover: advertisers, placements, KPIs, pause / resume / end / duplicate | `/discover/advertisers`, `/discover/placements` | [convoy-admin § 3](convoy-admin.md#3-discover) |
| Company Leads | `/leads` | [convoy-admin § 4](convoy-admin.md#4-company-leads) |
| Vehicle type requests (Add Type / Decline), country change requests | `/vehicle_type_requests`, `/country_requests` | [fleet § 5.2](fleet.md#52-request-a-new-type), [settings § 3.3](settings.md#33-request-a-country-change) |

---

## Dashboard

Rail icon `dashboard` (Company Dashboard).

| Screen / element | API | Doc |
| --- | --- | --- |
| Widget tray, sections | `GET /dashboard/widgets` | [dashboard § 1](dashboard.md#1-widgets-and-layout) |
| Pages, drag / resize / add / remove widgets, Save, Reset | `GET` / `PUT` / `DELETE /dashboard/layout` | [dashboard § 1](dashboard.md#1-widgets-and-layout) |
| Period select, every widget's figures (Open Ops Control Alerts is live) | `GET /dashboard?period=` | [dashboard § 2](dashboard.md#2-figures) |
| How It Works, ⓘ explainers, charts | FE only | — |

---

## Reports

Rail icon `insert_chart`. Needs `vehicles`, `finance` or `finview`.

| Screen / element | API | Doc |
| --- | --- | --- |
| Client, Shuttle Route, Period selects | `GET /reports/shuttle/options` | [reports § 1](reports.md#1-filters) |
| KPIs, Utilisation by Shuttle Timing, Stop Activity, Monthly Trend, chart | `GET /reports/shuttle?trip_id=&period=` | [reports § 2](reports.md#2-the-report) |
| Riders per Timing per Day, On Time Report (Month select) | `GET /reports/shuttle/grid?trip_id=&month=` | [reports § 3](reports.md#3-month-grids) |
| On-time allowance −1 / +1 min | `PATCH /clients/:id { client: { on_time_allowance } }` | [reports § 2](reports.md#2-the-report) |
| Click a count / time → stop record, Amend Record | `GET /trip_history/:id`, `POST /trip_history/:id/correction` | [reports § 4](reports.md#4-stop-record-and-amend-record) |
| Export CSV / Export PDF, How It Works | FE only | — |

---

## Finance

Rail icon `account_balance`. Needs `finance` or `finview`; Finance Settings `finset`; Vehicle Financials `vehfin`.

| Screen / element | API | Doc |
| --- | --- | --- |
| Client Invoices: KPIs, Aging | `GET /finance/invoices/summary` | [finance § 3](finance.md#3-client-invoices-payments-credit-notes-reports) |
| Client Invoices: Ready to Invoice, Create Draft | `GET /finance/invoices/ready`, `POST /finance/invoices` | [finance § 2](finance.md#2-client-invoices) |
| Client Invoices: Ad Hoc Trips, Invoice Now | `GET /finance/invoices/ad_hoc`, `POST /finance/invoices { trip_id }` | [finance § 2](finance.md#2-client-invoices) |
| Client Invoices: tabs, invoice dialog, Save Draft / Issue / Void / Delete | `/finance/invoices` | [finance § 2.2](finance.md#22-the-invoice) |
| Client Invoices: Record Payment, Credit Note, Email | `POST /finance/invoices/:id/payments`, `/credit_note`, `/send` | [finance § 3](finance.md#3-client-invoices-payments-credit-notes-reports) |
| Client Invoices: Clients card, Statement, Billing Details | `GET /finance/invoices/clients`, `/statement`, `/finance/billing/:client_id` | [finance § 3](finance.md#3-client-invoices-payments-credit-notes-reports) |
| Client Invoices: Invoice Settings | Finance Settings > Payment Details, Document Numbers | [finance § 1](finance.md#1-finance-settings) |
| Documents | `GET /finance/documents`, `/finance/documents/brand`, `/finance/documents/payment_notices/:id` | [finance § 5](finance.md#5-documents) |
| Operator Payments: requests, costs, items, approve, ad hoc | `/finance/operator_pay/...` | [finance § 4.1](finance.md#41-requests) |
| Operator Payments: batches, pay date, cancel, pay, bank file | `/finance/operator_pay/batches/...` | [finance § 4.2](finance.md#42-batches) |
| Vehicle Financials: list, vehicle, edit form, schedule, instalments | `/finance/vehicles`, `/finance/vehicles/:vehicle_id` | [finance § 6](finance.md#6-vehicle-financials-purchase-and-loan) |
| Vehicle Financials: P&L, charts, break-even, cost per km, spikes, due, manual entries | `/finance/vehicles/pl`, `/finance/vehicles/:vehicle_id/pl`, … | [finance § 7](finance.md#7-vehicle-financials-profit-and-loss) |
| Finance Settings | `/finance/settings` | [finance § 1](finance.md#1-finance-settings) |
| School Bus Collections | `GET /finance/school_collections` | [school-bus-finance § 6](school-bus-finance.md#6-company-finance-pages) |

---

## HR

Rail icon `badge`. Needs the `finance` or `finview` permission.

| Screen / element | API | Doc |
| --- | --- | --- |
| Drivers: list, search, Pay Scheme Today | `GET /pay/drivers` | [hr § 3](hr.md#3-drivers) |
| Drivers: Assign Scheme / Vehicle Type, dates, remove | `/pay/drivers/:id/schemes`, `/pay/drivers/:id/vehicle_types` | [hr § 3](hr.md#3-drivers) |
| Earnings: month, list, totals | `GET /pay/earnings?month=` | [hr § 5](hr.md#5-earnings) |
| Earnings: a driver (runs, breakdown, chart, bonuses) | `GET /pay/earnings/:driver_id?month=` | [hr § 5](hr.md#5-earnings) |
| Earnings: Raise an Issue / Clear Issue | `POST` / `DELETE /occurrences/:id/issue` | [hr § 5](hr.md#5-earnings) |
| Earnings: Confirm Month / Reopen Month | `POST` / `DELETE /pay/earnings/:driver_id/confirm` | [hr § 5](hr.md#5-earnings) |
| Earnings: Export Statement | FE only (print from the driver's month) | [hr § 5](hr.md#5-earnings) |
| Pay Schemes: list, editor, Save / Save and Lock, Lock / Unlock, Delete | `/pay/schemes` | [hr § 2](hr.md#2-pay-schemes) |
| Rate Plans: list, editor, Save / Save and Lock, Lock / Unlock, Delete | `/pay/rate_plans` | [hr § 1](hr.md#1-rate-plans) |
| Rate Plans: Coverage | `GET /pay/rate_plans/:id/coverage` | [hr § 1.2](hr.md#12-coverage) |
| Bonuses: list, editor, period options, Lock / Unlock, Delete | `/pay/bonuses`, `GET /pay/bonuses/periods` | [hr § 6](hr.md#6-bonuses) |
| Points: drivers, balance, history, Award / Deduct | `/pay/points`, `/pay/points/:driver_id` | [hr § 7.1](hr.md#71-points) |
| Rewards: list, editor, photo, Delete | `/pay/rewards` | [hr § 7.2](hr.md#72-rewards) |
| Salary Simulator: month, Fill Sample Month, Templates | `POST /pay/simulate`, `GET /pay/simulate/sample`, `/pay/simulator_templates` | [hr § 4](hr.md#4-salary-simulator) |
| Audit Log | `GET /pay/audit_log` | [hr § 8](hr.md#8-audit-log) |
| How It Works, ⓘ explainers | FE only | — |

---

## Settings

Rail footer icon `settings`.

### Company Settings

| Screen / element | API | Doc |
| --- | --- | --- |
| Open the page, View only banner (`can_edit`) | `GET /companies/:id` (id from `GET /session`) | [settings § 3.1](settings.md#31-open-and-save) |
| Save Changes (logo, Short Name, Theme Colour, Timezone, Date / Time Format, Business Units) | `PATCH /companies/:id` | [settings § 3.1](settings.md#31-open-and-save) |
| Country cards | `GET /countries`; pick once: `PATCH /companies/:id { company: { country } }` | [settings § 3.2](settings.md#32-countries-get-countries) |
| Request a Change, Withdraw | `POST /country_requests`, `POST /country_requests/:id/withdraw` | [settings § 3.3](settings.md#33-request-a-country-change) |
| Convoy Admin: Approve / Decline | `POST /country_requests/:id/approve` / `decline` | [settings § 3.3](settings.md#33-request-a-country-change) |

### Users

| Screen / element | API | Doc |
| --- | --- | --- |
| The list, Show Permissions | `GET /users` | [settings § 1.2](settings.md#12-list-get-users) |
| View Role Permissions, Start From a Role | `GET /users/roles` | [settings § 1.1](settings.md#11-roles-and-permissions-get-usersroles) |
| Add User / Edit (Save User) | `POST /users` / `PATCH /users/:id` | [settings § 1.3](settings.md#13-add-user--edit) |
| Suspend / Turn back on / Delete | `POST /users/:id/suspend` / `activate`, `DELETE /users/:id` | [settings § 1.4](settings.md#14-row-buttons) |

### Calendars

| Screen / element | API | Doc |
| --- | --- | --- |
| Tabs, Add Calendar, rename, delete, Observed Holidays, Regular Sessions | `/calendars` | [settings § 4.1](settings.md#41-tabs-get-calendars) |
| Public Holidays tab: year list, Add a Holiday, Add MOM Dates, remove | `/public_holidays` | [settings § 4.2](settings.md#42-public-holidays-tab-get-public_holidaysyear2026) |
| A calendar's days, Add a Day, remove | `GET /calendars/:id?year=`, `/calendars/:calendar_id/days` | [settings § 4.3](settings.md#43-a-calendars-days-get-calendarsidyear2026), [Change a Day](#change-a-day-calendars) |
| Trips Using This Calendar | `GET /calendars/:id/trips?year=` | [settings § 4.4](settings.md#44-trips-using-this-calendar-get-calendarsidtripsyear2026) |

---

## Shared dialogs

### Trip form

| Screen / element | API | Doc |
| --- | --- | --- |
| Open: New Trip / Edit | New: empty form on the FE (prefilled from the empty slot or Fill from Message) / Edit: `GET /trips/:id` | [scheduler § 7.1](scheduler.md#71-open) |
| Save / Save changes / Delete | `POST /trips` / `PATCH /trips/:id` / `DELETE /trips/:id` | [scheduler § 7.2](scheduler.md#72-save) |
| Every field, stops, vehicles, timings | In the save body | [scheduler § 7.3](scheduler.md#73-trip-fields-trip), [§ 7.4](scheduler.md#74-nested-lists-send-the-whole-list-existing-rows-with-id-_destroy-true-to-remove) |
| Attachments | `POST /trips/:trip_id/attachments` / `DELETE /trips/:trip_id/attachments/:id` | [scheduler § 7.5](scheduler.md#75-attachments) |
| Prices: Revenue by Vehicle / Price From Rate Card | `GET /trips/:id/prices?date=` / `POST /rate_cards/quote` | [scheduler § 7.6](scheduler.md#76-prices) |
| Client picker, Add New Client | `/clients` | [scheduler § 7.7](scheduler.md#77-client-picker-and-add-new-client) |
| Fill from Message | `POST /document_reads` `kind: trip_message` | [scheduler § 7.8](scheduler.md#78-fill-from-message) |
| School Run: Import Route List, review, Save Pick-up Point, Earlier Lists, Next 12 Months | `POST /route_lists/review`, `POST /trips/:trip_id/route_list`, `/pickup_points`, `GET /trips/:trip_id/route_list_versions`, `GET /trips/:trip_id/school_run_bill` | [scheduler § 7.9](scheduler.md#79-school-run-import-route-list) |

### Replace dialog and Replacements list

| Screen / element | API | Doc |
| --- | --- | --- |
| Preview while filling in | `GET /replacements/preview?...` | [scheduler § 9.1](scheduler.md#91-preview-while-the-dialog-is-filled-in) |
| Save | `POST /replacements` / `PATCH /replacements/:id` | [scheduler § 9.2](scheduler.md#92-save) |
| Replacements list (toolbar), remove | `GET /replacements?from=&vehicle_id=&scope=`, `DELETE /replacements/:id` | [scheduler § 9.3](scheduler.md#93-replacements-list-toolbar-and-remove) |

### Change a Day (calendars)

| Screen / element | API | Doc |
| --- | --- | --- |
| Calendars, a calendar's days | `GET /calendars`, `GET /calendars/:id` | [scheduler § 10](scheduler.md#10-change-a-day-calendars) |
| Change a Day / Add a Day / edit / remove | `POST /calendars/:calendar_id/days`, `PATCH` / `DELETE .../days/:id` | [scheduler § 10](scheduler.md#10-change-a-day-calendars) |
| New / edit / delete calendar | `POST /calendars`, `PATCH` / `DELETE /calendars/:id` | [scheduler § 10](scheduler.md#10-change-a-day-calendars) |
| Public holidays, Add MOM Dates | `/public_holidays`, `POST /public_holidays/import` | [scheduler § 10](scheduler.md#10-change-a-day-calendars) |

### Maintenance dialog and Workshops

| Screen / element | API | Doc |
| --- | --- | --- |
| New visit (defaults) | `GET /maintenance_visits/new?vehicle_id=&date=&start_time=` | [scheduler § 11](scheduler.md#11-maintenance-dialog-and-workshops) |
| Open a visit (purple block) | `GET /maintenance_visits/:id` | [scheduler § 11](scheduler.md#11-maintenance-dialog-and-workshops) |
| Plan the Visit / Record the Work / Cancel visit | `POST /maintenance_visits` or `PATCH /maintenance_visits/:id` / `PATCH /maintenance_visits/:id` (`status: completed`) / `PATCH /maintenance_visits/:id/cancel` | [scheduler § 11](scheduler.md#11-maintenance-dialog-and-workshops) |
| Delete ("Delete this maintenance record?") | `DELETE /maintenance_visits/:id` | [scheduler § 11](scheduler.md#11-maintenance-dialog-and-workshops) |
| Read the invoice | `POST /document_reads` `kind: maintenance_invoice` | [scheduler § 11](scheduler.md#11-maintenance-dialog-and-workshops) |
| Workshops window | `GET` / `POST /workshops`, `PATCH` / `DELETE /workshops/:id` | [scheduler § 11](scheduler.md#11-maintenance-dialog-and-workshops) |

### Notice form

| Screen / element | API | Doc |
| --- | --- | --- |
| Templates | `GET /notice_templates` | [scheduler § 12](scheduler.md#12-notice-form) |
| Send / Edit (scheduled) | `POST /notices` / `PATCH /notices/:id` | [scheduler § 12](scheduler.md#12-notice-form) |
| School Routes: school picker / route chips | `GET /schools` / `GET /schools/:id/routes?date=` | [scheduler § 12](scheduler.md#12-notice-form) |

### New External Vehicle

| Screen / element | API | Doc |
| --- | --- | --- |
| Save (from the Scheduler or External Vehicles) | `POST /vehicles/external` | [scheduler § 13](scheduler.md#13-new-external-vehicle) |

### Edit Vehicle

| Screen / element | API | Doc |
| --- | --- | --- |
| Open / Save / Add / Remove | `GET` / `PATCH /vehicles/:id`, `POST /vehicles`, `DELETE /vehicles/:id` | [scheduler § 14.1](scheduler.md#141-vehicle) |
| Default Driver: history / change from a date / remove an upcoming change | `GET` / `POST /vehicles/:vehicle_id/driver_schedules`, `DELETE .../driver_schedules/:id` | [scheduler § 14.2](scheduler.md#142-default-driver-own-buses) |
| Log Card: list / upload / pick the plate / delete | `/vehicles/:vehicle_id/log_cards`, `PATCH .../log_cards/:id/resolve_plate` | [scheduler § 14.3](scheduler.md#143-log-card) |
| Insurance: policies / files / Renew Policy | `/vehicles/:vehicle_id/insurance_policies`, `/insurance_documents`, `POST .../insurance_policies/renew` | [scheduler § 14.4](scheduler.md#144-insurance) |

---

## Public pages (no sign-in)

| Screen / element | API | Doc |
| --- | --- | --- |
| Trip Tracking page (link shared from the drawer) | `GET /public/tracking/:token` | [scheduler § 16](scheduler.md#16-public-trip-tracking-page) |
| External Vehicle Share Form: open / send | `GET` / `POST /public/share_forms/:token` | [fleet § 4.4](fleet.md#44-the-public-share-form-page-no-sign-in) |
| Client Portal sign-in (email, password, one-time code, set password, account picker, sign out) | `/portal/session`, `/portal/password` (own Portal token) | [clients § 5](clients.md#5-client-portal-sign-in) |

---

## School Bus: Schools & Year Setup

Rail icon `school`. Read: any company user (their schools). Changes: see [school-bus-setup](school-bus-setup.md).

| Screen / element | API | Doc |
| --- | --- | --- |
| Schools list, New School | `GET /schools`, `POST /schools` | [§ 1](school-bus-setup.md#1-schools) |
| School record header, Route Labels tab | `GET /schools/:id`, `PUT /schools/:id/route_labels` | [§ 1.3](school-bus-setup.md#13-school-record-and-route-labels) |
| Rider Data tab: lists, check file, Import, Delete | `/schools/:id/rider_datasets` (+ `/preview`) | [§ 2.1](school-bus-setup.md#21-rider-data-tab) |
| Riders tab: chips, search, paging, Add Rider, Export CSV | `/schools/:id/riders` (+ `/export`) | [§ 2.2](school-bus-setup.md#22-riders-tab) |
| Year selector, New Academic Year, Terms & Semesters, Save Calendar, Unlock, Delete Year | `/schools/:id/academic_years`, `/academic_years/:id` (+ `/calendar`, `/unlock`) | [§ 3](school-bus-setup.md#3-terms--semesters-academic-years) |
| Holidays & Special Days, Import Public Holidays | `PUT /academic_years/:id/holidays`, `GET /academic_years/:id/public_holidays` | [§ 4](school-bus-setup.md#4-holidays--special-days) |
| School Levels | `/schools/:id/levels`, `POST /schools/:id/unlock` | [§ 5](school-bus-setup.md#5-school-levels) |
| Bus Sessions, Copy AY X Sessions | `/academic_years/:id/sessions` (+ `/copy`) | [§ 6](school-bus-setup.md#6-bus-sessions) |
| Bus Attendants | `/schools/:id/bus_attendants` | [§ 7](school-bus-setup.md#7-bus-attendants) |
| Setup strip, Summary | `GET /academic_years/:id/setup` | [§ 8](school-bus-setup.md#8-setup-strip-and-summary) |
| Bus Fares: wizard, Save & Lock, Copy AY X Fares, fare table | `/academic_years/:id/fares` (+ `/copy`) | [money § 1–2](school-bus-money.md#1-bus-fares) |
| Extra Charges: list, add / edit / delete, Set End, preview | `/academic_years/:id/extra_charges` (+ `/preview`, `/:id/end`) | [money § 3](school-bus-money.md#3-extra-charges) |
| Payment & Refund Policy: versions, New Version, Publish | `/schools/:id/policy` | [money § 4](school-bus-money.md#4-payment--refund-policy) |
| Payment Methods | `/schools/:id/payment_methods` | [money § 5](school-bus-money.md#5-payment-methods) |
| Operator Pay, Break Month Calculator, BA prices | `/schools/:id/operator_pay` (+ `/calculator`) | [money § 6](school-bus-money.md#6-operator-pay) |
| Stop Library: list, search, stop detail, add / edit (confirm for shared stops), archive, Nearby | `/stops` (+ `/nearby`) | [stops § 1](school-bus-stops.md#1-stops-stop-library) |
| Stop Library: Requests tab, Add to the Stop Library, Approve / Keep for School | `/stops/requests`, `/stops/:id/library`, `/stops/:id/review` | [stops § 2](school-bus-stops.md#2-library-membership-and-requests) |
| Stop Assignment: School Stops / Needs Attention, catchment (postal codes, areas, points off), Browse Library, Import, Unlink | `/schools/:id/stops` (+ `/import`) | [stops § 3](school-bus-stops.md#3-a-schools-stops-and-catchments) |
| Stop Assignment: riders, candidates, Select Riders / Select Links | `/schools/:id/stop_assignment`, `/schools/:id/rider_links` (+ `/remove`) | [stops § 4](school-bus-stops.md#4-stop-assignment) |
| PUDO photo, photo requests, Accept / Reject, auto requests | `/stops/:id/points/:point_id/photo`, `/stop_photo_requests` | [stops § 5](school-bus-stops.md#5-photos-and-photo-requests) |
| Route Plans: Parameters, Priority, Run Routing, run progress | `/routing/settings`, `POST /schools/:id/routing_runs`, `GET /routing_runs/:id` | [routes § 1–2](school-bus-routes.md#1-parameters) |
| Route Plans: plan list and badges, plan detail (KPIs, unassigned, students, routes), Draw Routes, rename, comments, Compare, delete | `/schools/:id/plans`, `/plans/:id` (+ `/comments`, `/compare`) | [routes § 3](school-bus-routes.md#3-plans) |
| Route drawer and map tools: stops / riders, New Route, bus type, lock / hide, attendant, delete, Reset, Route Again | `/routes/:id` (+ `/stops`, `/reset`), `/plans/:plan_id/routes`, `/plans/:plan_id/route_again` | [routes § 4](school-bus-routes.md#4-hand-edits-and-route-again) |
| Adopt Plan, cancel scheduled; Stop Assignment: assigned PUDO, Set as assigned, Move All Riders Here, Notify | `/plans/:id/adopt`, `/plans/:id/cancel_adoption`, `/schools/:id/rider_assignments` (+ `/move`, `/notify`) | [routes § 5](school-bus-routes.md#5-adopt-plan-and-rider-assignments) |
| Route vehicle history, operator price, Route Charges | `/routes/:id/vehicle`, `/routes/:id/prices`, `/routes/:id/charges`, `/schools/:id/route_charges`, `/route_charges/:id` | [routes § 6](school-bus-routes.md#6-route-bus-and-money) |
| Feasibility Studies | `/feasibility_studies`, `/feasibility_scenarios/:id` | [routes § 7](school-bus-routes.md#7-feasibility-studies) |
| How It Works, Year / Week at a Glance, templates, unlock prompt | FE only | — |
| Families & Riders: list, search, add / rename / delete, guardians, link / unlink riders, Link Existing Rider, CSV import / export | `/schools/:id/families` (+ `/import`, `/export`), `/families/:id` (+ `/guardians`, `/riders`, `/candidates`) | [parents § 1](school-bus-parents.md#1-families--riders) |
| Bus Service Registration (Year Setup): schedule, who can apply, auto-accept, fees, form, 12 messages, Schedule / Unschedule, Release Now | `/academic_years/:id/registration` (+ `/schedule`, `/unschedule`, `/release`) | [parents § 2](school-bus-parents.md#2-bus-service-registration) |
| Bus Service Requests: year cards, windows, tiles, tabs, filters, list, drawer, Add Application, Acknowledge, Move Answer Date, Waitlist / Decline, Message | `/schools/:id/bus_requests` (+ `/decide`, `/message`), `/bus_requests/:id` (+ `/open`, `/acknowledge`, `/move_answer`) | [parents § 3–4](school-bus-parents.md#3-bus-service-requests-list-and-detail) |
| Route Fit / service check, Accept and Send Quote, bulk Accept, auto-accept and cover banners, Re-offer, Record First Invoice Paid | `/bus_requests/:id/accept`, `/schools/:id/bus_requests/accept`, `/bus_requests/:id/reoffer`, `/bus_requests/:id/record_payment` | [parents § 4](school-bus-parents.md#4-new-service-review-accept-first-invoice) |
| Change of Address / Service / Stop Service tabs, Not Agreed, End Rider | `/bus_requests/:id/confirm_change`, `/confirm_stop`, `/not_agreed`, `/end_rider` | [parents § 5](school-bus-parents.md#5-change-of-address-change-of-service-stop-service) |
| Bus requests bell, strip (Ops Control, School Live Ops), 08:00 email preview | `GET /bus_requests/alerts`, `GET /bus_requests/digest` | [parents § 6](school-bus-parents.md#6-alerts-and-the-0800-email) |
| CCA Rides: settings, week, Bus Not Running, No School credit | `/schools/:id/cca_rides` (+ `/not_running`) | [parents § 7](school-bus-parents.md#7-cca-rides) |
| Collections › Family Bills: period, draft / Draft Again, issue, settings | `/schools/:id/bill_runs` (+ `/issue`), `PATCH /school_bills/settings` | [finance § 1](school-bus-finance.md#1-family-bills-draft-and-issue) |
| Collections: KPIs, filters, list, CSV, Mark Paid, billing differences | `/schools/:id/bills` (+ `/export`, `/pay`, `/differences`) | [finance § 2](school-bus-finance.md#2-collections) |
| Collections: open a bill, Record Payment, Waive Late Fee, Credit / Debit Note, print | `/school_bills/:id` (+ `/payments`, `/waive_late`, `/notes`) | [finance § 3](school-bus-finance.md#3-one-bill-payments-notes-late-fees) |
| Documents: list, filters, print, Void receipt, Statement of Account | `/schools/:id/documents`, `/school_documents/:id` (+ `/void`), `/schools/:id/statement` | [finance § 4](school-bus-finance.md#4-documents-and-statements) |
| Operator Payments (school): month, routes, lines + files, invoice no., Send / Recall / Send Back / Approve / Reopen, Pay, voucher | `/schools/:id/payouts` (+ `/:operator_id/...`), `/school_payouts/:id/voucher` | [finance § 5](school-bus-finance.md#5-operator-payments-pay-runs) |
| School Dashboard › Operations: today, sessions, Needs Attention, coming up, next 90 days, students (distance bins, levels) | `GET /schools/:id/dashboard` | [live § 3](school-bus-live.md#3-dashboard--operations) |
| School Dashboard › Finance: month KPIs, Expected / Billed / Collected, overdue, year chart, money ahead, Needs Attention | `GET /schools/:id/dashboard/finance` | [live § 4](school-bus-live.md#4-dashboard--finance) |
| Live Ops: session picker, KPIs, Needs Attention, filters, route list, overview map | `GET /schools/:id/live` | [live § 1](school-bus-live.md#1-live-ops-the-session) |
| Live Ops route: banner, KPIs, boarding methods, crew, log, stops and children, route map | `GET /schools/:id/live/runs/:id`, `GET /live_map/runs/:id/track` | [live § 2](school-bus-live.md#2-live-ops-one-run) |
| Live Ops weather, traffic, incidents | **No API yet** (hide) | [live § 5](school-bus-live.md#5-not-built-yet) |

---

## Ops Control

Rail icon `desktop_windows`. Needs `vehicles` or `plans`. Poll the board every 10–15 s.

| Screen / element | API | Doc |
| --- | --- | --- |
| KPI tiles, action banner, tabs with counts, client select, search, sort, trip table (status, Driver App, GPS, ETA, timeline, issue) | `GET /ops_control?tab=&client_id=&q=&sort=` | [ops-control § 1](ops-control.md#1-the-board) |
| Rules card | `meta.rules` (static text) | [ops-control § 2](ops-control.md#2-rules) |
| Acknowledge (row, banner) | `POST /ops_control/runs/:id/acknowledge` | [ops-control § 3](ops-control.md#3-acknowledge) |
| Call | `tel:` driver phone | FE only |
| Alert Log | `GET /ops_control/log` | [ops-control § 4](ops-control.md#4-alert-log) |
| Alarm Sound, Full Screen, How It Works, ⓘ | FE only | — |
| Requests banner (School Bus) | **No API yet** | — |

---

## Live Map

Rail icon `map`. Needs `vehicles` or `plans`. Poll the board every 10–15 s.

| Screen / element | API | Doc |
| --- | --- | --- |
| Fleet panel: On Trip / Available / Offline counts, search, group by team, rows; bus markers | `GET /live_map?q=&state=&team_id=` | [live-map § 1](live-map.md#1-the-board) |
| Click a bus: Vehicle and Device window, trip drawer (points, On Board, ETA Last, stops, students) | `GET /live_map/vehicles/:id` | [live-map § 2](live-map.md#2-one-bus) |
| Trace switch (live) | `GET /live_map/runs/:id/track?since=` | [live-map § 3](live-map.md#3-trace-and-replay) |
| Replay: date, bus, run, play | `GET /live_map/vehicles/:id/runs?date=`, `GET /live_map/runs/:id/track` | [live-map § 3](live-map.md#3-trace-and-replay) |
| Themes, Plates / Drivers / Routes, Fit, panel, replay speed | FE only | — |
| Rain, Traffic, Road, location Check | **No API yet** (hide) | [live-map § 4](live-map.md#4-front-end-only) |

---

## Not built yet

These rail menus of Convoy OS have **no API yet**: Clients > Connected Clients.
Smaller gaps inside built menus are listed in [trips § 6](trips.md#6-not-built-yet) and
[fleet § 10](fleet.md#10-not-built-yet), [settings § 5](settings.md#5-not-built-yet), [clients § 7](clients.md#7-not-built-yet), [hr § 10](hr.md#10-not-built-yet) and [finance § 8](finance.md#8-not-built-yet).
