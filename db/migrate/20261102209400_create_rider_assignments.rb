# School Bus › Stop Assignment: the PUDO point each rider is assigned to — written from the AM plan when it is adopted,
# or set by hand (Set as assigned, Move All Riders Here) — and when parents were told (Notify; sending comes later).
class CreateRiderAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :rider_assignments do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.string :rid, null: false
      t.references :stop_point, null: false, foreign_key: { on_delete: :cascade }
      t.references :school_plan, foreign_key: { on_delete: :nullify }
      t.boolean :manual, null: false, default: false
      t.timestamptz :notified_at
      t.timestamps
    end
    add_index :rider_assignments, %i[school_id rid], unique: true
  end
end
