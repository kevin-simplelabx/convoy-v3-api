# Rate Cards page: the vehicle types a card prices (its columns, in order), a lock for concurrent edits, and card names
# unique in the company. Cards seeded before this take their types from their rates.
class CreateRateCardVehicleTypes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    create_table :rate_card_vehicle_types do |t|
      t.references :company, null: false, foreign_key: true
      t.references :rate_card, null: false, foreign_key: true
      t.references :vehicle_type, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :rate_card_vehicle_types, %i[rate_card_id vehicle_type_id], unique: true

    add_column :rate_cards, :lock_version, :integer, null: false, default: 0
    add_index :rate_cards, "company_id, lower(name)", unique: true, name: "index_rate_cards_on_company_and_name", algorithm: :concurrently

    # safety_assured: rate_card_rates is small (a few rows per card); a one-off backfill of the new table.
    safety_assured do
      execute <<~SQL.squish
        INSERT INTO rate_card_vehicle_types (company_id, rate_card_id, vehicle_type_id, position, created_at, updated_at)
        SELECT p.company_id, p.rate_card_id, r.vehicle_type_id, MIN(vt.seats), NOW(), NOW()
        FROM rate_card_rates r
        JOIN rate_card_periods p ON p.id = r.rate_card_period_id
        JOIN vehicle_types vt ON vt.id = r.vehicle_type_id
        GROUP BY p.company_id, p.rate_card_id, r.vehicle_type_id
      SQL
    end
  end

  def down
    remove_index :rate_cards, name: "index_rate_cards_on_company_and_name", algorithm: :concurrently
    remove_column :rate_cards, :lock_version
    drop_table :rate_card_vehicle_types
  end
end
