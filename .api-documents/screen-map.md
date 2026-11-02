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
- [Clients and Settings (pickers only)](#clients-and-settings-pickers-only)
- [Shared dialogs](#shared-dialogs)
- [Public pages (no sign-in)](#public-pages-no-sign-in)
- [Not built yet](#not-built-yet)

---

## Sign-in and app shell

| Screen / element | API | Doc |
| --- | --- | --- |
| Sign-in page: Sign In | `POST /session` → `data.token`, then `Authorization: Bearer <token>` on every call | [README](README.md#signing-in-bearer-token) |
| Page load: who am I, company name / logo / theme colour, date and time formats, rail items by permission | `GET /session` | [README](README.md#signing-in-bearer-token) |
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
| Raise an Issue / Clear Issue | `POST` / `DELETE /occurrences/:id/issue` | [scheduler § 5.2](scheduler.md#52-drawer-actions) |
| Change the pick-up time (Today Only / Every Run From Today / Undo) | `PATCH /occurrences/:id/time` | [scheduler § 5.2](scheduler.md#52-drawer-actions) |
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

## Clients and Settings (pickers only)

The Clients and Settings pages are not built yet, but the trip form and the Scheduler already use these APIs.

| Screen / element | API | Doc |
| --- | --- | --- |
| Client picker, Add New Client, Add New Customer (Service For) | `GET` / `POST /clients`, `GET /clients/:id`, `POST /clients/:client_id/end_customers` | [Trip form](#trip-form) |
| Client sites, saved pick-up points | `GET /clients/:client_id/sites`, `GET /clients/:client_id/pickup_points` | [scheduler § 15](scheduler.md#15-lists-the-forms-pick-from) |
| Settings > Calendars (used by Change a Day) | `/calendars`, `/calendars/:id/days`, `/public_holidays` | [Change a Day](#change-a-day-calendars) |
| Lists other forms pick from (vehicle types, teams, operators, drivers, attendants...) | See the doc | [scheduler § 15](scheduler.md#15-lists-the-forms-pick-from) |

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
| Read the invoice | `POST /document_reads` `kind: maintenance_invoice` | [scheduler § 11](scheduler.md#11-maintenance-dialog-and-workshops) |
| Workshops window | `GET` / `POST /workshops`, `PATCH` / `DELETE /workshops/:id` | [scheduler § 11](scheduler.md#11-maintenance-dialog-and-workshops) |

### Notice form

| Screen / element | API | Doc |
| --- | --- | --- |
| Templates | `GET /notice_templates` | [scheduler § 12](scheduler.md#12-notice-form) |
| Send / Edit (scheduled) | `POST /notices` / `PATCH /notices/:id` | [scheduler § 12](scheduler.md#12-notice-form) |

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

---

## Not built yet

These rail menus of Convoy OS have **no API yet**: Dashboard, Ops Control, Live Map, School Bus, Clients (the Managed
Clients and Connected Clients pages), Reports, Finance (including Vehicle Financials), HR, Settings (Company Settings,
Users, the Calendars page itself), and the Convoy Admin menus (Discover, Company Leads, Transport Companies).
Smaller gaps inside built menus are listed in [trips § 6](trips.md#6-not-built-yet) and
[fleet § 10](fleet.md#10-not-built-yet).
