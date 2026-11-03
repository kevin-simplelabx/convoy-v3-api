# Disposal actuals from the Convoy Driver app (the bus and driver at the client's disposal for a block of hours): the
# start (odometer and dash photo; the block from the agreed time, or now when the coordinator asked to start early),
# each run the coordinator directs, every extension the client signed for, and the end (odometer, photo, released by,
# optional signature) with the time used, overtime billed and distance. Billing reads these later (Finance).
class CreateOccurrenceDisposals < ActiveRecord::Migration[8.1]
  def change
    create_table :occurrence_disposals do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.integer :booked_minutes, null: false
      t.datetime :block_starts_at, null: false
      t.datetime :started_at, null: false
      t.boolean :early_start, null: false, default: false
      t.integer :late_minutes, null: false, default: 0
      t.integer :start_odometer, null: false
      t.string :start_photo
      t.integer :extension_minutes, null: false, default: 0
      t.datetime :ended_at
      t.integer :end_odometer
      t.string :end_photo
      t.string :released_by
      t.string :release_signature
      t.integer :used_minutes
      t.integer :overtime_minutes
      t.integer :km
      t.timestamps
    end
    add_index :occurrence_disposals, %i[occurrence_id occurrence_date], unique: true

    create_table :occurrence_disposal_runs do |t|
      t.references :occurrence_disposal, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.string :from_road
      t.string :to_road
      t.float :from_lat
      t.float :from_lng
      t.float :to_lat
      t.float :to_lng
      t.integer :pax
      t.timestamps
    end

    create_table :occurrence_disposal_extensions do |t|
      t.references :occurrence_disposal, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :at, null: false
      t.integer :from_minutes, null: false
      t.integer :to_minutes, null: false
      t.string :signed_by, null: false
      t.string :signature
      t.boolean :operations_told, null: false, default: false
      t.timestamps
    end
  end
end
