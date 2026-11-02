# Phase 6 — Replacements ✅ (30/10/2026)

## Bảng
| Bảng / cột | Ghi chú |
| --- | --- |
| replacements | kind drv / veh / crew / hand; scope run (trip, run_date, trip_run, slot_no) hoặc range (drv / veh: mọi run trên original_vehicle trong starts_on..ends_on); new vehicle; new driver (own / operator / tên + số tự gõ); handover_stop + handover_time; eta; pay_split original / new / both / split + original_share; arranged_by operator / us + deduction + premium; reason |
| replacement_notifications | audiences guests / parents, channels email / push (push chỉ cho parents; WhatsApp / Client Portal chưa có), message (ghi lại, chưa gửi thật) |
| trip_occurrences + | replacement_id, driver_name, driver_phone (driver không có hồ sơ) |
Replacement trỏ run bằng **identity** (trip, ngày, run, slot), không FK vào bảng partition → run bị sinh lại vẫn khớp.
Replace Driver tạm trong drawer (HTML `drv[key]`) = replacement drv scope run (một khái niệm).

## Generator: đủ layer theo thứ tự (.notes/03 mục 9)
1 trip → 2 assignment → 3 thay đổi tay trên row đang lưu (xe, operator_cost, shift Today Only; generator nhận `existing`) → 4 replacement → (5 status do Sync).
Sync giờ chỉ so digest và ghi (không tự merge override nữa); Move "one" sync lại ngày đó để replacement trên xe mới cũng áp.
- drv: xe giữ nguyên, driver = người thay.
- veh: xe mới, **driver gốc** đi theo; `original_vehicle_id` = xe gốc (ghost trên grid).
- crew: xe mới + driver của xe mới (hoặc người được chọn).
- hand: part 1 xe gốc tới giờ handover, part 2 xe mới từ giờ đó; trip value chia theo pay_split; giá client chỉ ở part 1.
- arranged_by us: run thuộc operator của xe mới (operator_cost theo trip); operator: operator gốc tự lo, pay giữ nguyên.
- Range chỉ áp lên run có xe gốc (sau layer 1–3) = original_vehicle → run đã kéo tay sang xe khác không bị ảnh hưởng.

## API
- `GET /replacements?from=&vehicle_id=&scope=` (mặc định từ 30 ngày trước; `status_label` Active / Coming Up / Ended, `summary`, `pay_text`).
- `GET /replacements/preview?occurrence_id=&replacement[...]` → số run bị ảnh hưởng (+ danh sách), message gửi khách, ai nhận trip value,
  operator gốc, `deduction_default` (pay của operator gốc cho các run đó), lỗi nếu có.
- `POST /replacements { replacement, occurrence_id (Replace từ drawer), notify { audiences, channels } }`, `PATCH`, `DELETE` (run về xe / driver thường).
- Kiểm tra như form HTML: handover phải trong giờ chạy ("The handover time must be during the trip, 08:00 to 09:00"), xe mới khác xe gốc,
  drv cần driver, range chỉ cho drv / veh. Replacement mới trên cùng run thay cái cũ.
- Grid: `grid_status` "replacement", `original_plate` (vẽ ghost), drawer có `replacement` (summary, pay_text, notifications).

## Seeds `43_replacements`
Driver Away trên PD3318K (Daniel Wong lái 2 ngày tuần sau), Vehicle Down PC8841T 1 ngày → PD5126A (driver gốc).

## Specs
130 examples (thêm 6): drv 1 run + xoá, Vehicle Down theo khoảng ngày + ghost, crew, handover (chia giờ / trip value, giờ sai),
arranged by us + preview deduction + notify, và chuỗi đầy đủ mục 9 (assign → replace → cancel → kéo tay → bỏ assign → Vehicle Down).
