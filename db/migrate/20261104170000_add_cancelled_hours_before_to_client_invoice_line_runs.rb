# Late cancellation runs on an invoice: how many hours before the start the client cancelled ("cancelled 3 h before"),
# kept with the run like its label and start time.
class AddCancelledHoursBeforeToClientInvoiceLineRuns < ActiveRecord::Migration[8.1]
  def up
    add_column :client_invoice_line_runs, :cancelled_hours_before, :integer

    # safety_assured: one-off backfill of a new column on a small table (late cancellations of draft / issued invoices).
    safety_assured do
      execute <<~SQL.squish
        UPDATE client_invoice_line_runs r
        SET cancelled_hours_before = GREATEST(0, ROUND(EXTRACT(EPOCH FROM (o.starts_at - o.cancelled_at)) / 3600))
        FROM client_invoice_lines l, trip_occurrences o
        WHERE l.id = r.client_invoice_line_id AND l.source = 'late_cancel'
          AND o.id = r.occurrence_id AND o.date = r.occurrence_date AND o.cancelled_at IS NOT NULL
      SQL
    end
  end

  def down
    remove_column :client_invoice_line_runs, :cancelled_hours_before
  end
end
