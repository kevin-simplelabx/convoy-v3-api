# Shapes FuelVehicleStats for the vehicle cards of Fuel & Energy and the Fuel section of the vehicle record.
module FuelStatsPresenter
  module_function

  def card(vehicle, stats)
    { vehicle_id: vehicle.id, plate: vehicle.plate, sub: [ vehicle.make, vehicle.model ].compact_blank.join(" ") }.merge(summary(stats))
  end

  # { entries:, month_cost:, fuel_efficiency:, elec_efficiency:, cost_per_km:, km:, last: { date, kind, kind_name, quantity, unit, odometer } }
  def summary(stats)
    return { entries: 0, month_cost: 0.to_d, fuel_efficiency: nil, elec_efficiency: nil, cost_per_km: nil, km: 0, last: nil } unless stats

    l = stats[:last]
    stats.except(:last).merge(last: l && { date: l.date, kind: l.kind, kind_name: l.kind_name, quantity: l.quantity, unit: l.unit, odometer: l.odometer })
  end
end
