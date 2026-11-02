# Phase 4 — Pay engine + Salary Simulator (02/11/2026)

- `Pay::Engine`: port `DP.simulate` theo inventory § 8.3 (coverage avail, inSched 6-days, shift, on-top days, post-guarantee boost,
  daily volume theo số thứ tự trip trong ngày, weekly target chủ nhật của tuần bắt đầu thứ hai trong đoạn, monthly target cuối đoạn,
  rejection penalty / fallback, route retainer theo band, route đếm trong school holidays). BigDecimal, làm tròn cents ở cuối.
  Thêm so với HTML: đoạn tháng (`factor` = ngày đoạn / ngày tháng) pro-rate base, guarantee, retainer, mục tiêu tháng (ceil);
  `job_pay[ref]` = tiền từng job (Earnings lưu theo run); rate theo vehicle type của từng job.
- `Pay::Month`: chia tháng theo scheme (lambda date → scheme), chạy engine từng đoạn, cộng tổng.
- `Pay::Simulation` (job từ JSON, route lái như trip khi không có retainer) + `sample` (port `DP.sampleJobs`).
- `pay_simulator_templates` (5 slot / company, jobs + routes jsonb = bản chụp). `PaySimulatorController`: simulate, sample, templates CRUD.
- Seed template 1 "Sample month". Spec `spec/services/pay/engine_spec.rb` (5, số tính tay), `hr_simulator_spec.rb` (2).
