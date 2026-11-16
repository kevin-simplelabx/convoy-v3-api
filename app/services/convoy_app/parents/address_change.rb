# Change of Address (3 steps): the new address, the move date and the children (every child who rides, and every child
# with an application in progress), then the sessions that move, then the fares before and after. The move date follows
# each school's Payment & Refund Policy (notice days, start any day / a Monday / the first school day of a month, how
# far ahead); with several schools the strictest applies, on a day every school has a bus. One request (kind adr) per
# child; "Update the Family's residential address" keeps the address to apply once the company confirms (MoveHome).
module ConvoyApp
  module Parents
    class AddressChange < RiderRequest
      RANK = { "any" => 0, "mon" => 1, "first" => 2 }.freeze
      LOOK = 150

      Kid = Data.define(:dependant, :school, :company, :rider, :family, :request, :service, :current_fare)
      Rule = Data.define(:lead, :start, :max, :from, :to, :schools)

      # Children who can move: riders (their current fare from the active request, else Bus Fares) and children whose
      # application is in progress (its quote or estimate).
      def self.kids(household)
        riders = RiderRequest.kids(household).map do |k|
          Parents.within(k.company) do
            quote = BusRequest.where(school_rider_id: k.rider.id, kind: "new", status: "Active").order(:submitted_at).last&.quote_amount
            fare = quote || Estimate.call(school: k.school, year: AcademicYear.default_for(k.school), point: { lat: k.rider.lat, lng: k.rider.lng, postal: k.rider.postal },
                                          am: k.rider.am, pm: k.rider.pm, cca: false, start_on: Date.current)[:amount]
            Kid.new(dependant: k.dependant, school: k.school, company: k.company, rider: k.rider, family: k.family, request: nil, service: k.service, current_fare: fare)
          end
        end
        taken = riders.map { it.dependant.id }.to_set
        facts = ConvoyApp::Households::BusService.facts(household)
        apps = household.dependants.reject { taken.include?(it.id) }.filter_map do |d|
          req = facts[d.id]&.dig(:request)
          next unless req && %w[Requested Under\ Review Accepted Waitlisted].include?(req.live_status)

          Parents.within(req.company) do
            r = BusRequest.includes(school: :company).find(req.id)
            Kid.new(dependant: d, school: r.school, company: r.company, rider: nil, family: r.family, request: r, service: Present.service(r),
                    current_fare: r.quote_amount || r.estimate)
          end
        end
        riders + apps
      end

      # The strictest rule of the schools and the dates allowed (call with today in the first school's time zone).
      def self.rule(kids, today)
        rules = kids.map(&:school).uniq.map do |school|
          Parents.within(school.company) do
            p = SchoolPolicyVersion.current_for(school.policy_versions, today)
            { lead: p&.address_notice_days || 14, start: p&.address_start || "any", max: p&.address_max_days || 90, school: }
          end
        end
        rules = [ { lead: 14, start: "any", max: 90, school: nil } ] if rules.empty?
        lead = rules.map { it[:lead] }.max
        max = rules.map { it[:max] }.min
        start = rules.map { it[:start] }.max_by { RANK[it] }
        Rule.new(lead:, start:, max:, from: today + lead, to: today + [ lead, max ].max, schools: rules.filter_map { it[:school] })
      end

      # Every date allowed by the rule: a weekday that is a bus day at every school (school day of its year, not a public
      # holiday of its company; a date outside any year counts), a Monday or the month's first such day when asked.
      def self.dates(rule)
        days = rule.schools.map do |s|
          Parents.within(s.company) do
            years = s.academic_years.includes(:terms, :holidays).to_a
            ph = PublicHoliday.between(rule.from.beginning_of_month, rule.to).pluck(:date).to_set
            (rule.from.beginning_of_month..rule.to).select do |d|
              y = years.find { it.starts_on <= d && d <= it.ends_on }
              !d.saturday? && !d.sunday? && !ph.include?(d) && (y.nil? || y.school_day?(d))
            end.to_set
          end
        end
        ok = days.reduce { |a, b| a & b } || (rule.from.beginning_of_month..rule.to).reject { it.saturday? || it.sunday? }.to_set
        (rule.from..rule.to).select do |d|
          next false unless ok.include?(d)
          next d.monday? if rule.start == "mon"
          next (d.beginning_of_month...d).none? { ok.include?(it) } if rule.start == "first"

          true
        end
      end

      def initialize(member:, params:, preview: false)
        super(member:, params:)
        @preview = preview
      end

      def call
        postal = @params[:postal].to_s.gsub(/\D/, "")
        raise Error, "Enter a 6-digit postal code" unless postal.match?(/\A\d{6}\z/)

        block = @params[:block].to_s.squish
        street = @params[:street].to_s.squish
        raise Error, "Enter the block or house number and the street" if block.empty? || street.empty?

        kids = chosen
        today = Parents.within(kids.first.company) { Date.current }
        rule = self.class.rule(kids, today)
        move = Date.parse(@params[:move_on].to_s)
        raise Error, "Pick the date from the calendar" unless self.class.dates(rule).include?(move)

        home = { block:, street:, floor: @params[:floor].to_s.squish.presence, unit: @params[:unit].to_s.squish.presence, postal: }
        address = Household.new(home).address
        hit = Parents.locate(postal)
        point = { postal:, lat: hit&.dig(:lat), lng: hit&.dig(:lng) }
        rows = kids.map { row(it, point, move) }
        return review(rows, address, postal, move) if @preview

        now = Time.current
        snapshot = ActiveModel::Type::Boolean.new.cast(@params[:update_home]) ? home.merge(line2: nil, lat: point[:lat], lng: point[:lng]).stringify_keys : nil
        ApplicationRecord.transaction { rows.map { create(it, address, point, move, snapshot, now) } }
      rescue Date::Error
        raise Error, "Pick the date from the calendar"
      end

      private

      # The children picked and the sessions that move ({ dependant_id, am, pm }); at least one session.
      def chosen
        list = Array(@params[:children]).map { it.to_h.symbolize_keys }
        raise Error, "Choose at least one child" if list.empty?

        all = self.class.kids(@household)
        out = list.map do |c|
          kid = all.find { it.dependant.id == c[:dependant_id].to_i } or raise Error, "Choose a child who rides or has a bus request"
          am = kid.service != "pm" && c.fetch(:am, true).then { ActiveModel::Type::Boolean.new.cast(it) }
          pm = kid.service != "am" && c.fetch(:pm, true).then { ActiveModel::Type::Boolean.new.cast(it) }
          [ kid, am, pm ]
        end
        raise Error, "Choose at least one service" if out.none? { _2 || _3 }

        out.select { _2 || _3 }.map { |kid, am, pm| { kid:, am:, pm: } }.tap { @sessions = it }.map { it[:kid] }
      end

      def row(kid, point, move)
        s = @sessions.find { it[:kid] == kid }
        new_fare = Parents.within(kid.company) do
          year = kid.request&.academic_year || AcademicYear.default_for(kid.school, move)
          Estimate.call(school: kid.school, year:, point:, am: kid.service != "pm", pm: kid.service != "am", cca: false, start_on: move)[:amount]
        end
        { kid:, am: s[:am], pm: s[:pm], new_fare: }
      end

      def review(rows, address, postal, move)
        { move_on: move, new_address: "#{address}, S#{postal}",
          children: rows.map do |r|
            k = r[:kid]
            { dependant_id: k.dependant.id, name: k.dependant.name, school: k.school.name, company: Parents.company_json(k.company),
              old_address: k.rider ? [ k.rider.address, "S#{k.rider.postal}" ].compact.join(", ") : [ k.request.address, "S#{k.request.postal}" ].compact.join(", "),
              moves: [ ("Morning pick-up moves" if r[:am]), ("Afternoon drop-off moves" if r[:pm]) ].compact,
              current_fare: k.current_fare, new_fare: r[:new_fare] }
          end,
          note: "#{rows.map { it[:kid].company.name }.uniq.join(' and ')} confirms the new pick-up point and fare before #{Parents.long(move)}. " \
                "The current service runs unchanged until then." }
      end

      def create(r, address, point, move, snapshot, now)
        k = r[:kid]
        Parents.within(k.company) do
          from = k.rider || k.request
          year = k.request&.academic_year || AcademicYear.default_for(k.school, move)
          req = k.school.bus_requests.create!(
            academic_year: year, kind: "adr", source: "app", status: "Requested", submitted_at: now, household: @household, dependant: k.dependant,
            app_account: @account, school_rider: k.rider, family: k.family, child_name: k.dependant.name, level: k.rider&.grade || k.request&.level,
            old_address: from.address, old_postal: from.postal, address:, postal: point[:postal], lat: point[:lat], lng: point[:lng],
            am: r[:am], pm: r[:pm], effective_on: move, current_fare: k.current_fare, estimate: r[:new_fare], new_home: snapshot, **Parents.parent(@account)
          )
          log(req, "Change of address", now)
          req
        end
      end
    end
  end
end
