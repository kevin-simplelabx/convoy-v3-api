# Scope: School Bus 3 — Stop Library & Stop Assignment (rà 02/11/2026)

Nguồn: `logic/mixins/vs-stops.js` (links ~58–114, candidates ~717, validate / coverage ~900–950, save ~1250, photo requests ~211–507,
photo editor ~508–668, subzoneAt / nextId ~669–750, archive ~876), `logic/mixins/vs-map.js` (library / assign views ~1490–2200, nearby 600 m ~1995),
`logic/mixins/admin.js` (library requests ~2195–2222), `standalone-api.js` (visibility ~227). Library, Assign và Route Plans là một màn bản đồ 3 chế độ.

## Làm
| Phần | Tính năng | Phase |
| --- | --- | --- |
| URA subzones | Bảng `ura_subzones` (332 subzone URA MP2019, data.gov.sg, có mã) — Stop ID `<mã subzone>-NNNN` theo điểm primary, tính ở server | 1 |
| Stop Library | Stop dùng chung company: tên, PUDO points (chữ A–P, mô tả, Pick-up / Drop-off / Both, cỡ xe S / M / L ≥ 1, primary, lat / lng, Street View link), ảnh điểm (CarrierWave, gốc + bản hiển thị + annotations) ; kiểm tra (tên, ≥ 1 point, cỡ xe, có catchment thì cần cả pick-up và drop-off); bảng coverage + cảnh báo; search (tên, Stop ID, PUDO ID, ID cũ); Nearby 600 m; Archive (khi không trường nào dùng); sửa vị trí stop đang dùng bởi trường khác → cần xác nhận (danh sách trường + số rider) | 1 |
| Thư viện | libStatus approved / school / pending: stop tạo ngoài trang Library thuộc trường (school), hỏi đưa vào thư viện (quyền `library` → approved, không → pending + người / lúc yêu cầu); tab Requests: Approve / Keep for School; stop school / pending ẩn với trường khác | 2 |
| Catchment trường | Link / Unlink stop với trường (Add to School, Browse Library, Import from Another School có / không catchment); postal codes (6 số, báo mã sai / trùng / trùng stop khác), vùng vẽ (lasso / corners / land lots, exclude), tắt point theo trường (off) | 3 |
| Stop Assignment | Rider trên ngày: PUDO hợp lệ (catchment hoặc liên kết tay − point off − disconnect), trạng thái assigned / conflict / none, chip School Stops / Needs Attention, số rider có PUDO / > 1; Select Riders → liên kết tay (alternative) cho rider hoặc postal; Select Links → disconnect | 4 |
| Photo requests | Hỏi ảnh PUDO (parents / driver / both / một phụ huynh, tối đa 1–12), tự hỏi cho point chưa có ảnh (driver / parent), submission Accept (thành ảnh point + credit, giữ Street View) / Reject; ảnh từ app = seed | 5 |
| Seed | Stop thư viện cho St. Stephen's từ stop các route seed, catchment theo postal rider | 6 |

## Chốt với user (02/11/2026)
- Photo requests: làm phía admin + seed; endpoint gửi ảnh từ app làm cùng app.

## Tự quyết
- `ura_subzones` nạp từ GeoJSON chính thức (đơn giản hoá toạ độ) trong seed; point-in-polygon ở Ruby (không PostGIS).
- Vùng vẽ (polygon) = jsonb; postal codes = mảng (GIN). Điểm bị bỏ giữ lại (retired) để không dùng lại chữ cái.
- Quyền: xem = user mở được trường; sửa stop / catchment / liên kết = `plans`; duyệt thư viện = `library`.
- "Set as assigned", "Move All Riders Here", Notify, cờ plan Out of Date: cần Route Plans → sub-menu 4 (ghi `schools.stops_changed_at` để báo "Stops changed since routing").

## Không làm
- Convoy AI (script), undo / redo, collaborator presence, vẽ / trace land lot, editor mũi tên trên ảnh: FE.
