# Fuel & Energy: the KPI row and the Usage card.
module Api
  module V1
    class FuelController < BaseController
      # GET /fuel/kpis?month=2026-11&vehicle_id=
      def kpis
        authorize FuelEntry, :index?
        month = params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.current
        render json: { data: FuelKpis.new(policy_scope(FuelEntry), month:, vehicle_id: params[:vehicle_id]).call }
      end

      # GET /fuel/usage?view=&key=&measure=&range=&zoom_from=&zoom_to= (see FuelUsage)
      def usage
        authorize FuelEntry, :index?
        render json: { data: FuelUsage.new(policy_scope(FuelEntry), params).call }
      end
    end
  end
end
