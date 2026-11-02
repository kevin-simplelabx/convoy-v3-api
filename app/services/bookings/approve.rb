# Approve & Convert to Trip: a booking trip becomes a one-off Scheduler trip with no vehicle (its runs show as
# Unassigned), or for a Two Way an outbound and its return linked as a pair (Trips::Save). Price from the estimate:
# a Two Way splits it between the two trips; Meet and Greet goes to its own fee. Trip value is entered when approving.
# A trip waiting for the client to acknowledge changes can be approved without waiting: say how the client agreed.
module Bookings
  class Approve < ApplicationService
    KINDS = { "one_way" => "ad_hoc", "two_way" => "ad_hoc", "disposal" => "disposal", "airport" => "airport_transfer" }.freeze

    def initialize(trip:, user:, trip_value:, return_trip_value: nil, how: nil, note: nil)
      @trip = trip
      @booking = trip.booking
      @user = user
      @value = trip_value.to_d
      @return_value = return_trip_value.to_d
      @how = how.presence
      @note = note.presence
    end

    def call
      raise Error, "This trip is #{@trip.status_label.downcase} already" unless @trip.pending? || @trip.awaiting_ack?
      raise Error, "Enter the trip value" if !@value.positive? || (@trip.two_way? && !@return_value.positive?)
      raise Error, "Say how the client agreed to the changes" if @trip.awaiting_ack? && !BookingTrip::APPROVAL_HOW.include?(@how)

      BookingTrip.transaction do
        result = Trips::Save.call(trip: Trip.new, attributes: trip_attributes, return_attributes:, user: @user)
        @trip.approve
        @trip.update!(approved_at: Time.current, approved_by: @user, approval_how: @how, approval_note: @note)
        @booking.update!(updated_at: Time.current)
        [ result.trip, result.return_trip ].compact
      end
    end

    private

    def mg_fee = @trip.arrival_with_meet_and_greet? ? estimate_line("meet_and_greet") : 0.to_d
    def estimate_line(kind) = @trip.estimate_lines.select { |l| l["kind"] == kind }.sum { |l| l["amount"].to_d }
    def price = @trip.two_way? ? (@trip.estimate_amount / 2).round(2) : @trip.estimate_amount - mg_fee
    def org = @booking.coordinator_org.presence || @booking.client.name
    def finish(minute) = (minute + 60) % 1440

    def trip_attributes
      out = @trip.out_points
      {
        kind: KINDS.fetch(@trip.kind), title:, label: @trip.label, client_id: @booking.client_id, client_site_id: @booking.client_site_id,
        client_end_customer_id: @booking.client_end_customer_id, service_for: @booking.service_for, starts_on: @trip.date, days: [],
        start_time: @trip.start_time, end_time: finish(@trip.start_time), hours: @trip.hours, pax: @trip.pax,
        luggage_on: @trip.luggage_on, luggage_cabin: @trip.luggage_cabin, luggage_medium: @trip.luggage_medium,
        luggage_large: @trip.luggage_large, luggage_extra_large: @trip.luggage_extra_large, luggage_oversized: @trip.luggage_oversized,
        requestor_name: @booking.coordinator_name, requestor_email: @booking.coordinator_email, requestor_phone: @booking.coordinator_phone,
        guest_is_requestor: @trip.contact_name.blank?, guest_name: @trip.contact_name, guest_phone: @trip.contact_phone,
        notes:, booking_ref: @booking.number, booking_trip_id: @trip.id,
        price:, price_per: "route", price_set: "same", price_basis: "trip", trip_value: @value,
        meet_and_greet: @trip.meet_and_greet, meet_and_greet_fee: mg_fee,
        vehicles_count: @trip.vehicles_count,
        vehicle_requirements_attributes: @trip.vehicles.map { |v| { vehicle_type_id: v.vehicle_type_id, count: v.count } },
        stops_attributes: stops(out), standby_attributes: standby(@trip.standby("out"))
      }.merge(airport).compact
    end

    def airport
      return {} unless @trip.airport?

      { airport_direction: @trip.airport_direction, flight_number: @trip.flight_number, terminal: @trip.terminal.presence || "T3",
        wait_minutes: @trip.departure? ? nil : @trip.wait_minutes.presence || 60, signboard_name: @trip.signboard_name }
    end

    def return_attributes
      return nil unless @trip.two_way?

      { start_time: @trip.return_time, end_time: finish(@trip.return_time), stops_attributes: stops(@trip.back_points),
        standby_attributes: standby(@trip.standby("back")), trip_value: @return_value, price:, booking_trip_id: @trip.id }.compact
    end

    def title
      drop = @trip.out_points.size > 1 ? @trip.out_points.last.name : nil
      case @trip.kind
      when "airport" then [ @trip.departure? ? "Changi Departure" : "Changi Arrival", @trip.flight_number ].compact_blank.join(" ")
      when "disposal" then "Disposal #{@trip.hours.to_d.to_s('F')} h"
      else "#{org} to #{drop || @trip.out_points.first.name}"
      end
    end

    def notes
      vehicles = @trip.vehicles.map { |v| "#{v.count} x #{v.vehicle_type.name}" }.join(", ")
      contact = @trip.contact_name.present? ? "Trip contact: #{[ @trip.contact_name, @trip.contact_phone ].compact_blank.join(' ')}" : nil
      [ @trip.note, "Vehicles requested: #{vehicles}", contact, @booking.po_number.presence && "PO #{@booking.po_number}",
        "Booking #{@booking.number}" ].compact_blank.join("\n")
    end

    def stops(points)
      points.each_with_index.map do |p, i|
        { direction: 1, position: i, name: p.name, address: p.address, lat: p.lat, lng: p.lng, use: p.use, driver_note: p.note }
      end
    end

    def standby(s)
      s && { location: s.location, minutes: s.minutes, lat: s.lat, lng: s.lng, note: s.note }
    end
  end
end
