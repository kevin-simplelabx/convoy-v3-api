# A booking. Default view: a row of the Bookings list. :full: the booking details and the booking form.
class BookingBlueprint < ApplicationBlueprint
  fields :number, :source, :coordinator_name, :coordinator_org, :coordinator_email, :coordinator_phone, :estimate_amount, :created_at
  field(:client) { |b| { id: b.client.id, name: b.client.name, code: b.client.code, kind: b.client.kind } }
  field(:client_site) { |b| b.client_site&.slice(:id, :name) }
  field(:tab) { |b| b.tab }
  field(:status_label) { |b| b.status_label }
  field(:kinds) { |b| b.trips.map(&:kind_name).uniq }
  field(:dates) { |b| b.days.map(&:date) }
  field(:trips_count) { |b| b.trips.size }

  view :full do
    fields :client_end_customer_id, :service_for, :po_number, :cost_centre, :notes, :lock_version
    field(:created_by) { |b| b.created_by&.name }
    field(:days) do |b|
      b.days.map do |d|
        { id: d.id, date: d.date, trips: BookingTripBlueprint.render_as_hash(d.trips.to_a) }
      end
    end
    field(:cancel_requests) do |b|
      b.cancel_requests.map do |r|
        { id: r.id, booking_trip_id: r.booking_trip_id, trip_date: r.booking_trip&.date, reason: r.reason, requested_by_name: r.requested_by_name,
          requested_at: r.requested_at, status: r.status, resolved_at: r.resolved_at, resolved_by: r.resolved_by&.name, resolution_note: r.resolution_note }
      end
    end
    field(:attachments) { |b| b.attachments.map { |a| { id: a.id }.merge(a.decorate.file_info(:file)) } }
  end
end
