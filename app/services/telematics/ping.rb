# One report from a device: where the bus is now, how fast, and the device's battery and signal. Overwrites the bus's
# last report (an older ping that arrives late does not), and adds the point to the run the bus is on (Trace, Replay,
# Trip History). The ingest endpoint for the driver app and trackers calls this when it comes; the seed and
# `live_map:simulate` use it now.
module Telematics
  class Ping < ApplicationService
    FIELDS = %i[lat lng speed_kmh heading battery_pct gps_signal gsm_bars].freeze

    def initialize(device:, at:, **report)
      @device = device
      @at = at
      @report = FIELDS.index_with { report[it] }
    end

    def call
      vehicle = @device.vehicle or raise Error, "This device is not fitted to a bus"
      raise Error, "A ping needs a position" if @report[:lat].nil? || @report[:lng].nil?

      run = LiveMap.run_now(TripOccurrence.where(vehicle:, date: (@at.to_date - 1)..@at.to_date).where.not(status: LiveMap::NOT_DRIVEN).to_a, @at)
      add_to_run(run) if run
      save_last(vehicle, run)
      run
    end

    private

    def add_to_run(run)
      Occurrences::Partitions.ensure!(run.date, run.date)
      OccurrencePosition.insert!({ occurrence_id: run.id, occurrence_date: run.date, company_id: run.company_id, recorded_at: @at,
                                   lat: @report[:lat], lng: @report[:lng], speed_kmh: @report[:speed_kmh], heading: @report[:heading] })
    end

    def save_last(vehicle, run)
      row = @report.merge(company_id: vehicle.company_id, vehicle_id: vehicle.id, tracking_device_id: @device.id, recorded_at: @at,
                          occurrence_id: run&.id, occurrence_date: run&.date)
      cols = (row.keys - %i[company_id vehicle_id]).map { |c| "#{c} = EXCLUDED.#{c}" }.join(", ")
      VehicleLivePosition.upsert(row, unique_by: :vehicle_id,
                                      on_duplicate: Arel.sql("#{cols} WHERE vehicle_live_positions.recorded_at <= EXCLUDED.recorded_at"))
    end
  end
end
