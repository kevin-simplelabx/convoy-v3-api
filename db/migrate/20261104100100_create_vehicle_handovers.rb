# Switch Vehicle in the Convoy Driver app: the driver taking over a bus photographs it (front, both sides, back, the
# odometer, inside; a photo can be marked up to point at damage) and signs the declaration. One handover per take-over,
# kept by the app's client_id so a retry does not make two.
class CreateVehicleHandovers < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_handovers do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :vehicle, null: false, foreign_key: true
      t.references :driver_account, null: false, foreign_key: true, index: false
      t.references :driver, foreign_key: true, index: false
      t.references :operator_driver, foreign_key: true, index: false
      t.references :vehicle_driver_schedule, foreign_key: { on_delete: :nullify }, index: false
      t.uuid :client_id, null: false
      t.datetime :at, null: false
      t.datetime :declared_at, null: false
      t.text :note
      t.timestamps
      t.check_constraint "num_nonnulls(driver_id, operator_driver_id) = 1", name: "vehicle_handovers_one_driver"
    end
    add_index :vehicle_handovers, %i[driver_account_id client_id], unique: true
    add_index :vehicle_handovers, %i[driver_id at]
    add_index :vehicle_handovers, %i[operator_driver_id at]

    create_table :vehicle_handover_photos do |t|
      t.references :vehicle_handover, null: false, foreign_key: { on_delete: :cascade }
      t.string :side, null: false
      t.string :photo, null: false
      t.string :marked_photo
      t.jsonb :marks, null: false, default: []
      t.timestamps
    end
    add_index :vehicle_handover_photos, %i[vehicle_handover_id side], unique: true
  end
end
