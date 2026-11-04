# A client's cancellation request (a booking, or one trip of it). Recorded on the client's behalf until the Client
# Portal sends it; the coordinators are told (bell). Resolving it: accept cancels the trips (approved ones: their
# Scheduler runs not started yet, or the trip itself when it has no runs yet); decline leaves them as they are.
module Bookings
  class CancelRequest < ApplicationService
    # actor: the Convoy OS user recording it for the client (by_name: the client's person), later a client user.
    def self.record(booking:, reason:, by_name:, actor:, trip: nil, at: Time.current)
      raise Error, "This trip is already #{trip.status_label.downcase}" if trip && (trip.cancelled? || trip.rejected?)
      raise Error, "Say who asked to cancel" if by_name.blank?

      BookingCancelRequest.transaction do
        request = booking.cancel_requests.new(booking_trip: trip, reason: reason.to_s.squish.presence, requested_at: at)
        request.stamp_actor(:requested, actor, name: by_name.squish).save!
        what = trip ? "the trip on #{trip.date.strftime('%a %-d/%-m')}" : "the booking"
        Notify.call(booking:, trip:, kind: "cancel_request", actor_name: request.requested_by_name, at:,
                    message: "#{request.requested_by_name} asks to cancel #{what}#{": #{request.reason}" if request.reason}")
        request
      end
    end

    def initialize(request:, decision:, user:, note: nil)
      @request = request
      @booking = request.booking
      @decision = decision.to_s
      @user = user
      @note = note.to_s.squish.presence
    end

    def call
      raise Error, "This request is #{@request.status} already" unless @request.open?
      raise Error, "Accept or decline the request" unless %w[accept decline].include?(@decision)

      BookingCancelRequest.transaction do
        cancel_trips if @decision == "accept"
        @request.update!(status: @decision == "accept" ? "accepted" : "declined", resolved_at: Time.current, resolved_by: @user, resolution_note: @note)
        @booking.trips.reset
        @booking.update!(estimate_amount: @booking.estimate_total, updated_at: Time.current)
        @request
      end
    end

    private

    def cancel_trips
      trips = @request.booking_trip ? [ @request.booking_trip ] : @booking.trips.to_a
      trips.select(&:may_cancel?).each do |trip|
        trip.scheduler_trips.kept.each { |t| cancel_runs(t) } if trip.approved?
        trip.cancel
        trip.update!(cancelled_at: Time.current)
      end
    end

    # Runs not started yet are cancelled (Cancelled on the Scheduler); a trip with no runs yet is removed.
    def cancel_runs(trip)
      runs = TripOccurrence.where(trip:).visible.to_a
      if runs.empty?
        trip.discard!
        Occurrences::Sync.call(trips: [ trip ], from: Date.current)
      else
        runs.select { |r| r.scheduled? && r.starts_at > Time.current }.each { |r| Occurrences::Edit.new(r, @user).cancel!(by_client: true) }
      end
    end
  end
end
