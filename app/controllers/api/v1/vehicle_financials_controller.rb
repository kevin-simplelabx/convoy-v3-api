# Finance > Vehicle Financials (purchase and loan): own vehicles with their funding status, a vehicle's purchase, loan
# and instalment schedule, the edit form (with the lender's schedule read by Claude), instalments marked paid.
module Api
  module V1
    class VehicleFinancialsController < BaseController
      # GET /finance/vehicles?filter=all|loan|cash|none&q=
      def index
        authorize :finance, :vehicles?
        vehicles = Vehicle.kept.own.includes(financial: :payments).order(:plate).to_a # rows carry next_due ("No. 3 of 60 | S$2,334.00")
        rows = vehicles.map { |v| row(v) }
        kpis = { purchase_cost: rows.sum(0.to_d) { |r| r[:purchase_price].to_d }, owed: rows.sum(0.to_d) { |r| r[:owed].to_d },
                 monthly: rows.select { |r| r[:status].in?(%w[loan_active overdue]) }.sum(0.to_d) { |r| r[:monthly].to_d },
                 due_this_month: rows.sum(0.to_d) { |r| r[:due_this_month].to_d } }
        rows = rows.select { |r| filter?(r) }
        rows = rows.select { |r| [ r[:plate], r[:make], r[:model], r[:lender] ].compact.any? { |s| s.downcase.include?(params[:q].downcase) } } if params[:q].present?
        render json: { data: rows, meta: kpis }
      end

      def show
        authorize :finance, :vehicles?
        render_vehicle
      end

      # PATCH /finance/vehicles/:vehicle_id (multipart with schedule_file) { financial: {...}, document_read_id, use_anyway }
      def update
        authorize :finance, :update_vehicles?
        read = params[:document_read_id].presence && policy_scope(DocumentRead).find(params[:document_read_id])
        VehicleFinance::Save.call(vehicle:, params: params.fetch(:financial, {}).permit(*VehicleFinance::Save::FIELDS, *VehicleFinance::Save::FLAGS, :schedule_file).to_h.symbolize_keys,
                                  user: current_user, document_read: read, use_anyway: ActiveModel::Type::Boolean.new.cast(params[:use_anyway]))
        render_vehicle
      end

      # POST /finance/vehicles/:vehicle_id/instalments { numbers: [1, 2], paid: true, paid_on } — without paid_on each
      # instalment is paid on its due date, or today when that is still ahead.
      def instalments
        authorize :finance, :update_vehicles?
        fin = vehicle.financial || raise(ApplicationService::Error, "Enter the loan first")
        numbers = Array(params.require(:numbers)).map(&:to_i)
        if ActiveModel::Type::Boolean.new.cast(params.fetch(:paid, true))
          due = fin.schedule.rows.to_h { [ it.n, it.due_on ] }
          numbers.each do |n|
            paid_on = params[:paid_on].presence || [ due[n], Date.current ].compact.min
            fin.payments.find_or_create_by!(instalment_no: n) { |p| p.assign_attributes(paid_on:, recorded_by: current_user) }
          end
        else
          fin.payments.where(instalment_no: numbers).destroy_all
        end
        render_vehicle
      end

      private

      def vehicle = @vehicle ||= Vehicle.kept.own.find(params[:vehicle_id])

      def filter?(r)
        case params[:filter]
        when "loan" then r[:funding] == "loan"
        when "cash" then r[:funding] == "cash"
        when "none" then r[:status] == "no_details"
        else true
        end
      end

      def row(v)
        f = v.financial
        s = f&.schedule
        { vehicle_id: v.id, plate: v.plate, make: v.make, model: v.model, status: f ? f.status : "no_details", funding: f&.funding,
          lender: f&.lender, purchase_price: f&.purchase_price, owed: s&.valid? ? s.owed : nil, monthly: s&.valid? ? s.monthly : nil,
          due_this_month: s ? s.rows.select { |r| r.status.in?(%w[due overdue]) }.sum(0.to_d, &:amount) : 0.to_d,
          next_due: s&.next_due && s.next_due.to_h.slice(:n, :due_on, :amount).merge(of: s.tenure) }
      end

      def render_vehicle
        v = Vehicle.kept.own.includes(financial: [ :document_read, { payments: :recorded_by } ]).find(vehicle.id)
        f = v.financial
        s = f&.schedule
        by = f ? f.payments.to_h { [ it.instalment_no, it.recorded_by&.shown_name ] } : {}
        render json: { data: row(v).merge(
          financial: f && f.slice(*VehicleFinance::Save::FIELDS).merge(schedule_file: f.decorate.file_info(:schedule_file), updated_at: f.updated_at),
          schedule: s&.summary, rows: s ? s.rows.map { it.to_h.merge(paid_by: by[it.n]) } : []
        ) }
      end
    end
  end
end
