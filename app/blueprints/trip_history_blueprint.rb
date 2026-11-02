# A row of Trip History (table and the list beside the record).
class TripHistoryBlueprint < ApplicationBlueprint
  fields :date, :trip_label, :kind, :trip_id, :school_route_id, :status
  field(:key) { |o| o.decorate.key }
  field(:title) { |o| o.decorate.title }
  field(:start_time) { |o| o.start_time_hm }
  field(:end_time) { |o| o.end_time_hm }
  field(:client) { |o| o.client&.slice(:id, :name) }
  field(:vehicle) do |o|
    used = TripHistory.vehicle(o)
    v = used[:vehicle]
    v ? { id: v.id, plate: v.plate, make: v.make, model: v.model, seats: v.seats } : used[:plate] && { id: nil, plate: used[:plate] }
  end
  field(:driver_name) { |o| TripHistory.driver_name(o) }
  field(:operator) { |o| o.operator ? o.operator.name : (o.vehicle ? "Own fleet" : nil) }
  field(:outcome) { |o| TripHistory.outcome(o) }
  field(:outcome_label) { |o| TripHistory::OUTCOMES.dig(TripHistory.outcome(o), :label) }
  field(:tone) { |o| TripHistory::OUTCOMES.dig(TripHistory.outcome(o), :tone) }
  field(:on_time) { |o, opts| TripHistory.on_time(o, opts.fetch(:on_time_minutes)) }
  field(:distance_km) { |o| o.trip_summary&.distance_km }
  # Riders carried (boarded at the stops when known); N/A (null) when it did not run.
  field(:pax) { |o| o.completed? ? TripHistory.pax(o) : nil }
  field(:corrected) { |o| TripHistory.corrected?(o) }
  field(:needs_look) { |o| TripHistory.needs_look?(o) }
  field(:skip_reason) { |o| o.skip_reason }
end
