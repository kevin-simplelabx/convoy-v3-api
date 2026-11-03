# Phase 1–6 — School Bus 2: Fares, Policy, Payment Methods, Operator Pay (02/11/2026)

- P1: `fare_tables` + tiers / size columns / tier sizes / surcharges / bus rates; `FareTables::Check` (port fareCheck / payCheck / busCheck), `Save` (cần calendar lock; lock + snapshot ngày học); copy.
- P2: `FareTables::Calc` (port fareCalc: fdist, per bill / billpro, 1-way pct / flat / custom, ampm, size columns, small / express, per bus); `FareTables.periods`.
- P3: `fare_adjustments` (Extra Charges), Save (từ tháng này, chỉ khi Scheduled), Set End, carried over, Preview 4 bill (`FareTables.adjusted`).
- P4: `school_policy_versions` + reminders (Publish thay version đã lên lịch, luật như HTML), `school_payment_methods` (tài khoản company / riêng).
- P5: `school_operator_pays` + `school_bus_size_rates`, `OperatorPays::Earned` + `Calculator`; giá BA ở Bus Attendants; setup steps đủ 7.
- P6: seed `49_school_money`, doc `.api-documents/school-bus-money.md`, index + OpenAPI. Spec mới: fares (4), policy (3), operator pay (2).
- Sửa kèm: unlock theo section (fares / operator_pay cần finance; bước khác cần plans / schools).
