# Phase 1–6 — School Bus 3: Stop Library & Stop Assignment (02/11/2026)

- P1: `ura_subzones` (data.gov.sg MP2019, 332, simplified) + seed; `stops`, `stop_points`; `Stops::Save` (luật editor, code theo subzone, chữ retired, confirm_required khi stop dùng chung); coverage, search, nearby 600 m, archive; ảnh point.
- P2: library_status approved / school / pending, `Stops::Library` ask / review, `GET /stops/requests`, ẩn với trường khác.
- P3: `school_stops` (postal codes + invalid + shared, areas + exclude, off points), import từ trường khác, unlink.
- P4: `SchoolStops::Assignment` (candidates, status, counts), `rider_point_links` alternative / disconnected.
- P5: `stop_photo_requests` + submissions, accept (ảnh thành ảnh point, credit, Street View) / reject / close, auto driver / parent.
- P6: seed `52_school_stops`, doc `.api-documents/school-bus-stops.md`, index + OpenAPI. Spec mới: stops (2), assignment (2), photos (2).
