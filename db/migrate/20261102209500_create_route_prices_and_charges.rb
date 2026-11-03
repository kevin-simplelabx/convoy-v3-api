# School Bus › Route Plans › route money: what the operator is paid for a route by month from a date (Fixed Monthly, or
# base + per rider over the riders included; history kept), and Route Charges — an extra the school pays on a run when it
# pays per bus (SGD or % of the bus rate, from a date; 0 ends it), carried to the best-matching route of a newly adopted
# plan for an Admin to check.
class CreateRoutePricesAndCharges < ActiveRecord::Migration[8.1]
  def change
    create_table :school_route_prices do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school_route, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.date :effective_from, null: false
      t.string :mode, null: false, default: "fixed"
      t.decimal :monthly, precision: 12, scale: 2
      t.decimal :base_price, precision: 12, scale: 2
      t.integer :riders_included
      t.decimal :per_rider, precision: 12, scale: 2
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :school_route_prices, %i[school_route_id effective_from], unique: true

    create_table :route_charges do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :school_route, foreign_key: { on_delete: :nullify }
      t.date :starts_on, null: false
      t.string :kind, null: false, default: "amt"
      t.decimal :value, precision: 12, scale: 2, null: false
      t.string :reason, null: false
      t.string :note
      t.string :status, null: false, default: "ok"
      t.references :carried_from, foreign_key: { to_table: :route_charges, on_delete: :nullify }, index: false
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :route_charges, %i[school_id status]
  end
end
