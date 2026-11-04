# Client Portal › Settings › Sites (read only, kept by the transport company): the sites a person covers, who each is
# billed to, and how many corporate shuttle routes serve it (the trip's site or a stop marked as the site).
module Portal
  class Sites < ApplicationService
    def initialize(client_user:)
      @user = client_user
      @client = client_user.client
    end

    def call
      sites = @user.limit_to_sites(@client.sites, :id).order(:name).to_a
      routes = shuttle_routes
      sites.map do |s|
        { id: s.id, name: s.name, address: s.address, lat: s.lat&.to_f, lng: s.lng&.to_f,
          billed_to: s.own_billing? ? { name: s.billing_name, uen: s.billing_uen, own: true } : { name: @client.bill_name, uen: @client.uen, own: false },
          shuttle_routes: routes[s.id] || 0 }
      end
    end

    private

    def shuttle_routes
      trips = Trip.kept.where(client: @client, kind: "corporate_shuttle")
      pairs = trips.where.not(client_site_id: nil).pluck(:client_site_id, :id) +
              TripStop.where(trip_id: trips.select(:id)).where.not(client_site_id: nil).distinct.pluck(:client_site_id, :trip_id)
      pairs.uniq.group_by(&:first).transform_values(&:size)
    end
  end
end
