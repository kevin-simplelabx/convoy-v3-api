# Convoy App › Book Again (sheet dup): a new first day (from today; the other days move with it), each day's new date
# with a Weekend / public holiday flag, and the New Booking values to start from: trips, points, driver notes, buses,
# passengers and notes are copied; the PO, flights and the approval are not (the price is worked out again from today's
# rate card when the form estimates it). Nothing is saved: the FE opens New Booking with `booking` and sends
# copied_from_id with it. Inside `within`.
module ConvoyApp
  module Bookings
    class Copy < ApplicationService
      def initialize(account:, booking:, first_day: nil, today: Date.current)
        @account = account
        @b = booking
        @first = parse(first_day)
        @today = today
      end

      def call
        raise Error, "Pick a date from today" if @first && @first < @today

        from = @b.days.first.date
        shift = @first ? (@first - from).to_i : nil
        dates = @b.days.map { shift && it.date + shift }
        holidays = dates.compact.any? ? PublicHoliday.where(date: dates.compact).pluck(:date, :name).to_h : {}
        { from: { id: @b.id, number: @b.number, title: @b.title || @b.number }, first_day: @first, shift_days: shift,
          days: @b.days.each_with_index.map do |d, i|
            date = dates[i]
            { was: d.date, date:, trips_count: d.trips.size, flag: date && (holidays[date] || ("Weekend" if date.saturday? || date.sunday?)) }
          end,
          payer: @b.payer, account: @account.key,
          booking: { title: @b.title, notes: @b.notes, client_bill_fund_id: @b.client_bill_fund_id, client_site_id: @b.client_site_id,
                     days: @b.days.each_with_index.map { |d, i| { date: dates[i], trips: d.trips.reject(&:cancelled?).map { trip(it) } } }.reject { it[:trips].empty? } } }
      end

      private

      def parse(value)
        value.present? ? Date.iso8601(value.to_s) : nil
      rescue Date::Error
        raise Error, "Pick the new date"
      end

      def trip(t)
        point = ->(p) { { name: p.name, address: p.address, lat: p.lat&.to_f, lng: p.lng&.to_f, use: p.use, note: p.note } }
        { kind: t.kind, start_time: t.start_time_hm, return_time: t.return_time_hm, hours: t.hours, airport_direction: t.airport_direction,
          terminal: t.terminal, pax: t.pax, adults: t.adults, note: t.note, distance_km: t.distance_km, return_distance_km: t.return_distance_km,
          points: t.out_points.map(&point), back_points: t.own_way_back? ? t.points.select { it.leg == "back" }.sort_by(&:position).map(&point) : [],
          vehicles: t.vehicles.map { { vehicle_type_id: it.vehicle_type_id, count: it.count } } }
      end
    end
  end
end
