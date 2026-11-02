# Phase 6 — Trip History: list + record (30/10/2026)

- **Lõi occurrence**: status mới `skipped` + cột `skip_reason` (migration `20261030190000`, `…190100` nới CHECK status;
  PG 17 không cho NOT VALID trên bảng partition → drop + add, check chỉ nới rộng). `Calendars::Context#trip_skips` →
  `{date => "Public holiday: X" | nhãn day off}`; Generator sinh row cho ngày bị bỏ (giá / trip value 0, không replacement);
  Sync: insert `skipped`, update chuyển skipped ↔ scheduled khi lịch đổi (trừ status do người đặt). Chỉ trip (School Bus route
  không sinh skipped: nghỉ cả kỳ sẽ quá nhiều row). `visible` loại cả skipped → Scheduler, Trips list, pay / invoice không thấy.
  `Occurrences::Edit` / `Move` chặn run skipped.
- `trip_occurrences.cancelled_by_client` (drawer cancel `by_client`; booking cancel accept = true) → outcome Cancelled by Client / Us.
- `companies.on_time_minutes` (mặc định 5) cho luật On Time (dùng ở Phase 8).
- Bảng `occurrence_notes`, `occurrence_driver_reports` (+ `occurrence_report_photos`, CarrierWave) trỏ run bằng (occurrence_id, occurrence_date);
  association khoá kép (`foreign_key: [occurrence_id, occurrence_date]`, `primary_key: [id, date]`) chạy được với Rails 8.1.
- `TripHistoryQuery` (filter list, facets đếm theo mọi filter khác như HTML, needs_look, sort new / old / id / client, tối đa 1 năm);
  `TripHistory::Record` (not_run, xe + crew, stops kế hoạch, trip info, standby, POC, passengers, driver report, changes, notes, log).
- API: `GET /trip_history`, `GET /trip_history/:id`, `POST /trip_history/:id/notes`.
- On time / distance / speed / driving summary: `na` / null tới Phase 8. Weather: backlog.
- Seed `92_trip_history`: chạy Complete, 1 run huỷ cho client + 1 huỷ bởi mình, 1 note, 6 driver report (1 có ảnh).
- Spec `trip_history_spec.rb` (3), sửa `sync_spec` (PH → row skipped, xoá PH → chạy lại). Tổng 178 specs.
