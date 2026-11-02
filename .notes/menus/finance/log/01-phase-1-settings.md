# Phase 1 — Finance Settings + đánh số (02/11/2026)

- `finance_settings` (1 / company, `FinanceSetting.current`): GST, approval single / maker, brand, payment details (bank, account,
  PayNow, note — gộp "Invoice Settings" của cinv vào đây), prefix 7 loại (inv cn dn rcp pv pn pb), lock. `finance_approvers` (user, can_prepare, can_approve).
- `Finance::SaveSettings` (validation như HTML + prefix không trùng), `FinanceSetting.split` (GST excl / incl, làm tròn cents).
- `Finance::Numbering.next!(type, date:)` = CompanySequence `doc:<type>:<year>`, `PREFIX-YYYY-000001` (user chốt một hệ).
- `FinancePolicy` headless (finance / finview, finset, vehfin, unlock admin). Users index `meta.maker_checker_warning` (xoá dòng backlog settings).
- Seed `75_finance` (GST 9 % excl, DBS, 2 approver). Spec `finance_settings_spec.rb` (3).
