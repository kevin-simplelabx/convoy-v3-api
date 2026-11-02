# Records a booking event for the bell and, for each coordinator who wants that kind by email, the email it would
# send (recorded only, not sent yet). Coordinators: active company users who may work on trips (vehicles permission).
module Bookings
  class Notify < ApplicationService
    SUBJECTS = { "new_booking" => "New booking", "client_approved" => "Client approval done", "client_declined" => "Declined by the client",
                 "acknowledged" => "Changes accepted", "cancel_request" => "Cancellation request" }.freeze

    def initialize(booking:, kind:, message:, actor_name: nil, trip: nil, at: Time.current)
      @booking = booking
      @kind = kind.to_s
      @message = message
      @actor = actor_name
      @trip = trip
      @at = at
    end

    def call
      event = BookingEvent.create!(booking: @booking, booking_trip: @trip, kind: @kind, message: @message, actor_name: @actor, occurred_at: @at)
      prefs = UserNotificationPreference.where(user: coordinators).index_by(&:user_id)
      coordinators.each do |user|
        pref = prefs[user.id] || UserNotificationPreference.new(user:)
        next unless pref.email? && pref.wants?(@kind)

        NotificationEmail.create!(user:, booking_event: event, to: user.email, subject: "#{SUBJECTS[@kind]}: #{@booking.number}",
                                  body: "#{@message}\n\nBooking #{@booking.number} | #{@booking.client.name}")
      end
      event
    end

    private

    def coordinators
      @coordinators ||= User.where(company: ActsAsTenant.current_tenant, status: "active").select { |u| u.can?(:vehicles) }
    end
  end
end
