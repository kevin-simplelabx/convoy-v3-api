# What is done to one booking trip besides approving it (Bookings::Approve). By the coordinator (actor: a User): reject
# (the reason is shown to the client), and Client Acknowledged: the client accepted our changes (with how they told us),
# recorded for them. By the client in the Client Portal or the Convoy App (actor: a ClientUser, or the AppAccount of a
# Personal booking; via: "Convoy App"): Accept Changes. The client's own approval is decided only in the Client Portal
# (Portal::Approval). Rejecting a trip of a prepaid booking refunds its share.
module Bookings
  class TripAction < ApplicationService
    ACTIONS = %w[reject acknowledge].freeze

    PORTAL_ACTIONS = %w[acknowledge].freeze

    def initialize(trip:, action:, actor:, reason: nil, how: nil, by_name: nil, via: "Client Portal")
      @trip = trip
      @booking = trip.booking
      @action = action.to_s
      @actor = actor
      @portal = actor.is_a?(ClientUser) || actor.is_a?(AppAccount)
      @reason = reason.to_s.squish
      @how = @portal ? via : how.to_s.squish
      @by = if actor.is_a?(AppAccount) then actor.display_name
      elsif @portal then actor.name
      else by_name.to_s.squish.presence || @booking.coordinator_name
      end
    end

    def call
      raise Error, "Unknown action" unless (@portal ? PORTAL_ACTIONS : ACTIONS).include?(@action)

      BookingTrip.transaction do
        # Under the booking's row lock (as the app's Cancel and Approve), checked on the trip as it is now.
        @booking = Booking.lock.find(@trip.booking_id)
        @trip.reload
        raise Error, "This trip is #{@trip.status_label.downcase}, so it can't be changed here" unless @trip.public_send(:"may_#{@action}?")

        send(@action)
        @trip.save!
        @booking.trips.reset
        @booking.update!(estimate_amount: @booking.estimate_total, updated_at: Time.current)
        @trip
      end
    end

    private

    def reject
      raise Error, "Enter the reason, the client sees it" if @reason.blank?

      @trip.reject
      @trip.assign_attributes(rejected_at: Time.current, rejection_reason: @reason)
      @trip.stamp_actor(:rejected, @actor)
      Prepaid.refund!(booking: @booking, trips: [ @trip ], note: "Declined by #{@booking.company.name}: #{@reason}")
      ConvoyApp::Alerts.safely { ConvoyApp::Alerts::Bookings.call(booking: @booking, kind: "declined", trip: @trip) }
    end

    def acknowledge
      @trip.acknowledge
      @trip.assign_attributes(acknowledged_at: Time.current, acknowledged_how: @how.presence || "Recorded by #{@actor.shown_name}")
      @trip.stamp_actor(:acknowledged, @actor, name: @by)
      notify("acknowledged", "#{@by} accepted the changes to the trip on #{day_text}")
    end

    def notify(kind, message) = Notify.call(booking: @booking, trip: @trip, kind:, message:, actor_name: @by)
    def day_text = @trip.date.strftime("%a %-d/%-m")
  end
end
