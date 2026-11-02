# Phase 3 — Client Invoices: tiền + báo cáo (02/11/2026)

- `ClientInvoices::Money`: pay! (≤ balance, method trong list), credit! (credit note = `client_invoices` kind credit_note, số CN, không GST),
  send! (ghi `client_invoice_sends`, mặc định To / CC từ billing people của entity).
- `ClientInvoices::Report`: KPIs (owed, overdue, invoiced, collected tháng), aging 5 bucket theo ngày quá hạn, clients (balance theo entity),
  statement (invoice / payment / credit note, running balance + aging). Collected lọc theo company qua join invoice (payments không có company_id).
- Seed: hóa đơn issued trả một nửa + ghi đã gửi. Spec thêm 1 (tổng 4).
