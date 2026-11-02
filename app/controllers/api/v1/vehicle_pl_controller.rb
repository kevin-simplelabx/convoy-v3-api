# Finance > Vehicle Financials (profit and loss): fleet and vehicle P&L by period and basis, cost spikes (Mark Checked),
# due in the next 90 days, and manual revenue / cost entries.
module Api
  module V1
    class VehiclePlController < BaseController
      # GET /finance/vehicles/pl?period=month|ytd|this_year|last_year|last_12|all&basis=profit|cash&month=2026-10
      def fleet
        authorize :finance, :vehicles?
        render json: { data: report.fleet }
      end

      # GET /finance/vehicles/:vehicle_id/pl?period=&basis=&month=
      def vehicle
        authorize :finance, :vehicles?
        v = Vehicle.kept.own.find(params[:vehicle_id])
        render json: { data: report(vehicles: [ v ]).vehicle(v).merge(entries: entries_json(v)) }
      end

      # GET /finance/vehicles/spikes?month=
      def spikes
        authorize :finance, :vehicles?
        render json: { data: report.spikes }
      end

      # POST /finance/vehicles/spikes/ack { vehicle_id, category, month }
      def ack_spike
        authorize :finance, :update_vehicles?
        VehicleCostSpikeAck.find_or_create_by!(vehicle: Vehicle.kept.own.find(params.require(:vehicle_id)), category: params.require(:category),
                                               month: Date.strptime(params.require(:month), "%Y-%m")) { |a| a.checked_by = current_user }
        head :no_content
      end

      # GET /finance/vehicles/due
      def due
        authorize :finance, :vehicles?
        render json: { data: report.due }
      end

      # POST /finance/vehicles/:vehicle_id/entries { entry: { kind, category, entry_on, amount, repeats_monthly, note } }
      def create_entry
        authorize :finance, :update_vehicles?
        v = Vehicle.kept.own.find(params[:vehicle_id])
        v.finance_entries.create!(entry_params.merge(company_id: v.company_id, created_by: current_user))
        render json: { data: entries_json(v) }, status: :created
      end

      # PATCH /finance/vehicles/:vehicle_id/entries/:id { entry: { …, repeat_until } } (Stop repeating from a month)
      def update_entry
        authorize :finance, :update_vehicles?
        entry = find_entry
        entry.update!(entry_params)
        render json: { data: entries_json(entry.vehicle) }
      end

      def destroy_entry
        authorize :finance, :update_vehicles?
        entry = find_entry
        entry.destroy!
        render json: { data: entries_json(entry.vehicle) }
      end

      private

      def report(vehicles: nil)
        month = params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.current
        Finance::VehicleReport.new(period: params[:period], basis: params[:basis], month:, vehicles:)
      rescue Date::Error
        raise ApplicationService::Error, "Month must look like 2026-11"
      end

      def find_entry = VehicleFinanceEntry.where(vehicle: Vehicle.kept.own.find(params[:vehicle_id])).find(params[:id])

      def entry_params = params.expect(entry: %i[kind category entry_on amount repeats_monthly repeat_until note])

      def entries_json(v)
        v.finance_entries.order(entry_on: :desc).map do |e|
          e.slice(:id, :kind, :category, :entry_on, :amount, :repeats_monthly, :repeat_until, :note)
        end
      end
    end
  end
end
