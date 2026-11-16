# Convoy App › booking changed by the transport company: Accept Changes (every trip waiting for the client's
# acknowledgement goes back to the company, "Convoy App"), or Can't Accept / Reply Again (what does not work and a message;
# the booking stays as it is until the company sends another option; Convoy OS is told). The actor is the client user of a
# school / company account, or the person on a Personal / Pay Myself booking. Inside `within`.
module ConvoyApp
  module Bookings
    module Changes
      module_function

      def actor(account, booking) = booking.paid_by_self? ? account.app_account : account.client_user
      def actor_name(actor) = actor.is_a?(AppAccount) ? actor.display_name : actor.name

      def accept!(account:, booking:)
        trips = booking.trips.select(&:awaiting_ack?)
        raise ApplicationService::Error.new("There are no changes to accept", code: "no_changes") if trips.empty?

        who = actor(account, booking)
        ::Booking.transaction { trips.each { ::Bookings::TripAction.call(trip: it, action: "acknowledge", actor: who, via: "Convoy App") } }
      end

      def reply!(account:, booking:, reason:, message: nil)
        raise ApplicationService::Error.new("There are no changes to reply to", code: "no_changes") unless booking.trips.any?(&:awaiting_ack?)

        who = actor(account, booking)
        name = actor_name(who)
        ::Booking.transaction do
          reply = booking.change_replies.new(company_id: booking.company_id, reason: reason.to_s, message: message.to_s.squish.presence, replied_by_name: name,
                                             replied_by_client_user: (who if who.is_a?(ClientUser)), replied_by_app_account: (who if who.is_a?(AppAccount)))
          reply.save!
          ::Bookings::Notify.call(booking:, kind: "change_reply", actor_name: name,
                                  message: "#{name} can't accept the changes: #{reply.reason}#{" (“#{reply.message}”)" if reply.message}")
          reply
        end
      end
    end
  end
end
