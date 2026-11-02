# Calendars & Public Holidays — hiện trạng

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| public_holidays | company, unique date, `observed`; preset MOM 2026–2027 (`config/presets/public_holidays.yml`), `POST import { year }` |
| calendars | school / general, observed_holidays off / work, morning_time / afternoon_time, discard; xoá bị chặn khi trip dùng |
| calendar_days | school: hol, ns, early, late (usual_time / new_time); general: off, shift (± phút), oil (in_place_of), work; range ngày |
| companies.observed_holidays | cho trip không có calendar |

## Quy tắc
- `Calendars::Context` (port `logic/calendars.js`), load trọn tháng: skips_public_holiday?, day_off, no_school?, time_shift, runs_on?, trip_dates, nth_run_date.
- Changed Times áp mọi trip; Early Dismissal chiều; Late Arrival sáng; School Run theo `session`.
- Mọi thay đổi → `OccurrenceSyncJob` sau commit (xem trigger trong `occurrences.md`).
- Calendar mới: `start_from` moe | blank | id calendar khác.

## Settings > Calendars (02/11/2026)
- Quyền ghi calendars / days / public holidays: `vehicles` hoặc `finance` (`CalendarPolicy#write?`); đọc: mọi user company.
- Tên calendar: unique không phân biệt hoa thường (kept), không được "Public Holidays"; `kind` không đổi sau khi tạo.
- Thêm PH vào Chủ nhật → tự thêm thứ Hai observed ("<name> Holiday") nếu chưa có (`PublicHoliday#add_observed_monday!`, `meta.observed`).
- `GET /public_holidays?year` meta: count, weekdays, preset_available, preset_missing. `GET /calendars` có `trips_count`;
  `GET /calendars/:id?year` lọc days; `GET /calendars/:id/trips?year` = `Calendars::TripsUsing` (dùng `Context#trip_skips`).

## Seeds
`10_calendars`: PH 2026–27, MOE School Calendar, Google Office Calendar.
