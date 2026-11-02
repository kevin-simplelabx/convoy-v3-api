# What the coordinator does to one booking trip besides approving it (Bookings::Approve):
# reject (the reason is shown to the client), and the client's steps recorded on their behalf until the Client Portal
# does them: acknowledge our changes (with how they told us), and their own approval done or declined.
module Bookings
  class TripAction < ApplicationService
    ACTIONS = %w[reject acknowledge client_approve client_decline].freeze

    def initialize(trip:, action:, user:, reason: nil, how: nil, by_name: nil)
      @trip = trip
      @booking = trip.booking
      @action = action.to_s
      @user = user
      @reason = reason.to_s.squish
      @how = how.to_s.squish
      @by = by_name.to_s.squish.presence || @booking.coordinator_name
    end

    def call
      raise Error, "Unknown action" unless ACTIONS.include?(@action)
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
      @trip.assign_attributes(rejected_at: Time.current, rejected_by: @user, rejected_by_name: @user.name, rejected_by_client: false, rejection_reason: @reason)
    end

    def acknowledge
      @trip.acknowledge
      @trip.assign_attributes(acknowledged_at: Time.current, acknowledged_by_name: @by, acknowledged_how: @how.presence || "Recorded by #{@user.name}")
      notify("acknowledged", "#{@by} accepted the changes to the trip on #{day_text}")
    end

    def client_approve
      @trip.client_approve
      notify("client_approved", "Approved by #{@by}, sent to you")
    end

    def client_decline
      @trip.client_decline
      @trip.assign_attributes(rejected_at: Time.current, rejected_by_name: @by, rejected_by_client: true, rejection_reason: @reason.presence)
      notify("client_declined", "Declined by #{@by}#{": #{@reason}" if @reason.present?}")
    end

    def notify(kind, message) = Notify.call(booking: @booking, trip: @trip, kind:, message:, actor_name: @by)
    def day_text = @trip.date.strftime("%a %-d/%-m")
  end
end
