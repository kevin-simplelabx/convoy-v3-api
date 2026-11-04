# Booking and trip status in the Client Portal's words (logic/app-feed.js ST_LBL, bookingStatus): a trip is Sent to
# <transport company> (pending), Changes to Review (awaiting_ack), Awaiting Approval (awaiting_client: the client's own
# approval flow), Confirmed (approved), Declined (rejected) or Cancelled. A booking: any trip with changes to review,
# else any awaiting approval, else all declined / cancelled, else any sent, else confirmed.
module Portal
  module BookingStatus
    TRIP = { "pending" => "sent", "awaiting_ack" => "changed", "awaiting_client" => "awaiting_approval", "approved" => "confirmed",
             "rejected" => "declined", "cancelled" => "cancelled" }.freeze
    LABELS = { "sent" => "Sent to Transport", "changed" => "Changes to Review", "awaiting_approval" => "Awaiting Approval",
               "confirmed" => "Confirmed", "declined" => "Declined", "cancelled" => "Cancelled" }.freeze

    def self.trip(trip) = TRIP.fetch(trip.status)

    def self.booking(trips)
      s = trips.map { trip(it) }
      return "changed" if s.include?("changed")
      return "awaiting_approval" if s.include?("awaiting_approval")
      return s.all?("cancelled") ? "cancelled" : "declined" if (s - %w[declined cancelled]).empty?
      return "sent" if s.include?("sent")

      "confirmed"
    end
  end
end
