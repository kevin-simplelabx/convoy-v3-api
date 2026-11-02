# HR > Earnings > Confirm Month: the driver's pay for a month, frozen when confirmed (the total, the breakdown rows of
# each part of the month, and what each paid run earned). Reopen Month deletes it; until confirmed, pay is worked out live.
# Runs keep (occurrence_id, occurrence_date) because trip_occurrences is partitioned by month.
class CreateDriverPayMonths < ActiveRecord::Migration[8.1]
  def change
    create_table :driver_pay_months do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :driver, null: false, foreign_key: true, index: false
      t.date :month, null: false
      t.decimal :total, precision: 12, scale: 2, null: false
      t.decimal :trips, precision: 10, scale: 2, null: false, default: 0
      t.integer :runs_count, null: false, default: 0
      t.references :confirmed_by, foreign_key: { to_table: :users }
      t.datetime :confirmed_at, null: false
      t.timestamps
    end
    add_index :driver_pay_months, %i[driver_id month], unique: true
    add_index :driver_pay_months, %i[company_id month]

    create_table :driver_pay_month_lines do |t|
      t.references :driver_pay_month, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.date :part_from
      t.date :part_to
      t.string :scheme_name
      t.string :label, null: false
      t.decimal :amount, precision: 12, scale: 2
      t.string :text
      t.timestamps
    end

    create_table :driver_pay_month_runs do |t|
      t.references :driver_pay_month, null: false, foreign_key: true
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.string :trip_label
      t.decimal :trip_value, precision: 10, scale: 2
      t.decimal :hours, precision: 6, scale: 2
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_index :driver_pay_month_runs, %i[occurrence_id occurrence_date]
  end
end
