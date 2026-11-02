# Phase 3 — Company Settings (02/11/2026)

- `CompanyPolicy#update?` = Convoy Admin hoặc company của mình + quyền `users` (trước: admin / owner). Company user không sửa `name`
  (Convoy đặt khi mở account); `country` chỉ khi chưa khoá. Thêm `remove_logo`.
- Migration: `companies.country_set_at`, `country_set_by_id` (FK validate riêng), backfill `country_set_at = created_at` (company cũ coi như đã chọn).
  `Company#country_locked?`; đổi country phải là nước `live` (`Country.live_codes`).
- `Country` = `Data.define` đọc `config/presets/countries.yml` (từ `logic/country.js`); `GET /countries`. `Company::COUNTRIES` = `Country.codes`.
- Bảng `company_country_requests` (from / to, reason, status pending / approved / declined / withdrawn, requested_by, decided_by,
  decided_at; partial unique 1 pending / company; check constraint). Không TenantScoped (Convoy Admin xem mọi company) — giống `vehicle_type_requests`.
  `CountryRequestsController`: index (Convoy Admin mọi company, company của mình), create, withdraw (company), approve / decline (Convoy Admin).
- `CompanyBlueprint` view `:settings` (country_locked, country_set_at / by, country_request pending, can_edit theo `actor`); `:platform` gồm `:settings`.
- Seed `61_company_settings`: country_set_by = owner SD, 1 request declined (ghi `validate: false` vì chỉ SG live).
- Spec `settings_company_spec.rb` (4, stub `Country.live_codes` = SG + MY).
