# Renew for <yr> / Change Service / Stop Bus Service screens: the riding children (renewals: only where the school takes
# renewals for next year) with what the form needs — the service now, the next level (none in the school's final level),
# the fares per service at the rider's point, the notice for a stop — and the Family's requests of that kind so far.
module ConvoyApp
  module Parents
    class Changes < ApplicationService
      KINDS = %w[renew svc stop].freeze

      def initialize(member:, kind:)
        @member = member
        @household = member.household
        @kind = KINDS.include?(kind.to_s) ? kind.to_s : raise(ApplicationService::Error, "Pick renew, svc or stop")
      end

      def call
        kids = RiderRequest.kids(@household).filter_map { row(it) }
        today = kids.any? ? nil : Date.current
        out = { kind: @kind, children: kids, mine: mine }
        out[:from_dates] = Parents.mondays(today || Date.current) if @kind == "svc"
        out[:why] = StopService::WHY.map { |value, label| { value:, label: } } if @kind == "stop"
        out
      end

      private

      def row(kid)
        Parents.within(kid.company) do
          today = Date.current
          base = { dependant_id: kid.dependant.id, name: kid.dependant.name, first_name: kid.dependant.first_name, level: kid.rider.grade,
                   school: { id: kid.school.id, name: kid.school.name }, company: Parents.company_json(kid.company), service: kid.service, cca: kid.cca? }
          case @kind
          when "renew" then renew_row(kid, base, today)
          when "svc" then base.merge(fares: fares(kid, AcademicYear.default_for(kid.school, today), today))
          else base.merge(notice: StopService.notice(kid.school, today), current_fare: fares(kid, AcademicYear.default_for(kid.school, today), today)[kid.service])
          end
        end
      end

      def renew_row(kid, base, today)
        win = Parents.window(kid.school, today, renew: true)
        return unless win&.state == "open" && win.year.starts_on > today

        levels = kid.school.levels.to_a
        i = levels.index { it.name == kid.rider.grade }
        nxt = i && !levels[i].final && levels[i + 1] ? levels[i + 1].name : nil
        # Only that year's own Bus Fares (HTML srFare); without them the fare comes with the confirmation.
        own = ::BusRequests::Fare.table_for(kid.school, win.year)&.academic_year_id == win.year.id # rubocop:disable Style/SafeNavigationChainLength
        base.merge(year: win.year.key, closes_on: win.closes_on, next_level: nxt, final_level: i ? levels[i].final : false,
                   levels: win.registration.levels.presence || levels.map(&:name), fares: own ? fares(kid, win.year, win.starts_on) : nil,
                   fare_note: own ? nil : "The #{win.year.key} fare comes with #{kid.company.name}'s confirmation")
      end

      # Monthly fare per service at the rider's point (nil without Bus Fares); cca = the CCA bus add-on a period.
      def fares(kid, year, start_on)
        @fares ||= {}
        @fares[[ kid.rider.id, year&.id ]] ||= begin
          point = { lat: kid.rider.lat, lng: kid.rider.lng, postal: kid.rider.postal }
          one = ->(am, pm, cca) { Estimate.call(school: kid.school, year:, point:, am:, pm:, cca:, start_on:) }
          both = one.(true, true, true)
          { "both" => both[:fare], "am" => one.(true, false, false)[:fare], "pm" => one.(false, true, false)[:fare], "cca" => both[:cca] }
        end
      end

      def mine
        Parents.companies(@household).flat_map do |company|
          Parents.within(company) do
            scope = BusRequest.from_household(@household).not_withdrawn.includes({ registration_bill: :lines }, :answer_moves, academic_year: :registration, school: :company, first_bill: :payments)
            scope = @kind == "renew" ? scope.where(kind: "new", renew: true) : scope.where(kind: @kind)
            scope.order(submitted_at: :desc).map { Present.call(it, billing: Parents.billing?(@member)) }
          end
        end.sort_by { it[:submitted_at] }.reverse
      end
    end
  end
end
