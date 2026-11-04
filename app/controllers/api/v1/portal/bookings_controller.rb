# Client Portal › Bookings: the list (Upcoming, Awaiting Approval, Past), a booking's details, New Booking (its form
# data, the live estimate with the approval it will get, Submit) and Accept Changes on a trip the transport company
# changed. Bookings cannot be edited or cancelled here (not in the design).
module Api
  module V1
    module Portal
      class BookingsController < AppController
        include Pagy::Backend

        TABS = %w[upcoming awaiting past].freeze
        LIST_INCLUDES = [ :client, :created_by, { client_site: [], days: { trips: [ :day, :points, :changes_made ] }, approval: ::Portal::Approval::INCLUDES } ].freeze
        FULL_INCLUDES = [ *LIST_INCLUDES, :attachments, { days: { trips: [ :day, :points, :changes_made, { vehicles: :vehicle_type } ] } } ].freeze

        # GET /portal/bookings?tab=upcoming|awaiting|past&page= — newest first; meta.counts: the three tabs.
        def index
          authorize_portal Booking
          base = visible
          tab = TABS.include?(params[:tab]) ? params[:tab] : "upcoming"
          pagy, records = pagy(in_tab(base, tab).includes(*LIST_INCLUDES).order(created_at: :desc, id: :desc))
          render json: { data: PortalBookingBlueprint.render_as_hash(records, **view_options(records)),
                         meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages, tab:,
                                 counts: TABS.index_with { in_tab(base, it).count } } }
        end

        def show
          authorize_portal Booking, :show?
          render_booking visible.find(params[:id])
        end

        # GET /portal/bookings/form — what New Booking offers this person.
        def form
          authorize_portal Booking, :create?
          render json: { data: ::Portal::BookingForm.call(client_user: current_client_user) }
        end

        # POST /portal/bookings/estimate { booking: { client_site_id, days: [{ date, trips: [...] }] } } — nothing saved.
        def estimate
          authorize_portal Booking, :create?
          render json: { data: ::Portal::BookingEstimate.call(client_user: current_client_user, params: booking_params) }
        end

        # POST /portal/bookings { booking: {...} } (JSON), or multipart: booking (the same as a JSON string) + files[]
        def create
          authorize_portal Booking, :create?
          booking = ::Portal::SubmitBooking.call(client_user: current_client_user, params: booking_params, files: params[:files])
          render_booking booking, status: :created
        end

        # POST /portal/bookings/:id/approve { note } — the viewer's decision on the step waiting (Approvals, booking detail)
        def approve
          authorize_portal Booking, :show?
          ::Portal::Approval.for(visible.find(params[:id])).approve!(current_client_user, note: params[:note])
          render_booking visible.find(params[:id])
        end

        # POST /portal/bookings/:id/decline { note } (required: "Why is it declined?")
        def decline
          authorize_portal Booking, :show?
          ::Portal::Approval.for(visible.find(params[:id])).decline!(current_client_user, note: params[:note])
          render_booking visible.find(params[:id])
        end

        # PATCH /portal/booking_trips/:id/accept_changes
        def accept_changes
          trip = BookingTrip.where(booking: visible).find(params[:id])
          authorize_portal Booking, :accept_changes?
          Bookings::TripAction.call(trip:, action: "acknowledge", actor: current_client_user)
          render_booking trip.booking
        end

        private

        def visible = policy_scope([ :portal, Booking ])

        def in_tab(scope, tab)
          days = BookingDay.where("booking_days.booking_id = bookings.id AND booking_days.date >= ?", Date.current).select(1)
          case tab
          when "upcoming" then scope.where("EXISTS (#{days.to_sql})")
          when "past" then scope.where("NOT EXISTS (#{days.to_sql})")
          else scope.where(id: BookingTrip.where(status: "awaiting_client").select(:booking_id))
          end
        end

        def view_options(records)
          { viewer: current_client_user, buses: ::Portal::BookingBuses.call(Array(records).flat_map { it.days.flat_map(&:trips) }) }
        end

        # The booking fields New Booking sends (no client: the signed-in organisation; no standby: the transport company adds it).
        def booking_params
          raw = params.require(:booking)
          raw = ActionController::Parameters.new(JSON.parse(raw)) if raw.is_a?(String)
          raw.permit(*(Bookings::Save::PERMIT - [ :client_id ]))
        rescue JSON::ParserError
          raise ActionController::BadRequest, "booking is not valid JSON"
        end

        def render_booking(booking, status: :ok)
          booking = visible.includes(*FULL_INCLUDES).find(booking.id)
          render json: { data: PortalBookingBlueprint.render_as_hash(booking, view: :full, **view_options([ booking ])) }, status:
        end
      end
    end
  end
end
