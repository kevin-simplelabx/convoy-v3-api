# Trips (trip templates). Filters: kind, client_id, vehicle_id, from / to (trips that may run in the range), q (title,
# client, label or a Trip ID).
module Api
  module V1
    class TripsController < BaseController
      FULL = Trip::FULL_INCLUDES

      def index
        authorize Trip
        render_page filtered.order(starts_on: :desc, start_time: :asc), TripBlueprint
      end

      def show
        render_data authorize(kept.includes(*FULL).find(params[:id])), TripBlueprint, view: :full
      end

      # POST { trip: {...}, return_trip: {...} } — return_trip makes a two-way Ad Hoc / Charter trip.
      def create
        trip = authorize Trip.new
        result = Trips::Save.call(trip:, attributes: trip_params, return_attributes: return_params, user: current_user)
        render json: {
          data: TripBlueprint.render_as_hash(present(reload(result.trip)), view: :full),
          meta: { return_trip: result.return_trip && TripBlueprint.render_as_hash(present(reload(result.return_trip)), view: :full) }
        }, status: :created
      end

      def update
        trip = authorize kept.includes(*FULL).find(params[:id])
        Trips::Save.call(trip:, attributes: trip_params, user: current_user)
        render_data reload(trip), TripBlueprint, view: :full
      end

      # Soft delete: future runs go (or are marked removed when something hangs on them); past runs stay.
      def destroy
        trip = authorize(kept.find(params[:id]))
        Trip.transaction do
          trip.discard!
          Occurrences::Sync.call(trips: [ trip ], from: Date.current)
        end
        head :no_content
      end

      # GET /trips/next_number — the Trip ID a new trip would get (New Trip header). Reserves nothing; informational only.
      def next_number
        authorize Trip, :create?
        render json: { data: { trip_id: Trip.next_trip_id } }
      end

      # GET /trips/:id/prices?date= — what each vehicle slot (and each run of a shuttle) earns on a date.
      def prices
        trip = authorize kept.includes(*FULL).find(params[:id]), :show?
        date = params[:date].present? ? Date.parse(params[:date]) : trip.starts_on
        ctx = Calendars::Context.for(current_company, from: date.beginning_of_month, to: date.end_of_month)
        pricer = Pricing::TripPrice.new(trip, ctx)
        slots = (1..trip.vehicles_count).to_a
        rows = if trip.corporate_shuttle?
                 trip.runs.flat_map { |run| slots.map { |n| { run: run.key, slot_no: n, amount: pricer.run_price(slot: n, date:, run:) } } }
        else
                 slots.map { |n| { run: nil, slot_no: n, amount: pricer.run_price(slot: n, date:) } }
        end
        render json: { data: rows, meta: { date:, total: rows.sum { |r| r[:amount] } } }
      end

      private

      def kept = policy_scope(Trip).kept

      def reload(trip) = kept.includes(*FULL).find(trip.id)

      def filtered
        scope = kept.includes(:client, :vehicle_requirements, :stops).search(params[:q])
        scope = scope.where(kind: params[:kind]) if params[:kind].present?
        scope = scope.where(client_id: params[:client_id]) if params[:client_id].present?
        scope = scope.where(id: TripVehicleSlot.where(vehicle_id: params[:vehicle_id]).select(:trip_id)) if params[:vehicle_id].present?
        scope = scope.active_between(Date.parse(params[:from]), Date.parse(params[:to])) if params[:from].present? && params[:to].present?
        scope
      end

      def trip_params = params.require(:trip).permit(policy(Trip).permitted_attributes)

      def return_params
        params[:return_trip].presence && params.require(:return_trip).permit(TripPolicy::RETURN)
      end
    end
  end
end
