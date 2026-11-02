# Phase 7 — Vehicle Financials: P&L (02/11/2026)

- `Finance::Cpf` (port `cpf.js`: bảng 2025 / 2026, band tuổi tháng sau sinh nhật, trần OW, chỉ Citizen / PR; residential nil = tính).
- `Finance::VehiclePl` (live, theo tháng): doanh thu run theo kind ("Shuttle" cho corporate_shuttle), entries tay (lặp tháng), insurance
  premium chia theo tháng phủ (open-ended 12, tối đa 60), fuel, maintenance completed (có GST), lương driver như prototype (user chốt:
  scheme tháng không job qua `Pay::Engine` × tỉ lệ ngày là default driver theo `vehicle_driver_schedules`, 36 tháng gần nhất) + CPF,
  profit: khấu hao (tới tháng COE hết hạn, không thì 120) + lãi; cash: purchase / down + instalments.
- `Finance::VehicleReport`: kỳ (month / ytd / this_year / last_year / last_12 / all), fleet (theo xe, category, chart 12 tháng, cost/km theo size
  Minibus ≤13 / Medium 14–29 / Coach 30+ từ `fuel_entries.km_since`), vehicle (+ break-even), spikes (median 6 tháng, ≥3 tháng, ×1.5, ≥ S$100; ack),
  due 90 ngày (instalment, insurance, road tax ước từ entry Road Tax, COE).
- `VehiclePlController` (fleet, vehicle, spikes, ack, due, entries CRUD). Seed entries (contract, parking, road tax). Spec `finance_vehicle_pl_spec.rb` (2, số tính tay).
