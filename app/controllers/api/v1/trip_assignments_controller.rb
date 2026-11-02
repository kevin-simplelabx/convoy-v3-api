# Assign page of a trip: every run x vehicle slot with who runs it as of a date, the history, and give or take back.
module Api
  module V1
    class TripAssignmentsController < BaseController
      before_action :set_trip

      # GET /trips/:trip_id/assignments?from=
      def index
        authorize TripAssignment
        as_of = params[:from].present? ? Date.parse(params[:from]) : [ Date.current, @trip.starts_on ].max
        history = @trip.assignments.includes(:operator, :vehicle, :created_by, slots: :trip_run).reverse
        render json: {
          data: {
            as_of:, operator_cancel_rule: @trip.operator_cancel_rule,
            slots: Assignments::Board.call(@trip, as_of).map(&:to_h),
            history: history.map { |a| entry(a) }
          }
        }
      end

      # POST { effective_from, slots: ["d1r0|1", "trip|2"], assignee: own | operator | none, operator_id, vehicle_id, pay_amount, pay_basis }
      def create
        authorize TripAssignment
        p = params.permit(:effective_from, :assignee, :operator_id, :vehicle_id, :pay_amount, :pay_basis, slots: [])
        assignment = Assignments::Create.call(
          trip: @trip, effective_from: Date.parse(p.require(:effective_from)), slots: slot_ids(p[:slots]),
          assignee: p.require(:assignee), user: current_user,
          operator: p[:operator_id].presence && Operator.kept.find(p[:operator_id]),
          vehicle: p[:vehicle_id].presence && Vehicle.kept.find(p[:vehicle_id]),
          pay_amount: p[:pay_amount].presence, pay_basis: p[:pay_basis].presence || "run"
        )
        render json: { data: entry(assignment.reload) }, status: :created
      end

      def destroy
        Assignments::Remove.call(authorize(@trip.assignments.find(params[:id])))
        head :no_content
      end

      private

      def set_trip
        @trip = Trip.kept.includes(:vehicle_slots, runs: :slots, assignments: :slots).find(params[:trip_id])
      end

      # "d1r0|1" -> [run id, 1]; "trip|2" -> [nil, 2]
      def slot_ids(keys)
        runs = @trip.runs.index_by(&:key)
        Array(keys).map do |key|
          run_key, slot = key.to_s.split("|")
          raise ApplicationService::Error, "No run #{run_key}" unless run_key == "trip" || runs[run_key]

          [ run_key == "trip" ? nil : runs[run_key].id, slot.to_i ]
        end
      end

      def entry(a)
        { id: a.id, effective_from: a.effective_from, assignee: a.assignee, operator_id: a.operator_id, operator_name: a.operator&.name,
          vehicle_id: a.vehicle_id, plate: a.vehicle&.plate, pay_amount: a.pay_amount, pay_basis: a.pay_basis,
          slots: a.slot_keys, by: a.created_by&.name, at: a.created_at }
      end
    end
  end
end
