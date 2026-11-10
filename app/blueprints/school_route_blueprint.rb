# A route of a plan with the engine's figures, hand-edit flags, regular bus today, attendant and stops with riders.
class SchoolRouteBlueprint < ApplicationBlueprint
  fields :number, :label, :route_key, :bus_type, :seats, :student_seats, :capacity, :floor, :span_seconds, :ride_minutes,
         :locked, :hidden, :edited, :manual, :vias, :riders_count
  field(:badges) { |r| r.shown_badges }
  field(:fill) { |r| r.fill&.to_f } # a ratio, a number like the plan summary's avgFill
  field(:start_time) { |r| r.start_time_hm }
  field(:end_time) { |r| r.end_time_hm }
  field(:attendant) { |r| r.attendant&.slice(:id, :name, :phone) }
  field(:regular_vehicle_id) { |r| r.regular_vehicle_id(Date.current) }
  # Bus History and the price history (id to remove one; by = who set it: "Set by …").
  def self.vehicle_row(c) = { id: c.id, from: c.effective_from, vehicle_id: c.vehicle_id, plate: c.vehicle&.plate, by: c.created_by&.shown_name }
  def self.price_row(p) = p.slice(:id, :effective_from, :mode, :monthly, :base_price, :riders_included, :per_rider).merge(by: p.created_by&.shown_name)

  # The route's own BA settings and who is paid when it has no bus (null = the school's default / Not assigned).
  def self.pay_setup(r) = { attendant_required: r.attendant_required, attendant_provided_by: r.attendant_provided_by, attendant_price: r.attendant_price,
                            pay_to: r.pay_to, pay_to_operator: r.pay_to_operator && { id: r.pay_to_operator.id, name: r.pay_to_operator.name } }

  field(:pay_setup) { |r| pay_setup(r) }
  field(:vehicles) { |r| r.vehicle_changes.map { vehicle_row(it) } }
  field(:prices) { |r| r.prices.map { price_row(it) } }
  field(:charges) { |r| r.charges.map { it.slice(:id, :starts_on, :kind, :value, :reason, :note, :status) } }
  field(:stops) do |r|
    r.stops.map do |s|
      { id: s.id, position: s.position, name: s.name, lat: s.lat&.to_f, lng: s.lng&.to_f, time: s.scheduled_time_hm, riders_count: s.riders_count,
        dwell_seconds: s.dwell_seconds, stop_id: s.stop_id, stop_code: s.stop&.code, stop_point_id: s.stop_point_id,
        pudo_code: s.stop_point && "#{s.stop&.code}#{s.stop_point.suffix}", riders: s.riders.map(&:rid) }
    end
  end
end
