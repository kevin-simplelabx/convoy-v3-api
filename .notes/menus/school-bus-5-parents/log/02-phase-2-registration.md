# Phase 2 — Bus Service Registration (03/11/2026)

- `school_registrations` (1 / academic year): status draft / scheduled; windows renew_from..renew_to (renewals), general_from..general_to (mọi người),
  service_starts_on, confirm_hours 48, ack_days 3 / plan_weeks 3 (mid-year), levels[] (tên School Levels, rỗng = tất cả), sessions[] AM/PM/CCA,
  grad (on, message, link), auto-accept (renew + check address / session / debt, near km + cover, siblings + cover, run arrive / daily + run_at phút,
  seats_buffer, waitlist_auto), show_fare, extra_terms, asks[] (REGASK: cls sidn dob med photo emerg cca).
- `registration_messages` (12 dòng / registration, preset `config/presets/registration_messages.yml` = REGMSG): enabled, email / whatsapp / app,
  offset_days (giữ dấu của preset, chỉ đổi khi adjustable), offset_hours (crem), subject / body / whatsapp_body, scheduled (wel: Release Now nếu không),
  released_at (Phase 7). `sends_on` = anchor (eF / eT / gF / start) + offset, 09:00.
- Mặc định (regDef): ngày học đầu tiên S → renew S−122..S−79, general S−78..S+242, start S.
- `SchoolRegistrations::Save`: kiểm như HTML (8 thông báo + run_at khi daily); Schedule cần calendar / sessions / fares đã lock + policy đang dùng
  → 422 `not_ready` `details.missing`. Unschedule = draft. State: draft / upcoming / renewals_open / general_upcoming / open / closed.
- API: `GET/PUT /academic_years/:id/registration`, `POST …/schedule`, `POST …/unschedule`. Quyền: xem show?, sửa setup? (plans / schools).
- Seed `54_school_parents`: AY 2027 draft. Spec 2.
