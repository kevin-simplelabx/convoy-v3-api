# A booking. Default view: a row of the Bookings list. :full: the booking details and the booking form.
class BookingBlueprint < ApplicationBlueprint
  fields :number, :title, :source, :payer, :coordinator_name, :coordinator_org, :coordinator_email, :coordinator_phone, :estimate_amount, :created_at
  field(:client) { |b| { id: b.client.id, name: b.client.name, code: b.client.code, kind: b.client.kind } }
  field(:client_site) { |b| b.client_site&.slice(:id, :name) }
  field(:tab) { |b| b.tab }
  field(:status_label) { |b| b.status_label }
  field(:kinds) { |b| b.trips.map(&:kind_name).uniq }
  field(:dates) { |b| b.days.map(&:date) }
  field(:trips_count) { |b| b.trips.size }
  # The client's own approval in the Client Portal (read only here): who it waits for, or how it ended. While it waits,
  # the booking can't be changed (can_edit false).
  field(:client_approval) do |b|
    next unless b.approval

    view = Portal::ApprovalView.call(b.approval)
    view.slice(:status, :name, :current_step, :steps_count, :waiting_for, :waiting_text, :decided_at)
  end
  field(:can_edit) { |b| !b.approval&.waiting? }

  view :full do
    fields :client_end_customer_id, :service_for, :po_number, :cost_centre, :notes, :lock_version
    # Who recorded it: a Convoy OS user, or the client user who booked in the Client Portal (created_by_kind).
    field(:created_by) { |b| b.created_by_name || b.created_by&.name }
    field(:created_by_kind) { |b| b.created_by_kind }
    field(:days) do |b|
      b.days.map do |d|
        { id: d.id, date: d.date, trips: BookingTripBlueprint.render_as_hash(d.trips.to_a) }
      end
    end
    field(:cancel_requests) do |b|
      b.cancel_requests.map do |r|
        { id: r.id, scope: r.scope, booking_trip_id: r.booking_trip_id, booking_day_id: r.booking_day_id,
          trip_date: r.booking_trip&.date || r.booking_day&.date, reason: r.reason, note: r.note, fee_quoted: r.fee_quoted,
          requested_by_name: r.requested_by_name, requested_by_kind: r.requested_by_kind,
          requested_at: r.requested_at, status: r.status, resolved_at: r.resolved_at, resolved_by: r.resolved_by&.name, resolution_note: r.resolution_note }
      end
    end
    field(:attachments) { |b| b.attachments.map { |a| { id: a.id }.merge(a.decorate.file_info(:file)) } }
    # Convoy App: the Bill To fund, Book Again source, charter terms, the receipt name of a Personal booking, its payments
    # (paid in the app, never invoiced) and Can't Accept replies to our changes.
    field(:bill_fund) { |b| b.bill_fund&.slice(:id, :name) }
    field(:copied_from) { |b| b.copied_from && { id: b.copied_from.id, number: b.copied_from.number } }
    fields :terms_accepted_at, :receipt_name, :receipt_uen, :receipt_address
    field(:payments) do |b|
      b.payments.map { |p| p.slice(:id, :kind, :method, :method_label, :amount, :card_fee, :reference, :paid_at, :note).merge(charged: p.charged) }
    end
    field(:change_replies) do |b|
      b.change_replies.map { |r| r.slice(:id, :reason, :message, :replied_by_name, :created_at) }
    end
  end
end
