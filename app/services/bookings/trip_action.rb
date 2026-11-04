# What is done to one booking trip besides approving it (Bookings::Approve). By the coordinator (actor: a User): reject
# (the reason is shown to the client), and Client Acknowledged: the client accepted our changes (with how they told us),
# recorded for them. By the client in the Client Portal (actor: a ClientUser): Accept Changes. The client's own approval
# is decided only in the Client Portal (Portal::Approval).
module Bookings
  class TripAction < ApplicationService
    ACTIONS = %w[reject acknowledge].freeze

    PORTAL_ACTIONS = %w[acknowledge].freeze

    def initialize(trip:, action:, actor:, reason: nil, how: nil, by_name: nil)
      @trip = trip
      @booking = trip.booking
      @action = action.to_s
      @actor = actor
      @portal = actor.is_a?(ClientUser)
      @reason = reason.to_s.squish
      @how = @portal ? "Client Portal" : how.to_s.squish
      @by = @portal ? actor.name : by_name.to_s.squish.presence || @booking.coordinator_name
    end

    def call
      raise Error, "Unknown action" unless (@portal ? PORTAL_ACTIONS : ACTIONS).include?(@action)
      raise Error, "This trip is #{@trip.status_label.downcase}, so it can't be changed here" unless @trip.public_send(:"may_#{@action}?")

      BookingTrip.transaction do
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
