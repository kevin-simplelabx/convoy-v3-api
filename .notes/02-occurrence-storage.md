# Occurrence storage — so sánh

Occurrence = 1 lần chạy cụ thể: trip × date × run (shuttle) × vehicle slot.
Xe/driver của 1 occurrence được quyết định bởi (thứ tự ưu tiên):
replacement → override drag-drop ngày đó → assignment (latest `from <= date`) → run slot (rv) → trip vehicle slot.
Driver = default driver schedule của xe tại ngày đó → replacement driver.
Ngày chạy = days of week, date range, end mode, Public Holiday (skipPH, observed), calendar day off / working holiday.

## A. On-the-fly (như HTML)
Lưu: trips (template) + `occurrence_overrides` (vehicle, shift, cancel, ended, issue) chỉ khi khác template.

```ruby
# Driver: trip hôm nay
candidates = Trip.active_on(date)          # SQL: date <= d AND (until IS NULL OR until >= d) AND (dow = ANY(days) OR (days='{}' AND date=d))
occ = Occurrences::Expander.new(candidates, date..date).call   # Ruby: PH, calendar, runs, slots, overrides, assignments, replacements
occ.select { |o| o.driver_id == driver.id }                    # lọc trong Ruby — không biết trước driver ở xe nào
```
- Driver/vehicle không nằm trên trip → **phải expand toàn bộ trip của company cho ngày đó rồi lọc trong Ruby**.
- 1 ngày: OK (vài trăm occurrence). 1 tháng (Earnings, invoice, P&L, report): expand 30 ngày × mọi trip → chậm, không phân trang bằng SQL, không `GROUP BY`.
- Lịch sử không bất biến: sửa giá / calendar / driver schedule hôm nay làm thay đổi "quá khứ" (invoice, pay đã chốt bị lệch) → phải tự snapshot riêng.
- Ít rows, không cần sync.

## B. Materialize (đề xuất)
Lưu thêm `trip_occurrences`, mỗi row = 1 occurrence với giá trị đã resolve:
`date, start_at, end_at, trip_id, trip_run_id, slot_no, vehicle_id, driver_id, operator_id, status, price, operator_cost, trip_value, overridden_vehicle, shift_min, cancelled_at, ...`

```ruby
# Driver app: hôm nay / ngày mai / 1 ngày
TripOccurrence.for_driver(driver).on(Date.current).order(:start_at)
TripOccurrence.for_driver(driver).on(Date.tomorrow)
# Admin: Scheduler 1 tuần, kèm unassigned
TripOccurrence.between(from, to).includes(:trip, :vehicle, :driver)
TripOccurrence.on(date).unassigned.count
# Thống kê
TripOccurrence.completed.between(m.beginning_of_month, m.end_of_month).group(:client_id).sum(:price)
TripOccurrence.completed.for_driver(d).in_month(m).sum(:trip_value)
```
Index: `(company_id, date)`, `(driver_id, date)`, `(vehicle_id, date)`, unique `(trip_id, date, trip_run_id, slot_no)`.

Chi phí:
- **Sync**: khi trip / calendar / PH / assignment / replacement / driver schedule đổi → `Occurrences::SyncJob(trip_ids, date_range)` regenerate các row **tương lai**, giữ nguyên row đã override (cột `locked_fields`) và row quá khứ.
- **Horizon**: series "Never" không thể sinh vô hạn → sinh tới `today + 180d`, job hằng ngày đẩy thêm; xem xa hơn horizon → generator chạy in-memory (cùng code) hoặc mở rộng horizon khi cần.
- **Số rows**: 200 shuttle × 10 run × 2 xe × 260 ngày ≈ 1M rows/năm → PG xử lý tốt; sau này partition theo `date` nếu cần.
- Quá khứ là **snapshot bất biến** (giá, xe, driver lúc chạy) → đúng cho invoice, driver pay, report, Trip History.

## Kết luận
Chọn **B**. Generator (`Occurrences::Generator`) là pure Ruby, dùng chung cho: sinh row, preview form (Next 12 Months), và fallback ngoài horizon.
Row quá khứ không regenerate (trừ khi admin "Correct Record").

## Điểm yếu của B và cách xử lý (đã chốt B, 30/10/2026)

| Rủi ro | Xử lý |
| --- | --- |
| Hai nguồn sự thật (template + rows) lệch nhau khi quên sync | Mọi thay đổi đi qua service (`Trips::Upsert`, `Replacements::Create`...), service gọi `Occurrences::Sync` trong cùng transaction cho trip/ngày bị ảnh hưởng; không sửa occurrence trực tiếp từ controller. Rake `occurrences:verify` so generator vs DB. |
| Một thay đổi lan rộng (sửa PH, calendar, lịch driver mặc định) phải ghi lại nhiều row | Sync theo phạm vi (trip_ids × date range) chạy bằng job; chỉ update row khác biệt (upsert_all theo unique key). |
| Sync ghi đè chỉnh sửa tay (kéo thả, đổi giờ một ngày) | Row có `overridden_fields` (vehicle, shift, cancel...); Sync giữ các field đó. |
| Đổi template khi đã có row quá khứ | Chỉ regenerate từ hôm nay; quá khứ chỉ đổi qua "Correct Record". "From this date on" = split series. |
| Horizon: series "Never" không sinh vô hạn; xem quá horizon thì thiếu row | Horizon +180 ngày, job hằng ngày đẩy; xem xa hơn dùng generator in-memory (cùng code). |
| Race: 2 admin cùng sửa / job sync chạy song song | Advisory lock theo trip_id khi sync; optimistic locking (`lock_version`) trên trip và occurrence. |
| Lịch driver mặc định đổi → driver_id trên row cũ lỗi thời | driver_id là cột denormalized, Sync cập nhật cho row tương lai của xe đó. |
| Số row lớn | Index theo date; partition theo tháng/năm khi > vài chục triệu row. |

---

## Thảo luận lại (30/10/2026): A vs B (+ C lai)

Quy mô giả định 1 company: 150 xe, ~300 trip/series, ~2.000 occurrence/ngày, ~60.000/tháng.
Đo ước lượng expander Ruby: 1 ngày ~30–80 ms, 1 tuần ~0,3 s, 1 tháng ~1–2 s (chưa cache).

**C. Lai (lazy materialize)**: tương lai tính on-the-fly như A; row chỉ được tạo khi (1) có chỉnh sửa trên occurrence đó
(kéo thả, đổi giờ, huỷ, issue, attendance, replacement) hoặc (2) ngày đã qua — job đêm "đóng sổ" hôm qua thành row bất biến.

| Tiêu chí | A. On-the-fly | B. Materialize | C. Lai |
| --- | --- | --- | --- |
| Driver: hôm nay / mai / 1 ngày | Expand 1 ngày cả company rồi lọc (~50 ms) | 1 query index | Như A |
| Scheduler 1 tuần | Expand ~0,3 s | 1 query | Như A (quá khứ đọc bảng) |
| Thống kê quá khứ (invoice, pay, report, P&L) | Expand cả tháng ~1–2 s, không GROUP BY | SQL | SQL |
| Thống kê tương lai (forecast, unassigned 30 ngày) | Expand | SQL | Expand |
| BI tool (Metabase) / SQL tay | Không | Có | Chỉ quá khứ |
| Phân trang Table view, search Trip ID | Ruby | SQL | Ruby cho tương lai |
| Quá khứ bất biến | Phải snapshot riêng | Có | Có |
| Rủi ro lệch dữ liệu (quên sync) | Không có | Cao nhất | Thấp (chỉ override + đóng sổ) |
| Sửa template / PH / calendar / lịch driver | Không cần làm gì | Sync hàng nghìn row tương lai | Không cần (trừ row override) |
| FK cho attendance / issue / replacement | Tạo override row khi cần | Có sẵn | Tạo row khi cần |
| Số đường đọc (code paths) | 1 (expander) | 1 (SQL) + expander ngoài horizon | 2 (expander tương lai + SQL quá khứ, phải merge khi range vắt qua hôm nay) |
| Công sức build | Thấp | Cao nhất (sync, horizon, lock) | Trung bình |

Câu hỏi quyết định:
1. Có cần SQL/BI trên dữ liệu **tương lai** không (forecast doanh thu, xe rảnh 30 ngày tới, export cho bên ngoài)? Có → B.
2. Có sợ lỗi lệch dữ liệu hơn là chậm vài trăm ms ở query tương lai? Có → C.
3. Quy mô có tăng lên hàng chục nghìn occurrence/ngày (nhiều company lớn, driver app poll liên tục)? Có → B (hoặc C + cache).

## Quy mô lớn (vài nghìn driver) — khuyến nghị B
- 3.000 driver × ~5 occurrence/ngày ≈ 15.000/ngày, ~5,5M row/năm (mọi tenant).
- A/C: mỗi lần driver mở app phải expand cả company rồi lọc; 6h sáng 3.000 request cùng lúc → buộc phải cache; cache + invalidation = tự làm lại B nhưng kém hơn.
- B: `WHERE driver_id = ? AND date = ?` (~1 ms). Diff khi sync = danh sách occurrence đổi → push cho đúng driver bị ảnh hưởng.
- Thiết kế cho scale: PG native partitioning theo tháng trên `trip_occurrences` (ngay từ đầu), horizon 90 ngày (giảm write khi sync), sync qua job theo phạm vi (trip_ids × date range), `upsert_all` chỉ row thay đổi, advisory lock theo trip, read replica cho driver app/report khi cần.
