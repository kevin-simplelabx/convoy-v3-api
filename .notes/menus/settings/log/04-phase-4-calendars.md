# Phase 4 — Calendars page (02/11/2026)

- Đã có từ Scheduler: CRUD calendars / days / public holidays, import MOM, `saturday`. Phase này chỉ bổ sung phần trang Settings.
- `GET /calendars` thêm `trips_count` (1 query group by); `GET /calendars/:id?year=` lọc days chạm năm (blueprint option `year`).
- `GET /calendars/:id/trips?year=` → `Calendars::TripsUsing` (trip recurring dùng calendar, `runs_skipped` + `skipped[]` từ `Context#trip_skips`),
  blueprint `CalendarTripBlueprint`. HTML chỉ có card này cho calendar riêng (không cho Public Holidays) → không làm cho PH.
- `GET /public_holidays?year=` thêm meta (count, weekdays, preset_available, preset_missing). `POST /public_holidays`: Chủ nhật →
  thêm thứ Hai observed (giống HTML), trả `meta.observed`. Thông báo trùng ngày: "is already a public holiday".
- Calendar: tên unique không phân biệt hoa thường, cấm "Public Holidays", không đổi `kind`.
- Quyền: `CalendarPolicy#write?` cần `vehicles` hoặc `finance` (HTML `holOk`); `CalendarDayPolicy`, `PublicHolidayPolicy` kế thừa.
  Spec cũ dùng member không quyền → thêm `vehicles` (calendars_spec, trips_spec).
- Seed: dùng seed `10_calendars` có sẵn (không thêm bảng). Spec calendars_spec thêm 3. Tổng 240 specs.
