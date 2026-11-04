# Client Portal › New Booking while it is filled in (nothing saved): each trip's estimate from the client's rate card,
# the total, who it is billed to, and the approval it will get (Portal::ApprovalRoute: "Rule: …", the steps and names,
# "Then it goes to …", or "Goes straight to …").
module Portal
  class BookingEstimate < ApplicationService
    def initialize(client_user:, params:)
      @user = client_user
      @client = client_user.client
      @params = params.to_h.deep_symbolize_keys
    end

    def call
      pricer = Bookings::Estimate.pricer_for(@client)
      trips = days.flat_map do |date, list|
        list.map do |t|
          trip = Bookings::TripBuilder.call(BookingTrip.new, t.except(:standby, :return_standby))
          r = date ? Bookings::Estimate.call(client: @client, trip:, date:, pricer:) : nil
          { date:, kind: trip.kind, amount: r&.amount || 0, lines: r&.lines || [], without_rate: r&.without_rate }
        end
      end
      total = trips.sum { it[:amount] }
      dates = days.map(&:first).compact
      route = ApprovalRoute.call(client: @client, booking: { site_id: site&.id, booker: @user, kinds: trips.pluck(:kind).compact.uniq,
                                                             amount: total, lead: dates.any? ? (dates.min - Date.current).to_i : nil })
      { trips:, total:, rate_card: pricer&.card&.slice(:id, :name), billed_to:, approval: route.to_h }
    end

    private

    def days
      @days ||= Array(@params[:days]).map do |d|
        date = begin
          Date.iso8601(d[:date].to_s)
        rescue Date::Error
          nil
        end
        [ date, Array(d[:trips]) ]
      end
    end

    def site = @site ||= @params[:client_site_id].presence && @client.sites.find(@params[:client_site_id])

    def billed_to
      site&.own_billing? ? { name: site.billing_name, uen: site.billing_uen, own: true } : { name: @client.bill_name, uen: @client.uen, own: false }
    end
  end
end
