# The phone's geofence alert for a point of the trip on the road: enter (the bus came into the 30 m circle) starts the
# server's dwell clock and confirms at once when the bus's last report is slow; exit before arriving = drove past.
module DriverApp
  class Geofence < ApplicationService
    EVENTS = %w[enter exit].freeze

    def initialize(occ:, member:, position:, event:, at: nil)
      @occ = occ
      @member = member
      @position = position
      @event = event.to_s
      @at = at.presence ? [ Time.zone.iso8601(at.to_s), Time.current ].min : Time.current
    rescue ArgumentError
      raise Error.new("at must be an ISO 8601 time", details: { at: [ "is not a time" ] })
    end

    def call
      raise Error, "event must be enter or exit" unless EVENTS.include?(@event)
      raise Error.new("This trip was given to another driver", code: "replaced") unless Runs.mine?(@occ, @member)
      raise Error.new("Swipe to start the trip first", code: "not_started") unless @occ.started_at && @occ.ended_at.nil?

      point = Occurrences::Stops.detailed(@occ).find { it[:position] == @position.to_i } or raise Error, "Unknown point #{@position}"
      event = Runs.event_for(@occ, point)
      if @event == "enter"
        event.update!(geofence_entered_at: @at, geofence_exited_at: nil, source: event.persisted? ? event.source : "telematics")
        ConfirmArrival.call(occ: @occ, points: last_report, now: Time.current)
      else
        event.update!(geofence_exited_at: @at, geofence_entered_at: event.arrived_at ? event.geofence_entered_at : nil,
                      source: event.persisted? ? event.source : "telematics")
      end
      event.reload
    end

    private

    # The bus's last report when it is recent (the speed at the alert).
    def last_report
      live = @occ.vehicle&.live_position
      return [] unless live && live.recorded_at > @at - 1.minute

      [ { at: @at, lat: live.lat, lng: live.lng, speed_kmh: live.speed_kmh } ]
    end
  end
end
