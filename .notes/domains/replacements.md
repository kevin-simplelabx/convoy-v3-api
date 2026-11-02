# Replacements — hiện trạng

Layer 4 của occurrence (xem `occurrences.md`). Service: `Replacements::Save / Remove / Affected / Wording`.

## Bảng
| Bảng | Ghi chú |
| --- | --- |
| replacements | kind drv / veh / crew / hand; scope `run` (identity: trip, run_date, trip_run, slot_no) hoặc `range` (drv / veh trên original_vehicle, starts_on..ends_on); xe mới; driver mới (own / operator / tên + số); handover_stop / time; eta; pay_split + original_share; arranged_by operator / us + deduction + premium; reason |
| replacement_notifications | audiences guests / parents, channels email / push; **chỉ ghi lại, chưa gửi** |
| trip_occurrences.replacement_id, driver_name, driver_phone | kết quả áp lên run |

Trỏ run bằng identity (không FK partition) → run sinh lại vẫn khớp. Replacement mới trên cùng run thay cái cũ.

## Áp lên run
- drv: giữ xe, đổi driver. veh: xe mới + driver gốc, ghost `original_vehicle_id`. crew: xe mới + driver xe mới.
- hand: part 1 xe gốc tới giờ handover, part 2 xe mới; trip value theo pay_split; giá client chỉ part 1.
- arranged_by us: run thuộc operator xe mới; deduction mặc định = pay operator gốc cho các run đó.
- Range chỉ áp khi xe gốc (sau layer 1–3) = original_vehicle.

School Bus route có bảng riêng `school_route_replacements` (layer 1 của route), xem `school.md`.

## Seeds
`43_replacements` (Driver Away PD3318K, Vehicle Down PC8841T).
