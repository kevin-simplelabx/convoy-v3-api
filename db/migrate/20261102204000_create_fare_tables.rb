# School Bus › Year Setup › Bus Fares: one fare table per academic year — who pays, how fares are set (distance tiers or
# zones, bus size columns, 1-way, Small Bus / Express, CCA / ASA, surcharges) or the per-bus rates — and the school days of
# each billing period frozen when it is locked (period_snapshot: [[school_days, cca_days], …]).
class CreateFareTables < ActiveRecord::Migration[8.1]
  def change
    create_table :fare_tables do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :academic_year, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :payer, null: false, default: "parents"
      t.string :bill_to_name
      t.string :bill_to_contact
      t.string :bill_to_email
      t.string :basis, null: false, default: "distance"
      t.string :trip, null: false, default: "both"
      t.string :cycle, null: false, default: "period"
      t.integer :months, array: true, null: false, default: (1..12).to_a
      t.string :distribution, null: false, default: "equal"
      t.string :one_way_type, null: false, default: "pct"
      t.decimal :one_way_value, precision: 12, scale: 2
      t.boolean :by_size, null: false, default: false
      t.boolean :small_on, null: false, default: false
      t.string :small_type, null: false, default: "pct"
      t.decimal :small_value, precision: 12, scale: 2
      t.integer :small_seats, null: false, default: 15
      t.boolean :express_on, null: false, default: false
      t.string :express_type, null: false, default: "pct"
      t.decimal :express_value, precision: 12, scale: 2
      t.boolean :cca_on, null: false, default: false
      t.string :cca_per, null: false, default: "trip"
      t.string :cca_price, null: false, default: "fixed"
      t.decimal :cca_fixed, precision: 12, scale: 2
      t.string :cca_split, null: false, default: "equal"
      t.boolean :cca_with_services, null: false, default: false
      %w[non am pm].each do |k|
        t.boolean :"cca_#{k}_on", null: false, default: false
        t.string :"cca_#{k}_type", null: false, default: "pct"
        t.decimal :"cca_#{k}_amount", precision: 12, scale: 2
      end
      t.string :bus_count, null: false, default: "plan"
      t.jsonb :period_snapshot
      t.timestamps
    end

    create_table :fare_tiers do |t|
      t.references :fare_table, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.decimal :max_km, precision: 6, scale: 2
      t.string :name
      t.string :sectors, array: true, null: false, default: []
      t.jsonb :area
      t.decimal :fare, precision: 12, scale: 2
      t.decimal :pm_fare, precision: 12, scale: 2
      t.decimal :one_way_fare, precision: 12, scale: 2
      t.decimal :period_fares, precision: 12, scale: 2, array: true, null: false, default: []
      t.decimal :period_pm_fares, precision: 12, scale: 2, array: true, null: false, default: []
      t.decimal :small_fare, precision: 12, scale: 2
      t.decimal :express_fare, precision: 12, scale: 2
      t.decimal :cca_fare, precision: 12, scale: 2
    end
    add_index :fare_tiers, %i[fare_table_id position]

    create_table :fare_size_columns do |t|
      t.references :fare_table, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.integer :max_seats
    end
    add_index :fare_size_columns, %i[fare_table_id position]

    create_table :fare_tier_sizes do |t|
      t.references :fare_tier, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :fare_size_column, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.decimal :fare, precision: 12, scale: 2
      t.decimal :pm_fare, precision: 12, scale: 2
      t.decimal :one_way_fare, precision: 12, scale: 2
      t.decimal :period_fares, precision: 12, scale: 2, array: true, null: false, default: []
      t.decimal :period_pm_fares, precision: 12, scale: 2, array: true, null: false, default: []
    end
    add_index :fare_tier_sizes, %i[fare_tier_id fare_size_column_id], unique: true

    create_table :fare_surcharges do |t|
      t.references :fare_table, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.string :name, null: false
      t.string :sectors, array: true, null: false, default: []
      t.jsonb :area
      t.string :kind, null: false, default: "flat"
      t.decimal :amount, precision: 12, scale: 2
      t.string :one_way_kind, null: false, default: "same"
      t.decimal :one_way_value, precision: 12, scale: 2
    end
    add_index :fare_surcharges, %i[fare_table_id position]

    create_table :fare_bus_rates do |t|
      t.references :fare_table, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :bus_type, null: false
      t.decimal :rate, precision: 12, scale: 2, null: false
      t.integer :booked_runs
    end
    add_index :fare_bus_rates, %i[fare_table_id bus_type], unique: true
  end
end
