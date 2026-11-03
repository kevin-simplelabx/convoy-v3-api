# Live Map: every bus now (state, position, device, driver, the run it is on), one bus with its device and the stops of
# its run, the runs of a bus on a day (Replay) and a run's GPS points (Trace and Replay).
module Api
  module V1
    class LiveMapController < BaseController
      before_action { authorize :live_map, :index? }

      # GET /live_map?q=&state=on_trip|available|offline&team_id=
      def index
        rows = LiveMap::Board.new(vehicles).rows
        counts = LiveMap::Board::STATES.index_with { |s| rows.count { |r| r[:state] == s } }
        rows = rows.select { |r| r[:state] == params[:state] } if LiveMap::Board::STATES.include?(params[:state])
        rows = rows.select { |r| r.dig(:team, :id) == params[:team_id].to_i } if params[:team_id].present?
        if (q = params[:q].to_s.strip.downcase).present?
          rows = rows.select { |r| r[:plate].downcase.include?(q) || r.dig(:driver, :name).to_s.downcase.include?(q) }
        end
        render json: { data: rows, meta: { counts:, now: Time.current, teams:, offline_after_minutes: LiveMap::OFFLINE_AFTER.in_minutes.to_i } }
      end

      # GET /live_map/vehicles/:id
      def vehicle
        v = vehicles.find(params[:id])
        render json: { data: LiveMap::Board.new([ v ]).detail(v) }
      end

      # GET /live_map/vehicles/:id/runs?date= — Replay: the bus's runs on a day and how many GPS points each has.
      def runs
        v = vehicles.find(params[:id])
        date = params[:date].present? ? Date.iso8601(params[:date]) : Date.current
        list = TripOccurrence.where(vehicle: v, date:).where.not(status: LiveMap::NOT_DRIVEN).includes(:client, :trip, :school_route).order(:starts_at)
        stats = OccurrencePosition.where(occurrence_id: list.map(&:id), occurrence_date: date).group(:occurrence_id)
                                  .pluck(:occurrence_id, Arel.sql("COUNT(*)"), Arel.sql("MIN(recorded_at)"), Arel.sql("MAX(recorded_at)"))
                                  .to_h { |id, n, from, to| [ id, { points: n, from:, to: } ] }
        render json: { data: list.map { |o| run_item(o, stats[o.id]) }, meta: { date: } }
      rescue Date::Error
        raise ApplicationService::Error, "Date must look like 2026-11-02"
      end

      # GET /live_map/runs/:id/track?since= — GPS points [at, lat, lng, speed_kmh, heading], oldest first (only the ones
      # after `since` when given), with the stops planned and reached.
      def track
        occ = policy_scope(TripOccurrence).where.not(status: LiveMap::NOT_DRIVEN).includes(:stop_events, trip: :stops, trip_run: :times,
                                                                                                         school_route: :stops).find(params[:id])
        points = occ.positions.order(:recorded_at)
        points = points.where("recorded_at > ?", Time.zone.iso8601(params[:since])) if params[:since].present?
        events = occ.stop_events.index_by(&:position)
        render json: { data: {
          columns: %w[at lat lng speed_kmh heading],
          points: points.pluck(:recorded_at, :lat, :lng, :speed_kmh, :heading).map { |t, *rest| [ t.iso8601, *rest ] },
          speed_limit_kmh: current_company.speed_limit_kmh,
          stops: TripHistory.planned_stops(occ).map do |s|
            e = events[s[:position]]
            { position: s[:position], name: s[:name], lat: s[:lat]&.to_f, lng: s[:lng]&.to_f, planned_at: LiveMap.at_minute(occ, s[:planned_minute]),
              arrived_at: e&.arrived_at, departed_at: e&.departed_at, skipped: e&.skipped || false }
          end
        } }
      rescue ArgumentError
        raise ApplicationService::Error, "since must be an ISO 8601 time"
      end

      private

      def vehicles
        policy_scope(Vehicle).kept.includes(:vehicle_team, :operator, :operator_driver, :tracking_devices, driver_schedules: :driver,
                                                                                                           live_position: :tracking_device).order(:plate)
      end

      def teams = VehicleTeam.order(:name).map { |t| t.slice(:id, :name, :color) }

      def run_item(o, stat)
        { id: o.id, key: o.decorate.key, trip_label: o.trip_label, title: o.decorate.title, client: o.client&.name, status: o.status,
          starts_at: o.starts_at, ends_at: o.ends_at, points: stat ? stat[:points] : 0, track_from: stat&.dig(:from), track_to: stat&.dig(:to) }
      end
    end
  end
end
