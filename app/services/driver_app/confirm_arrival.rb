# The server side of the geofence (dual trigger, decided 26/10/2026): the trip on the road arrives at its next point when
# the bus is inside the point's 30 m circle and slow (5 km/h or less), or has been inside for 15 s (from the phone's
# enter alert, or from the first point inside). A bus driving past in the next lane does neither. The driver's own Arrive
# wins: this only fills an arrival the driver has not sent. Returns the position arrived at, or nil.
module DriverApp
  class ConfirmArrival < ApplicationService
    def initialize(occ:, points: [], now: nil)
      @occ = occ
      @points = points.sort_by { it[:at] }
      @now = now
    end

    def call
      return if @occ.started_at.nil? || @occ.ended_at || @occ.cancelled?

      target = next_point or return
      event = Runs.event_for(@occ, target)
      at = arrival_time(target, event) or return
      event.update!(arrived_at: at, source: event.persisted? ? event.source : "telematics")
      TripHistory::Punctuality.call(@occ)
      target[:position]
    end

    private

    # The first point not reached yet (waypoints and points without a pin are passed by).
    def next_point
      events = @occ.stop_events.index_by(&:position)
      Occurrences::Stops.detailed(@occ).find do |p|
        next false if p[:waypoint]

        e = events[p[:position]]
        !(e&.arrived_at || e&.skipped)
      end&.then { it[:lat] && it[:lng] ? it : nil }
    end

    def arrival_time(target, event)
      pin = [ target[:lat].to_f, target[:lng].to_f ]
      inside_since = event.geofence_entered_at
      @points.each do |p|
        unless Geo.metres([ p[:lat], p[:lng] ], pin) <= Gps::RADIUS_M
          inside_since = nil
          next
        end
        inside_since ||= p[:at]
        return p[:at] if p[:speed_kmh] && p[:speed_kmh] <= Gps::SLOW_KMH
        return inside_since if p[:at] - inside_since >= Gps::DWELL_SECONDS
      end
      inside_since if @now && inside_since && @now - inside_since >= Gps::DWELL_SECONDS
    end
  end
end
