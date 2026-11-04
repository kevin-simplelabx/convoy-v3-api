# Client Portal — Invoices (read only)

For billing roles (`can.billing`: Super Admin, Admin, Finance Admin, Site Finance; else `403`). Paying online, statements
and PDFs are not built ("Pay by the details on each invoice").

`GET /portal/invoices?filter=all|not_paid|trips|school_bus&q=`

```json
{ "data": {
  "kpis": { "outstanding": { "amount": "6200.0", "count": 2 }, "overdue": { "amount": "4820.0", "count": 1 }, "invoices": 3 },
  "has_school_bus": true,
  "rows": [ { "kind": "trips", "id": 3, "number": "INV-2026-000004", "for": "Google Asia Pacific Pte. Ltd.", "site": null,
              "period": "1 Oct to 31 Oct 2026", "issued_on": "2026-11-01", "due_on": "2026-12-01", "total": "2760.0", "paid": "1380.0",
              "balance": "1380.0", "late_fee": "0.0", "status": "Part Paid" },
            { "kind": "school_bus", "id": 8, "number": "SB-SSS-T4-2026", "for": "St. Stephen's School", "site": "St. Stephen's School",
              "period": "Term 4 2026", "issued_on": "2026-09-25", "due_on": "2026-10-25", "total": "4820.0", "paid": "0.0",
              "balance": "4820.0", "late_fee": "20.0", "status": "Overdue" } ] } }
```

- `kind`: `trips` (trips and bookings: issued, not void; `for` = who it is billed to: the organisation or a site's own
  entity) or `school_bus` (bills the client pays as a school, with the late fee of the school's payment policy).
- Site Finance (and other site roles) see only their sites' own-entity invoices and their sites' schools' bills.
- `status`: Paid, Part Paid, Overdue, Due (School Bus also Credited). `paid` includes credit notes. `balance` = "To pay".
- KPIs (before the filter): Outstanding (sum of `balance`, count not fully paid), Overdue, Invoices (count).
- Filter pills All / Not Paid / Trips and Bookings / School Bus (show School Bus only when `has_school_bus`); `q` searches
  number, site, billed to and period. Newest first, up to 200 rows. Row: icon, number, "Trips and bookings | <for>" or
  "School Bus | <site>", period, Issued / Due (dd/mm/yyyy), amount, "To pay <balance>", status badge.
