# School Bus › Bus Service Requests: a school's requests (New Service by academic year, Change of Address / Service, Stop
# Service), a request with its history, Add Application, opening one (Under Review), Acknowledge / Move Answer Date for
# mid-year requests, Waitlist / Decline and Message (one or many).
module Api
  module V1
    class BusRequestsController < BaseController
      FILTERS = %i[status tag level session deadline check q page limit].freeze

      # GET /schools/:school_id/bus_requests?kind=new&academic_year_id=&status=&tag=&level=&session=&deadline=&q=&page=&limit=
      def index
        school = find_school
        authorize BusRequest
        years = school.academic_years.includes(:registration, :terms).to_a
        year = params[:academic_year_id].present? ? years.find { it.id == params[:academic_year_id].to_i } : BusRequests.default_year(years)
        raise ActiveRecord::RecordNotFound unless year || years.empty?

        out = BusRequests::Board.new(school, year:, years:, kind: params[:kind] || "new", filters: params.permit(*FILTERS).to_h.symbolize_keys).call
        render json: { data: out[:rows], meta: out[:meta] }
      end

      def show
        render json: { data: BusRequests.detail(authorize(find)) }
      end

      # GET /bus_requests/alerts — the bell and the strip: requests that need someone across the schools the user opens.
      def alerts
        authorize BusRequest, :index?
        items = BusRequests::Alerts.new(policy_scope(School)).call
        render json: { data: items, meta: BusRequests::Alerts.summary(items) }
      end

      # GET /bus_requests/digest — the 08:00 email to School Bus admins as it would go today (recorded, not sent).
      def digest
        authorize BusRequest, :index?
        p = BusRequests::Digest.new(ActsAsTenant.current_tenant).preview
        render json: { data: { to: p[:to].map(&:name), subject: p[:subject], groups: p[:groups] } }
      end

      # POST /schools/:school_id/bus_requests { academic_year_id, child_name, parent_name, parent_phone, parent_email, level, address,
      #   postal, am, pm, start_on, fee_paid }
      def create
        school = find_school
        authorize BusRequest
        year = school.academic_years.find(params.require(:academic_year_id))
        req = BusRequests::Add.call(year, add_params, user: current_user)
        render json: { data: BusRequests.detail(find(req.id)) }, status: :created
      end

      # POST /bus_requests/:id/open — the first time a request is opened it is Under Review (mid-year ones wait for Acknowledge).
      def open
        req = authorize find, :update?
        if req.status == "Requested" && !BusRequests.mid?(req, BusRequests.mid_settings(req.academic_year))
          req.update!(status: "Under Review")
          req.log!("Opened by #{current_user.name}. Under review", by: current_user)
        end
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/acknowledge { answer_by, note }
      def acknowledge
        req = authorize find, :update?
        BusRequests::Acknowledge.call(req, answer_by: params[:answer_by], note: params[:note], user: current_user)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/move_answer { answer_by, reason }
      def move_answer
        req = authorize find, :update?
        BusRequests::MoveAnswer.call(req, answer_by: params[:answer_by], reason: params[:reason], user: current_user)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/accept { amount, note, start_on } — Accept and Send Quote.
      def accept
        req = authorize find, :update?
        BusRequests::Accept.call([ req ], user: current_user, quote: params.permit(:amount, :note, :start_on).to_h.symbolize_keys)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/reoffer — a lapsed offer sent again (same quote and invoice number, new hours to pay).
      def reoffer
        req = authorize find, :update?
        BusRequests::Accept.call([ req ], user: current_user, reoffer: true)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/record_payment { method } — Record First Invoice Paid: Active.
      def record_payment
        req = authorize find, :update?
        BusRequests::RecordPayment.call(req, method: params[:method], user: current_user)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/confirm_change { amount, note, stop } — Change of Address (stop needed) or Service; Change the Fare when Not Agreed.
      def confirm_change
        req = authorize find, :update?
        BusRequests::ConfirmChange.call(req, amount: params[:amount], note: params[:note], stop: params[:stop], user: current_user)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/confirm_stop { last_on, note }
      def confirm_stop
        req = authorize find, :update?
        BusRequests::ConfirmStop.call(req, last_on: params[:last_on], note: params[:note], user: current_user)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/not_agreed { choice: keep | stop } — after the parent turned down a higher fare for a move.
      def not_agreed
        req = authorize find, :update?
        BusRequests::NotAgreed.call(req, choice: params[:choice], user: current_user)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /bus_requests/:id/end_rider — End Rider / Remove from Rider List.
      def end_rider
        req = authorize find, :update?
        BusRequests::EndRider.call(req, user: current_user)
        render json: { data: BusRequests.detail(find(req.id)) }
      end

      # POST /schools/:school_id/bus_requests/accept { ids: [] } — accept many at their Bus Fares quotes.
      def accept_many
        reqs = pick
        list = BusRequests::Accept.call(reqs, user: current_user)
        render json: { data: { updated: list.size } }
      end

      # POST /schools/:school_id/bus_requests/decide { ids: [], to: Waitlisted | Declined, reason, note }
      def decide
        reqs = pick
        BusRequests::Decide.call(reqs, to: params[:to], reason: params[:reason], note: params[:note], user: current_user)
        render json: { data: { updated: reqs.size } }
      end

      # POST /schools/:school_id/bus_requests/message { ids: [], text }
      def message
        reqs = pick
        BusRequests::Message.call(reqs, text: params[:text], user: current_user)
        render json: { data: { updated: reqs.size } }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def find(id = params[:id])
        BusRequest.where(school: policy_scope(School)).includes(:family, :school_rider, :events, :acked_by, :quoted_by, :confirmed_by, :places, { first_bill: :payments },
                                                                answer_moves: :moved_by, academic_year: %i[registration terms])
                                .find(id)
      end

      def pick
        school = find_school
        authorize BusRequest, :update?
        ids = Array(params[:ids]).map(&:to_i).uniq
        raise ApplicationService::Error, "Pick at least one request" if ids.empty?

        reqs = school.bus_requests.includes(:events, :places, { first_bill: :payments }, :school_rider, :family, academic_year: :registration).where(id: ids).to_a
        raise ActiveRecord::RecordNotFound if reqs.size != ids.size

        reqs
      end

      def add_params
        p = params.permit(:child_name, :parent_name, :parent_phone, :parent_email, :level, :address, :postal, :am, :pm, :start_on, :fee_paid)
                  .to_h.symbolize_keys
        %i[am pm fee_paid].each { p[it] = ActiveModel::Type::Boolean.new.cast(p[it]) if p.key?(it) }
        p
      end
    end
  end
end
