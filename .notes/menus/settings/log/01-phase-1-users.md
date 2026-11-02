# Phase 1 — Users (02/11/2026)

- Migration `users`: `discarded_at`, `all_schools` (mặc định true), `display_name` (Phase 2), `created_by_id` (FK validate riêng);
  unique email thành partial `WHERE discarded_at IS NULL` (`index_users_on_live_email`); index `(company_id, discarded_at)`.
  Bảng `user_schools` (user, school, unique cặp).
- `User`: bỏ Devise `:validatable`, tự validate email (format, unique trong user chưa xoá), password (8..128, `config.password_length`).
  `find_for_authentication` chỉ tìm user chưa xoá; `active_for_authentication?` = active + kept. `audited` (trừ cột mật khẩu / token).
  `ROLE_PRESETS` (10, từ HTML), `PERMISSION_LABELS`, `role_label` (Super Admin / Admin / preset khớp đúng quyền / Custom), `every_school?`.
- Role: `Users::Save` set `admin` khi owner hoặc đủ 10 quyền (lưu đủ 10 quyền), ngược lại `member`. Seed / factory cũ (admin, quyền rỗng) vẫn chạy nhờ `effective_permissions`.
- `Users::Save`: tạo (name, email, password) / sửa (owner, permissions, all_schools, school_ids; name / email bỏ qua khi sửa).
  `Users::Act`: suspend (xoá allowlisted_jwts), activate, remove (discard + xoá token). `Users::Guard`: chỉ owner đụng / tạo owner,
  không tự suspend / xoá, không tự bỏ quyền `users`, luôn ≥ 1 owner active (kiểm sau khi đổi, trong transaction).
- `UsersController` + `UserPolicy` (quyền `users`; Convoy Admin chỉ xem; scope = tenant hiện tại, kept). Blueprint view `:manage`
  (role_label, all_schools, every_school, schools, created_by, can_edit, can_act theo `actor`). Search `q[name_or_email_i_cont]`.
- Không làm: chữ mô tả bảng View Role Permissions (FE tĩnh); áp `user_schools` vào School Bus (backlog).
- Seed `60_users`: planner (1 trường), opsmgr, viewer suspended, 1 user đã xoá. Spec `settings_users_spec.rb` (11). Tổng 231 specs.
