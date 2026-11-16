# Convoy App › Cancel (sheet cx): what can still be cancelled, the charge, and sending it (decision 2026-11-04: the OS rule).
# Scopes (HTML bkScopes): the Whole Booking (Rest of the Booking once a part has gone), each day, each trip — only trips
# not cancelled, declined or already asked about, from tomorrow on, or today before the pick-up time and not under way.
# Charge: trips the company has not confirmed are free and cancelled at once (a prepaid booking gets their share back);
# confirmed trips become a request the company accepts in Convoy OS, charged in full for runs starting within the client's
# `late_cancel_hours` (school / company: the runs' client price, as Finance bills a late cancellation; prepaid: the
# trip's share of what was paid, each way on its own), free before that. The charge is shown before sending and kept on
# the request. Inside `within`.
module ConvoyApp
  module Bookings
    class Cancel < ApplicationService
      Scope = Data.define(:key, :label, :trips)

      def self.scopes(booking, runs, now: Time.current)
        items = booking.days.flat_map { |d| d.trips.select { cancellable?(it, booking, runs, now) } }
        return [] if items.empty?

        all = booking.trips.size
        out = [ Scope.new(key: "booking", label: items.size < all ? "Rest of the Booking" : "Whole Booking", trips: items) ]
        if items.size > 1 && booking.days.size > 1
          booking.days.each_with_index do |d, i|
            list = items.select { it.booking_day_id == d.id }
            out << Scope.new(key: "day-#{d.id}", label: "Day #{i + 1} · #{d.date.strftime('%a %-d %b')}", trips: list) if list.any?
          end
        end
        if items.size > 1
          items.each do |t|
            next unless t.day.trips.size > 1 || booking.days.size == 1

            out << Scope.new(key: "trip-#{t.id}", label: "#{t.kind_name} · #{t.date.strftime('%a %-d %b')} #{t.start_time_hm}", trips: [ t ])
          end
        end
        out
      end

      def self.cancellable?(trip, booking, runs, now)
        return false if trip.cancelled? || trip.rejected?
        return false if booking.cancel_requests.any? { it.open? && it.trips.include?(trip) }

        today = now.to_date
        trip.date > today || (trip.date == today && trip.start_time > (now.hour * 60) + now.min && !runs.live?(trip))
      end

      # { fee, text, note, confirmed } for some trips.
      def self.quote(account, booking, trips, runs, now: Time.current)
        hours = booking.client.late_cancel_hours
        confirmed = trips.select(&:approved?)
        charges = confirmed.map { charge(booking, it, runs, hours, now) }
        fee = charges.sum(0.to_d).round(2)
        tc = account.tc
        text = if confirmed.empty? then "No charge: #{tc} has not confirmed the buses yet"
        elsif charges.any?(&:positive?) && charges.any?(&:zero?) then "Per trip: full charge within #{hours} hours of the start, free before that"
        elsif fee.positive? then "Full charge: less than #{hours} hours before the trip"
        else "No charge: more than #{hours} hours before the trip"
        end
        prepaid = booking.paid_by_self?
        note = if confirmed.any?
          "#{tc} confirms the cancellation and the charge#{'; the rest goes back to your card or PayNow' if prepaid}. The buses stay booked until then."
        elsif prepaid
          "Cancelled straight away; what you paid for it is refunded in full."
        else
          "Cancelled straight away. #{tc}#{' and your approver' if booking.approval} are told."
        end
        { fee:, fee_text: text, note:, confirmed: confirmed.any?, late_cancel_hours: hours }
      end

      # The charge for one confirmed trip cancelled now.
      def self.charge(booking, trip, runs, hours, now)
        late = ->(at) { at > now && at - now < hours.hours }
        if booking.paid_by_self?
          legs = trip.two_way? ? [ trip.start_time, trip.return_time ] : [ trip.start_time ]
          share = trip.paid_share / legs.size
          legs.sum { |m| late.call(trip.date.in_time_zone + m.minutes) ? share : 0 }.to_d
        else
          runs.for(trip).select { it.scheduled? && late.call(it.starts_at) }.sum(0.to_d, &:price)
        end
      end

      def initialize(account:, booking:, scope:, reason:, note: nil, now: Time.current)
        @account = account
        @booking = booking
        @key = scope.to_s
        @reason = reason.to_s
        @note = note
        @now = now
      end

      # -> { cancelled: [trip ids], requested: request or nil }
      def call
        raise Error, "Pick a reason" unless BookingCancelRequest::REASONS.include?(@reason)

        ::Booking.transaction do
          @booking.class.lock.find(@booking.id) # one cancellation at a time per booking
          @booking = ::Booking.includes(*Present::INCLUDES).find(@booking.id)
          runs = Runs.load([ @booking ], now: @now)
          scope = self.class.scopes(@booking, runs, now: @now).find { it.key == @key } or
            raise Error.new("This can't be cancelled in the app any more. Call #{@account.tc} for changes on the day", code: "not_cancellable")
          now_trips, ask = scope.trips.partition { !it.approved? }
          quote = self.class.quote(@account, @booking, ask, runs, now: @now)
          cancel_now(now_trips) if now_trips.any?
          request = ask.any? ? send_request(scope, quote[:fee], ask) : nil
          @booking.trips.reset
          @booking.update!(estimate_amount: @booking.estimate_total, updated_at: Time.current) unless @booking.paid_by_self?
          { cancelled: now_trips.map(&:id), requested: request }
        end
      end

      private

      def actor = @account.personal? || @booking.paid_by_self? ? @account.app_account : @account.client_user
      def by_name = actor.is_a?(AppAccount) ? actor.display_name : actor.name
      def why = [ @reason, @note.to_s.squish.presence ].compact.join(": ")

      # Not confirmed yet: cancelled at once, free; the company is told; a prepaid booking gets the share back; an
      # approval left with nothing to approve is closed.
      def cancel_now(trips)
        trips.each do |t|
          t.cancel
          t.update!(cancelled_at: @now)
        end
        what = trips.size == @booking.trips.size ? "the booking" : trips.map { "the #{it.kind_name} on #{it.date.strftime('%a %-d/%-m')}" }.join(", ")
        ::Bookings::Notify.call(booking: @booking, trip: (trips.first if trips.one?), kind: "client_cancelled", actor_name: by_name,
                                message: "#{by_name} cancelled #{what} in the Convoy App (not confirmed yet): #{why}")
        ::Bookings::Prepaid.refund!(booking: @booking, trips:, note: "Cancelled before it was confirmed")
        approval = @booking.approval
        return unless approval&.waiting? && @booking.trips.reload.none?(&:awaiting_client?)

        approval.update!(status: "none", decided_at: @now)
      end

      # The confirmed trips of the scope, as quoted: only those are cancelled when the company accepts.
      def send_request(scope, fee, trips)
        kind, id = @key.split("-")
        trip = kind == "trip" ? @booking.trips.find(id) : nil
        day = kind == "day" ? @booking.days.find(id) : nil
        ::Bookings::CancelRequest.record(booking: @booking, trip:, day:, scope: kind, reason: @reason, note: @note, fee:, trips:, by_name:, actor:, at: @now)
      end
    end
  end
end
