# A booking's status in the app's words (Convoy App bkSt / bkAll): from its trips, the client's approval and cancel requests.
#   cancelled — every trip cancelled; cxreq — an open request to cancel the booking (the rest of it); changed — the
#   company changed a trip (Accept Changes / Can't Accept); past (no trip left from today): completed (something ran),
#   else rejected; pending — waiting for the client's approver, or (no approval / Personal) for the company; approved —
#   the approval is done and the company has not confirmed yet; ongoing — confirmed with a bus on the road today;
#   confirmed. Trip status: pending, approved, changed, confirmed, live, done, declined, cancelled, cancel_requested.
module ConvoyApp
  module Bookings
    module Status
      TRIP_LABELS = { "pending" => "Pending", "approved" => "Approved", "changed" => "Changed", "confirmed" => "Confirmed", "live" => "On the way",
                      "done" => "Completed", "declined" => "Declined", "cancelled" => "Cancelled", "cancel_requested" => "Cancel Requested" }.freeze
      TRIP_TONES = { "pending" => "warning", "approved" => "info", "changed" => "warning", "confirmed" => "success", "live" => "warning",
                     "done" => "neutral", "declined" => "danger", "cancelled" => "danger", "cancel_requested" => "warning" }.freeze

      module_function

      def booking(b, runs, today = Date.current)
        trips = b.trips.to_a
        return "cancelled" if trips.all?(&:cancelled?)
        return "cxreq" if b.cancel_requests.any? { it.open? && it.for_booking? }
        return "changed" if trips.any?(&:awaiting_ack?)

        open = trips.reject { it.cancelled? || it.rejected? }
        return trips.any?(&:approved?) ? "completed" : "rejected" if open.none? { it.date >= today }
        return approval_done?(b) ? "approved" : "pending" if open.any? { it.pending? || it.awaiting_client? }

        open.any? { it.date == today && runs.live?(it) } ? "ongoing" : "confirmed"
      end

      def trip(t, b, runs, today = Date.current)
        return "cancelled" if t.cancelled?
        return "declined" if t.rejected?
        return "cancel_requested" if b.cancel_requests.any? { it.open? && it.trips.include?(t) }
        return "changed" if t.awaiting_ack?
        return "pending" if t.awaiting_client?
        return approval_done?(b) ? "approved" : "pending" if t.pending?
        return "done" if t.date < today || (t.date == today && runs.ended?(t))

        t.date == today && runs.live?(t) ? "live" : "confirmed"
      end

      def tab(status) = TABS.find { |_, list| list.include?(status) }&.first

      # The client's approver signed off (the trips now wait for the company).
      def approval_done?(b) = b.approval&.status == "ok"
    end
  end
end
