# Convoy Driver app parity (19/11/2026): the flight's other city on an airport transfer — where an arrival comes from
# ("From Sydney"), where a departure flies to ("Flight to London"). Typed in the trip form's Airport block.
class AddTripsFlightCity < ActiveRecord::Migration[8.1]
  def change
    add_column :trips, :flight_city, :string
  end
end
