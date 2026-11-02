# The Scheduler grid for a date range (Day or Week): the vehicles (with the Scheduler's filters and sort), every run in
# the range (runs exist up to meta.horizon; later dates are empty), the unassigned runs, and the nearest dates with unassigned runs
# before and after the range.
module Api
  module V1
    class SchedulerController < BaseController
      MAX_DAYS = 42

      def show
        authorize :scheduler
        from = Date.parse(params.require(:from))
        to = params[:to].present? ? Date.parse(params[:to]) : from
        return render_error(:bad_request, "Pick up to #{MAX_DAYS} days") if (to - from).to_i >= MAX_DAYS || to < from

        search = VehicleSearch.new(policy_scope(Vehicle).kept, params)
        runs = OccurrenceWindow.new(from:, to:).all
        visits = policy_scope(MaintenanceVisit).on_grid.between(from, to).includes(:vehicle, :driver, :workshop, :lines, :invoices)
        render json: {
          data: {
            vehicles: VehicleBlueprint.render_as_hash(search.call.decorate),
            occurrences: TripOccurrenceBlueprint.render_as_hash(runs.select(&:vehicle_id).map(&:decorate)),
            unassigned: TripOccurrenceBlueprint.render_as_hash(runs.reject(&:vehicle_id).map(&:decorate)),
            # Workshop visits as purple blocks on the bus (not draggable; click opens the maintenance dialog)
            maintenance: MaintenanceVisitBlueprint.render_as_hash(visits.decorate)
          },
          meta: { from:, to:, horizon: Occurrences::Sync.horizon, facets: search.facets, **unassigned_nav(from, to) }
        }
      end

      # GET /scheduler/assign_summary — Assign Trips: every running shuttle with how many run slots are assigned.
      def assign_summary
        authorize :scheduler, :show?
        today = Date.current
        trips = Trip.kept.corporate_shuttle.where("trips.end_mode = 'never' OR trips.ends_on >= ? OR trips.starts_on >= ?", today, today)
                    .includes(:client, :vehicle_slots, runs: :slots, assignments: :slots).order(:title)
        rows = trips.map do |t|
          slots = Assignments::Board.call(t, [ today, t.starts_on ].max)
          done = slots.count { |s| s.vehicle_id || s.operator_id }
          { trip_id: t.id, title: t.title, client_name: t.client.name, runs: t.runs.size, vehicles: t.vehicles_count,
            assigned: done, total: slots.size, status: done == slots.size ? "all" : (done.zero? ? "none" : "some") }
        end
        render json: { data: rows, meta: { open: rows.count { |r| r[:status] != "all" } } }
      end

      private

      # Previous and next dates that have unassigned runs (stored rows).
      def unassigned_nav(from, to)
        scope = TripOccurrence.unassigned.where("starts_at > ?", Time.current)
        { unassigned_before: scope.where(date: ...from).maximum(:date), unassigned_after: scope.where("date > ?", to).minimum(:date) }
      end
    end
  end
end
