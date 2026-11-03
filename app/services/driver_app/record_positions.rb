# GPS from the Driver app (a batch, oldest first): the points go to the trip on the road (or the bus's run at that time)
# and the bus's last report through the phone's tracking device at the picked company; then the server checks the
# geofence of the next point. Points come only while a trip runs or is coming (the app's rule); without a bus today
# nothing is stored. Returns { recorded:, run_id:, vehicle:, arrived: [positions] }.
module DriverApp
  class RecordPositions < ApplicationService
    def initialize(jwt:, member:, points:)
      @jwt = jwt
      @member = member
      @points = Array(points)
    end

    def call
      points = clean(@points)
      run = Runs.on_the_road(@member)
      vehicle = run&.vehicle || Vehicles.current(@member)&.dig(:vehicle)
      touch_session(nil)
      return { recorded: 0, run_id: run&.id, vehicle: nil, arrived: [] } if vehicle.nil? || points.empty?

      device = device_for(vehicle)
      touch_session(device)
      result = Telematics::Ingest.call(device:, points:, run:)
      arrived = run ? [ ConfirmArrival.call(occ: run, points:) ].compact : []
      { recorded: result[:recorded], run_id: run&.id, vehicle: { id: vehicle.id, plate: vehicle.plate }, arrived: }
    end

    private

    def clean(points)
      raise ApplicationService::Error, "Send #{Gps::PROFILE[:max_points]} points at most" if points.size > Gps::PROFILE[:max_points]

      now = Time.current
      points.filter_map do |raw|
        p = raw.to_h.symbolize_keys
        at = Time.zone.iso8601(p[:at].to_s)
        next if at < now - Gps::MAX_AGE

        { at: [ at, now ].min, lat: Float(p[:lat]), lng: Float(p[:lng]), speed_kmh: p[:speed_kmh]&.to_f, heading: p[:heading]&.to_f,
          battery_pct: p[:battery_pct]&.to_i, gps_signal: Gps.signal(p[:accuracy_m]&.to_f), gsm_bars: p[:gsm_bars]&.to_i }
      end
    rescue ArgumentError, TypeError
      raise ApplicationService::Error.new("Each point needs at (ISO 8601), lat and lng", details: { points: [ "are not valid" ] })
    end

    # The phone as a tracking device at the company (one per driver account), fitted to the bus it reports for.
    def device_for(vehicle)
      device = TrackingDevice.find_or_initialize_by(identifier: "driver_app:#{@jwt.driver_account_id}")
      device.assign_attributes(kind: "driver_app", vehicle:, name: @jwt.name.presence || device.name || "Convoy Driver app",
                               report_interval_seconds: Gps::PROFILE[:interval_seconds])
      device.save! if device.changed?
      device
    end

    def touch_session(device)
      session = @jwt.driver_app_session_id && DriverAppSession.find_by(id: @jwt.driver_app_session_id)
      return unless session

      attrs = { last_seen_at: Time.current }
      attrs[:tracking_device_id] = device.id if device && session.tracking_device_id != device.id
      session.update_columns(attrs) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
