# Per own vehicle, over its whole fuel log: average efficiency (km/L over fuel fills, kWh/100km over charges), cost per
# km (all cost / km between the lowest and highest reading), the month's cost and the last entry. One query for the
# vehicle cards of Fuel & Energy and the Fuel summary of the vehicle record.
class FuelVehicleStats
  def initialize(scope = FuelEntry.all, month: Date.current)
    @scope = scope
    @month = month
  end

  # { vehicle_id => { fuel_efficiency:, elec_efficiency:, cost_per_km:, km:, month_cost:, entries:, last: entry } }
  def call(vehicle_ids)
    return {} if vehicle_ids.empty?

    month = @month.beginning_of_month..@month.end_of_month
    rows = @scope.where(vehicle_id: vehicle_ids).group(:vehicle_id).pluck(
      :vehicle_id,
      Arel.sql("ROUND(AVG(efficiency) FILTER (WHERE kind <> 'elec'), 1)"),
      Arel.sql("ROUND(AVG(efficiency) FILTER (WHERE kind = 'elec'), 1)"),
      Arel.sql("SUM(cost)"), Arel.sql("MAX(odometer) - MIN(odometer)"),
      Arel.sql(FuelEntry.sanitize_sql([ "COALESCE(SUM(cost) FILTER (WHERE date BETWEEN ? AND ?), 0)", month.first, month.last ])),
      Arel.sql("COUNT(*)")
    )
    last = @scope.where(vehicle_id: vehicle_ids).select("DISTINCT ON (vehicle_id) *")
                 .order(:vehicle_id, date: :desc, time: :desc, id: :desc).index_by(&:vehicle_id)
    rows.to_h do |vid, fuel, elec, cost, km, month_cost, n|
      [ vid, { fuel_efficiency: fuel, elec_efficiency: elec, km: km.to_i,
               cost_per_km: km.to_i.positive? ? (cost / km).round(2) : nil, month_cost: month_cost.to_d.round(2),
               entries: n, last: last[vid] } ]
    end
  end
end
