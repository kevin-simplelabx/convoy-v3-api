# Scope: menu Finance (rail `fin`, icon `account_balance`), rà 02/11/2026

Chi tiết HTML từng trang (màn, chữ, công thức, dòng code): `inventory.md`. File này là quyết định làm gì.
Submenu: School Bus Collections, Client Invoices, Documents, Operator Payments, Vehicle Financials, Finance Settings.

## Quyền (theo HTML)
Xem: `finance` / `finview`; ghi: `finance`; Finance Settings: `finset`; Vehicle Financials: `vehfin`. Unlock: admin / `users`. Convoy Admin chỉ xem.
Operator Payments: chỉ approver trong Finance Settings mới approve / đặt ngày trả / ghi nhận thanh toán (khi có approver).

## Chốt với user (02/11/2026)
- Làm phần dữ liệu Rails có; **School Bus Collections**, chứng từ School Bus (INV / CN / DN / RCP / PV của school), route pay theo trường của
  Operator Payments, doanh thu "School Bus (auto)" của xe → làm cùng menu School Bus (backlog).
- **Một hệ đánh số**: mỗi loại INV, CN, DN, RCP, PV, PN, PB một bộ đếm / năm (`CompanySequence`), `PREFIX-YYYY-000001`; prefix ở Finance Settings, không trùng nhau.
- Client Invoices tính run như prototype; huỷ trong cut-off (24 h mặc định) tính đủ tiền **chỉ khi `cancelled_by_client`**.
- Lương driver trong P&L xe **như prototype**: mô phỏng pay scheme (lương cố định + top-up, không trip) × tỉ lệ ngày driver là default driver của xe, + CPF employer.

## Tự quyết
- PDF / in: FE in từ dữ liệu (như prototype), không thêm gem PDF. Email chứng từ: chỉ ghi lại (chưa có SMTP).
- Documents: gồm cả client invoice + credit note + payment notice (một kho chứng từ).
- Maker-checker giữ như prototype: chỉ áp cho pay run trường (School Bus); trang Operator Payments chỉ cần là approver.
- GST snapshot trên mỗi chứng từ lúc tạo draft; P&L tính live (không snapshot).
- Bank file: CSV chung như prototype (chưa theo format riêng từng ngân hàng).

## Không làm (backlog)
School Bus Collections + chứng từ trường, pay run theo trường + PV, doanh thu School Bus của xe, Connected Clients, gửi email thật,
format file ngân hàng riêng, Debit Note / Receipt cho client invoice (prototype không có).
