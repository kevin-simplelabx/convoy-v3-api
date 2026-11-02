# Fix — `insurance` luôn là object trên vehicle (02/11/2026)

FE báo: `GET /vehicles`, `GET /vehicles/:id` trả `"insurance": null` cho xe không có policy current, trái với `fleet.md` § 1.1
(`status: "none"`). Đúng: `VehicleDecorator#insurance_summary` trả `nil` khi không có `current_insurance_policy`;
`"none"` chỉ ra khi policy có nhưng thiếu `ends_on`. HTML (`logic/mixins/fleet.js` `vInsTxt`): không có `insTo` → không hiện dòng bảo hiểm.

- `insurance_summary` luôn trả `{ insurer, ends_on, status }`; không có policy → `{ insurer: nil, ends_on: nil, status: "none" }`.
- Spec: `vehicle_documents_spec` (list + show, không policy).
- Doc: `fleet.md` § 1.1 ghi rõ trường hợp `none`; sinh lại `convoy-v3-api.openapi.json` (`api_docs:all`).
