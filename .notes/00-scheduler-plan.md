# Scheduler API — Plan

Nguồn: `Convoy Project/Convoy OS.dc.html` (template dòng ~777–3876) + `Convoy Project/logic/mixins/scheduler.js`, `trip-form.js`,
`logic/pricing.js`, `logic/calendars.js`, `logic/estimates.js`. Chỉ build Scheduler (rail icon `calendar_view_week`) và
những gì Scheduler dùng trực tiếp.

Stack: Rails 8.1 API, PG, Devise, Draper, Blueprinter, CarrierWave. Không lưu JSON blob khi dữ liệu cần query.

---

## 1. Tính năng Scheduler cần cover (inventory)

**Grid & điều hướng**
- View Day / Week; layout Timeline (hàng = xe), Lanes (cột = xe), Week, Table; zoom; date picker, Today.
- Lọc xe: Own / Managed / External; size (Sedan ≤4, MPV 5–7, Small Bus 8–15, Medium 16–30, Large 31+); tags + VIP; search plate/model/driver.
- Sort: Type (default), Smallest First, Largest First.
- Unassigned Trips tray (+ prev/next ngày có trip chưa gán).
- Link lines: runs move together (rg), replacement ghost → bản thay, outbound → return (pair).
- Empty slot menu (15') → New Trip / Maintenance / Inspection (soon).
- View Only / Editing lock (client-side, idle 10').
- Legend, How It Works (FE only).

**Trip (series template)** — 5 kind: Ad Hoc / Charter, Corporate Shuttle, Airport Transfer, Disposal, School Run.
- Client (Managed Client) + Site, Sub-contractor (main contractor, Service For end customer), contractor contact, Require MC App.
- Ngày, lặp (days of week, end never/date/count), Run on PH, Calendar, start/end, hours (Disposal), pax, luggage theo size.
- Route: points (pick-up/drop-off/both/waypoint), stop details (address, lat/lng, note, Street View, ≤3 photos, client site), via points.
- Two-Way (Ad Hoc): sinh 2 trip liên kết pair/ret, return route riêng.
- Shuttle: timetable Direction 1 / Return (runs × stops times), return stops riêng (rsep), tags, sites, color, rules (appr, seatRes, cnt).
- Airport: dir arr/dep, flight, flight time, terminal, wait, meet & greet + signboard + mgFee.
- Standby Area & Reporting time (location, pin, minutes, details + photos, runs bỏ qua).
- Vehicles required (type × count), vehicle slots (vid, giá từng xe), Vehicle for Each Run (rv), run groups (rg).
- Revenue: price, pPer route|veh, pSet same|each, pBasis trip|day|month, shuttle price table (pm), price2.
- Cost: Trip Value driver (tv, tv2, tvMode, tvPer, runTv, tvRound), operator cost (opc, opc2, oBasis, oEach, opcRun, oSplit, oCx), cost table.
- Requestor, guest, label, notes, attachments, Business Unit / Project.
- Trip ID (TID + running number, company sequence).
- School Run: session, stops & students, paid months, charge No School days, route list history, attendance.

**Occurrence (một lần chạy cụ thể = trip × date × run × vehicle slot)**
- Key cũ: `a|tripId|date|k`. Status: un, ok, live, done, cancel, cancelUn, replaced, repl.
- Override vehicle (drag-drop "This date only"), shift time (quick time change Today Only), cancel/restore, ended, issue (giữ pay driver).
- "From this date on": split series hoặc ghi assignment.
- Passenger list / attendance (Boarded, Alighted, Absent).
- Share tracking link (token, 7 ngày).

**Assign page (shuttle)**: slot run × vehicle → Operator / External / Own bus, pay per run|day|month, effective from (lịch sử).

**Replacements**: drv / veh / crew / hand; theo 1 occurrence hoặc date range trên xe gốc (Driver Away, Vehicle Down);
pay orig|new|both|split %, notify guests/parents (record only), opBy op|us.

**Liên quan hiển thị trên Scheduler**
- Vehicles (own/managed/external), vehicle types (platform), teams, tags, default driver schedule, drivers, operator drivers, operators.
- External vehicle quick add (+ company), Assign External Vehicle.
- Calendars + Public Holidays, Change a Day.
- Maintenance visits (block tím trên xe) + workshops.
- Notices (banner trong drawer, Send Notice).
- Clients, client sites, end customers (Service For), New Client từ trip form.
- Drop warnings: seats, clash, vehicle type.

---

## 2. Data model (PG tables)

Tenant = `companies`. Mọi bảng nghiệp vụ có `company_id` (acts_as_tenant).

| Domain | Tables |
| --- | --- |
| Org | companies, users (devise), company_sequences (trip_no, ...) |
| Calendar | public_holidays, calendars, calendar_days |
| Clients | clients, client_sites, client_end_customers |
| Fleet | vehicle_types (platform), company_vehicle_types (bật/tắt), vehicle_teams, vehicles, vehicle_tags (hoặc `tags` text[]), drivers, vehicle_driver_schedules, operators, operator_drivers |
| Trip template | trips, trip_stops (direction 1/2, position, use, waypoint), trip_stop_photos, trip_vias, trip_vehicle_requirements, trip_vehicle_slots, trip_runs, trip_run_stop_times, trip_run_slots (rv), trip_run_groups, trip_price_cells (kind price/cost, row, col), trip_standbys, trip_standby_photos, trip_standby_skips, trip_attachments |
| School Run | trip_stop_students, route_list_versions (+ stops/students của bản cũ) |
| Assignment | trip_assignments, trip_assignment_slots |
| Occurrence | trip_occurrences, occurrence_events (audit), occurrence_attendances, occurrence_issues, tracking_links |
| Replacement | replacements, replacement_notifications |
| Liên quan | maintenance_visits, workshops, notices, notice_targets |

Nguyên tắc:
- Giờ lưu `start_min`/`end_min` (integer phút từ 0h, có thể > 1440 cho trip qua đêm) + `date`; hiển thị `HH:MM` ở blueprint.
- Tiền: `decimal(12,2)`.
- Enum Rails (string-backed) cho kind, status, use, pay basis...
- Mọi file: CarrierWave uploader (mount_uploader / mount_uploaders), storage :file (dev) → fog/S3 sau.
- Vẫn có thể giữ `jsonb` cho dữ liệu chỉ là snapshot hiển thị (vd. tracking_link snapshot) — ghi rõ từng chỗ.

### Occurrence: materialize (đề xuất)
`trip_occurrences` unique (trip_id, date, trip_run_id, slot_no). Sinh bằng service `Occurrences::Generator`
cho horizon (vd. -400 ngày → +120 ngày), job hằng ngày đẩy horizon; sửa trip → regenerate occurrence tương lai chưa bị override.
Cột snapshot: vehicle_id, driver_id, start_min, end_min, shift_min, price, operator_cost, trip_value, status, override flags.
→ Query trực tiếp cho Scheduler, Earnings, Invoices, Reports, P&L.

---

## 3. Phases

### Phase 0 — Foundation
- Quyết định giữ/viết lại app hiện tại; gem setup (draper, blueprinter, carrierwave, acts_as_tenant, pundit, pagy, ransack, ...).
- Base controller, error handling (JSON), auth Devise, tenant scoping, Pundit policies, request specs setup.
- Seeds framework (`db/seeds/*.rb` theo domain, idempotent).

### Phase 1 — Reference data
- Calendars & Public Holidays (+ MOM 2026/2027 seed), Change a Day.
- Clients, sites, end customers.
- Vehicle types, teams, vehicles (photo carrierwave), drivers, default driver schedule, operators, operator drivers, external vehicle quick add.
- API filter/sort xe giống Scheduler (size band, tags, VIP, type).

### Phase 2 — Trip template (CRUD)
- trips + stops + photos + vias + vehicle requirements/slots + standby + attachments.
- Ad Hoc, Airport, Disposal, Two-Way (pair), validations như `schSaveTrip`.
- Trip number sequence, Trip ID.
- Form object / service `Trips::Upsert` (nested), decorator + blueprint.

### Phase 3 — Shuttle
- trip_runs, run stop times, return stops (rsep), run slots (rv), run groups (rg).
- Price / cost table (trip_price_cells), legacy fields, pricing service (port `logic/pricing.js`: schRunP, schOpRun, schMxAmt).

### Phase 4 — Occurrence engine
- Port `calendars.js` (ahDates, skipsPH, dayOff, shift) → `Calendars::Context`.
- `Occurrences::Generator`, horizon job, regenerate khi sửa trip.
- `GET /scheduler?from&to` (occurrences + vehicles + unassigned), status computation.
- Cancel/restore, ended, issue, quick time change (today only / every run from today → split series).

### Phase 5 — Scheduler actions
- Drag-drop: move / swap, this date / from this date on, drop warnings (seats, clash, type), drop pay prefill.
- Assign page: trip_assignments (effective from, slots, own/operator/external, pay).
- Unassigned tray navigation.

### Phase 6 — Replacements
- 4 kinds, per occurrence hoặc date range (Driver Away / Vehicle Down), ghost/handover split, pay rules, notify record.
- Áp vào occurrence (vehicle/driver hiệu lực) + lịch sử.

### Phase 7 — Related on Scheduler
- Maintenance visits & workshops (block trên xe).
- Notices (banner trong drawer, Send Notice).
- Tracking share link.
- Stop photos từ drawer.

### Phase 8 — School Run (nếu trong scope)
- Students per stop, attendance/passenger list, paid months, No School charge, route list history, 7-year purge job.

### Phase 9 — FE wiring
- Sửa `Convoy OS.dc.html` / mixins để gọi API REST thay `schCfg()/schSave()` (localStorage).

Mỗi phase: migration + model + policy + decorator + blueprint + controller + request spec + seed.

---

## 4. Open questions
Xem `01-decisions.md`.
