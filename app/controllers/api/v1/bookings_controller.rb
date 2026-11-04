# Trips > Bookings: tabs Pending, Approved, Rejected, Completed with search; booking details; Record Booking / Save
# Changes; the estimate of a trip while the form is open.
module Api
  module V1
    class BookingsController < BaseController
      LIST_INCLUDES = [ :client, :client_site, :days, { trips: :day, approval: ::Portal::Approval::INCLUDES } ].freeze
      FULL_INCLUDES = [ :client, :client_site, :created_by, :attachments, { cancel_requests: %i[booking_trip resolved_by] },
                        { approval: ::Portal::Approval::INCLUDES },
                        { trips: :day, days: { trips: [ :day, :points, :standbys, :approved_by, :rejected_by, { vehicles: :vehicle_type },
                                                        { changes_made: :changed_by }, { scheduler_trips: [] } ] } } ].freeze

      # A booking with everything the details page shows, approved trips marked Assigned / Unassigned.
      def self.load(scope, id)
        booking = scope.includes(*FULL_INCLUDES).find(id)
        Bookings::Assignment.load!(booking.days.flat_map(&:trips) + booking.trips.to_a)
        booking
      end

      # GET /bookings?tab=pending|approved|rejected|completed &q= — newest first; meta.counts: the four tabs.
      def index
        authorize Booking
        base = policy_scope(Booking)
        tab = Booking::TABS.include?(params[:tab]) ? params[:tab] : "pending"
        scope = base.in_tab(tab).search(params[:q]).includes(*LIST_INCLUDES).order(created_at: :desc, number: :desc)
        pagy, records = pagy(scope)
        Bookings::Assignment.load!(records)
        render json: { data: BookingBlueprint.render_as_hash(records),
                       meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages, tab:, counts: Booking.tab_counts(base) } }
      end

      def show
        render_booking authorize(find)
      end

      # POST { booking: {..., days: [{ date, trips: [...] }]} }
      def create
        booking = Bookings::Save.call(booking: authorize(Booking.new), params: booking_params, actor: current_user)
        render_booking booking, status: :created
      end

      # PATCH { booking: {...whole booking, days and trips with ids}, lock_version }
      def update
        booking = Bookings::Save.call(booking: authorize(find), params: booking_params, actor: current_user, lock_version: params[:lock_version])
        render_booking booking
      end

      # POST /bookings/estimate { client_id, date, trip: {...} } — the trip card's estimate while editing.
      def estimate
        authorize Booking
        client = policy_scope(Client).kept.find(params.require(:client_id))
        trip = Bookings::TripBuilder.call(BookingTrip.new, params.require(:trip).permit(*Bookings::TripBuilder::PERMIT))
        result = Bookings::Estimate.call(client:, trip:, date: Date.iso8601(params.require(:date)))
        render json: { data: { amount: result.amount, lines: result.lines, without_rate: result.without_rate, card: result.card&.slice(:id, :name) } }
      end

      private

      def find = policy_scope(Booking).find(params[:id])
      def booking_params = params.require(:booking).permit(*Bookings::Save::PERMIT)

      def render_booking(booking, status: :ok)
        render_data self.class.load(policy_scope(Booking), booking.id), BookingBlueprint, view: :full, status:
      end
    end
  end
end
