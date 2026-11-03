# Reports from one device, oldest first: each point goes to the run the bus was on at that time (Trace, Replay, Trip
# History), and the newest becomes the bus's last report (an older one arriving late does not overwrite it). One query
# for the runs and one insert for the points, however many points come at once (the Driver app sends batches).
#   points: [{ at, lat, lng, speed_kmh, heading, battery_pct, gps_signal, gsm_bars }]
# run: the run to add the points to when the caller knows it (the Driver app's trip on the road), else the bus's run then.
# Returns { recorded:, runs: [runs the points went to] }.
module Telematics
  class Ingest < ApplicationService
    FIELDS = %i[lat lng speed_kmh heading battery_pct gps_signal gsm_bars].freeze

    def initialize(device:, points:, run: nil)
      @device = device
      @points = points.map { it.to_h.symbolize_keys }.sort_by { it[:at] }
      @run = run
    end

    def call
      vehicle = @device.vehicle or raise Error, "This device is not fitted to a bus"
      raise Error, "A ping needs a position" if @points.any? { it[:lat].nil? || it[:lng].nil? }
      return { recorded: 0, runs: [] } if @points.empty?

      runs = @run ? [ @run ] : runs_of(vehicle)
      placed = @points.map { [ it, @run || LiveMap.run_now(runs, it[:at]) ] }
      add_to_runs(placed.select(&:last))
      save_last(vehicle, *placed.last)
      { recorded: @points.size, runs: placed.filter_map(&:last).uniq }
    end

    private

    def runs_of(vehicle)
      days = (@points.first[:at].to_date - 1)..@points.last[:at].to_date
      TripOccurrence.where(vehicle:, date: days).where.not(status: LiveMap::NOT_DRIVEN).to_a
    end

    def add_to_runs(placed)
      return if placed.empty?

      dates = placed.map { it.last.date }
      Occurrences::Partitions.ensure!(dates.min, dates.max)
      OccurrencePosition.insert_all!(placed.map do |p, run|
        { occurrence_id: run.id, occurrence_date: run.date, company_id: run.company_id, recorded_at: p[:at],
          lat: p[:lat], lng: p[:lng], speed_kmh: p[:speed_kmh], heading: p[:heading] }
      end)
    end

    def save_last(vehicle, point, run)
      row = FIELDS.index_with { point[it] }.merge(company_id: vehicle.company_id, vehicle_id: vehicle.id, tracking_device_id: @device.id,
                                                  recorded_at: point[:at], occurrence_id: run&.id, occurrence_date: run&.date)
      cols = (row.keys - %i[company_id vehicle_id]).map { |c| "#{c} = EXCLUDED.#{c}" }.join(", ")
      VehicleLivePosition.upsert(row, unique_by: :vehicle_id,
                                      on_duplicate: Arel.sql("#{cols} WHERE vehicle_live_positions.recorded_at <= EXCLUDED.recorded_at"))
    end
  end
end
