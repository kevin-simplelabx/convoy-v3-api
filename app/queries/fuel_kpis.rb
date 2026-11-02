# The KPI row of Fuel & Energy for a month (all buses or one): spend against the month before, litres and kWh,
# efficiency over the month's measured full fills, cost per km, and how many fills need a look.
class FuelKpis
  def initialize(scope, month:, vehicle_id: nil)
    @vehicle_id = vehicle_id.presence
    @scope = @vehicle_id ? scope.where(vehicle_id: @vehicle_id) : scope
    @month = month.beginning_of_month
  end

  def call
    now = sums(@month)
    before = sums(@month.prev_month)
    {
      month: @month.strftime("%Y-%m"),
      spend: now[:spend], spend_before: before[:spend],
      spend_change_pct: before[:spend].positive? ? ((now[:spend] - before[:spend]) / before[:spend] * 100).round : nil,
      fuel_litres: now[:fuel], kwh: now[:elec], fills: now[:fills],
      fuel_efficiency: now[:fuel_eff], elec_efficiency: now[:elec_eff], measured: now[:measured],
      km: now[:km], cost_per_km: now[:km].positive? ? (now[:spend] / now[:km]).round(2) : nil,
      needs_a_look: FuelAlert.open.then { |a| @vehicle_id ? a.where(vehicle_id: @vehicle_id) : a }.count
    }
  end

  private

  def sums(month)
    row = @scope.in_month(month).pick(
      Arel.sql("COALESCE(SUM(cost), 0)"),
      Arel.sql("COALESCE(SUM(quantity) FILTER (WHERE kind IN ('diesel', 'petrol')), 0)"),
      Arel.sql("COALESCE(SUM(quantity) FILTER (WHERE kind = 'elec'), 0)"),
      Arel.sql("COUNT(*) FILTER (WHERE kind <> 'elec')"),
      Arel.sql("ROUND(AVG(efficiency) FILTER (WHERE kind <> 'elec'), 1)"),
      Arel.sql("ROUND(AVG(efficiency) FILTER (WHERE kind = 'elec'), 1)"),
      Arel.sql("COUNT(efficiency)"),
      Arel.sql("COALESCE(SUM(km_since), 0)")
    )
    %i[spend fuel elec fills fuel_eff elec_eff measured km].zip(row).to_h
  end
end
