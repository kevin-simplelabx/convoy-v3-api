class CreateRateCards < ActiveRecord::Migration[8.1]
  def change
    # Named rate cards: periods (days, time ranges, override) with a trip and hourly rate per vehicle type, plus extras.
    create_table :rate_cards do |t|
      t.references :company, null: false, foreign_key: true
      t.string  :name, null: false
      t.text    :description
      t.boolean :default_card, null: false, default: false
      t.integer :wait_free_minutes, null: false, default: 10
      t.decimal :wait_fee, precision: 10, scale: 2, null: false, default: 15
      t.integer :wait_block_minutes, null: false, default: 15
      t.boolean :distance_pricing, null: false, default: false
      t.boolean :stop_fees, null: false, default: false
      t.string  :disposal_mode, null: false, default: "hourly"   # hourly | hourly_distance
      t.decimal :disposal_free_km, precision: 8, scale: 1, null: false, default: 0
      t.boolean :meet_and_greet, null: false, default: false
      t.decimal :meet_and_greet_fee, precision: 10, scale: 2, null: false, default: 0
      t.datetime :archived_at
      t.timestamps
    end
    add_index :rate_cards, :company_id, unique: true, where: "default_card AND archived_at IS NULL", name: "index_rate_cards_one_default"

    create_table :rate_card_periods do |t|
      t.references :company, null: false, foreign_key: true
      t.references :rate_card, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :days, array: true, null: false, default: []   # mon tue wed thu fri sat sun ph
      t.boolean :override, null: false, default: false         # wins over the other periods (Weekend and PH)
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    # A time range of a period; ends_at <= starts_at runs past midnight.
    create_table :rate_card_ranges do |t|
      t.references :company, null: false, foreign_key: true
      t.references :rate_card_period, null: false, foreign_key: true
      t.integer :starts_at, null: false
      t.integer :ends_at, null: false
      t.timestamps
    end

    create_table :rate_card_rates do |t|
      t.references :company, null: false, foreign_key: true
      t.references :rate_card_period, null: false, foreign_key: true
      t.references :vehicle_type, null: false, foreign_key: true
      t.decimal :trip_rate, precision: 10, scale: 2, null: false, default: 0
      t.decimal :hourly_rate, precision: 10, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :rate_card_rates, %i[rate_card_period_id vehicle_type_id], unique: true

    # Distance Pricing bands on the total route distance (up_to_km null = the last band and above; per_km on the last band).
    create_table :rate_card_distance_bands do |t|
      t.references :company, null: false, foreign_key: true
      t.references :rate_card, null: false, foreign_key: true
      t.integer :position, null: false
      t.decimal :up_to_km, precision: 8, scale: 1
      t.boolean :per_km, null: false, default: false
      t.timestamps
    end

    # Amounts by vehicle type for the extras: a distance band, the extra-stop fee, the disposal per-km charge.
    create_table :rate_card_amounts do |t|
      t.references :company, null: false, foreign_key: true
      t.references :rate_card, null: false, foreign_key: true
      t.string :kind, null: false                              # distance_band | stop_fee | disposal_km
      t.references :rate_card_distance_band, foreign_key: true
      t.references :vehicle_type, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.timestamps
    end
  end
end
