# HR > Points: a ledger by lots. Every award (by hand, or a bonus paid in a confirmed month) is a lot that expires
# 24 months later; a deduction uses points from the lots expiring first (allocations), so expiry only takes what is
# left of a lot. HR > Rewards: what drivers can redeem points for in the driver app.
class CreateDriverPointsAndRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :driver_point_lots do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :driver, null: false, foreign_key: true, index: false
      t.integer :points, null: false
      t.integer :remaining, null: false
      t.string :source, null: false, default: "manual"
      t.string :reason, null: false
      t.date :awarded_on, null: false
      t.date :expires_on, null: false
      t.references :awarded_by, foreign_key: { to_table: :users }
      t.references :pay_bonus, foreign_key: true
      t.references :driver_pay_month, foreign_key: true
      t.timestamps
    end
    add_index :driver_point_lots, %i[driver_id expires_on]
    add_index :driver_point_lots, :company_id
    add_check_constraint :driver_point_lots, "points > 0 AND remaining BETWEEN 0 AND points", name: "driver_point_lots_points"
    add_check_constraint :driver_point_lots, "source IN ('manual', 'bonus')", name: "driver_point_lots_source"

    create_table :driver_point_deductions do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :driver, null: false, foreign_key: true
      t.integer :points, null: false
      t.string :reason, null: false
      t.date :deducted_on, null: false
      t.references :deducted_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :driver_point_deductions, :company_id
    add_check_constraint :driver_point_deductions, "points > 0", name: "driver_point_deductions_points"

    create_table :driver_point_allocations do |t|
      t.references :driver_point_deduction, null: false, foreign_key: true
      t.references :driver_point_lot, null: false, foreign_key: true
      t.integer :points, null: false
      t.timestamps
    end

    create_table :pay_rewards do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :title, null: false
      t.text :description
      t.string :photo
      t.integer :points_required, null: false
      t.string :status, null: false, default: "inactive"
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :pay_rewards, %i[company_id status]
    add_check_constraint :pay_rewards, "status IN ('active', 'inactive')", name: "pay_rewards_status"
  end
end
