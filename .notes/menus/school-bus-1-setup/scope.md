# Scope: School Bus 1 — Schools & Year Setup cơ bản (rà 02/11/2026)

Nguồn: `logic/mixins/admin.js` (saVals_schools ~1700, saVals_riders ~1853, saVals_labels ~2224), `standalone-api.js` (CSV ~160,
riders ~104), `logic/mixins/school.js` (calendar ~1327, ayVals ~1483, ayDelVals ~1297, sessions ~2149, levels ~2809, baset ~924,
setup strip ~1999, aysum ~2993), `school-finance.js` calPageVals2 ~1431, `Convoy OS.dc.html` schoolDays ~18253. Tổng quan: `../school-bus/overview.md`.

## Làm
| Trang | Tính năng | Phase |
| --- | --- | --- |
| Schools | List (address, số dataset, Rider Data In Use theo ngày); New School (name, short, address, postal 6 số → OneMap, lưu lat / lng); record (header). Quyền `schools`; user không phải admin chỉ thấy trường của mình (`user_schools`) | 1 |
| Route Labels | AM / PM / CCA-ASA: prefix, start ≥ 0, digits 0–4, suffix; preview; lưu | 1 |
| Geocode | OneMap search theo postal ở server (cache bảng `postal_geocodes`), dùng cho school, rider, dataset | 1 |
| Rider Data | Dataset theo Effective From (file CSV / XLSX lưu CarrierWave): xem trước (số rider + lỗi từng dòng, cột tên linh hoạt như HTML), import, geocode nền (địa chỉ không tìm thấy = No Location), trạng thái In Use / Scheduled / Replaced, xoá | 2 |
| Riders | Danh sách theo ngày (dataset đang dùng + rider thêm tay, lọc start / end): chip All / AM / PM / CCA / Unlocated có số, search, phân trang; Add Rider (tên first / last + thứ tự, rider ID, gender, grade, address, postal, AM / PM / CCA days, start / end, parent, contact, remarks); Export CSV | 2 |
| Terms & Semesters | Năm học (key `2026` / `2026/27`, tháng bắt đầu, 12 tháng): New Academic Year (copy ngày chạy + cấu trúc từ năm khác hoặc trống), operating days, Semesters (2) / Terms (3 / 4), từng term start / end (trong năm, nối tiếp), CCA cùng ngày term hoặc kỳ riêng; số ngày học từng term / tổng; Save & Lock / Unlock; Delete Year (chưa bắt đầu, Admin; xoá cả dữ liệu theo năm) | 3 |
| Holidays & Special Days | Luôn sửa được: holidays (name, from, to), special days (date, type Early / Late Dismissal, Early / Late Arrival, Other, time, mô tả); import public holiday (bảng `public_holidays` có sẵn) trong năm, bỏ trùng; "N operating days off" | 4 |
| Scheduler | Run School Bus sinh theo lịch năm học (operating day, trong term, không holiday; chưa có năm học → T2–T6 trừ PH); Late Arrival / Early Dismissal dời giờ AM / PM như hiện tại; đổi lịch → sync run route của trường | 4 |
| School Levels | Theo trường: sections (Pre-school, Primary, Secondary, JC, International Grade / Year) chèn level mặc định; bảng level (thứ tự, tên unique, số rider, Final Level); gợi ý từ rider data; level lạ trong rider data; Save & Lock / Unlock | 5 |
| Bus Sessions | Theo năm học (cần lịch đã lock): To School / To Home / CCA-ASA; name, max journey, d2d / p2p, days (chỉ operating day), arrival from / to, dismissal, departure, variants theo ngày (không trùng ngày); copy từ năm khác; Save & Lock / Unlock | 5 |
| Bus Attendants | Theo trường: Statutory / All / Selected sizes (size theo luật luôn bật), provided by Operator / Us; số route cần BA (khi có Route Plans); Save & Lock. Bảng giá BA = Operator Pay (sub-menu 2) | 5 |
| Year Setup | Thanh bước (Levels, Terms, Sessions, Fares, Policy, Bus Attendants, Operator Pay, Holidays) + "n of 7 done"; Summary (bước chưa làm ở sub-menu 2 = chưa có) | 5 |

## Tự quyết (theo HTML / Rails)
- Lưu bảng PG thay blob `cfg`; lock = `setup_locks` (school, năm học hoặc không, section, at, by) — một chỗ cho mọi bước (sub-menu 2 dùng tiếp).
  Gõ AY key / "UNLOCK" để mở khoá là việc FE; server chặn sửa khi đang lock (422).
- Scope dữ liệu như HTML: theo năm học = lịch, holidays, special days, sessions (sau: fares, registration); theo trường = levels, labels, BA (sau: policy, operator pay).
- Rider thêm tay không thuộc dataset (như HTML), luôn có trong list theo start / end. Rider ID trống → `M-xxxx`.
- Geocode ở server (OneMap search công khai, không key) qua job; spec dùng fake. Holidays import từ `public_holidays` (không hard-code 2026).
- `schools.calendar_id` (Clients › School Calendar) giữ nguyên nhưng không còn dùng cho run School Bus.
- Không có Edit / Delete School (HTML không có).

## Không làm / để sau
- "How It Works", Year at a Glance, Week at a Glance, template CSV / XLSX: FE.
- Bảng giá BA, số route cần BA: cần Operator Pay (sub-menu 2) / Route Plans (sub-menu 4).
- Riders gắn family, rider events (dashboard): sub-menu 5 / 7.
