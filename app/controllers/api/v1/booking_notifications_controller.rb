# The bell for bookings: events of the last 14 days the user wants (new bookings from the Portal or the App, client
# approval done or declined, changes accepted, cancellation requests), newest first, and how many are unseen.
module Api
  module V1
    class BookingNotificationsController < BaseController
      LABELS = {
        "new_booking" => [ "New booking", "A client sends a booking from the Client Portal or the Convoy App" ],
        "client_approved" => [ "Client approval done", "The client's own approval flow approves a booking and sends it to you" ],
        "client_declined" => [ "Declined by the client", "A booking is declined in the client's approval flow before it reaches you" ],
        "acknowledged" => [ "Changes accepted", "The client accepts the changes you made to a trip" ],
        "cancel_request" => [ "Cancellation request", "The client asks to cancel a booking, a day or a trip" ]
      }.freeze

      before_action :set_preference

      # GET /booking_notifications
      def show
        authorize @pref
        events = BookingEvent.recent.where(kind: @pref.kinds_on)
        unseen = @pref.seen_at ? events.where("occurred_at > ?", @pref.seen_at) : events
        list = events.includes(booking: [ :client, { trips: :day } ]).limit(20).to_a
        Bookings::Assignment.load!(list.map(&:booking).uniq)
        render json: { data: list.map { |e| item(e) }, meta: { unseen_count: unseen.count, seen_at: @pref.seen_at } }
      end

      # PATCH /booking_notifications/seen — the bell was opened.
      def seen
        authorize @pref
        @pref.update!(seen_at: Time.current)
        render json: { data: { seen_at: @pref.seen_at } }
      end

      # GET /booking_notifications/preferences
      def preferences
        authorize @pref, :show?
        render_preferences
      end

      # PATCH /booking_notifications/preferences { new_booking, client_approved, client_declined, acknowledged, cancel_request, email }
      def update_preferences
        authorize @pref, :update?
        @pref.update!(params.permit(*BookingEvent::KINDS, :email))
        render_preferences
      end

      private

      def set_preference
        @pref = UserNotificationPreference.for(current_user)
        @pref.company ||= current_user.company || ActsAsTenant.current_tenant
      end

      def item(event)
        b = event.booking
        { id: event.id, kind: event.kind, message: event.message, actor_name: event.actor_name, occurred_at: event.occurred_at,
          unseen: @pref.seen_at.nil? || event.occurred_at > @pref.seen_at, booking_id: b.id, booking_trip_id: event.booking_trip_id,
          booking_number: b.number, client_name: b.client.name, tab: b.tab }
      end

      def render_preferences
        render json: { data: {
          email: @pref.email, user: current_user.name,
          kinds: BookingEvent::KINDS.map { |k| { kind: k, label: LABELS[k][0], description: LABELS[k][1], on: @pref.wants?(k) } }
        } }
      end
    end
  end
end
