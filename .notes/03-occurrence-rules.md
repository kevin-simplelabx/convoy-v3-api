# Occurrence — Option B (chốt 30/10/2026)

`trip_occurrences` lưu mọi lần chạy đã resolve. Trip là template; occurrence là thứ Scheduler, driver app, invoice, pay, report đọc.

## 1. Lợi ích
- Driver / admin query theo ngày bằng index: `for_driver(d).on(date)`, `for_vehicle(v).between(a, z)`, `on(date).unassigned`.
- Thống kê bằng SQL (`GROUP BY` client, vehicle, driver, kind, tháng); BI tool đọc trực tiếp.
- Phân trang, search Trip ID, filter (ransack) ngay trên bảng.
- Quá khứ là snapshot bất biến: xe, driver, giá, cost, trip value lúc chạy → invoice, driver pay, Trip History không bị lệch khi sửa template.
- FK thật cho attendance, issue, replacement, tracking link, notice, audit.
- Diff khi sync = danh sách occurrence bị đổi → notify đúng driver / client.
- Scale: vài nghìn driver, partition theo tháng, read replica.

## 2. Cấu trúc
`trip_occurrences` (partition theo `date`, RANGE theo tháng):
- Khoá: unique `(trip_id, date, trip_run_id, slot_no, part)`; `part` 1 = bình thường, 2 = phần sau của Handover.
- Resolve: `vehicle_id`, `driver_id`, `operator_id`, `original_vehicle_id` (ghost khi replacement veh/crew), `replacement_id`, `assignment_id`.
- Giờ: `start_at`, `end_at` (timestamptz theo tz company), `shift_min`.
- Tiền: `price`, `operator_cost`, `trip_value`, `trip_value_2`.
- Trạng thái: `status` (scheduled, cancelled, completed, issue...), `cancelled_at/by`, `ended_at`.
- Denormalized để query: `company_id`, `client_id`, `kind`, `trip_no_label` (Trip ID hiển thị).
- `overridden_fields` text[] — field do người sửa tay, Sync không được ghi đè.
- `lock_version`, `generated_at`, `source_digest` (hash đầu vào generator để biết row có cần cập nhật).

Index: `(company_id, date)`, `(driver_id, date)`, `(vehicle_id, date)`, `(trip_id, date)`, partial `(company_id, date) WHERE vehicle_id IS NULL` (unassigned).

## 3. Quy tắc bất biến
1. **Chỉ service ghi occurrence** (`Occurrences::Sync`, `Occurrences::Override`, `Occurrences::Correct`). Controller / model callback không update trực tiếp.
2. **Quá khứ không regenerate**: row có `start_at <= now` không bị Sync đụng tới. Chỉ đổi qua *Correct Record* (bắt buộc reason, audited).
3. **Override được giữ**: Sync bỏ qua mọi field trong `overridden_fields`.
4. **Row không còn sinh ra nữa** (đổi days, đổi số xe, xoá trip): không có dữ liệu phụ thuộc → xoá; có (attendance, issue, override, tracking, notice) → `status: removed` + flag để admin xem.
5. **Horizon**: sinh tới `today + 90d`; job hằng ngày đẩy thêm 1 ngày. Xem xa hơn → generator in-memory (cùng code, không ghi).
6. **Đồng thời**: `pg_advisory_xact_lock(trip_id)` khi sync 1 trip; `lock_version` trên trip và occurrence (409 khi conflict).
7. Sync trong cùng transaction với thay đổi khi phạm vi nhỏ (1 trip); phạm vi lớn (calendar, PH) → `Occurrences::SyncJob` sau commit.

## 4. Thay đổi nào → cần sync gì (checklist)

| Thay đổi | Phạm vi sync | Ghi chú |
| --- | --- | --- |
| Tạo trip | trip, `trip.date` → horizon | Trip lùi ngày được: sinh cả ngày quá khứ (chưa có row). Two-Way: cả 2 trip. |
| Sửa trip (tuyến, giờ, giá, days, số xe, vehicle slots, rv, run groups) | trip, `max(today, trip.date)` → horizon | Xoá/`removed` slot vượt số xe mới. |
| Sửa "From this date on" / Every Run From Today | Split series: trip cũ `until = d-1`, trip mới từ `d`; chuyển row tương lai sang trip mới | Lịch sử giữ ở trip cũ. |
| Xoá trip | trip, today → horizon | Trip soft-delete; quá khứ giữ nguyên. |
| Shuttle timetable (runs, stop times, return stops) | trip, today → horizon | `trip_run_id` mất → quy tắc 4. |
| Assignment tạo / xoá (Assign page) | trip, `from` → assignment kế tiếp (hoặc horizon) | |
| Kéo thả "This date only" | 1 occurrence | `Override`: `vehicle_id` vào `overridden_fields`; swap = 2 row. |
| Kéo thả "From this date on" | Ghi assignment hoặc sửa slot → sync như trên | |
| Quick time "Today Only" | 1 occurrence | `shift_min` override. |
| Cancel / Restore | 1 occurrence | `status` override; Restore xoá override. |
| Raise / Clear Issue | 1 occurrence | Ảnh hưởng driver pay, không đổi xe/giờ. |
| Replacement 1 trip (drv, veh, crew) | 1 occurrence | `vehicle_id`/`driver_id`, `original_vehicle_id`, `replacement_id`. |
| Replacement Handover | 1 occurrence → tạo `part 2` | Part 1 `end_at` = giờ handover. |
| Driver Away / Vehicle Down (date range) | occurrence của `vid0` trong range | Xoá replacement → sync lại range. |
| Default driver schedule đổi | occurrence của xe từ `from` → horizon | Chỉ `driver_id`. |
| Driver nghỉ / vehicle ngừng dùng | occurrence tương lai của driver/xe | Xe → unassigned; driver → null. |
| Calendar day thêm/sửa/xoá (Change a Day) | mọi trip có `calendar_id` đó, range ngày thay đổi | Job. |
| Calendar `obs` đổi | trip của calendar, các ngày observed | Job. |
| Public holiday thêm/sửa/xoá | trip của company, ngày đó | Job. |
| Company `ph_obs` đổi | trip không có calendar, ngày observed | Job. |
| Rate / giá trip thay đổi | trip, today → horizon (chỉ cột tiền) | Quá khứ giữ giá cũ. |
| Timezone company đổi | toàn company | Hiếm; job. |
| Maintenance visit | Không sync occurrence | Hiển thị riêng; chỉ cảnh báo clash. |

## 5. Job định kỳ
- `Occurrences::ExtendHorizonJob` (hằng ngày): sinh ngày `today + 90`.
- `Occurrences::CompleteJob` (mỗi 5–15'): `end_at < now`, chưa cancel → `completed`.
- `Occurrences::VerifyJob` / `rake occurrences:verify`: so generator vs DB cho range tương lai, log lệch.
- `Occurrences::PartitionJob` (hằng tháng): tự tạo partition cho 3 tháng tới (không dùng pg_partman, chốt 30/10/2026).

## 6. Test bắt buộc
- Generator: days, end modes, PH skip, observed, calendar off / working holiday / shift, shuttle runs × slots, two-way.
- Sync: giữ override, quy tắc 4, không đụng quá khứ, idempotent (chạy 2 lần không đổi gì).
- Mỗi dòng trong bảng mục 4 có 1 spec.

## 7. Series không có ngày kết thúc (End: Never)
- Trip lưu `until_date = NULL`, `end_mode = never` (không giả "2 năm" như HTML).
- Row chỉ có tới horizon (`today + 90d`); `ExtendHorizonJob` sinh tiếp mỗi ngày → series chạy mãi.
- Đọc quá horizon (Scheduler xem tháng sau nữa, preview Next 12 Months): `Occurrences::Generator` in-memory, cùng code, trả về cùng shape (blueprint), có cờ `virtual: true`.
- Ghi quá horizon (huỷ / kéo thả / đổi giờ một ngày xa): **materialize đúng row đó on-demand** rồi override. Khi horizon tới, upsert theo unique key nên không trùng, và override được giữ (quy tắc 3).
- Thống kê SQL chỉ phủ tới horizon; forecast xa hơn dùng generator.

## 8. Assignment / Replacement cho tương lai
- Là **rule riêng**, không nằm trên occurrence: `trip_assignments (trip_id, effective_from, slots, vehicle/operator, pay)`, `replacements (kind, occurrence_id | vehicle_from_id + date range, ...)`.
- Generator đọc rule khi resolve xe/driver, nên:
  - Tạo/sửa/xoá rule → sync `[from, min(to, horizon)]`.
  - Phần sau horizon tự áp khi horizon đẩy tới (job sinh row mới vẫn đọc rule).
  - Assignment mở (tới khi đổi) và Driver Away / Vehicle Down xa trong tương lai đều được.
- Thứ tự resolve: xem mục 9 (layer model). Xe gốc = override "This date only" > assignment > rv > vehicle slot; replacement áp **lên trên** xe gốc (như `schTrips` trong HTML).
- Rule mới phủ lên ngày đã có override tay: override giữ nguyên; API trả `conflicts: [occurrence_ids]` để UI hỏi Giữ / Reset (Reset = xoá field khỏi `overridden_fields` rồi sync).
- Replacement 1 trip trên ngày quá horizon → materialize on-demand (mục 7).
- Notify (guests/parents) ghi theo replacement; gửi thật khi tới thời điểm (job), không gửi khi tạo rule xa.

## 9. Chuỗi thao tác trên cùng occurrence (layer model)
Mỗi thao tác là 1 layer lưu riêng, không ghi đè nhau. Trạng thái cuối = resolve các layer theo thứ tự cố định,
nên làm theo thứ tự nào, undo cái nào giữa chừng đều ra kết quả đúng.

| # | Layer | Lưu ở | Quyết định | Undo |
| --- | --- | --- | --- | --- |
| 1 | Template | trip, trip_vehicle_slots, trip_run_slots | xe mặc định, giờ, giá | sửa trip |
| 2 | Assignment | trip_assignments (effective_from) | xe / operator / pay từ ngày đó | Remove assignment |
| 3 | Override tay | occurrence `overridden_fields` (vehicle_id, shift_min) | xe gốc ngày đó, giờ | Reset override |
| 4 | Replacement | replacements (theo occurrence, hoặc xe gốc + range) | xe/driver thực chạy, ghost, handover part 2, pay | Remove replacement |
| 5 | Status | occurrence `status` override (cancelled), issue | huỷ, giữ pay | Restore / Clear issue |

Xe gốc = (3) ?? (2) ?? (1). Driver = lịch driver của xe gốc tại ngày đó. Replacement (4) áp lên xe gốc:
theo occurrence → luôn áp; theo range (Driver Away / Vehicle Down) → chỉ áp nếu xe gốc của ngày đó = `vehicle_from_id`.
Status (5) áp cuối; occurrence huỷ vẫn giữ xe và replacement (để hiện `cancelRepl` và Restore về đúng chỗ).

Ví dụ (shuttle chạy mỗi ngày, xe mặc định PD3318K):
1. Assign từ 01/11 cho Operator A, xe PC1111 → 01/11+ chạy PC1111.
2. 05/11 Replace Driver Unavailable (driver X) → 05/11: PC1111, driver X.
3. 06/11 Cancel → 06/11 huỷ, vẫn ghi PC1111.
4. Kéo 07/11 sang PD4472H (This date only) → 07/11: PD4472H.
5. Remove assignment → 01/11+ về PD3318K; 05/11 vẫn có driver X (replacement theo occurrence); 06/11 vẫn huỷ; 07/11 vẫn PD4472H (override giữ).
6. Vehicle Down PD3318K 10–12/11 thay bằng PE1290S → chỉ 10–12/11 đổi xe; 07/11 không bị ảnh hưởng vì xe gốc ngày đó là PD4472H.

Mỗi thao tác = 1 API call riêng: transaction + advisory lock theo trip + sync phạm vi + `occurrence_events` (ai, lúc nào, trước/sau) + audited.
Response trả occurrence sau khi resolve và `conflicts` (nếu có). Client gửi `lock_version`; lệch → 409.

Bulk (chọn nhiều occurrence rồi cancel / assign / replace một lần): endpoint `POST /occurrences/bulk` cùng service, 1 transaction — thêm ở Phase 5.

Spec bắt buộc: ví dụ trên thành 1 spec chạy từng bước + mọi hoán vị undo của layer 2–5.
