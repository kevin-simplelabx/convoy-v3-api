# Base of the requests a Family sends for children who already ride (Renew for next year, Change Service, Stop Bus Service,
# Change of Address): the riding children (each with its rider, family and school, read inside the rider's company), the
# fields every such request carries, and a fare at the Family's home for the current or the new service.
module ConvoyApp
  module Parents
    class RiderRequest < ApplicationService
      Kid = Data.define(:dependant, :rider, :family, :school, :company) do
        def service = rider.am && rider.pm ? "both" : rider.am ? "am" : "pm"
        def cca? = rider.cca_days.any?
      end

      # The Family's children on a rider list today or later, grouped by nothing (one per rider).
      def self.kids(household, today: nil)
        deps = household.dependants.index_by(&:id)
        return [] if deps.empty?

        Parents.companies(household).flat_map do |company|
          Parents.within(company) do
            day = today || Date.current
            frs = FamilyRider.where(dependant_id: deps.keys, family_id: Family.where(household_id: household.id).select(:id)).includes(:family, school: :company)
                             .order(:id).to_a
            # Per school: the riders on the list that day, else the first one starting later (one query each, not per child).
            riders = frs.group_by(&:school).to_h do |school, list|
              rids = list.map(&:rid)
              now = SchoolRider.of_school_on(school, day).where(rid: rids).index_by(&:rid)
              later = SchoolRider.where(school:, rid: rids - now.keys).where(starts_on: day..).order(:starts_on).to_a.group_by(&:rid).transform_values(&:first)
              [ school.id, later.merge(now) ]
            end
            frs.filter_map do |fr|
              rider = riders.dig(fr.school_id, fr.rid)
              rider && Kid.new(dependant: deps[fr.dependant_id], rider:, family: fr.family, school: fr.school, company:)
            end
          end
        end
      end

      def initialize(member:, params:)
        @member = member
        @household = member.household
        @account = member.app_account
        @params = params
      end

      private

      def picked
        ids = Array(@params[:children]).map { (it.respond_to?(:to_h) ? it.to_h.symbolize_keys : { dependant_id: it })[:dependant_id].to_i }
        raise Error, "Choose at least one child" if ids.empty?

        kids = self.class.kids(@household)
        chosen = ids.uniq.map { |id| kids.find { it.dependant.id == id } or raise Error, "Choose a child who rides the school bus" }
        not_pending!(chosen)
        chosen
      end

      # A child whose offer waits for its first invoice is listed but does not ride yet: nothing to renew, change or stop.
      def not_pending!(chosen)
        chosen.group_by(&:company).each do |company, list|
          pending = Parents.within(company) { Parents.pending_offer_ids(list.map { it.dependant.id }) }
          (kid = list.find { pending.include?(it.dependant.id) }) and raise Error, "Pay the first invoice for #{kid.dependant.first_name} first"
        end
      end

      def per(kid) = Array(@params[:children]).map { it.respond_to?(:to_h) ? it.to_h.symbolize_keys : {} }.find { it[:dependant_id].to_i == kid.dependant.id } || {}

      # The fields every request about a riding child carries.
      def base(kid, year, now)
        { academic_year: year, source: "app", status: "Requested", submitted_at: now, household: @household, dependant: kid.dependant,
          app_account: @account, school_rider: kid.rider, family: kid.family, child_name: kid.dependant.name, level: kid.rider.grade || kid.dependant.level,
          address: kid.rider.address || @household.address, postal: kid.rider.postal, lat: kid.rider.lat, lng: kid.rider.lng, **Parents.parent(@account) }
      end

      # The monthly fare at the rider's point for a service (nil without Bus Fares).
      def fare(kid, year, service, cca, start_on)
        point = { lat: kid.rider.lat, lng: kid.rider.lng, postal: kid.rider.postal }
        Estimate.call(school: kid.school, year:, point:, am: service != "pm", pm: service != "am", cca:, start_on:)[:amount]
      end

      # The year has its own Bus Fares (not the latest earlier table OS falls back to).
      def own_fares?(school, year) = ::BusRequests::Fare.table_for(school, year)&.academic_year_id == year&.id

      def year_on(school, date) = AcademicYear.default_for(school, date)

      def log(req, what, now) = req.log!("#{what} sent from the Convoy App by #{@account.display_name}", by: "Parent", at: now)
    end
  end
end
