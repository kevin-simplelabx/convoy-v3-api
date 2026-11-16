# Convoy App › School Bus page: the pending Change of Address banner, a card per child who rides (legs, next bus day,
# Track Bus), a card per child without a bus (badge, line and button: Request School Bus while the school takes requests,
# View Request, Pay Registration Fee, View First Invoice), and the quick actions. Every company's data is read inside that
# company. The CCA Bus card shows when a school charges it per ride. Money buttons go to the Billing Contact only.
module ConvoyApp
  module Parents
    class Page
      def initialize(member)
        @member = member
        @household = member.household
        @billing = Parents.billing?(member)
      end

      def call
        kids = @household.dependants.to_a
        facts = ConvoyApp::Households::BusService.facts(@household)
        @schools = {}
        rides = rides(kids, facts)
        riding = rides.map { it[:dependant_id] }.to_set
        others = kids.reject { riding.include?(it.id) }.map { child(it, facts[it.id]) }
        unpaid = @billing ? ConvoyApp::Fees.outstanding(@household).size : 0
        { family: { name: @household.name, address: @household.address, postal: @household.postal },
          you: { admin: @member.admin?, billing_contact: @billing },
          riders: rides, children: others, address_change: address_banner, cca: ConvoyApp::Cca.card(@household),
          actions: actions(rides, others, unpaid) }
      end

      private

      # Children with a rider on the list today or later (and no first invoice owed), each read in its company.
      def rides(kids, facts)
        ids = kids.index_by(&:id)
        riding = facts.select { |id, f| f[:riding] && ids[id] }.keys
        return [] if riding.empty?

        Parents.companies(@household).flat_map do |company|
          Parents.within(company) do
            FamilyRider.where(dependant_id: riding, family_id: Family.where(household_id: @household.id).select(:id)).includes(school: :company)
                       .order(:id).filter_map do |fr|
              ride = Ride.new(ids[fr.dependant_id], fr)
              next unless ride.present?

              @schools[ride.school.id] = ride.school
              card(ride)
            end
          end
        end
      end

      def card(ride)
        d = ride.dependant
        { dependant_id: d.id, name: d.name, first_name: d.first_name, level: ride.rider.grade || d.level, rid: ride.rider.rid,
          school: { id: ride.school.id, name: ride.school.name }, company: Parents.company_json(ride.company),
          next_bus_date: ride.date, today: ride.date == Date.current, legs: ride.sessions.map { ride.leg(it) }, can_track: ride.can_track? }
      end

      # A child without a bus: the latest application, else the school's registration window.
      def child(dep, fact)
        base = { dependant_id: dep.id, name: dep.name, first_name: dep.first_name, meta: [ dep.level, dep.school_name ].compact.join(" · "),
                 school: { id: dep.school_id, name: dep.school_name } }
        req = fact&.dig(:request)
        return base.merge(request_card(req)) if req

        base.merge(window_card(dep))
      end

      def request_card(req)
        Parents.within(req.company) do
          req = BusRequest.includes(:registration_bill, :academic_year, school: :company, first_bill: :payments).find(req.id)
          st = req.live_status
          tc = req.school.company.name
          b = Present.badge(req)
          line, action = case st
          when "Accepted"
                           [ "#{tc} accepted at #{Present.money(req.quote_amount)} a month. Pay the first invoice to confirm",
                             @billing && req.first_bill ? { kind: "first_invoice", label: "View First Invoice", bill_id: req.first_bill.id } : nil ]
          when "Active" then [ "Service confirmed from #{Parents.long(req.start_on)}", nil ]
          when "Requested", "Under Review"
                           [ "Requested #{Parents.long(req.submitted_at.to_date)} for AY#{req.academic_year&.key}#{", est. #{Present.money(req.estimate)} a month" if req.estimate}. " \
                             "#{tc} replies within 1 to 2 weeks", nil ]
          else [ Present.line(req, st, tc), nil ]
          end
          action ||= if !req.fee_paid && req.registration_bill && @billing
                       { kind: "pay_registration", label: "Pay Registration Fee", bill_id: req.registration_bill_id }
          else
                       { kind: "view_request", label: "View Request" }
          end
          { badge: b, line:, request_id: req.id, company: Parents.company_json(req.school.company), action: action.merge(request_id: req.id) }
        end
      end

      # No application yet: the school's registration (open / soon / closed) at the companies serving it.
      def window_card(dep)
        schools = Parents.schools_named(dep.school_name)
        none = { badge: { label: "No Bus Yet", tone: "neutral" }, action: nil }
        return none.merge(line: "#{dep.school_name} is not on Convoy yet") if schools.empty?

        wins = schools.filter_map { |s| Parents.within(s.company) { (w = Parents.window(s, Date.current)) && [ s, w ] } }
        return none.merge(line: "#{dep.school_name} is not taking bus requests yet. Service by #{schools.map { it.company.name }.uniq.join(' and ')}") if wins.empty?

        school, win = wins.find { it[1].state == "open" } || wins.min_by { it[1].opens_on }
        providers = wins.select { it[1].state == win.state }.map { it[0].company.name }.uniq.join(" and ")
        line = case win.state
        when "open" then "#{school.name} is accepting bus requests for #{win.year.key} until #{Parents.long(win.closes_on)}. Service by #{providers}"
        when "soon" then "#{school.name} opens bus requests for #{win.year.key} on #{Parents.long(win.opens_on)}"
        else "Bus requests for #{win.year.key} closed on #{Parents.long(win.closes_on)}. Ask #{providers} about a late request"
        end
        none.merge(line:, window: { state: win.state, year: win.year.key, opens_on: win.opens_on, closes_on: win.closes_on },
                   action: win.state == "open" ? { kind: "request", label: "Request School Bus", school_id: school.id } : nil)
      end

      # The latest Change of Address (not withdrawn) for the Family, grouped by move date and address (HTML addrChg).
      def address_banner
        latest = nil
        Parents.companies(@household).each do |company|
          Parents.within(company) do
            reqs = BusRequest.from_household(@household).of_kind("adr").not_withdrawn.includes(school: :company).order(:submitted_at).to_a
            next if reqs.empty?

            last = reqs.last
            group = reqs.select { it.effective_on == last.effective_on && it.address == last.address }
            if latest.nil? || last.submitted_at > latest[:at]
              latest = { at: last.submitted_at, from: last.effective_on, address: [ last.address, "S#{last.postal}" ].compact.join(", "),
                         names: group.map(&:child_name), status: last.live_status, line: Present.line(last, last.live_status, company.name),
                         ask: group.any?(&:waiting_for_parent?), request_ids: group.map(&:id),
                         fares: group.select(&:waiting_for_parent?).map { { request_id: it.id, name: it.child_name, from: it.current_fare, to: it.quote_amount, note: it.quote_note } } }
            end
          end
        end
        latest&.except(:at)
      end

      # Quick actions (with at least one child riding). fees.due = the Family's bills still to pay (registration fees, first
      # invoices, period bills), for the Billing Contact only.
      def actions(rides, others, unpaid)
        any = rides.any?
        renew = any ? renew_year : nil
        { renew: renew && { year: renew }, bus_not_required: any, school_calendar: any, guardians: true, change_of_address: any || others.any? { it[:request_id] },
          change_service: any, stop: any, contact: any, fees: @billing ? { due: unpaid } : nil }
      end

      # "Renew for <yr>" while a riding child's school takes renewals for a later year.
      def renew_year
        @schools.values.filter_map do |school|
          Parents.within(school.company) do
            w = Parents.window(school, Date.current, renew: true)
            w.year.key if w&.state == "open" && w.year.starts_on > Date.current
          end
        end.min
      end
    end
  end
end
