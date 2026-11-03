# School Bus › Year Setup › Operator Pay of a school: which months operators are paid (all, chosen, or chosen in full and
# the rest at a %), how part months count, break months paid as a retainer (in full or earned by the terms / school days
# the route ran before), and the default monthly price per bus size (fixed, and / or base + per rider) with bus
# attendant add-ons (theirs / ours).
class CreateSchoolOperatorPay < ActiveRecord::Migration[8.1]
  def change
    create_table :school_operator_pays do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: { unique: true }
      t.string :scheme, null: false, default: "all"
      t.integer :paid_months, array: true, null: false, default: (1..12).to_a
      t.decimal :part_pct, precision: 5, scale: 2, null: false, default: 50
      t.string :part_basis, null: false, default: "school"
      t.integer :break_months, array: true, null: false, default: [ 6, 12 ]
      t.string :break_pay, null: false, default: "full"
      t.string :earn_by, null: false, default: "terms"
      t.integer :grace_start_days, null: false, default: 0
      t.integer :deduct_days, null: false, default: 0
      t.references :updated_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end

    create_table :school_bus_size_rates do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.string :bus_type, null: false
      t.boolean :fixed_on, null: false, default: true
      t.decimal :monthly, precision: 12, scale: 2
      t.boolean :rider_on, null: false, default: false
      t.decimal :base_price, precision: 12, scale: 2
      t.integer :riders_included
      t.decimal :per_rider, precision: 12, scale: 2
      t.string :default_mode, null: false, default: "fixed"
      t.decimal :ba_operator, precision: 12, scale: 2
      t.decimal :ba_us, precision: 12, scale: 2
      t.timestamps
    end
    add_index :school_bus_size_rates, %i[school_id bus_type], unique: true
  end
end
