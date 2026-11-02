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

## Seeds
`10_calendars`: PH 2026–27, MOE School Calendar, Google Office Calendar.
