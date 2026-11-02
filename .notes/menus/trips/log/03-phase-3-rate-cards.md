# Phase 3 — Rate Cards (30/10/2026)

- Migration `20261030160000`: bảng `rate_card_vehicle_types` (cột của card, position; backfill từ rates), `rate_cards.lock_version`,
  unique `(company_id, lower(name))`.
- Services: `RateCards::Form` (build cả card trong bộ nhớ từ params + luật của trang), `Save` (thay toàn bộ con; kiểm lock trước
  vì chỉ đổi con thì Rails không bump lock_version → luôn ghi card), `Check` (overlaps / gaps như `rcOverlaps` / `rcGaps`),
  `Standard` (card mẫu `rcStd`, dùng cho `GET /rate_cards/new` và seed), `ChangeState` (make_default / archive / unarchive).
- API: `GET/POST /rate_cards`, `GET /rate_cards/new`, `GET/PATCH /rate_cards/:id`, `POST /rate_cards/check`, `PATCH .../make_default|archive|unarchive`,
  `GET /rate_card_assignments`, `PATCH /rate_card_assignments/:client_id`.
- Show = đúng shape body save (Duplicate = GET → đổi tên → POST; HTML copy ở client nên không cần endpoint riêng).
- Khác HTML: không xoá card (HTML cũng không có); amounts luôn theo loại xe (bỏ dạng số chung của card cũ HTML);
  chọn card default cho client = xoá assignment (như HTML `rcAssign`); "Connected" clients chưa có → lọc theo `clients.kind`.
- Seed `35_rate_cards` viết lại bằng Standard + Save; thêm card archived "2025 Rates".
- Spec `rate_cards_spec.rb` (4). Tổng 164 specs.
