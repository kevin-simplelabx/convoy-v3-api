# Works out the derived columns of every fuel entry of one vehicle, in order (date, time, id), as the Fuel & Energy
# page reads them:
#   km_since       odometer minus the vehicle's previous reading (any kind); null and odometer_back set when it went back
#   energy_km      km since the previous reading of the same energy (fuel, elec, def): fuel per km by driver or vehicle
#   efficiency     at a full fill: km since the previous full fill of the same energy, divided by what was added since
#                  then (this fill plus partial fills in between). km/L for fuel, kWh/100km for electricity; none for DEF
#   driver_id      the bus's default driver that day (own drivers), so fuel can be counted per driver
# Only changed rows are written. Called after an entry is saved or deleted, and when the bus's default driver changes.
module FuelEntries
  class Recompute < ApplicationService
    def initialize(vehicle:)
      @vehicle = vehicle
    end

    def call
      schedules = @vehicle.driver_schedules.to_a
      prev_odo = nil
      prev_energy = {}
      last_full = {}
      FuelEntry.where(vehicle_id: @vehicle.id).chronological.each do |e|
        row = { km_since: nil, energy_km: nil, odometer_back: nil, efficiency: nil, driver_id: driver_on(schedules, e.date) }
        odo = e.odometer
        if odo && prev_odo
          odo >= prev_odo ? row[:km_since] = odo - prev_odo : row[:odometer_back] = prev_odo
        end
        row[:energy_km] = odo - prev_energy[e.energy] if odo && prev_energy[e.energy] && odo >= prev_energy[e.energy]
        prev_odo = odo if odo
        prev_energy[e.energy] = odo if odo
        measure(e, odo, last_full, row) if odo && e.energy != "def"
        changed = row.reject { |k, v| e.public_send(k) == v }
        e.update_columns(changed.merge(updated_at: Time.current)) if changed.any?
      end
    end

    private

    def measure(entry, odo, last_full, row)
      full = last_full[entry.energy]
      if full && entry.full? && odo > full[:odo]
        added = full[:added] + entry.quantity
        dist = odo - full[:odo]
        row[:efficiency] = (entry.elec? ? added / dist * 100 : dist / added).round(1) if added.positive?
      end
      full[:added] += entry.quantity if full && !entry.full?
      last_full[entry.energy] = { odo:, added: 0.to_d } if entry.full?
    end

    def driver_on(schedules, date) = schedules.select { |s| s.starts_on <= date }.max_by(&:sort_key)&.driver_id
  end
end
