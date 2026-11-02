# Phase 7 — Points & Rewards (02/11/2026)

- Sổ điểm FIFO theo lô (user chốt): `driver_point_lots` (points, remaining, source manual / bonus, hết hạn +24 tháng, bonus + tháng nguồn),
  `driver_point_deductions` + `driver_point_allocations` (trừ từ lô hết hạn sớm nhất, khoá dòng). Check constraint remaining 0..points.
- `Pay::Points`: balance (remaining của lô chưa hết hạn), earned, used, expired (remaining của lô đã hết hạn), expiring_soon 60 ngày, history; award! / deduct!.
- Confirm Month: điểm của bonus paid_now → lô `bonus` gắn `driver_pay_month`. Reopen: xoá các lô đó, chặn nếu đã dùng.
- `pay_rewards` (CarrierWave `RewardPhotoUploader` ≤ 2 MB, 480 px; status active / inactive; discard). Chưa có redemption (driver app).
- Seed: 2 driver có điểm (1 đã trừ), 3 rewards. Spec `hr_points_rewards_spec.rb` (2).
