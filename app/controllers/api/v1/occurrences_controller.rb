# Runs for drivers and admins (today, tomorrow, a date or a range; by driver, vehicle, trip, status), the drawer
# detail, and what can be done to one run.
module Api
  module V1
    class OccurrencesController < BaseController
      before_action :set_occurrence, except: %i[index list]

      # GET /occurrences?date= | from=&to= &driver_id= &operator_driver_id= &vehicle_id= &trip_id= &status= &unassigned=1
      def index
        authorize TripOccurrence
        scope = policy_scope(TripOccurrence).visible.includes(*OccurrenceWindow::INCLUDES)
        scope = filter(scope)
        render_page scope.chronological, TripOccurrenceBlueprint
      end

      # GET /occurrences/list?from=&to= &q= &kind= &operator= &status_group= &sort= — the Trips page (meta: chip counts, filter menus).
      def list
        authorize TripOccurrence, :index?
        search = RunSearch.new(policy_scope(TripOccurrence), params)
        render_page search.call, TripOccurrenceBlueprint, view: :list, meta: search.facets
      end

      def show
        authorize @occ
        render_drawer @occ
      end

      # PATCH { lock_version, by_client } — by_client: cancelled at the client's request.
      def cancel = act(:cancel?) { |e| e.cancel!(by_client: ActiveModel::Type::Boolean.new.cast(params[:by_client]) || false) }
      def restore = act(:restore?) { |e| e.restore! }
      # PATCH /occurrences/:id/end { lock_version } — Force End Trip.
      def end_run = act(:end?) { |e| e.force_end! }

      # POST /occurrences/:id/issue { reason } raises; DELETE clears.
      def issue = act(:issue?) { |e| e.raise_issue!(params.require(:reason)) }
      def clear_issue = act(:issue?) { |e| e.clear_issue! }

      # GET /occurrences/:id/move_preview?vehicle_id= — choices, warnings and cost to prefill before a drop.
      def move_preview
        authorize @occ, :show?
        render json: { data: Occurrences::MovePreview.call(occurrence: @occ, vehicle: target_vehicle) }
      end

      # POST /occurrences/:id/move { vehicle_id (empty = Unassigned), scope: one | later, cost, cost_basis, lock_version }
      # School route runs: { vehicle_id, scope: one | range | perm, starts_on, ends_on, arranged_by, daily_rate, deduct, reason }
      def move
        authorize @occ, :move?
        return move_route if @occ.school_route_id

        moved = Occurrences::Move.call(occurrence: @occ, vehicle: target_vehicle, scope: params.require(:scope), user: current_user,
                                       cost: params[:cost], cost_basis: params[:cost_basis], lock_version: params[:lock_version])
        render json: { data: TripOccurrenceBlueprint.render_as_hash(moved.map(&:decorate)) }
      end

      # POST /occurrences/:id/tracking_link — a public link to this run (Trip Tracking page ?trk=token).
      def tracking_link
        authorize @occ, :share?
        link = Occurrences::ShareTracking.call(@occ, current_user)
        render json: { data: { token: link.token, expires_at: link.expires_at, api_path: "/api/v1/public/tracking/#{link.token}" } }, status: :created
      end

      # GET /occurrences/:id/passengers — Passenger List (School Run).
      def passengers
        authorize @occ, :show?
        render json: { data: SchoolRuns::Passengers.call(@occ) }
      end

      # PATCH /occurrences/:id/passengers/:key { mark: boarded | alighted | not_boarded | expected }
      def mark_passenger
        authorize @occ, :move?
        Occurrences::MarkPassengers.call(occ: @occ, marks: [ { key: params[:key], state: params.require(:mark) } ],
                                         by: current_user.name, source: "office")
        render json: { data: SchoolRuns::Passengers.call(@occ) }
      end

      # PATCH /occurrences/:id/regular_bus — Back to Regular Bus.
      def regular_bus = act(:move?) { |e| e.reset_vehicle! }

      # PATCH /occurrences/:id/time { start_time, scope: today | from_here | reset }
      def time
        act(:time?) do |e|
          case params.require(:scope)
          when "today" then e.shift_today!(params.require(:start_time))
          when "from_here" then e.change_from_here!(params.require(:start_time))
          when "reset" then e.reset_time!
          else raise ActionController::BadRequest, "scope must be today, from_here or reset"
          end
        end
      end

      private

      def target_vehicle = params[:vehicle_id].presence && Vehicle.kept.find(params[:vehicle_id])

      def move_route
        occ = SchoolRoutes::Move.call(occurrence: @occ, vehicle: target_vehicle, scope: params.require(:scope), user: current_user,
                                      starts_on: params[:starts_on], ends_on: params[:ends_on], arranged_by: params[:arranged_by].presence || "operator",
                                      daily_rate: params[:daily_rate], deduct: params.fetch(:deduct, true), reason: params[:reason])
        render json: { data: TripOccurrenceBlueprint.render_as_hash([ occ.decorate ]) }
      end

      def set_occurrence
        @occ = policy_scope(TripOccurrence).includes(*OccurrenceWindow::INCLUDES, :cancelled_by, :issue_raised_by, :ended_by).find(params[:id])
      end

      def act(query)
        authorize @occ, query
        yield Occurrences::Edit.new(@occ, current_user, lock_version: params[:lock_version])
        render_drawer @occ.reload
      end

      # The drawer shows the whole trip: load it with everything it needs.
      def render_drawer(occ, status: :ok)
        occ.trip = Trip.with_discarded.includes(*Trip::FULL_INCLUDES).find(occ.trip_id) if occ.trip_id
        render_data occ, TripOccurrenceBlueprint, view: :drawer, status:
      end

      def filter(scope)
        scope = scope.on(Date.parse(params[:date])) if params[:date].present?
        scope = scope.between(Date.parse(params[:from]), Date.parse(params[:to])) if params[:from].present? && params[:to].present?
        %i[driver_id operator_driver_id vehicle_id trip_id client_id].each { |k| scope = scope.where(k => params[k]) if params[k].present? }
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.unassigned if ActiveModel::Type::Boolean.new.cast(params[:unassigned])
        scope
      end
    end
  end
end
