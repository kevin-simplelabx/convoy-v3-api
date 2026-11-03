# A route of a plan with the engine's figures, hand-edit flags, regular bus today, attendant and stops with riders.
class SchoolRouteBlueprint < ApplicationBlueprint
  fields :number, :label, :route_key, :bus_type, :seats, :student_seats, :capacity, :floor, :fill, :span_seconds, :ride_minutes, :badges,
         :locked, :hidden, :edited, :manual, :vias, :riders_count
  field(:start_time) { |r| r.start_time_hm }
  field(:end_time) { |r| r.end_time_hm }
  field(:attendant) { |r| r.attendant&.slice(:id, :name, :phone) }
  field(:regular_vehicle_id) { |r| r.regular_vehicle_id(Date.current) }
  field(:vehicles) { |r| r.vehicle_changes.map { { from: it.effective_from, vehicle_id: it.vehicle_id, plate: it.vehicle&.plate } } }
  field(:prices) { |r| r.prices.map { it.slice(:effective_from, :mode, :monthly, :base_price, :riders_included, :per_rider) } }
  field(:charges) { |r| r.charges.map { it.slice(:id, :starts_on, :kind, :value, :reason, :note, :status) } }
  field(:stops) do |r|
    r.stops.map do |s|
      { id: s.id, position: s.position, name: s.name, lat: s.lat&.to_f, lng: s.lng&.to_f, time: s.scheduled_time_hm, riders_count: s.riders_count,
        dwell_seconds: s.dwell_seconds, stop_id: s.stop_id, stop_code: s.stop&.code, stop_point_id: s.stop_point_id,
        pudo_code: s.stop_point && "#{s.stop&.code}#{s.stop_point.suffix}", riders: s.riders.map(&:rid) }
    end
  end
end
