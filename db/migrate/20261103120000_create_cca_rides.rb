# School Bus › CCA Rides: the CCA / ASA bus charged per ride at a school (price, days, seats a day), the rides parents
# book and pay for each week in the Convoy App (a CCA bill per payment, with its lines and the credit used), days the
# bus does not run, and the credit each booked ride on such a day gives the family.
class CreateCcaRides < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :cca_ride_settings do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, null: false, default: false
      t.decimal :price, precision: 12, scale: 2, null: false, default: 0
      t.integer :days, array: true, null: false, default: [ 2, 4 ]
      t.integer :seats, null: false, default: 40
      t.references :saved_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end

    create_table :school_bill_lines do |t|
      t.references :school_bill, null: false, foreign_key: { on_delete: :cascade }
      t.string :child_name
      t.string :description, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :position, null: false, default: 0
    end

    create_table :cca_bookings do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :family, null: false, foreign_key: true
      t.references :school_rider, foreign_key: { on_delete: :nullify }, index: false
      t.references :school_bill, foreign_key: { on_delete: :nullify }
      t.string :child_name, null: false
      t.string :class_name
      t.date :date, null: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.date :paid_on, null: false
      t.string :method, null: false
      t.boolean :late, null: false, default: false
      t.boolean :not_riding, null: false, default: false
      t.timestamps
    end
    add_index :cca_bookings, %i[school_id date]
    add_index :cca_bookings, %i[family_id child_name date], unique: true

    create_table :cca_off_days do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.date :date, null: false
      t.string :reason, null: false
      t.string :by_name
      t.references :user, foreign_key: { on_delete: :nullify }, index: false
      t.timestamps
    end
    add_index :cca_off_days, %i[school_id date], unique: true

    create_table :cca_credits do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :family, null: false, foreign_key: true
      t.references :cca_booking, foreign_key: { on_delete: :nullify }, index: { unique: true }
      t.string :child_name
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :date, null: false
      t.string :reason, null: false
      t.timestamps
    end

    add_column :school_bills, :gross, :decimal, precision: 12, scale: 2
    add_column :school_bills, :credit_used, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :school_bills, :week_of, :date
  end
end
