# Phase 2 — Profile (02/11/2026)

- `GET / PATCH /profile` (`ProfilesController`, `UserPolicy#profile?` = chính mình, Convoy Admin cũng sửa được profile của mình).
  Nhận `display_name` (squish, trống = nil, ≤ 60), `mobile` (phonelib, lưu E.164, `possible`), `avatar` / `remove_avatar` (CarrierWave `ImageUploader`).
  `name`, `email` không nhận ở đây.
- `UserBlueprint` mặc định (session cũng dùng) thêm `display_name`, `shown_name`, `mobile_display`, `role_label`; `initials` lấy từ `shown_name`.
- Seed: dispatch@ có display name + mobile. Spec `settings_profile_spec.rb` (2).
