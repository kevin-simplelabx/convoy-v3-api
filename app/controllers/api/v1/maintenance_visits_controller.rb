# Maintenance dialog (Scheduler toolbar, empty slot, Fleet > Maintenance): plan a visit, record the work, cancel, delete.
module Api
  module V1
    class MaintenanceVisitsController < BaseController
      FULL = [ :vehicle, :driver, :workshop, :completed_by, :lines, :invoices ].freeze
      FIELDS = [ :vehicle_id, :driver_id, :date, :start_time, :end_time, :workshop_id, :address, :kind, :work_to_do, :status,
                 :odometer, :gst_on, :gst_rate,
                 { lines_attributes: %i[id position line_type description part_number brand model tyre_position quantity unit_price _destroy] } ].freeze

      # GET /maintenance_visits?tab=upcoming|to_record|completed|cancelled&q=&vehicle_id= (Fleet > Maintenance; meta.counts
      # per tab) or ?from=&to=&vehicle_id= (every visit in the dates, soonest first).
      def index
        authorize MaintenanceVisit
        scope = policy_scope(MaintenanceVisit).includes(:vehicle, :driver, :workshop, :lines, :invoices)
        if params[:from].present? && params[:to].present?
          scope = scope.between(Date.parse(params[:from]), Date.parse(params[:to])).order(:date, :start_time)
          scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
          return render_page scope, MaintenanceVisitBlueprint
        end

        page = MaintenancePage.new(scope, params)
        render_page page.list, MaintenanceVisitBlueprint, meta: { counts: page.counts }
      end

      # GET /maintenance_visits/summary?vehicle_id= — KPI tiles, spend of the last 12 months, tyre changes.
      def summary
        authorize MaintenanceVisit, :index?
        page = MaintenancePage.new(policy_scope(MaintenanceVisit), params)
        render json: { data: { kpis: page.kpis, spend: page.spend } }
      end

      # GET /maintenance_visits/new?vehicle_id=&date=&start_time= — a blank visit: the bus's default driver that day, 2 hours.
      def new
        authorize MaintenanceVisit, :create?
        vehicle = Vehicle.kept.own.find(params.require(:vehicle_id))
        date = params[:date].present? ? Date.parse(params[:date]) : Date.current
        start = Clock.minutes(params[:start_time].presence || "09:00")
        driver = vehicle.default_driver_on(date)
        render json: { data: { vehicle_id: vehicle.id, plate: vehicle.plate, driver_id: driver.is_a?(Driver) ? driver.id : nil,
                               date:, start_time: Clock.hm(start), end_time: Clock.hm([ start + 120, 1439 ].min),
                               kind: "service", status: "scheduled", gst_on: true, gst_rate: 9, tyre_positions: vehicle.tyre_positions } }
      end

      def show
        render_data authorize(find), MaintenanceVisitBlueprint, view: :full
      end

      # POST { maintenance_visit: {...}, workshop_name, workshop_address, invoice (file) | document_read_id }
      def create
        save(authorize(MaintenanceVisit.new), :created)
      end

      def update
        save(authorize(find), :ok)
      end

      def cancel
        visit = authorize find
        visit.update!(status: "cancelled")
        render_data visit, MaintenanceVisitBlueprint, view: :full
      end

      # DELETE — any saved visit, with its lines and invoice files; a completed one's cost leaves Vehicle Financials.
      def destroy
        authorize(find).destroy!
        head :no_content
      end

      private

      def find = policy_scope(MaintenanceVisit).includes(*FULL).find(params[:id])

      def save(visit, status)
        read = params[:document_read_id].presence && policy_scope(DocumentRead).find(params[:document_read_id])
        result = Maintenance::Save.call(visit:, attributes: params.require(:maintenance_visit).permit(*FIELDS), user: current_user,
                                        workshop_name: params[:workshop_name], workshop_address: params[:workshop_address],
                                        invoice: params[:invoice], document_read: read)
        render json: {
          data: MaintenanceVisitBlueprint.render_as_hash(policy_scope(MaintenanceVisit).includes(*FULL).find(result.visit.id).decorate, view: :full),
          meta: { filled: result.filled, warnings: result.warnings }
        }, status:
      end
    end
  end
end
