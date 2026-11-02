# Phase 8 — Audit Log (02/11/2026)

- `Pay::AuditLog` đọc `audits` (user chốt) của model HR, lọc theo company qua `auditable_id IN (model.unscoped.where(company_id))`
  vì bảng audits không có company; 500 dòng mới nhất, map action (comment Locked / Unlocked → lock / unlock; DriverPayMonth create /
  destroy → confirm / reopen; lot / deduction → award / deduct), item, name (record hoặc tên lưu trong audit khi đã xoá), details
  (comment, câu cho assignment, Created / Deleted, cột đổi). Filter q / action / item lọc trong Ruby, phân trang `pagy_array` (extra array).
- Spec `hr_audit_log_spec.rb` (1).
