# Phase 11 — Horizon 120 ngày, bỏ run virtual ✅ (30/10/2026)

User: logic gộp run lưu + run virtual sẽ phình (replacement driver...), user không thao tác quá horizon → bỏ virtual, tăng 90 → 120.

## Đổi
- `Sync::HORIZON_DAYS = 120`. Bỏ `beyond_horizon` và nhánh "row lưu trước sau horizon" trong `Sync#write`
  (nhánh đó còn làm sync 1 ngày — kéo thả one, Back to Regular Bus — tính lại tới tận horizon; giờ chỉ đúng khoảng được gọi).
- Xoá `Occurrences::Materialize`, `POST /occurrences`, field `virtual`, `TripOccurrence#virtual?`; `OccurrenceWindow` chỉ đọc bảng.
- `Members.on_date` không tạo row thiếu nữa (bỏ qua).
- **Lỗi có từ trước:** daily job chỉ sync trip lặp lại → trip một lần đặt xa hơn horizon không bao giờ có row (virtual che mất).
  Sửa: sync mọi trip `active_between` ngày horizon.

## Spec
Bỏ spec virtual / materialize; thêm: không lưu gì sau horizon, rồi trip một lần + assignment đặt sau horizon được áp khi daily job chạy tới (154).
Dev: 2.281 run (SD), verify all match.

## Doc FE
README "Runs" (horizon 120, không xem quá horizon, thay đổi tương lai là rule), scheduler.md (bỏ virtual, 5.1 materialize; ghi chú
assignment `effective_from` và replacement preview `affected`).
