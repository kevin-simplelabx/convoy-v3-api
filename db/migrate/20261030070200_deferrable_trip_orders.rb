class DeferrableTripOrders < ActiveRecord::Migration[8.1]
  # Reordering stops, vias or vehicle slots in one save swaps positions; the uniqueness is checked at commit.
  # safety_assured: the tables were created in the migration before and hold no rows yet.
  def change
    safety_assured do
      remove_index :trip_stops, %i[trip_id direction position], unique: true
      add_unique_constraint :trip_stops, %i[trip_id direction position], deferrable: :deferred, name: "trip_stops_order"

      remove_index :trip_route_vias, %i[trip_id direction from_position position], unique: true, name: "index_trip_route_vias_order"
      add_unique_constraint :trip_route_vias, %i[trip_id direction from_position position], deferrable: :deferred, name: "trip_route_vias_order"

      remove_index :trip_vehicle_slots, %i[trip_id slot_no], unique: true
      add_unique_constraint :trip_vehicle_slots, %i[trip_id slot_no], deferrable: :deferred, name: "trip_vehicle_slots_order"
    end
  end
end
