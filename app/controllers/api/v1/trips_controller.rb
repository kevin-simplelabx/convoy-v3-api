module Api
  module V1
    class TripsController < BaseController
      before_action :require_company!
      before_action -> { require_permission!("vehicles") }, only: [ :create, :destroy ]

      # GET /api/v1/trips
      def index
        trips = current_company.trips.order(:trip_date, :start_time)
        render json: trips.map(&:to_api)
      end

      # POST /api/v1/trips  (upsert by id)
      def create
        raw = params.to_unsafe_h.except("controller", "action", "format")
        attrs = Trip.from_params(raw, current_company)
        trip = current_company.trips.find_by(id: attrs[:id])
        if trip
          trip.update!(attrs.except(:id, :company_id))
        else
          trip = Trip.create!(attrs)
        end
        render json: trip.to_api
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.record.errors.full_messages.first)
      end

      # DELETE /api/v1/trips/:id
      def destroy
        trip = current_company.trips.find_by(id: params[:id])
        return render_error("Trip not found", :not_found) unless trip
        trip.destroy!
        render json: { ok: true }
      end
    end
  end
end
