# Phase 2 — Drivers & Operator Drivers (31/10/2026)

- Gems `phonelib` (initializer default SG) + `groupdate` (dùng ở Phase 6, 8). Mobile lưu E.164, `phone_display` dạng quốc tế.
- Migration: drivers + operator_drivers thêm `last_vehicle_id`, `display_name`, `display_photo` (CarrierWave), `display_set_by_id`,
  `display_set_at`, `discarded_at`; unique `(company_id, phone)` thành partial `status IN (pending, active) AND discarded_at IS NULL`.
  Bảng `driver_invites` (polymorphic, kind invite / resend, message, delivery `recorded`), `driver_kyc_profiles` (polymorphic 1–1,
  `id_number` **encrypts** + `id_number_masked`). Khoá AR Encryption thêm vào `config/credentials.yml.enc`.
- Concern `InvitedDriver` (model): aasm trên enum status (accept, decline, remove, reinvite), phone unique khi live, khoá mobile khi
  không còn pending, `set_display!`, `record_invite!`. Concern `DriverInviteActions` (controller) dùng chung 2 controller.
- `Drivers::Invite`, `Drivers::Act` (resend, accept, decline, reinvite, remove, delete), `Drivers::InviteMessage`.
  Remove own driver: entry schedule `driver nil` từ hôm nay trên xe đang lái + các entry tương lai của driver → nil.
  Delete = discard (giữ lịch sử run). Khác HTML: Accept **không** sinh KYC giả (HTML tạo demo) — KYC null tới khi app chia sẻ.
- Index mặc định tab `active` (trước đây trả mọi status khi không có `status`), `meta.counts` đủ 4 tab.
- `OperatorDriver`: đổi operator → rời xe của operator cũ (chỉ khi record đã lưu).
- Action `display` trùng `Kernel#display` → route `PATCH :id/display` trỏ `set_display`.
- Seed `32_drivers`: past driver, operator driver pending, invites, KYC cho driver active (1 BDVL hết hạn, 1 sắp hết), display cho Eric.
- Spec `fleet_drivers_spec.rb` (6). Tổng 195 specs.
