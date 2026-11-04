# A trip of a booking, as the booking details and the booking form show it.
class BookingTripBlueprint < ApplicationBlueprint
  fields :position, :kind, :kind_name, :status, :label, :hours, :airport_direction, :flight_number, :terminal, :wait_minutes,
         :meet_and_greet, :signboard_name, :pax, :luggage_on, :luggage_cabin, :luggage_medium, :luggage_large,
         :luggage_extra_large, :luggage_oversized, :contact_name, :contact_phone, :note, :distance_km, :return_distance_km,
         :estimate_amount, :estimate_lines
  field(:date) { |t| t.day.date }
  field(:locked) { |t| t.locked? }
  field(:status_label) { |t| t.status_label }
  # Approve buttons: "Approve & Convert to Trip" (pending), "Approve Without Waiting" (awaiting_ack, needs how).
  field(:can_approve) { |t| t.may_approve? }
  field(:can_reject) { |t| t.may_reject? }
  field(:approval) do |t|
    t.approved_at && { at: t.approved_at, by: t.approved_by&.name, how: t.approval_how, note: t.approval_note }
  end
  # by_kind: client_user (the client in the Client Portal) or user (us, recording it for them; by = their name).
  field(:acknowledgement) do |t|
    t.acknowledged_at && { at: t.acknowledged_at, by: t.acknowledged_by_name, by_kind: t.acknowledged_by_kind, how: t.acknowledged_how }
  end
  field(:rejection) do |t|
    t.rejected_at && { at: t.rejected_at, by: t.rejected_by_name, by_kind: t.rejected_by_kind, by_client: t.rejected_by_client?, reason: t.rejection_reason }
  end
  field(:cancelled_at) { |t| t.cancelled_at }
  field(:changes) { |t| t.changes_made.reverse.map { |c| { at: c.created_at, by: c.changed_by&.name, items: c.items } } }
  # Scheduler trips it became (Open in Scheduler: the trip's date, Day view).
  field(:scheduler_trips) { |t| t.scheduler_trips.map { |x| { id: x.id, title: x.title, is_return: x.is_return } } }
  field(:start_time) { |t| t.start_time_hm }
  field(:return_time) { |t| t.return_time_hm }
  field(:points) { |t| t.out_points.map { |p| point(p) } }
  # The way back as it runs (its own points once changed, else the way there reversed); own_way_back tells which.
  field(:back_points) { |t| t.two_way? ? t.back_points.map { |p| point(p) } : [] }
  field(:own_way_back) { |t| t.two_way? && t.own_way_back? }
  field(:standby) { |t| standby(t.standby("out")) }
  field(:return_standby) { |t| standby(t.standby("back")) }
  field(:vehicles) do |t|
    t.vehicles.map { |v| { vehicle_type_id: v.vehicle_type_id, name: v.vehicle_type.name, seats: v.vehicle_type.seats, count: v.count } }
  end
  field(:seats_requested) { |t| t.seats_requested }
  # "12 passengers but only 10 seats requested. Add a vehicle or a bigger bus"
  field(:seats_warning) do |t|
    seats = t.seats_requested
    "#{t.pax} passengers but only #{seats} seats requested. Add a vehicle or a bigger bus" if seats.positive? && t.pax > seats
  end

  def self.point(p) = p.slice(:name, :address, :lat, :lng, :use, :note)

  def self.standby(s)
    s && { location: s.location, minutes: s.minutes, lat: s.lat, lng: s.lng, note: s.note }
  end
end
