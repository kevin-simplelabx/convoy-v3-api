# Reports — hiện trạng

- Shuttle Report (trip `corporate_shuttle`): `Reports::ShuttleRuns` lấy run trong kỳ (không cancelled / removed / skipped), stop theo
  `TripHistory.planned_stops` + `recorded_stops` + Correct Record (`occurrence_corrections`), trạng thái stop ok / early (> 5 phút sớm) /
  late (> `clients.on_time_allowance`) / edep (rời pick-up trước giờ) / skip; run không có dữ liệu stop bị bỏ.
- `Reports::Shuttle`: KPIs (util = riders / tổng seats run, OTP = (ok + early) / (ok + early + late + edep)), so kỳ trước cùng độ dài,
  timings, stop activity (≥ 3 stop), trend 12 tháng; `grid(month)` riders / on-time theo timing × ngày.
- Không bảng riêng. Quyền `ReportPolicy` (vehicles / finance / finview). Seed `94_shuttle_report` (stop events MBC 3 tháng).
