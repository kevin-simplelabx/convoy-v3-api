# Phase 3 — Client Users (02/11/2026)

- Bảng `portal_accounts` (email unique, name, encrypted_password, password_set_at, last_sign_in_at): 1 người / email cho mọi client
  của mọi transport company. `client_users` (company, client, portal_account, name, title, email, role 7 loại + check constraint,
  created_by, discarded_at; unique (client, email) khi chưa xoá) + `client_user_sites`.
- `ClientUser::ROLES` (label, tag, wide) từ `logic/app-feed.js`; `GET /client_users/roles`.
- `ClientUsers::Save`: tạo (name, email → `PortalAccount.for_email!`) / sửa (title, role, site_ids; name / email không đổi).
  Luật: email không trùng user Convoy OS của company; site role cần ≥ 1 site khi client có site; wide role xoá sites; site phải của client;
  luôn còn Super Admin (khi sửa). `ClientUsers::Remove` (discard, giữ Super Admin).
- Controller nested `/clients/:client_id/users`; `GET /clients` thêm `users_count`. Policy như client (mọi company user ghi).
- Chưa có: thu hồi token Portal khi xoá user / xoá client → Phase 4 (sign-in bỏ qua client_user đã xoá và client đã xoá).
- Seed `47_client_records`: 3 user Google (super, fin, sa Mapletree), Priya cũng là member St. Stephen's (chọn account). Spec `client_users_spec.rb` (3).
