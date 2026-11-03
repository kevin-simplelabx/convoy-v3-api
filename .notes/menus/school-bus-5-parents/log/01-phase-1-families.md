# Phase 1 — Families (02/11/2026)

- `families` (code FAM-0001 unique company, name auto = họ của Father > Mother > guardian đầu + " Family" / custom, source console / app, sample),
  `family_guardians` (8 quan hệ, kiểm phone / email, cần first hoặc last), `family_riders` (school + rid unique: một family / rider / trường).
- `Families.search` (tên, code, guardian name / phone / email, rider id / name, số ≥ 3 chữ số theo phone), `candidates` (parent match theo tên phụ huynh
  hoặc 8 số cuối, rồi cùng họ), `link` (rider rời family khác cùng trường), `export`; `Families::Import` (khớp family_id > tên > phone, tạo / đổi tên
  có cảnh báo, guardian theo tên, rider không có trên list vẫn link + cảnh báo, xoá family rỗng).
- API: `/schools/:id/families` (+ import / export, meta unlinked_riders), `/families/:id` (+ guardians, riders, candidates); Add Rider có `family_id`.
  Quyền `FamilyPolicy`: plans / schools / finance. Spec 2.
