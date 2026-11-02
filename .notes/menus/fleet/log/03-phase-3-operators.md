# Phase 3 — Managed Operators + banks (31/10/2026)

- Bảng platform `banks` (key 7171D / 7171P..., code, name, short_name, branch_rule pre3 / pre3drop / posb / sc / uob / list)
  + `bank_branches` (code, name, `account_prefix` cho UOB / Far Eastern). Seed `04_banks` từ `db/seeds/files/sg_banks.json`
  (export từ `Convoy Project/sg-banks.js`): 47 bank, 1141 branch.
- `Banks::BranchFor` (port `sgBranch`): code, name, `send` (số gửi file thanh toán), note POSB 9 số; lỗi kèm field.
- `operators`: `bank_id` (FK; bank_code tự chép từ bank — DBS / POSB chung 7171), `cost_per_trip`, `cost_per_day`.
  Validate managed: UEN format, PayNow (mặc định = UEN) hoặc bank đủ (6–14 số, account name, branch); đổi bank → xoá branch cũ.
  External không validate thanh toán. Factory operator thêm `paynow_uen`.
- `GET /banks`, `GET /banks/:id/branch`. Operators list view `:list` (`routes_count` = School Bus route đang chạy có xe regular
  hôm nay thuộc operator — `Operators::RouteCounts`; `vehicles_count`), view `:detail` (bank_name, branch_name, pays_by,
  account_number_sent); vehicle lồng operator giữ view mặc định (tránh N+1).
- Xoá operator còn xe: message "Remove the N vehicles of X first".
- Seed Hup Seng: UEN, email, bank DBS; Kallang: cost per trip / day.
- Spec `fleet_operators_spec.rb` (5). Tổng 200 specs.
