# Fuel & Energy > Needs a Look: unusual fills of the last 90 days (FuelAlerts::Scan), Open / Checked tabs, Mark Checked, Undo.
module Api
  module V1
    class FuelAlertsController < BaseController
      # GET /fuel_alerts?status=open|checked&vehicle_id= — newest first, meta.counts per tab.
      def index
        authorize FuelAlert
        scope = policy_scope(FuelAlert).includes(:vehicle, :checked_by, fuel_entry: %i[fuel_company driver])
        scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
        counts = { open: 0, checked: 0 }.merge(scope.group(:status).count.symbolize_keys)
        render_page scope.where(status: params[:status].presence || "open").order(date: :desc, id: :desc), FuelAlertBlueprint,
                    meta: { counts: }
      end

      def check
        alert = authorize policy_scope(FuelAlert).find(params[:id]), :update?
        alert.check!(current_user)
        render_data alert, FuelAlertBlueprint
      end

      def reopen
        alert = authorize policy_scope(FuelAlert).find(params[:id]), :update?
        alert.reopen!
        render_data alert, FuelAlertBlueprint
      end
    end
  end
end
