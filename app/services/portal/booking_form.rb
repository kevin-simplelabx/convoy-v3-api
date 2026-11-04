# Client Portal › New Booking: what the form offers this person — the coordinator (themselves), the sites they cover
# and who each is billed to, Service For (main contractors), the vehicle types the client may book, the rate card the
# estimates come from, and the limits.
module Portal
  class BookingForm < ApplicationService
    def initialize(client_user:)
      @user = client_user
      @client = client_user.client
    end

    def call
      card = Bookings::Estimate.pricer_for(@client)&.card
      {
        coordinator: { name: @user.name, email: @user.email },
        site_required: @user.client_has_sites?,
        sites: Sites.call(client_user: @user).map { it.except(:shuttle_routes) },
        main_contractor: @client.main_contractor?,
        end_customers: @client.main_contractor? ? @client.end_customers.order(:name).map { { id: it.id, name: it.name } } : [],
        vehicle_types: vehicle_types.map { { id: it.id, name: it.name, seats: it.seats } },
        rate_card: card&.slice(:id, :name),
        company: { name: @client.company.decorate.display_name, country: @client.company.country },
        limits: { days: Booking::MAX_DAYS, span_days: Booking::MAX_SPAN_DAYS, trips_a_day: Booking::MAX_TRIPS_A_DAY,
                  vehicles_a_trip: BookingTrip::MAX_VEHICLES, stops: BookingTrip::MAX_STOPS, files: Booking::MAX_ATTACHMENTS,
                  file_mb: SubmitBooking::MAX_FILE / 1.megabyte }
      }
    end

    private

    def vehicle_types
      types = VehicleType.enabled_for(@client.company).order(:seats, :name)
      picked = @client.bookable_vehicle_types.pluck(:vehicle_type_id)
      picked.empty? ? types : types.where(id: picked)
    end
  end
end
