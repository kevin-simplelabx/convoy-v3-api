class PayRatePlanBlueprint < ApplicationBlueprint
  fields :name, :description, :locked_at

  field(:locked) { |p| p.locked? }
  field(:locked_by) { |p| p.locked_by && { id: p.locked_by.id, name: p.locked_by.shown_name } }
  field(:periods_count) { |p| p.periods.size }
  # List: pass schemes: { plan_id => [names] } for "Used by 2 schemes" and the delete guard.
  field(:used_by, if: ->(_n, _p, o) { o.key?(:schemes) }) { |p, o| Array(o[:schemes][p.id]) }

  view :detail do
    field(:vehicle_type_ids) { |p| p.plan_vehicle_types.map(&:vehicle_type_id).sort }
    field(:periods) do |p|
      p.periods.map do |x|
        { id: x.id, name: x.name, days: x.days, takes_priority: x.takes_priority,
          ranges: x.ranges.map { |r| { start_time: r.start_time_hm, end_time: r.end_time_hm, ends_next_day: r.overnight? } },
          rates: x.rates.sort_by(&:vehicle_type_id).map { |r| { vehicle_type_id: r.vehicle_type_id, per_trip: r.per_trip, per_hour: r.per_hour } } }
      end
    end
  end
end
