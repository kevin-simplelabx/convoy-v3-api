# Scope: School Bus 5 — Families & Riders, Requests, Registration, CCA Rides (rà 02/11/2026)

Nguồn: `logic/mixins/school.js` (families 2325–2679, REGMSG ~2681, regDef ~2944, regVals ~3144, requests 3321–4948: appAY, reqTabVals 4394,
accept 4515, reqLink 4299, planSync 3801, rfOf / rfCk 3657–3776, mid-year 3883–4094, reqBellVals 3952, rqs ~3980), `logic/requests.js` (trạng thái,
lapse, fareFrom, firstInv, mid-year clock / ack / moveAns, endOf, riderPatch, needs, regWin), `logic/route-fit.js`, `logic/plan-changes.js`,
`logic/families.js`, `logic/cca.js` + `logic/mixins/cca.js`, `Bus Service Applications - Requirements.md`. Báo cáo rà: hội thoại 02/11/2026.

## Chốt với user (02/11/2026)
- First invoice = chứng từ thật (bill gia đình: INV theo bộ đếm company, GST, thanh toán) — bảng bill tối thiểu ở đây, sub-menu 6 dùng tiếp.
- Active / Stopping tự sửa route plan như HTML: version mới từ ngày hiệu lực (Route Fit, không chạy lại routing).

## Tự quyết
- Trạng thái theo code HTML: Requested, Under Review, Accepted, Active, Waitlisted, Declined, Lapsed (tính, không lưu), Withdrawn, Not Agreed,
  Stopping, Stopped (tính). Service check = Route Fit (bỏ appChecks cũ). Tin nhắn phụ huynh / email 08:00 chỉ ghi lại.
- Request từ Convoy App chưa có → seed; console tạo được "Add Application" thay phụ huynh. Một rider thuộc một family / trường (như HTML).
- Rider rời danh sách luôn bằng một click (không tự động); rider patch (đổi địa chỉ / dịch vụ) áp khi tới ngày (job hằng ngày).

## Phase (plan.md)
1 Families · 2 Registration settings · 3 Requests (list, tabs, detail, add, ack / move date, waitlist / decline, message) · 4 Accept + first invoice +
Route Fit + auto-accept · 5 Change of address / service / stop + rider patch + plan versions · 6 CCA Rides · 7 Thông báo (bell, rqs, email 08:00),
seed · 8 Docs, kiểm tra.

## Không làm
- Fees của family (Coming Soon trong HTML) → sub-menu 6. Emergency / billing contact (requirements, UI không có). Gửi tin thật. Endpoint Convoy App.
