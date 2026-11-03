# First invoices and CCA bills recorded their payment on the bill (paid_at, method, recorded_by); payments now live in
# school_bill_payments, so copy them over, mark every numbered bill issued, and drop the old columns.
class MoveSchoolBillPayments < ActiveRecord::Migration[8.1]
  def up
    # Safe: a data copy on small School Bus tables (first invoices and CCA bills only), no locks held for long.
    safety_assured { copy_payments }
    change_column_default :school_bills, :status, from: "open", to: "draft"
    # Safe: nothing reads these columns after this change and School Finance has not been deployed yet.
    safety_assured { remove_column :school_bills, :paid_at }
    safety_assured { remove_column :school_bills, :method }
    safety_assured { remove_reference :school_bills, :recorded_by, foreign_key: { to_table: :users }, index: false }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def copy_payments
    execute <<~SQL.squish
      INSERT INTO school_bill_payments (school_bill_id, paid_on, amount, method, source, recorded_by_id, created_at, updated_at)
      SELECT id, (paid_at AT TIME ZONE 'Asia/Singapore')::date, total, method, CASE WHEN kind = 'cca' THEN 'app' ELSE 'console' END,
             recorded_by_id, paid_at, paid_at
      FROM school_bills WHERE status = 'paid' AND paid_at IS NOT NULL
    SQL
    execute "UPDATE school_bills SET status = 'issued', issued_at = created_at, due_on = COALESCE((due_at AT TIME ZONE 'Asia/Singapore')::date, issued_on)"
  end
end
