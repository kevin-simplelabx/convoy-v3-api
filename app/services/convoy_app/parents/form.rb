# Convoy App › Request School Bus, steps 1 and 2: for a school (any provider's id, or the child's school from the
# directory) the providers taking requests, and for each the year, the start options (before term: first school day or a
# date from it; mid-year: as soon as possible or one of the next 8 Mondays, default after the usual planning weeks), the
# levels and sessions it offers, the CCA bus, the registration fee and the agreement text, and the Family's children at
# that school with whether each can still apply. Each provider is read inside its company.
module ConvoyApp
  module Parents
    class Form < ApplicationService
      def initialize(member:, school_id:)
        @household = member.household
        @school = Parents.school!(school_id)
      end

      def call
        schools = Parents.schools_named(@school.name)
        { school: { name: @school.name }, home: { address: @household.address, postal: @household.postal },
          providers: schools.filter_map { provider(it) } }
      end

      private

      def provider(school)
        Parents.within(school.company) do
          today = Date.current
          win = Parents.window(school, today)
          next unless win

          reg = win.registration
          mid = Parents.mid?(win, today)
          policy = SchoolPolicyVersion.current_for(school.policy_versions, today)
          table = ::BusRequests::Fare.table_for(school, win.year)
          mondays = Parents.mondays(today)
          set = ::BusRequests.mid_settings(win.year)
          { school_id: school.id, company: Parents.company_json(school.company), year: win.year.key,
            window: { state: win.state, opens_on: win.opens_on, closes_on: win.closes_on, starts_on: win.starts_on, ends_on: win.ends_on },
            mid_year: mid ? { ack_days: set.ack_days, plan_weeks: set.plan_weeks } : nil,
            start: { options: mid ? %w[asap pref fixed] : %w[first pref fixed], default: mid ? "asap" : "first", first_day: win.starts_on,
                     dates: mid ? mondays : nil, default_on: mid ? (mondays.find { it >= today + (set.plan_weeks * 7) } || mondays.last) : win.starts_on,
                     fix_why: FIX_WHY.map { |value, label| { value:, label: } } },
            levels: reg.levels.presence || school.levels.map(&:name).presence || SchoolDirectory::DEFAULT_LEVELS,
            sessions: reg.sessions, services: SERVICES.select { |k, _| k == "both" ? (reg.sessions & %w[AM PM]).size == 2 : reg.sessions.include?(k.upcase) }
                                                    .map { |value, label| { value:, label: } },
            cca: cca(reg, table, win, today), show_fare: reg.show_fare,
            registration_fee: policy&.registration_fee.to_d.positive? ? policy.registration_fee : nil,
            agreement: { text: policy&.ack_text, extra_terms: reg.extra_terms },
            children: children(school, win) }
        end
      end

      def cca(reg, table, win, today)
        return { on: false } unless reg.sessions.include?("CCA") && table&.cca_on

        starts = win.year.terms.map { win.year.cca_same_as_terms ? it.starts_on : it.cca_starts_on }.compact.sort
        { on: true, per: table.cca_per, per_ride: Estimate.per_ride(table), starts_on: starts.find { it >= today } || starts.first }
      end

      # The Family's children at this school: each can apply unless they already ride or have an application this year.
      def children(school, win)
        @household.dependants.select { it.school_name.to_s.casecmp?(school.name) }.map do |d|
          open = BusRequest.where(dependant_id: d.id, kind: "new", academic_year: win.year).where.not(status: %w[Withdrawn Declined]).find { it.live_status != "Lapsed" }
          rides = SchoolRider.where(school:, rid: FamilyRider.where(school:, dependant_id: d.id).select(:rid)).where(ends_on: [ nil, Date.current.. ]).exists?
          why = open ? "Already requested for #{win.year.key}" : rides ? "Already rides the bus" : nil
          { dependant_id: d.id, name: d.name, level: d.level, student_id: d.student_id, can_apply: why.nil?, reason: why, request_id: open&.id }
        end
      end
    end
  end
end
