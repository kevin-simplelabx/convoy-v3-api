# Decisions

Mọi quyết định đã chốt với user. Thêm dòng mới ở cuối; quyết định bị thay thì ghi dòng mới và gạch dòng cũ (~~...~~), không xoá.
`Menu` = menu đang làm lúc chốt (`all` = áp dụng chung).

| Ngày | Menu | Quyết định |
| --- | --- | --- |
| 30/10/2026 | scheduler | Viết lại convoy-v3-api từ đầu cho Scheduler (bỏ migrations/models/controllers/blueprints cũ; giữ Gemfile, config, Devise). |
| 30/10/2026 | scheduler | Stack: Rails API, PG, Devise, Draper (decorator), Blueprinter (views), CarrierWave (mọi upload, không URL/data URL). |
| 30/10/2026 | scheduler | Scope: mọi thứ Scheduler dùng — gồm School Run, School Bus routes trên grid, AI (Fill from Message, Route List Import) gọi Claude từ Rails, Maintenance, Notices. |
| 30/10/2026 | scheduler | Occurrence storage: **B — Materialize** (`trip_occurrences`, partition theo tháng, horizon ~~90~~ 120 ngày). Hiện trạng: domains/occurrences.md. |
| 30/10/2026 | scheduler | Không dùng pg_partman: job tự tạo partition. |
| 30/10/2026 | scheduler | Lịch sử thay đổi: **audited**. Gems chốt: acts_as_tenant, pundit, pagy, ransack, audited, rspec-rails, factory_bot_rails, faker. |
| 30/10/2026 | scheduler | Gems thêm: discard, strong_migrations, oj, annotaterb, bullet, shoulda-matchers. Audits jsonb. JSON key snake_case. Giờ trong ngày lưu phút, API dùng "HH:MM". |
| 30/10/2026 | scheduler | Phase 1 chỉ làm phần Fleet/Clients mà Scheduler dùng; log card, insurance, financials, share form, KYC để cho các page khác. |
| 30/10/2026 | scheduler | Scope rule: tính năng mở / dùng được từ Scheduler thì làm hết, không có thì chưa làm (chi tiết menus/scheduler/scope.md). Thêm Phase 1b (form xe: log card, insurance), 2b (Fill from Message), 9 (School Bus routes trên grid). |
| 30/10/2026 | scheduler | Gems: anthropic, roo. Mọi việc đọc bằng Claude đi qua `document_reads` + job nền + poll; kết quả AI lưu jsonb (bản chụp, không query). Model claude-opus-5-5, structured outputs, server-side fallback. |
| 30/10/2026 | scheduler | Renew Policy: policy mới mang sẵn insurer, agent, HP, cover, starts_on = ngày sau hết hạn cũ (user đồng ý, không tạo policy trống). ANTHROPIC_API_KEY: user thêm sau. |
| 30/10/2026 | scheduler | Shuttle chỉ dùng price table (bỏ field legacy của HTML); đổi dạng bảng giữ tổng làm ở FE. Run times gửi theo thứ tự đi của direction. |
| 30/10/2026 | scheduler | trip_occurrences: PK (id, date), partition tháng tạo lúc chạy, schema = structure.sql. Every Run From Today = trip_time_changes (không tách series). Lịch sử run = audits. |
| 30/10/2026 | scheduler | Assignment dùng cho mọi loại trip (không chỉ shuttle); kéo From This Date On = assignment (không tách series). Không làm swap trip (HTML không có). |
| 30/10/2026 | scheduler | Replacement trỏ run bằng identity (không FK partition). Replace Driver tạm = replacement drv. Generator áp đủ layer 1–4 (nhận row đang lưu); Sync chỉ so digest. Notify chỉ ghi lại. |
| 30/10/2026 | scheduler | Run của School Bus route nằm chung trip_occurrences (school_route_id, trip/client nullable, identity 6 phần). |
| 30/10/2026 | scheduler | Phase 10 không sửa FE; thay bằng tài liệu API cho FE trong `.api-documents/` (English, Markdown, mỗi menu 1 file). |
| 30/10/2026 | all | Tổ chức `.notes`: `domains/` = tài liệu sống (luôn đúng hiện trạng), `menus/<menu>/` = scope + plan + `log/` (nhật ký phase, không sửa lại), `decisions.md`, `backlog.md`, `data-ownership.md`. |
| ~~30/10/2026~~ | ~~scheduler~~ | ~~User không thao tác run quá 90 ngày (horizon). `GET /occurrences` chỉ đọc bảng, không gộp run virtual; horizon giữ 90 ngày.~~ (thay bởi dòng dưới) |
| 30/10/2026 | scheduler | **Bỏ hẳn run virtual** (không materialize, không `POST /occurrences`), **horizon 120 ngày**. User không xem / thao tác run sau horizon; thay đổi tương lai là rule, áp khi daily job thêm ngày. Lý do: giữ logic đơn giản (replacement driver... không phình). |
| 30/10/2026 | trips | Menu Trips gồm Trips, Trip History, Notices, Bookings, Rate Cards (scope: `menus/trips/scope.md`). |
| 30/10/2026 | trips | Trip History telematics: làm bảng (GPS partition tháng, stop events, summary) + seed; endpoint ingest làm cùng driver app; thời tiết / giao thông backlog. |
| 30/10/2026 | trips | Ngày lịch bỏ qua lưu row `trip_occurrences.status = skipped` (để query / thống kê); Scheduler, invoice, pay lọc bỏ. |
| 30/10/2026 | trips | Bookings: đủ backend gồm client approval + yêu cầu huỷ; admin ghi thay phía client (kèm cách xác nhận); endpoint Portal làm sau. |
| 30/10/2026 | trips | Chuông thông báo booking + preference theo user; email chỉ ghi lại. |
| 30/10/2026 | trips | Gem `aasm` cho trạng thái trip của booking. Không dùng pg_trgm (search ILIKE; tối ưu khi chậm). |
| 31/10/2026 | fleet | Menu Fleet gồm Fleet (Vehicles, Drivers, Bus Attendants, External Vehicles, Fuel & Energy, Maintenance, Vehicle Types) + Transport Operators (Managed Operators, Operator Vehicles, Operator Drivers); Connected Operators bỏ (Coming Soon). Scope: `menus/fleet/scope.md`. |
| 31/10/2026 | fleet | Vehicle Financials để cho menu Finance; record xe trả `financials: null`. Phần còn thiếu ghi ở backlog. |
| 31/10/2026 | fleet | Invite driver / operator driver: admin ghi thay Accept / Decline (như Bookings); SMS chỉ ghi lại; KYC bảng `driver_kyc_profiles` chỉ seed (Driver app ghi sau), NRIC mã hoá bằng Active Record Encryption. |
| 31/10/2026 | fleet | Gems: `groupdate` (biểu đồ Fuel, chi tiêu Maintenance), `phonelib` (chuẩn hoá + chống trùng số mobile). |
| 31/10/2026 | fleet | Xoá xe (`Vehicles::Remove`) chặn khi còn run chưa kết thúc / maintenance đã lên lịch từ hôm nay (HTML xoá luôn) — không để run trỏ xe đã xoá. |
| 31/10/2026 | fleet | Accept driver (admin ghi thay) không sinh KYC giả; KYC null tới khi Driver app chia sẻ. Xoá driver = discard (giữ lịch sử run). |
| 31/10/2026 | fleet | Ngân hàng SG thành bảng platform `banks` / `bank_branches` (seed từ `sg-banks.js`); operator lưu `bank_id`, branch do server tính. |
| 31/10/2026 | fleet | Share Form public throttle bằng rack-attack có sẵn (10 / giờ / IP) thay vì `rate_limit`. |
| 31/10/2026 | fleet | Fuel: số tính được (km, hiệu suất, driver của ngày) lưu cột trên `fuel_entries`; Needs a Look lưu bảng `fuel_alerts` (query / thống kê, giữ Checked). Thống kê theo kỳ dùng groupdate. |
