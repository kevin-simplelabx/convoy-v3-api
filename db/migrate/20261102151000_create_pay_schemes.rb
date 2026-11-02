# HR > Pay Schemes: how drivers are paid each month. Three types: Basic + Trips (optional daily included trips and a
# guarantee), Monthly Pay with a Minimum (daily or monthly), Shift Based (salary for set shift hours, work outside paid
# extra). Every type has the school route retainer (route_bands), the rejection penalty and three incentives
# (daily volume tiers, weekly / monthly target tiers). One scheme per company is the default.
class CreatePaySchemes < ActiveRecord::Migration[8.1]
  def change
    create_table :pay_schemes do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :description
      t.boolean :is_default, null: false, default: false
      t.string :scheme_type, null: false, default: "basic_plus_trips"
      t.references :pay_rate_plan, foreign_key: true

      t.decimal :basic_salary, precision: 12, scale: 2, null: false, default: 0
      t.boolean :basic_covers_daily_trips, null: false, default: false
      t.integer :basic_covered_daily_trips, null: false, default: 1
      t.string :basic_covered_schedule, null: false, default: "mon-fri"
      t.boolean :basic_cover_ph, null: false, default: false
      t.boolean :disposal_counts_as_trips, null: false, default: false

      t.boolean :has_guarantee, null: false, default: false
      t.decimal :guaranteed_amount, precision: 12, scale: 2, null: false, default: 2200
      t.boolean :on_top_ph, null: false, default: false
      t.boolean :on_top_sat, null: false, default: false
      t.boolean :on_top_sun, null: false, default: false
      t.boolean :has_post_guarantee_boost, null: false, default: false
      t.string :post_guarantee_boost_type, null: false, default: "percentage"
      t.decimal :post_guarantee_boost_value, precision: 12, scale: 2, null: false, default: 50

      t.boolean :has_rejection_penalty, null: false, default: false
      t.integer :rejection_allowed_jobs, null: false, default: 0
      t.decimal :rejection_fallback_basic, precision: 12, scale: 2, null: false, default: 0
      t.boolean :rejection_keeps_incentives, null: false, default: true

      t.decimal :monthly_pay_amount, precision: 12, scale: 2, null: false, default: 2200
      t.string :monthly_minimum_type, null: false, default: "daily"
      t.integer :monthly_daily_trips, null: false, default: 6
      t.integer :monthly_trips, null: false, default: 150
      t.string :monthly_schedule, null: false, default: "mon-fri"
      t.boolean :monthly_cover_ph, null: false, default: false

      t.decimal :shift_salary, precision: 12, scale: 2, null: false, default: 0
      t.integer :shift_start_time, null: false, default: 480
      t.integer :shift_end_time, null: false, default: 1080
      t.string :shift_working_days, array: true, null: false, default: %w[mon tue wed thu fri]
      t.string :shift_overtime_pay_type, null: false, default: "trip_rates"
      t.decimal :shift_overtime_hourly_rate, precision: 12, scale: 2, null: false, default: 0

      t.boolean :school_routes_pay, null: false, default: false
      t.boolean :school_routes_count, null: false, default: false
      t.boolean :school_routes_in_guarantee, null: false, default: true

      t.boolean :has_daily_volume_incentive, null: false, default: false
      t.boolean :daily_volume_in_guarantee, null: false, default: false
      t.boolean :has_weekly_target_incentive, null: false, default: false
      t.boolean :weekly_target_in_guarantee, null: false, default: false
      t.boolean :has_monthly_target_incentive, null: false, default: false
      t.boolean :monthly_target_in_guarantee, null: false, default: false

      t.datetime :locked_at
      t.references :locked_by, foreign_key: { to_table: :users }
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :pay_schemes, %i[company_id name], unique: true, where: "discarded_at IS NULL"
    add_index :pay_schemes, :company_id, unique: true, where: "is_default AND discarded_at IS NULL", name: "index_pay_schemes_one_default"
    add_check_constraint :pay_schemes, "scheme_type IN ('basic_plus_trips', 'monthly_with_minimum', 'shift_based')", name: "pay_schemes_type"

    create_table :pay_scheme_route_bands do |t|
      t.references :pay_scheme, null: false, foreign_key: true
      t.integer :up_to_minutes
      t.decimal :monthly_amount, precision: 12, scale: 2, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :pay_scheme_volume_tiers do |t|
      t.references :pay_scheme, null: false, foreign_key: true
      t.integer :from_trip, null: false
      t.integer :to_trip
      t.string :boost_type, null: false, default: "flat"
      t.decimal :boost_value, precision: 12, scale: 2, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :pay_scheme_target_tiers do |t|
      t.references :pay_scheme, null: false, foreign_key: true
      t.string :period, null: false
      t.integer :target_trips, null: false
      t.string :pay_as, null: false, default: "lump_sum"
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :pay_scheme_target_tiers, "period IN ('weekly', 'monthly')", name: "pay_scheme_target_tiers_period"
  end
end
