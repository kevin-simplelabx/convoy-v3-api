# Phase 5 — Change of Address / Service / Stop, plan versions, rider records (03/11/2026)

- Cột thêm trên `bus_requests`: effective_on (ngày chuyển / đổi), current_fare, old_address / old_postal, new_stop, agree (wait / yes / no),
  old_am / old_pm / old_cca, adds (svc thêm session → mid-year clock), last_on, stop_why (+ note), notice_n / unit, earliest_on, early,
  confirmed_at / by / note, pay_to, planned_at / planned_ok / plan_lines[], ended_on / at / by, rider_patched_on, level_moved_on.
  Status lưu thêm "Stopped" (adr dừng dịch vụ); Stopping quá last_on đọc là Stopped.
- `ConfirmChange` (adr: fare + điểm đón mới bắt buộc; svc: fare): giá cao hơn current_fare → Accepted + agree wait ("Waiting for Parent"), không thì
  Active + vào plan. Not Agreed: Change the Fare (= ConfirmChange), `NotAgreed` keep (Declined "Kept the old pick-up") / stop (Stopped, leave từ ngày chuyển).
  `Agree` (trả lời của phụ huynh — chỉ service, endpoint thuộc Convoy App). `ConfirmStop` (last day ≥ hôm nay; trước earliest → pay_to = earliest).
- **Plan versions** `Plans::ApplyChange` (port plan-changes.js): plan session đang dùng ngày đó bị tách (cũ kết thúc hôm trước; bản copy route / stop /
  rider / vehicle_changes / prices chạy từ ngày đó đến hết hạn cũ), mọi plan adopted sau đó cũng nhận thay đổi; join / move bằng Route Fit trên plan đó
  (fits: thêm vào stop; new: chèn stop mới, dời giờ trước / sau như HTML, sửa start / end route); drop / leave bỏ rider, stop rỗng bị xoá; không vừa →
  không đổi gì (rollback). Tên "<plan> · from dd/mm/yyyy · N changes"; `school_plan_changes` ghi lại; `Plans.resync` cho Scheduler.
  `BusRequests::PlanSync` (pcOf): new (không renewal) Active → join từ start; adr Active → move; adr Stopped → leave; svc Active → join / drop session
  khác; stop Stopping → leave từ hôm sau last day. Chạy ngay khi RecordPayment / ConfirmChange (không tăng giá) / Agree yes / ConfirmStop / NotAgreed stop,
  một lần (planned_at), dòng kết quả lưu + log.
- **End Rider** (`BusRequests.end_of`, rdEndOf): lapsed / withdrawn chưa trả (hôm qua), stop (last day), adr stopped (trước ngày chuyển), renewal declined khi
  năm mới bắt đầu; `EndRider` đặt rider.ends_on, log. Không tự động.
- `BusRequests::RiderSync` + `BusRequestsDailyJob` (12:30am): svc / adr Active tới ngày → sửa rider (am / pm / cca_days; address / postal / lat / lng) một lần;
  renewal Active khi tới start → grade = level mới.
- List tab adr / svc / stop có `change`, `status_label`, `end_action`; Check chạy Route Fit cho adr đang mở tại địa chỉ mới.
- API: `POST /bus_requests/:id/confirm_change|confirm_stop|not_agreed|end_rider`. Spec 1 (luồng đầy đủ). Seed: adr, adr chờ phụ huynh, svc, stop.
