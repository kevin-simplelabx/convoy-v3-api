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
| 31/10/2026 | fleet | Gửi SMS invite driver thật; Driver app nhận invite / accept / decline / chia sẻ KYC | Chưa có SMS / Driver app |
| 31/10/2026 | fleet | Connected Operators (công ty có tài khoản Convoy riêng, nhận trip) | HTML Coming Soon |
| 31/10/2026 | fleet | Log card "Get from Corppass" | HTML Coming Soon |
| 02/11/2026 | platform | Refresh token / gia hạn JWT; màn "thiết bị đang đăng nhập" + đăng xuất từ xa / tất cả (đọc `allowlisted_jwts`); xoá token khi đổi mật khẩu. | HTML không có màn (user chốt 02/11/2026 khi làm Settings); 30 ngày đủ cho giai đoạn test |
| 02/11/2026 | settings | Card On Time / Speed Limit trong Company Settings (cột đã có) | HTML không có, user chốt để sau |
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
| 02/11/2026 | finance | School Bus Collections (bill, receipt, DN / CN, waiver, policy), chứng từ trường trong Documents, pay run trường + maker-checker + PV, doanh thu "School Bus (auto)" của xe | Cần dữ liệu School Bus |
| 02/11/2026 | finance | Debit note / receipt cho client invoice; format file ngân hàng riêng (DBS IDEAL, UOB…); PDF server-side | Prototype không có / chưa cần |
| 02/11/2026 | finance | Lương driver trong P&L xe dùng số HR đã confirm thay cho ước tính scheme | User chọn giữ như prototype |
| 02/11/2026 | convoy-admin | Endpoint Convoy App: hiển thị Discover theo đối tượng / khu vực, đếm view / tap / sold, bán trip / đăng ký, gửi Company Lead | Làm cùng Convoy App |
| 02/11/2026 | live-map | Nút Check location sharing (hỏi thiết bị ngay), màn quản lý thiết bị (`tracking_devices`), endpoint ingest ping từ driver app / tracker (gọi `Telematics::Ping`) | Cần driver app / tracker thật |
| 02/11/2026 | live-map | ETA theo đường thật (routing) thay đường chim bay 30 km/h; tên đường (Road) hiện tại | Cần dịch vụ bản đồ |
| 02/11/2026 | live-map | Rain (radar + NEA forecast), Traffic (LTA Speed Bands) trên Live Map | Chưa có tích hợp (cùng dòng thời tiết / giao thông của Trips) |
| 02/11/2026 | ops-control | Gửi escalation thật tới Ops Manager (push / email / SMS); hiện chỉ ghi `escalated_at` | Chưa có kênh gửi |
| 02/11/2026 | ops-control | Endpoint driver app: đăng nhập (`driver_app_sessions`), Start / End (`Occurrences::DriverProgress`) | Làm cùng driver app |
| 02/11/2026 | ops-control | Banner Requests (đơn School Bus) trên Ops Control | Làm cùng School Bus |
| 02/11/2026 | school-bus-1 | Bảng giá BA (Their / Our BA) + số route cần BA; bước Fares / Policy / Operator Pay trong setup strip | School Bus 2 / 4 |
| 02/11/2026 | school-bus-1 | Rider gắn family, rider events (dashboard), sửa rider (updRider từ Requests) | School Bus 5 / 7 |
| 02/11/2026 | school-bus-2 | Route Charges (giá thêm theo run khi school pays per bus) | Cần Route Plans (School Bus 4) |
| 02/11/2026 | school-bus-2 | Gửi reminder theo policy, phí admin card / PayNow vào bill, cổng thanh toán | School Bus 6 / chưa có kênh / gateway |
| 02/11/2026 | school-bus-3 | Set as assigned, Move All Riders Here, Notify (gửi PUDO cho phụ huynh), đánh dấu plan Out of Date khi stop đổi | Cần Route Plans (School Bus 4) |
| 02/11/2026 | school-bus-3 | Endpoint Convoy App gửi ảnh PUDO (photo submissions) | Làm cùng Convoy App |
| 02/11/2026 | school-bus-4 | Self-host OSRM (bản đồ Geofabrik Malaysia–Singapore–Brunei, `osrm-backend`, công thức `node-app/deploy/osrm-setup.sh`) thay `router.project-osrm.org` | User chốt để sau khi scale (hiện 1 user) |
| 02/11/2026 | school-bus-4 | Feasibility: kéo stop giữa các route trên bản đồ (fzMove / fzUndo) | FE trước, lưu sau nếu cần |
| 02/11/2026 | school-bus-4 | AM plan adopt ngày tương lai: gán rider → PUDO ngay (HTML gán khi plan thành current) — chuyển sang job khi plan tới ngày nếu cần | Đơn giản hoá |
| 03/11/2026 | school-bus-5 | Endpoint Convoy App: gửi request (new / renewal / adr / svc / stop), rút, trả bill, đồng ý giá; tự auto-accept khi request tới (run arrive / daily, waitlist_auto); CCA Rides: đặt + trả, Not Riding, Same Days Every Week | Làm cùng Convoy App |
