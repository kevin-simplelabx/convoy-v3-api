# Phase 4 — Client Portal sign-in (02/11/2026)

- `PortalAccount`: Devise `database_authenticatable` + `jwt_authenticatable` (revocation Null: allowlist tự quản như Convoy OS),
  `devise_for :portal_accounts, skip: :all`; password 8..128 + confirmation; `accounts` = client_users kept của client kept (mọi company, `without_tenant`).
- Bảng `portal_jwts` (allowlist + `client_user_id` đã chọn) và `portal_sign_in_codes` (purpose first / reset, HMAC digest, 15 phút,
  5 lần thử, dùng 1 lần; code mới vô hiệu code cũ; ≤ 5 code / giờ / người). Job 3:00 xoá jwt hết hạn + code > 1 ngày.
- Token scope `portal_account` (`Portal::IssueToken`, `Portal::FindToken`); Convoy OS `Auth::FindToken` chỉ nhận scope `user` → 2 loại token tách biệt.
- `Api::V1::Portal::SessionsController`: lookup (password / code), code (quên mật khẩu), verify (→ `set_password_token` = MessageVerifier,
  fingerprint theo encrypted_password nên dùng 1 lần), create, show, update (chọn account), destroy. `PasswordsController#create`:
  đặt mật khẩu, xoá jwt cũ, đăng nhập. 1 account → tự chọn. Xoá client user → bỏ chọn trên jwt.
- `PortalMailer.sign_in_code` (text + html, deliver_later). `ApplicationMailer` from = ENV `MAIL_FROM` (mặc định no-reply@convoy.sg).
  Chưa có SMTP: `dev_code` khi `PORTAL_SHOW_CODE=1` (đã thêm vào `config/deploy.yml` staging; production không đặt).
- Rack::Attack: `portal_sign_in/ip` 10 / phút cho POST /portal/session* và /portal/password.
- Seed: Portal123! cho priya (2 client), kenneth; meiling chưa đặt. Spec `portal_sign_in_spec.rb` (3), `spec/mailers/portal_mailer_spec.rb` (1).
