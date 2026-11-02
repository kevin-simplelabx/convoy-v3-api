# Phase 8 — Docs & kiểm tra (02/11/2026)

- `.api-documents/finance.md` (§ 1 Settings, § 2–3 Client Invoices, § 4 Operator Payments, § 5 Documents, § 6–7 Vehicle Financials,
  § 8 chưa làm, § 9 endpoint cũ đổi); README, integration (page id cinv / cfdocs / cfpay / vehfin / finset), screen-map (mục Finance),
  fleet (financials trên record xe), settings (maker-checker warning).
- OpenAPI: `finance.md` vào `MENUS`, folder "Finance".
- Notes: `domains/finance.md` (mới), data-ownership, backlog (xoá dòng Vehicle Financials của fleet, thêm 3 dòng finance), decisions.
- Kiểm tra: 288 specs, rubocop sạch, seed ×2, `occurrences:verify`, anchor doc không hỏng.
