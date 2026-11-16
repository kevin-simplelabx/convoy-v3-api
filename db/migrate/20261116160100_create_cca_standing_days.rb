# Same Days Every Week (Convoy App › CCA Bus): the weekdays picked for a child each week at a school that charges the CCA bus
# per ride. They only pre-pick next week; the parent still pays to confirm.
class CreateCcaStandingDays < ActiveRecord::Migration[8.1]
  def change
    create_table :cca_standing_days do |t|
      t.references :company, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.references :family, null: false, foreign_key: { on_delete: :cascade }
      t.references :school_rider, null: false, foreign_key: { on_delete: :cascade }
      t.integer :days, array: true, null: false, default: []
      t.timestamps
    end
    add_index :cca_standing_days, %i[family_id school_rider_id], unique: true
  end
end
