# Trips > Trip History: every run that ran, was cancelled or skipped, with filters, the record of one run and notes.
module Api
  module V1
    class TripHistoryController < BaseController
      # GET /trip_history?from=&to=&q=&client_id[]=&vehicle_id[]=&driver[]=&operator[]=&kind[]=&outcome[]=&on_time[]=&needs_look=&sort=
      def index
        authorize TripOccurrence, :index?
        minutes = current_company.on_time_minutes
        query = TripHistoryQuery.new(policy_scope(TripOccurrence), params, on_time_minutes: minutes)
        render_page query.call, TripHistoryBlueprint, on_time_minutes: minutes,
                                                      meta: { from: query.from, to: query.to, on_time_minutes: minutes,
                                                              speed_limit_kmh: current_company.speed_limit_kmh, facets: query.facets }
      end

      def show
        occ = authorize find, :show?
        render json: { data: TripHistory::Record.call(occ) }
      end

      # GET /trip_history/:id/track — the GPS pings for the map, replay and speed chart, oldest first, as rows of
      # [at (ISO 8601), lat, lng, speed_kmh, heading].
      def track
        occ = authorize find, :show?
        rows = occ.positions.order(:recorded_at).pluck(:recorded_at, :lat, :lng, :speed_kmh, :heading)
        render json: { data: { columns: %w[at lat lng speed_kmh heading], points: rows.map { |t, *rest| [ t.iso8601, *rest ] },
                               interval_seconds: occ.trip_summary&.ping_interval_seconds, speed_limit_kmh: current_company.speed_limit_kmh,
                               stops: TripHistory.stop_record(occ, current_company.on_time_minutes)
                                                 .map { |s| s.slice(:position, :name, :lat, :lng, :served, :skipped, :late) } } }
      end

      # POST /trip_history/:id/notes { body } — kept with the author and time.
      def create_note
        occ = authorize find, :note?
        occ.history_notes.create!(body: params.require(:body).to_s.strip, author: current_user)
        render json: { data: TripHistory::Record.call(find) }, status: :created
      end

      # POST /trip_history/:id/correction { lock_version, correction: { outcome, vehicle_id | vehicle_plate,
      #   driver_id | driver_name, stops: [{ position, arrived_at, departed_at, boarded, alighted }], reason } }
      def correct
        occ = authorize find, :correct?
        TripHistory::Correct.call(occ:, user: current_user, params: correction_params, lock_version: params[:lock_version])
        render json: { data: TripHistory::Record.call(find) }
      end

      private

      def correction_params
        params.require(:correction).permit(policy(TripOccurrence).permitted_attributes_for_correct)
      end

      def find
        policy_scope(TripOccurrence).where(status: %w[completed cancelled skipped]).includes(*TripHistory::Record::INCLUDES).find(params[:id])
      end
    end
  end
end
