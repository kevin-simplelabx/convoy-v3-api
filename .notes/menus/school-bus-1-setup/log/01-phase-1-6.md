# Phase 1–6 — School Bus 1: Schools & Year Setup (02/11/2026)

- P1: `schools.postal`, `school_route_labels`, `postal_geocodes` + `Geo::OneMap` (Faraday, spec `FakeOneMap`); `SchoolPolicy` scope `user_schools`; list / create / show / route labels.
- P2: `rider_datasets` (CarrierWave) + `school_riders`; `SchoolRiders::FileReader` (roo), Import + `SchoolRidersLocateJob`, Add Rider, list theo ngày + counts, export CSV.
- P3: `academic_years`, `academic_terms` (CCA trong term), `setup_locks` + `SchoolSetup` (lock / unlock / guard); Create (copy cấu trúc), Save Calendar (rules → lock), Unlock, Delete Year.
- P4: holidays / special days (thay cả list), public holidays để import; `RouteGenerator` theo lịch năm học (bỏ dời giờ special day, như HTML); spec route cũ cập nhật; seed `48_school_setup`.
- P5: `school_levels` (gợi ý từ rider data), `bus_sessions` + variants (cần calendar lock, copy từ năm khác), `school_attendant_policies`, `GET /academic_years/:id/setup`.
- P6: doc `.api-documents/school-bus-setup.md`, README / integration / screen-map / OpenAPI (folder School Bus). Spec mới 15 (tổng 321).
- Ngoài lề: sửa `Occurrences::Verify` (ReplacementIndex dùng chung) — trước đó báo lệch giả TID100036 / 37.
