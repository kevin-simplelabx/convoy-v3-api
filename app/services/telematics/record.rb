# Stores what the driver app / telematics sent for a run — GPS pings, what happened at each stop — then works out the
# driving summary and On Time. Replaces what was stored for the run before. Used by the seed now; the ingest endpoint
# comes with the driver app.
#   positions:   [{ at, lat, lng, speed_kmh, heading }]
#   stop_events: [{ position, arrived_at, departed_at, skipped, boarded, alighted }] (positions in travel order from 0)
module Telematics
  class Record < ApplicationService
    def initialize(occ:, positions:, stop_events:, odometer_start_km: nil, fuel_used: nil, fuel_unit: nil)
      @occ = occ
      @positions = positions
      @events = stop_events
      @summary = { odometer_start_km:, fuel_used:, fuel_unit: }
    end

    def call
      raise Error, "Only a run that ran has a GPS record" unless @occ.completed?

      Occurrences::Partitions.ensure!(@occ.date, @occ.date)
      names = Occurrences::Stops.planned(@occ).to_h { |s| [ s[:position], s[:name] ] }
      OccurrencePosition.transaction do
        @occ.positions.delete_all
        @occ.stop_events.delete_all
        OccurrencePosition.insert_all!(@positions.map { |p| position_row(p) }) if @positions.any?
        @events.each do |e|
          @occ.stop_events.create!(e.slice(:position, :arrived_at, :departed_at, :skipped, :boarded, :alighted)
                                    .merge(stop_name: names[e[:position]]))
        end
        Summarize.call(@occ, **@summary)
        TripHistory::Punctuality.call(@occ)
      end
    end

    private

    def position_row(p)
      { occurrence_id: @occ.id, occurrence_date: @occ.date, company_id: @occ.company_id, recorded_at: p[:at],
        lat: p[:lat], lng: p[:lng], speed_kmh: p[:speed_kmh], heading: p[:heading] }
    end
  end
end
