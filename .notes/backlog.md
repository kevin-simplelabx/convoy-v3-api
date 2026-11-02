# Backlog — việc đã hoãn

Việc biết là cần nhưng chưa làm. Ghi: ngày · menu phát hiện · việc · lý do hoãn. Làm xong thì xoá dòng (ghi lại trong `log/` của phase đó).

| Ngày | Menu | Việc | Vì sao hoãn |
| --- | --- | --- | --- |
| 30/10/2026 | scheduler | Gửi thật notify của replacement (email / push) và notice (push / sms); hiện chỉ ghi lại | Chưa có app / kênh gửi |
| 30/10/2026 | scheduler | WhatsApp, Client Portal làm kênh notify / notice | Chưa có tích hợp |
| 30/10/2026 | scheduler | Driver app auth (token) | Chưa tới driver app |
| 30/10/2026 | scheduler | Inspection (empty slot menu "coming soon") | HTML chưa có |
| 30/10/2026 | scheduler | Bulk actions trên nhiều run (`POST /occurrences/bulk`) | HTML chưa có |
| 31/10/2026 | trips | Correct Record chưa đổi pay / invoice (driver / xe đã sửa, run Incomplete) | Chưa làm màn Pay / Invoice |
| 30/10/2026 | scheduler | Trả `conflicts` khi assignment / replacement mới phủ lên run đã sửa tay (hiện sửa tay luôn thắng) | HTML không hỏi |
| 30/10/2026 | scheduler | Kiểm postal code với OneMap ở server (hiện FE làm) | FE đang có sẵn |
| 30/10/2026 | scheduler | Màn sửa cho dữ liệu `seed` — xem cột "Màn sửa sẽ ở" trong `data-ownership.md` | Theo scope rule |
| 30/10/2026 | scheduler | Storage file lên S3 (fog) cho production | Dev dùng file |
| 30/10/2026 | scheduler | Read replica cho driver app / report | Khi có tải thật |
| 30/10/2026 | trips | Thời tiết / giao thông trong Trip History (NEA, LTA DataMall) | Chưa có tích hợp, HTML dùng sample |
| 30/10/2026 | trips | Endpoint ingest GPS / stop events / driver report | Làm cùng driver app |
| 30/10/2026 | trips | Endpoint Client Portal / Convoy App cho booking (đặt, duyệt, xác nhận, xin huỷ) | Làm cùng Portal |
| 30/10/2026 | trips | Gửi email thật cho thông báo booking | Chưa cấu hình mail |
| 30/10/2026 | trips | Client approval nhiều bước (approvers theo site, steps) của Client Portal; hiện chỉ ghi kết quả done / declined | Thuộc Client Portal |
| 31/10/2026 | trips | Giữ GPS bao lâu (xoá / gộp partition `occurrence_positions` cũ) | Chưa có số liệu thật |
| 31/10/2026 | trips | Passenger list của run School Bus trong Trip History (rider hiện chỉ là riders_count) | Rider theo tên thuộc menu School |
| 31/10/2026 | trips | Tên đường cho replay (map matching / reverse geocode) | Cần dịch vụ bản đồ |
| 30/10/2026 | trips | Chạy `bin/rails occurrences:sync` sau deploy để các trip cũ có row skipped quá khứ (backfill 400 ngày) | Việc vận hành khi lên production |
| 31/10/2026 | fleet | **Vehicle Financials** (menu Finance, mở từ record xe): mua xe + khoản vay, lịch trả góp (`logic/vehicle-loan.js`), đọc PDF lịch trả góp bằng Claude + dialog plate không khớp, trạng thái (No Details / Paid in Full / Incomplete / Overdue / Loan Paid Off / Loan Active), P&L tháng (doanh thu run + School Bus route, chi phí tay, lương driver theo pay scheme, khấu hao, lãi, trả góp; basis profit / cash), biểu đồ P&L, break-even, khoản đến hạn 90 ngày (trả góp, renew insurance, road tax, COE), cost/km theo size, lợi nhuận theo xe, cost spikes, đoạn tóm tắt; tóm tắt `vfMini` trên record xe. Nguồn: `fleet.js` vf* (dòng 56–1410), HTML `sa.isVehFin` ~12163. Dữ liệu chi phí có sẵn để dùng: fuel_entries, maintenance_visits, insurance premium | Thuộc Finance, cần HR pay |
| 31/10/2026 | fleet | Gửi SMS invite driver thật; Driver app nhận invite / accept / decline / chia sẻ KYC | Chưa có SMS / Driver app |
| 31/10/2026 | fleet | Connected Operators (công ty có tài khoản Convoy riêng, nhận trip) | HTML Coming Soon |
| 31/10/2026 | fleet | Log card "Get from Corppass" | HTML Coming Soon |
| 02/11/2026 | platform | Refresh token / gia hạn JWT; màn "thiết bị đang đăng nhập" + đăng xuất từ xa / tất cả (đọc `allowlisted_jwts`); xoá token khi đổi mật khẩu. | HTML không có màn (user chốt 02/11/2026 khi làm Settings); 30 ngày đủ cho giai đoạn test |
| 02/11/2026 | settings | Card On Time / Speed Limit trong Company Settings (cột đã có) | HTML không có, user chốt để sau |
| 02/11/2026 | settings | Cảnh báo maker-checker khi chỉ còn 1 user active (trang Users) | Cần Finance Settings |
| 02/11/2026 | settings | Áp `user_schools` vào dữ liệu School Bus | Làm cùng menu School Bus |
| 02/11/2026 | clients | Connected Clients | HTML Coming Soon |
| 02/11/2026 | clients | Client Portal API sau đăng nhập (booking, approval, invoice, live map, quản lý người từ Portal theo `userCan` / `rolesToGive`) | Làm cùng Client Portal |
| 02/11/2026 | clients | Cấu hình SMTP thật cho `PortalMailer` (bỏ `PORTAL_SHOW_CODE` ở staging) | Chưa có dịch vụ mail |
| 02/11/2026 | hr | Rejection count, OTP %, attendance % thật → rejection penalty và bonus OTP / Attendance trong Earnings | Cần driver app / dữ liệu |
| 02/11/2026 | hr | Bonus quarterly / half-yearly / yearly, trả trễ X tháng, chia đợt; Excluded Days | Chưa có kỳ lương nhiều tháng |
| 02/11/2026 | hr | Driver app: sign-up bonus, đổi reward (redemption trừ điểm), xem statement | Chưa có driver app |
| 02/11/2026 | hr | Payroll: payslip, CPF, allowances / deductions, export ngân hàng, maker-checker lương driver | HTML không có trong HR |
| 02/11/2026 | hr | Shift qua nửa đêm; tuần lẻ đầu / cuối tháng cho weekly target (giữ như HTML) | Cần quyết định nghiệp vụ |
| 02/11/2026 | hr | Version scheme / rate plan (đổi rate ảnh hưởng tháng chưa confirm) | HTML không có |
