# A client's cancellation request: the booking (the rest of it), one day or one trip. Sent from the Convoy App for
# confirmed trips (the charge quoted then, Bookings::CancelFee), or recorded in Convoy OS on the client's behalf; the
# coordinators are told (bell). Resolving it: accept cancels the trips (approved ones: their Scheduler runs not started
# yet, as cancelled when the client asked, so the late-cancel rule bills what was quoted; a trip with no runs yet is
# removed) and refunds a prepaid booking its share less the charge; decline leaves them as they are.
module Bookings
  class CancelRequest < ApplicationService
    # actor: the Convoy OS user recording it for the client (by_name: the client's person), a client user or an app
    # account (Convoy App). scope: booking | day | trip (with day / trip). fee: the charge quoted to the client.
    # trips: the trips asked about (the Convoy App passes those it quoted); default: the scope's trips not cancelled,
    # declined or started yet. They are kept on the request, and accepting it cancels only those.
    def self.record(booking:, reason:, by_name:, actor:, trip: nil, day: nil, scope: nil, note: nil, fee: 0, trips: nil, at: Time.current)
      scope ||= if trip then "trip"
      elsif day then "day"
      else "booking"
      end
      raise Error, "This trip is already #{trip.status_label.downcase}" if trip && (trip.cancelled? || trip.rejected?)
      raise Error, "Say who asked to cancel" if by_name.blank?

      trips ||= open_trips(booking, trip:, day:, at:)
      raise Error, "Nothing left to cancel: every trip has gone, was declined or has started" if trips.empty?

      BookingCancelRequest.transaction do
        request = booking.cancel_requests.new(scope:, booking_trip: (trip if scope == "trip"), booking_day: (day if scope == "day"),
                                              reason: reason.to_s.squish.presence, note: note.to_s.squish.presence, fee_quoted: fee.to_d, requested_at: at)
        trips.each { request.request_trips.build(booking_trip: it, company_id: booking.company_id) }
        request.stamp_actor(:requested, actor, name: by_name.squish).save!
        what = case scope
        when "trip" then "the trip on #{trip.date.strftime('%a %-d/%-m')}"
        when "day" then "#{day.date.strftime('%a %-d/%-m')}"
        else "the booking"
        end
        Notify.call(booking:, trip:, kind: "cancel_request", actor_name: request.requested_by_name, at:,
                    message: "#{request.requested_by_name} asks to cancel #{what}#{": #{request.reason}" if request.reason}")
        request
      end
    end

    # The scope's trips still to come: not cancelled or declined, a later day, or today before the pick-up time.
    def self.open_trips(booking, trip:, day:, at:)
      list = if trip then [ trip ]
      elsif day then booking.trips.select { it.booking_day_id == day.id }
      else booking.trips.to_a
      end
      today = at.to_date
      minute = (at.hour * 60) + at.min
      list.reject { it.cancelled? || it.rejected? || it.date < today || (it.date == today && it.start_time <= minute) }
    end

    def initialize(request:, decision:, user:, note: nil)
      @request = request
      @booking = request.booking
      @decision = decision.to_s
      @user = user
      @note = note.to_s.squish.presence
    end

    def call
      raise Error, "Accept or decline the request" unless %w[accept decline].include?(@decision)

      BookingCancelRequest.transaction do
        # One change at a time per booking (the app's Cancel, Approve and TripAction take the same row lock): two Accepts
        # cannot both cancel and refund.
        @booking = Booking.lock.find(@request.booking_id)
        @request = @booking.cancel_requests.find(@request.id)
        raise Error, "This request is #{@request.status} already" unless @request.open?

        cancel_trips if @decision == "accept"
        @request.update!(status: @decision == "accept" ? "accepted" : "declined", resolved_at: Time.current, resolved_by: @user, resolution_note: @note)
        @booking.trips.reset
        @booking.update!(estimate_amount: @booking.estimate_total, updated_at: Time.current)
        ConvoyApp::Alerts.safely { ConvoyApp::Alerts::Bookings.call(booking: @booking, kind: @decision == "accept" ? "cancelled" : "cancel_declined", request: @request) }
        @request
      end
    end

    private

    def cancel_trips
      trips = @request.trips.select(&:may_cancel?)
      trips.each do |trip|
        trip.scheduler_trips.kept.each { |t| cancel_runs(t) } if trip.approved?
        trip.cancel
        trip.update!(cancelled_at: Time.current)
      end
      Prepaid.refund!(booking: @booking, trips:, fee: @request.fee_quoted, note: "Cancellation accepted#{" (charge #{@request.fee_quoted.to_s('F')})" if @request.fee_quoted.positive?}")
    end

    # Runs not started yet are cancelled (Cancelled on the Scheduler); a trip with no runs yet is removed.
    def cancel_runs(trip)
      runs = TripOccurrence.where(trip:).visible.to_a
      if runs.empty?
        trip.discard!
        Occurrences::Sync.call(trips: [ trip ], from: Date.current)
      else
        at = [ @request.requested_at, Time.current ].min
        runs.select { |r| r.scheduled? && r.starts_at > Time.current }.each { |r| Occurrences::Edit.new(r, @user).cancel!(by_client: true, at:) }
      end
    end
  end
end
