# A booking in the Client Portal (Bookings list, Home, booking detail). options: viewer (the client user), buses
# ({ booking_trip_id => plates }, Portal::BookingBuses).
class PortalBookingBlueprint < Blueprinter::Base
  identifier :id
  fields :number, :service_for, :coordinator_name, :estimate_amount, :created_at

  field(:status) { |b| Portal::BookingStatus.booking(trips(b)) }
  field(:status_label) { |b| Portal::BookingStatus::LABELS.fetch(Portal::BookingStatus.booking(trips(b))) }
  field(:site) { |b| b.client_site&.slice(:id, :name) }
  field(:booked_by) { |b, o| { name: b.created_by_name || b.created_by&.name, in_portal: b.created_by_kind == "client_user", me: b.created_by_client_user_id == o[:viewer].id } }
  field(:dates) { |b| b.days.map(&:date) }
  field(:billed_to) do |b|
    site = b.client_site
    site&.own_billing? ? { name: site.billing_name, uen: site.billing_uen, own: true } : { name: b.client.bill_name, uen: b.client.uen, own: false }
  end
  field(:trips) { |b, o| trips(b).map { |t| row(t, o) } }
  # The client's own approval (Portal::ApprovalView), or null when the flow was off.
  field(:approval) { |b, o| b.approval && Portal::ApprovalView.call(b.approval, viewer: o[:viewer]) }

  view :full do
    fields :coordinator_org, :coordinator_email, :coordinator_phone, :po_number, :cost_centre, :notes
    field(:attachments) { |b| b.attachments.map { |a| { id: a.id }.merge(a.decorate.file_info(:file)) } }
    field(:trips) { |b, o| trips(b).map { |t| detail(t, o) } }
  end

  def self.trips(booking) = booking.days.flat_map { |d| d.trips.sort_by(&:position) }

  # A trip row: day, times, route, status, estimate, the bus.
  def self.row(t, o)
    status = Portal::BookingStatus.trip(t)
    { id: t.id, date: t.date, kind: t.kind, kind_name: t.kind_name, label: t.label, start_time: t.start_time_hm, return_time: t.return_time_hm,
      hours: t.hours&.to_f, pax: t.pax, from: t.out_points.first&.name, to: t.out_points.last&.name, stops: [ t.out_points.size - 2, 0 ].max,
      status:, status_label: Portal::BookingStatus::LABELS.fetch(status), estimate_amount: t.estimate_amount,
      buses: o[:buses].to_h.fetch(t.id, []), changes: status == "changed" ? t.changes_made.last&.items : nil }
  end

  # Everything the trip details show, and whether the viewer may Accept Changes.
  def self.detail(t, o)
    row(t, o).merge(
      airport_direction: t.airport_direction, flight_number: t.flight_number, terminal: t.terminal, wait_minutes: t.wait_minutes,
      meet_and_greet: t.meet_and_greet, signboard_name: t.signboard_name, luggage_on: t.luggage_on,
      luggage_cabin: t.luggage_cabin, luggage_medium: t.luggage_medium, luggage_large: t.luggage_large, luggage_extra_large: t.luggage_extra_large,
      luggage_oversized: t.luggage_oversized,
      contact_name: t.contact_name, contact_phone: t.contact_phone, note: t.note,
      points: t.out_points.map { it.slice(:name, :address, :lat, :lng, :use, :note) },
      back_points: t.two_way? ? t.back_points.map { it.slice(:name, :address, :lat, :lng, :use, :note) } : [],
      own_way_back: t.two_way? && t.own_way_back?,
      vehicles: t.vehicles.map { { vehicle_type_id: it.vehicle_type_id, name: it.vehicle_type.name, seats: it.vehicle_type.seats, count: it.count } },
      seats_requested: t.seats_requested, estimate_lines: t.estimate_lines,
      acknowledgement: t.acknowledged_at && { at: t.acknowledged_at, by: t.acknowledged_by_name, how: t.acknowledged_how },
      rejection: t.rejected_at && { at: t.rejected_at, by: t.rejected_by_name, by_client: t.rejected_by_client?, reason: t.rejection_reason },
      can_accept_changes: t.awaiting_ack? && o[:viewer].can?(:book)
    )
  end
end
