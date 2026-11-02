# Phase 2 — Pay Schemes (02/11/2026)

- Bảng `pay_schemes` (cột theo inventory § 2.3, tên Rails: has_*, *_in_guarantee, on_top_ph / sat / sun, shift phút, shift_working_days
  string[], check constraint type; partial unique 1 default / company, name unique kept), `pay_scheme_route_bands` (up_to_minutes null = mở),
  `pay_scheme_volume_tiers`, `pay_scheme_target_tiers` (period weekly / monthly).
- `PaySchemes::Save`: field + list nào gửi thì thay list đó; default duy nhất; không còn default → scheme này. Lock / unlock / xoá (≥ 1, không xoá default).
- Rate plan: xoá chặn khi scheme dùng (`used_by` thật). Message lỗi field theo dạng chuẩn Rails ("Rate plan must be picked").
- Seed: Basic + Trips (default, locked, như HTML) + Monthly 2,400. Spec `hr_pay_schemes_spec.rb` (2).
