# HR > Rate Plans: per-trip and per-hour driver rates for each vehicle type, by day (Mon–Sun, PH) and time. A period
# with takes_priority wins where periods overlap (weekend and PH rates). A pay scheme uses one rate plan.
class CreatePayRatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :pay_rate_plans do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :description
      t.datetime :locked_at
      t.references :locked_by, foreign_key: { to_table: :users }
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :pay_rate_plans, %i[company_id name], unique: true, where: "discarded_at IS NULL"

    create_table :pay_rate_plan_vehicle_types do |t|
      t.references :pay_rate_plan, null: false, foreign_key: true, index: false
      t.references :vehicle_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :pay_rate_plan_vehicle_types, %i[pay_rate_plan_id vehicle_type_id], unique: true, name: "index_pay_rate_plan_vehicle_types_unique"

    create_table :pay_rate_periods do |t|
      t.references :pay_rate_plan, null: false, foreign_key: true
      t.string :name, null: false
      t.string :days, array: true, null: false, default: []
      t.boolean :takes_priority, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :pay_rate_period_ranges do |t|
      t.references :pay_rate_period, null: false, foreign_key: true
      t.integer :start_time, null: false
      t.integer :end_time, null: false
      t.timestamps
    end

    create_table :pay_rates do |t|
      t.references :pay_rate_period, null: false, foreign_key: true, index: false
      t.references :vehicle_type, null: false, foreign_key: true
      t.decimal :per_trip, precision: 12, scale: 2
      t.decimal :per_hour, precision: 12, scale: 2
      t.timestamps
    end
    add_index :pay_rates, %i[pay_rate_period_id vehicle_type_id], unique: true
  end
end
