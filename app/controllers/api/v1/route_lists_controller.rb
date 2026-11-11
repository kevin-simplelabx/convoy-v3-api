# Import Route List (School Run trip form): review a read list, apply it onto a saved School Run, the Earlier Lists,
# and the Next 12 Months bill.
module Api
  module V1
    class RouteListsController < BaseController
      # Import Route List is a paid add-on: 403 when Convoy Admin has it off for the company.
      before_action do
        raise Pundit::NotAuthorizedError, "Import Route List is not enabled for this company" unless current_company.route_list_import_enabled?
      end

      # POST /route_lists/review { document_read_id, joins: [bool per row], trip_id }
      def review
        authorize Trip, :create?
        render json: { data: SchoolRuns::RouteListReview.call(read:, joins:, trip: params[:trip_id].presence && school_run(params[:trip_id])) }
      end

      # POST /trips/:trip_id/route_list { document_read_id, joins, apply_from } — Apply From on a saved School Run.
      def apply
        trip = authorize school_run(params[:trip_id]), :update?
        review = SchoolRuns::RouteListReview.call(read:, joins:, trip:)
        SchoolRuns::ApplyRouteList.call(trip:, review:, apply_from: Date.parse(params.require(:apply_from)), user: current_user,
                                        file_name: read.file&.file&.filename)
        render_data Trip.includes(*Trip::FULL_INCLUDES).find(trip.id), TripBlueprint, view: :full
      end

      # GET /trips/:trip_id/route_list_versions — Earlier Lists.
      def versions
        trip = authorize school_run(params[:trip_id]), :show?
        render json: {
          data: trip.route_list_versions.includes(stops: :students).map do |v|
            { id: v.id, name: v.name, valid_until: v.valid_until, stops: v.stops.size, students: v.stops.sum { |s| s.students.size } }
          end
        }
      end

      # GET /trips/:trip_id/school_run_bill?from= — Next 12 Months.
      def bill
        trip = authorize school_run(params[:trip_id]), :show?
        months = SchoolRuns::BillPreview.call(trip, params[:from].present? ? Date.parse(params[:from]) : Date.current)
        render json: { data: months, meta: { total: months.sum { |m| m[:amount] }, empty_months: months.count { |m| m[:runs].zero? } } }
      end

      private

      def read = @read ||= policy_scope(DocumentRead).find(params.require(:document_read_id))
      def joins = params[:joins].presence&.map { |j| ActiveModel::Type::Boolean.new.cast(j) }
      def school_run(id) = Trip.kept.school_run.includes(stops: %i[students photos]).find(id)
    end
  end
end
