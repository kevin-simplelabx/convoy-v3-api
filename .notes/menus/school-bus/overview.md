# School Bus — tổng quan (rà 02/11/2026)

Menu rất lớn (~25 trang, logic `school.js`, `school-finance.js`, `vs-*.js`, `cca.js`, `requests.js`, `families.js`, `fam-inv.js`, `finance.js`,
engine `convoy-pathfinder-cf.js`). Chia 7 sub-menu, mỗi sub-menu một thư mục `menus/school-bus-<n>-<tên>/` (scope, plan, log).

| # | Sub-menu | Trang HTML |
| --- | --- | --- |
| 1 | Schools & Year Setup cơ bản | Schools (list, record: Riders, Rider Data, Route Labels), Terms & Semesters (năm học), Holidays & Special Days, Levels, Sessions, Bus Attendants, Year Setup Summary |
| 2 | Tiền của năm học | Bus Fares (+ Extra Charges, Route Charges), Payment & Refund Policy, Payment Methods, Operator Pay |
| 3 | Stops | Stop Library (+ requests, photo requests), Stop Assignment |
| 4 | Route Plans | Route Plans (routing qua service Node, sửa tay, adopt, version), Feasibility Studies |
| 5 | Phụ huynh | Families & Riders, Requests, Registration, CCA Rides ✅ (03/11/2026, `menus/school-bus-5-parents/`) |
| 6 | School Finance | Collections, Documents, Operator Payments (trường), Finance › School Bus Collections |
| 7 | Theo dõi | School Dashboard, Live Ops |

## Chốt với user (02/11/2026)
- Routing engine: **service Node** (engine JS của prototype, `node-app`), Rails gọi qua job nền và lưu input / kết quả.
- Lịch: **tách như HTML** — lịch năm học riêng của School Bus (terms, ngày chạy, CCA, holidays, special days); bộ sinh run School Bus
  (`Occurrences::RouteGenerator`) chuyển sang đọc lịch này thay Settings › Calendars. Trip thường / School Run vẫn dùng Calendars.
  HTML (`scheduler.js` `schTrips` + `schoolDays`): ngày chạy = operating day, trong term, không trong holidays; chưa có năm học → T2–T6 trừ PH.
- Thứ tự: 1 → 7. Chủ động chia nhiều phase khi lớn.

## Câu hỏi cần chốt khi tới từng sub-menu (từ đợt rà 02/11/2026)
- **2 (Tiền):** fares lưu bảng theo năm học (tiers km / zone, bySize, svc small / express, CCA, surcharges, one-way) + snapshot ngày học khi lock;
  Extra Charges không có ngày kết thúc kéo sang năm sau?; Policy có version theo ngày hiệu lực; late fee chỉ tính live (không thành chứng từ)?;
  cổng thanh toán (PayNow / Card) chưa có → chỉ cấu hình.
- **3 (Stops):** walking distance (130 m vs 400 m); ai được sửa điểm vật lý của stop dùng chung; "Keep for School" có cuối cùng không; photo request (crowdsource
  qua app) có làm không.
- **4 (Route Plans):** service Node (engine `convoy-pathfinder-cf.js` / `node-app`), OSRM self-host hay public; mô hình version plan (kết quả bất biến
  + lớp sửa tay, hay mỗi lần đổi một version); có bước duyệt trước Adopt?; Route Fit tự áp vào plan đang chạy hay chờ planner; params theo company / trường.
- **5 (Phụ huynh):** bộ trạng thái Request (code: Requested / Under Review / Accepted / Active=đã trả invoice đầu / Declined / Lapsed; requirements doc khác);
  first invoice là chứng từ thật hay thuộc tính request; auto-accept; một family / trường; CCA booking store bằng id thật; tin nhắn phụ huynh chỉ ghi lại.
- **6 (Finance trường):** đánh số chung company (Rails) thay vì theo trường; PV vs Payment Notice; maker-checker; credit dư (carry) bị mất; void chỉ receipt;
  auto-draft bằng job.
- **7 (Theo dõi):** Live Ops HTML toàn dữ liệu mẫu → làm từ run thật (như Live Map / Ops Control); absence (Bus Not Required) từ app phụ huynh.
