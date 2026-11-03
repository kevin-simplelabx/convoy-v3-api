# School Bus › Bus Fares › Extra Charges: charges on top of a locked fare table (such as a fuel surcharge) — a % or an
# amount on every bill from a month (to a month, or on into later years), or a one-off on one month's bill — for all
# riders or some tiers / bus sizes (targets: fare tier ids, or "bus:<type>" when the school pays per bus).
class CreateFareAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :fare_adjustments do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :academic_year, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :name, null: false
      t.string :kind, null: false
      t.decimal :value, precision: 12, scale: 2, null: false
      t.date :from_month, null: false
      t.date :to_month
      t.string :targets, array: true, null: false, default: []
      t.string :note
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :fare_adjustments, %i[school_id from_month]
    add_index :fare_adjustments, :academic_year_id
  end
end
