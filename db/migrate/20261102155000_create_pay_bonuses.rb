# HR > Bonuses: campaigns on top of pay schemes — a trip target, an on-time range or full attendance over periods
# (daily … yearly) from starts_on to the period starting last_period_on (nil = no end). Tiers (highest reached is
# paid, with optional points), who can join (schemes, specific drivers, sign-up), how it meets the scheme's own
# incentive of the same period (additive / supercede / prevail), and when it is paid (payout_type, split payments).
class CreatePayBonuses < ActiveRecord::Migration[8.1]
  def change
    create_table :pay_bonuses do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :description
      t.string :plan_type, null: false, default: "trip_target"
      t.string :frequency, null: false, default: "monthly"
      t.date :starts_on, null: false
      t.date :last_period_on
      t.string :payout_type, null: false, default: "end_of_period"
      t.integer :payout_delay_months, null: false, default: 1
      t.boolean :all_schemes, null: false, default: true
      t.boolean :requires_sign_up, null: false, default: false
      t.date :sign_up_from
      t.date :sign_up_to
      t.text :terms
      t.string :overlap_daily, null: false, default: "additive"
      t.string :overlap_weekly, null: false, default: "additive"
      t.string :overlap_monthly, null: false, default: "additive"
      t.datetime :locked_at
      t.references :locked_by, foreign_key: { to_table: :users }
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :pay_bonuses, %i[company_id starts_on]
    add_check_constraint :pay_bonuses, "plan_type IN ('trip_target', 'reliability_otp', 'reliability_attendance')", name: "pay_bonuses_plan_type"
    add_check_constraint :pay_bonuses, "frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'half_yearly', 'yearly')", name: "pay_bonuses_frequency"

    create_table :pay_bonus_tiers do |t|
      t.references :pay_bonus, null: false, foreign_key: true
      t.integer :target_trips
      t.decimal :metric_min, precision: 5, scale: 2
      t.decimal :metric_max, precision: 5, scale: 2
      t.string :pay_as, null: false, default: "lump_sum"
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.integer :points
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :pay_bonus_payments do |t|
      t.references :pay_bonus, null: false, foreign_key: true
      t.integer :percentage, null: false
      t.integer :months_after, null: false, default: 1
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :pay_bonus_schemes do |t|
      t.references :pay_bonus, null: false, foreign_key: true, index: false
      t.references :pay_scheme, null: false, foreign_key: true
      t.timestamps
    end
    add_index :pay_bonus_schemes, %i[pay_bonus_id pay_scheme_id], unique: true

    create_table :pay_bonus_drivers do |t|
      t.references :pay_bonus, null: false, foreign_key: true, index: false
      t.references :driver, null: false, foreign_key: true
      t.string :role, null: false
      t.datetime :signed_up_at
      t.references :signed_up_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :pay_bonus_drivers, %i[pay_bonus_id role driver_id], unique: true
    add_check_constraint :pay_bonus_drivers, "role IN ('eligible', 'signed_up')", name: "pay_bonus_drivers_role"

    create_table :pay_bonus_excluded_periods do |t|
      t.references :pay_bonus, null: false, foreign_key: true
      t.string :name
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.timestamps
    end
  end
end
