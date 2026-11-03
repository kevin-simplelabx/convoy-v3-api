# Scope: School Bus 2 — Fares, Policy, Payment Methods, Operator Pay (rà 02/11/2026)

Nguồn: `logic/fares.js` (fdist, fareTiers, sizeCols, fareCalc, routeCost), `logic/mixins/school-finance.js` (fareBlank ~1445, farePeriods ~1465,
payCheck / busCheck / fareCheck ~1828–1935, fareVals / fareWizard ~1935–2400, adjVals ~970, polDefault ~371, polVals ~414, payRate / earned ~111–155,
Operator Pay ~1229–1420), `logic/mixins/fam-inv.js` pmOf / pmVals ~194–293, `Convoy OS.dc.html` bill() ~18204.

## Làm
| Trang | Tính năng | Phase |
| --- | --- | --- |
| Bus Fares | Theo năm học (cần calendar lock): Who Pays (parents / school per rider + bill to / school per bus), basis distance / zone, trip both / one / AM+PM, cycle term / tháng (chọn tháng), phân bổ equal / prorated / per bill / per bill theo ngày / custom, 1-way (% / bớt tiền / riêng), tiers (km tăng dần hoặc zone: tên + postal sectors hoặc vùng vẽ), giá theo cỡ xe (cột ghế), surcharges, Small Bus / Express, CCA / ASA (per trip / per kỳ, fixed / theo tier, chia đều / theo ngày CCA, rider không đi bus / chỉ AM / chỉ PM), per bus: giá mỗi cỡ xe + booked runs; kiểm tra từng bước như HTML; Save & Lock (chụp số ngày học mỗi kỳ); Unlock; copy từ năm khác | 1 |
| Fare Table | Tính ở server (port `fareCalc`): mỗi tier × kỳ, annual, 2-way / 1-way / AM / PM, cỡ xe, Small / Express; kỳ bill (term hoặc tháng, ngày học, ngày CCA) | 2 |
| Extra Charges | Khi fares lock: name, % / số tiền / một lần, value, từ tháng (≥ tháng này), đến tháng (trống = kéo sang năm sau), tiers, note; trạng thái Scheduled / Active / Ended; sửa / xoá khi Scheduled; Set End; preview 4 bill tới trước / sau | 3 |
| Payment & Refund Policy | Version theo ngày hiệu lực (không quá khứ; publish thay version đang lên lịch): due (trước N ngày / ngày cố định 1–28 / ngày học đầu), late (none / flat / % tháng + cap, grace, flag), reminders (khi, kênh, nội dung), withdrawal, change of address, deposit / reg fee, acknowledgement; lịch sử Scheduled / In Use / Replaced | 4 |
| Payment Methods | Bank Transfer / PayNow / Card: bật, admin fee (none / fixed / % ≤ 10); tài khoản company (Finance Settings) hoặc tài khoản riêng của trường (bank, account, name, PayNow) | 4 |
| Operator Pay | Theo trường: scheme 12 tháng / chọn tháng / chọn tháng + % còn lại; part month theo ngày học / ngày lịch; break months + retainer full / earned (theo term / theo ngày học + grace + trừ ngày); giá mặc định theo cỡ xe: Fixed Monthly và / hoặc Fixed + Per Rider (base, riders included, per rider, mặc định), BA their / our; Save & Lock; Break Month Calculator (server, cùng engine); bảng giá BA ở trang Bus Attendants | 5 |
| Year Setup | Bước Fares / Policy / Operator Pay có trạng thái thật | 5 |

## Tự quyết
- Lưu bảng PG: `fare_tables` (cột cấu hình) + `fare_tiers`, `fare_size_columns`, `fare_tier_sizes`, `fare_surcharges`, `fare_bus_rates`; vùng vẽ (polygon)
  và số ngày chụp khi lock = jsonb (bản chụp, đọc nguyên khối). Policy version = bảng + `policy_reminders`. Operator pay = bảng + `school_bus_size_rates`.
- Tính fare ở server (Ruby, cùng công thức `logic/fares.js`), để sub-menu 6 (bill) dùng chung.
- Quyền: xem = như Year Setup; sửa Fares / Extra Charges / Policy / Payment Methods / Operator Pay = `finance` (HTML `finRO` / `canFin`).
- Route Charges (giá thêm theo run của plan) làm ở sub-menu 4 (cần Route Plans).

## Không làm
- Gửi reminder / email / WhatsApp, cổng thanh toán, phí card thật: chỉ cấu hình (sub-menu 6 / backlog).
- Vẽ vùng trên map, preview tin nhắn, wizard UI, CSV export: FE.
