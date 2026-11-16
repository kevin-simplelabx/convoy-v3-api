# Convoy App › Pick a Point: the lists under the search (search itself, the map and reverse geocoding are FE: OneMap /
# OSM). Organisation points: the client's saved pick-up points (school / company accounts; its booking admins — Super
# Admin, Admin, Site Super Admin, Site Admin — add to them). My Points: the person's own (every account) and, on Personal,
# Home from the Family's address. Recent: the last 5 distinct points of this account's bookings not saved already.
# Save: to My Points, or to the organisation (booking admins only). Inside `within`.
module ConvoyApp
  module Bookings
    module Points
      RECENT = 5

      module_function

      def can_save_org?(account) = account.link? && ClientUserAccess::MANAGE.include?(account.client_user.role)

      def call(account)
        org = account.link? ? account.client.pickup_points.includes(:created_by, :created_by_client_user).order(:name).map { org_json(it) } : []
        mine = home(account) + account.app_account.saved_points.map { mine_json(it) }
        { org_name: account.link? ? account.client.name : nil, can_save_org: can_save_org?(account), org:, mine:, recent: recent(account, org + mine) }
      end

      def save!(account, params)
        p = params.to_h.symbolize_keys
        attrs = { name: p[:name], address: p[:address], lat: p[:lat], lng: p[:lng], note: p[:note].to_s.strip.presence }
        if p[:to].to_s == "org"
          raise Pundit::NotAuthorizedError, "Only #{account.link? ? account.client.name : 'an organisation'}'s booking admins add points for everyone" unless can_save_org?(account)

          point = account.client.pickup_points.new(attrs.merge(company_id: account.client.company_id, created_by_client_user: account.client_user))
          raise ApplicationService::Error, "#{account.client.name} already has a point called #{point.name}" unless point.save

          org_json(point)
        else
          point = account.app_account.saved_points.new(attrs)
          raise ApplicationService::Error, point.errors.full_messages.first unless point.save

          mine_json(point)
        end
      end

      def org_json(p)
        by = p.created_by_client_user&.name || p.created_by&.shown_name
        { id: p.id, kind: "org", name: p.name, address: p.address, lat: p.lat&.to_f, lng: p.lng&.to_f, note: p.note, by: }
      end

      def mine_json(p) = { id: p.id, kind: "mine", name: p.name, address: p.address, lat: p.lat&.to_f, lng: p.lng&.to_f, note: p.note, by: nil }

      def home(account)
        return [] unless account.personal?

        household = Household.kept.joins(:members).find_by(household_members: { app_account_id: account.app_account.id, status: "active" })
        return [] unless household

        address = [ "#{household.block} #{household.street}", ("##{household.floor}-#{household.unit}" if household.floor.present?),
                    "Singapore #{household.postal}" ].compact.join(", ")
        [ { id: "home", kind: "home", name: "Home", address:, lat: household.lat&.to_f, lng: household.lng&.to_f, note: nil, by: nil } ]
      end

      def recent(account, saved)
        names = saved.map { it[:name].to_s.downcase }.to_set
        rows = BookingTripPoint.joins(trip: :booking).merge(Bookings.visible(account)).order(created_at: :desc).limit(100)
                               .pluck(:name, :address, :lat, :lng, :note)
        rows.uniq { [ it[0].downcase, it[1].to_s.downcase ] }.reject { names.include?(it[0].downcase) }.first(RECENT).map do |name, address, lat, lng, note|
          { id: nil, kind: "recent", name:, address:, lat: lat&.to_f, lng: lng&.to_f, note:, by: nil }
        end
      end
    end
  end
end
