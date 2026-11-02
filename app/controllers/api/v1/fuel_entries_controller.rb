# Fleet > Fuel & Energy: the monthly log, vehicle cards, the entry form (with receipt reading) and delete.
module Api
  module V1
    class FuelEntriesController < BaseController
      INCLUDES = %i[vehicle driver fuel_company created_by].freeze
      FIELDS = %i[vehicle_id date time kind quantity cost odometer full fuel_company_id station note].freeze

      # GET /fuel_entries?month=2026-11&kind=all|fuel|elec|def&vehicle_id= — the month's log, newest first.
      def index
        authorize FuelEntry
        scope = policy_scope(FuelEntry).includes(*INCLUDES).in_month(month).of_kind(params[:kind])
        scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
        render_list scope.order(date: :desc, time: :desc, id: :desc), FuelEntryBlueprint,
                    meta: { month: month.strftime("%Y-%m"), next_month: month < Date.current.beginning_of_month }
      end

      # GET /fuel_entries/vehicles?month= — a card per own vehicle (month cost, efficiency, cost per km, last entry).
      def vehicles
        authorize FuelEntry, :index?
        list = Vehicle.kept.own.order(:plate).to_a
        stats = FuelVehicleStats.new(policy_scope(FuelEntry), month:).call(list.map(&:id))
        render json: { data: list.map { |v| FuelStatsPresenter.card(v, stats[v.id]) } }
      end

      # GET /fuel_entries/new?vehicle_id= — a blank entry: now, the kind of the bus's last entry, its last odometer.
      def new
        authorize FuelEntry, :create?
        vehicle = params[:vehicle_id].presence && Vehicle.kept.own.find(params[:vehicle_id])
        last = vehicle && policy_scope(FuelEntry).where(vehicle:).latest_first.first
        now = Time.current
        render json: { data: { vehicle_id: vehicle&.id, date: now.to_date, time: now.strftime("%H:%M"), kind: last&.kind || "diesel",
                               full: true, last_odometer: policy_scope(FuelEntry).where(vehicle:).maximum(:odometer) } }
      end

      def show
        render_data authorize(find), FuelEntryBlueprint
      end

      # POST { fuel_entry: {...}, receipt (file) | document_read_id } → meta { filled, warnings }
      def create = save(authorize(FuelEntry.new), :created)

      def update = save(authorize(find), :ok)

      def destroy
        entry = authorize find
        entry.destroy!
        FuelEntries::Recompute.call(vehicle: entry.vehicle)
        FuelAlerts::Scan.call
        head :no_content
      end

      private

      def find = policy_scope(FuelEntry).includes(*INCLUDES).find(params[:id])

      def month
        @month ||= params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.current.beginning_of_month
      rescue Date::Error
        raise ActionController::BadRequest, "month must be YYYY-MM"
      end

      def save(entry, status)
        read = params[:document_read_id].presence && policy_scope(DocumentRead).find(params[:document_read_id])
        result = FuelEntries::Save.call(entry:, attributes: params.require(:fuel_entry).permit(*FIELDS), user: current_user,
                                        receipt: params[:receipt], document_read: read)
        render json: {
          data: FuelEntryBlueprint.render_as_hash(policy_scope(FuelEntry).includes(*INCLUDES).find(result.entry.id).decorate),
          meta: { filled: result.filled, warnings: result.warnings }
        }, status:
      end
    end
  end
end
