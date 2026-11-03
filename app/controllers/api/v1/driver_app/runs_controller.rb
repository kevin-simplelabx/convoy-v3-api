# Convoy Driver app › Drive (Today / Tomorrow), Plan (month and day), the floating on-going trip and Trip Details: the
# runs of the company picked for the sign-in that this driver drives (or a replacement took from them).
module Api
  module V1
    module DriverApp
      class RunsController < BaseController
        MAX_DAYS = 31

        before_action :require_membership!
        rescue_from(Date::Error) { render_error(:unprocessable_content, "Dates are YYYY-MM-DD, months YYYY-MM") }

        # GET /driver/runs?date=YYYY-MM-DD (default today) or ?from=&to= (up to 31 days)
        def index
          from, to = range
          runs = ::DriverApp::Runs.scope(current_membership).where(date: from..to).includes(::DriverApp::Runs::INCLUDES).order(:starts_at, :id).to_a
          render json: { data: ::DriverApp::RunList.call(member: current_membership, runs:), meta: { from:, to:, vehicle_switches: switches(from, to) } }
        end

        # GET /driver/runs/schedule?month=YYYY-MM → the days of the month with runs (Plan calendar dots)
        def schedule
          month = parse_month(params[:month])
          counts = ::DriverApp::Runs.scope(current_membership).where(date: month..month.end_of_month).group(:date).count
          render json: { data: { month: month.strftime("%Y-%m"), days: counts.sort.map { |date, runs| { date:, runs: } } } }
        end

        # GET /driver/runs/on_going → the run being driven (started, not ended), or null
        def on_going
          occ = ::DriverApp::Runs.on_the_road(current_membership)
          render json: { data: occ && ::DriverApp::RunList.new(member: current_membership, runs: [ occ ]).card(occ) }
        end

        # GET /driver/runs/:id
        def show
          render json: { data: ::DriverApp::RunDetail.call(member: current_membership, occ: run(::DriverApp::Runs::DETAIL_INCLUDES)) }
        end

        # POST /driver/runs/:id/start | arrive | leave | skip_stop | attendance | count | complete | force_end | skip,
        # PATCH /driver/runs/:id/route — { client_id, at, … } → Trip Details after the action (meta.replayed: sent before).
        ::DriverApp::Drive::ACTIONS.each do |action|
          define_method(action) do
            occ = run(::DriverApp::Runs::DETAIL_INCLUDES)
            _occ, replayed = ::DriverApp::Drive.call(account: current_account, member: current_membership, occ:, action:,
                                                     params: params.except(:controller, :action, :id, :format).permit!)
            render json: { data: ::DriverApp::RunDetail.call(member: current_membership, occ: run(::DriverApp::Runs::DETAIL_INCLUDES)),
                           meta: { replayed: } }
          end
        end

        # POST /driver/runs/:id/geofence { position, event: enter | exit, at } — the phone's geofence alert
        def geofence
          occ = run(::DriverApp::Runs::DETAIL_INCLUDES)
          e = ::DriverApp::Geofence.call(occ:, member: current_membership, position: params.require(:position), event: params.require(:event), at: params[:at])
          render json: { data: { position: e.position, entered_at: e.geofence_entered_at, exited_at: e.geofence_exited_at, arrived_at: e.arrived_at } }
        end

        # POST /driver/runs/:id/seen
        def seen
          occ = ::DriverApp::MarkSeen.call(occ: run(::DriverApp::Runs::INCLUDES), member: current_membership)
          render json: { data: ::DriverApp::RunList.new(member: current_membership, runs: [ occ ]).card(occ) }
        end

        private

        # The Switch Vehicle cards: buses this driver takes over in the range (from now on), in time order with the runs.
        def switches(from, to)
          ::DriverApp::Vehicles.switches(current_membership, to:).select { it[:starts_at].to_date.between?(from, to) }.map do |sw|
            { starts_at: sw[:starts_at], vehicle: { id: sw[:vehicle].id, plate: sw[:vehicle].plate },
              handover_done: VehicleHandover.exists?(driver_id: current_membership.id, vehicle_id: sw[:vehicle].id, at: sw[:starts_at].to_date.all_day) }
          end
        end

        def run(includes) = ::DriverApp::Runs.scope(current_membership).includes(includes).find_by!(id: params[:id])

        def range
          from = parse_date(params[:from] || params[:date]) || Date.current
          to = parse_date(params[:to]) || from
          raise ApplicationService::Error, "to must be on or after from" if to < from
          raise ApplicationService::Error, "Ask for #{MAX_DAYS} days at most" if (to - from).to_i >= MAX_DAYS

          [ from, to ]
        end

        def parse_date(value) = value.presence && Date.iso8601(value)
        def parse_month(value) = value.present? ? Date.strptime(value, "%Y-%m") : Date.current.beginning_of_month
      end
    end
  end
end
