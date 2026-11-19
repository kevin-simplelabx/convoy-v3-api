# Convoy Driver app parity (19/11/2026): Switch Vehicle › "Anything to Highlight?" adds any number of extra photos (side
# "highlight", each with its own marked copy) besides the six sides, which stay one per handover.
class AllowVehicleHandoverHighlightPhotos < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :vehicle_handover_photos, %i[vehicle_handover_id side], unique: true, where: "side <> 'highlight'",
                                                                      name: "index_vehicle_handover_photos_one_per_side", algorithm: :concurrently
    remove_index :vehicle_handover_photos, %i[vehicle_handover_id side], unique: true,
                                                                         name: "index_vehicle_handover_photos_on_vehicle_handover_id_and_side", algorithm: :concurrently
  end
end
