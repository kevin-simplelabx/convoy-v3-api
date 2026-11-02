# Scope: menu HR (rail `pay`, icon `badge`), rà 02/11/2026

Chi tiết đầy đủ từng trang (màn hình, chữ, validation, công thức, dòng code): `inventory.md` (rà bằng agent từ `Convoy OS.dc.html`,
`logic/mixins/pay.js`, `driver-pay.js`, `param-explainers-hr.js`). File này là quyết định làm gì.
Submenu: Drivers, Earnings, Pay Schemes, Rate Plans, Bonuses, Points, Rewards, Salary Simulator, Audit Log.

## Quyền (theo HTML)
- Xem HR: `finance` hoặc `finview` (admin / owner luôn có). Ghi: `finance`. Unlock (rate plan / scheme / bonus) và Reopen Month: admin / owner hoặc quyền `users`.
- Convoy Admin chỉ xem.

## Chốt với user (02/11/2026)
- Đổi scheme / loại xe giữa tháng: **chia tháng theo đoạn**, lương cố định (basic, monthly, shift, guarantee, route retainer) chia theo ngày lịch; áp cả driver vào / nghỉ giữa tháng.
- Bonus **Trip Target** (daily / weekly / monthly, payout end of period / next payroll) tính thật trong Earnings; điểm thưởng của bonus vào sổ điểm khi confirm tháng.
- Audit Log đọc từ bảng `audits` (audited), hành động đặc biệt ghi `comment`.
- Points: sổ FIFO theo lô (hết hạn 24 tháng, trừ từ lô cũ nhất).

## Tự quyết (theo dữ liệu Rails có sẵn)
- Driver = bảng `drivers` (own drivers), không theo tên; operator driver không có trong HR (operator trả).
- Trip value lấy `trip_occurrences.trip_value` (đã gồm per-run, chiều về, shuttle chia theo ngày, handover split của replacement).
  Job tính theo giờ: kind `disposal` hoặc trip `trip_value_mode = hours` (giờ = end − start, làm tròn 0.25 theo `trip_value_rounding`).
- Run được trả: `completed` (hoặc đã qua giờ kết thúc, không cancelled / removed / skipped) và **không có issue**. Issue = `issue_raised_at` có sẵn.
- Confirm tháng: snapshot vào bảng (tổng + dòng breakdown + từng run và tiền của run). Đã confirm thì không raise / clear issue các run tháng đó.
- Scheme / rate plan không có version: tháng chưa confirm luôn theo cấu hình hiện tại (giống HTML); tháng đã confirm giữ snapshot.
- Simulator: tính server-side bằng cùng engine, không ghi dữ liệu thật; template dùng chung (5 ô) lưu bảng, jobs của tháng mẫu để jsonb (bản chụp ít dùng).

## Không làm (backlog)
- Rejection count, OTP %, Attendance % thật (chưa có driver app / dữ liệu) → penalty và bonus OTP / Attendance chỉ trong simulator.
- Bonus quarterly / half-yearly / yearly, trả trễ X tháng, chia đợt; excluded attendance days.
- Driver sign-up bonus trong app, đổi reward (redemption), driver app xem statement.
- Payroll thật: payslip, CPF, allowances / deductions, export ngân hàng, maker-checker cho lương driver.
- Ca đêm qua nửa đêm của Shift; tuần lẻ đầu / cuối tháng (giữ như HTML, ghi lại).
