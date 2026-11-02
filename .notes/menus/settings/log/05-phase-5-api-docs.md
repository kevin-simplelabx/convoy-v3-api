# Phase 5 — Docs & kiểm tra (02/11/2026)

- `.api-documents/settings.md` (Users, Profile, Company Settings, Calendars, Not built yet); `scheduler.md` § 10 thêm quyền + link;
  `README.md` (bảng menu, ví dụ session có `display_name`, `shown_name`, `role_label`, `mobile_display`);
  `integration.md` (file list, page id `coset`, `users`, `phol`, Profile); `screen-map.md` (mục Settings, Profile trong app shell,
  bỏ "Clients and Settings (pickers only)" → "Clients (pickers only)").
- OpenAPI: `settings.md` vào `MENUS`; folder Settings = users, profiles, companies, countries, country_requests, calendars,
  calendar_days, public_holidays (companies chuyển từ Common). Heading có 2 endpoint làm summary hỏng → đổi heading 1.3, 3.1.
  `bin/rails api_docs:all`: 253 operations / 58 resources.
- Kiểm tra: 240 specs, rubocop sạch, seed ×2, `occurrences:verify`.
