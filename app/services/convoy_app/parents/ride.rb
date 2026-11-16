# One child's school bus as the parent sees it (port of app-feed.js parentKids / legInfo): the rider linked to the child,
# the next bus day (today, else the next day with a bus within 15 days), and per session (am, pm) the route, stop, times,
# bus, crew and the run's state that day, or Bus Not Required. Only the child's own stop is named. Runs inside the
# rider's company.
module ConvoyApp
  module Parents
    class Ride
      LOOKAHEAD = 15
      LABELS = { "am" => "Pick-up", "pm" => "Drop-off" }.freeze

      attr_reader :dependant, :rider, :school, :date

      def initialize(dependant, family_rider, today: Date.current)
        @dependant = dependant
        @school = family_rider.school
        @rider = SchoolRider.of_school_on(@school, today).find_by(rid: family_rider.rid) ||
                 SchoolRider.where(school: @school, rid: family_rider.rid).where(starts_on: today..).order(:starts_on).first
        @today = today
        @years = @school.academic_years.includes(:terms, :holidays).to_a
        @date = next_bus_day
      end

      def present? = @rider.present?
      def company = @school.company

      def sessions = %w[am pm].select { @rider.public_send(it) }

      # A day with a bus: a school day of its year with a plan running for one of the child's sessions.
      def bus_day?(d)
        year = @years.find { it.starts_on <= d && d <= it.ends_on }
        return false unless year&.school_day?(d)

        sessions.any? { place(it, d) }
      end

      def next_bus_day
        start = [ @today, @rider&.starts_on ].compact.max
        (0...LOOKAHEAD).map { start + it }.find { bus_day?(it) }
      end

      # { plan:, route:, stop: } of the child on a session that day, else nil.
      def place(session, d = @date)
        return unless d

        @places ||= {}
        @places[[ session, d ]] ||= begin
          plans = SchoolPlan.where(school: @school, session:).running_between(d, d).includes(routes: [ :attendant, :vehicle_changes, { replacements: :vehicle }, { stops: :riders } ]).to_a
          plan = plans.select { it.days.include?(d.cwday) }.max_by(&:effective_from)
          route = plan&.routes&.find { |r| r.stops.any? { |s| s.riders.any? { it.rid == @rider.rid } } }
          stop = route&.stops&.find { |s| s.riders.any? { it.rid == @rider.rid } }
          route && { plan:, route:, stop: }
        end
      end

      def occurrence(route, d = @date)
        @occ ||= {}
        @occ[[ route.id, d ]] ||= TripOccurrence.where(school_route_id: route.id, date: d).where.not(status: LiveMap::NOT_DRIVEN)
                                                .includes(:driver, :operator_driver, :vehicle).first
      end

      def absence(d = @date) = d && SchoolRiderAbsence.find_by(school: @school, rid: @rider.rid, date: d)

      # The bus that day: the run's, else a replacement, else the route's regular bus.
      def vehicle(route, d = @date)
        occurrence(route, d)&.vehicle || route.replacement_on(d)&.vehicle || (id = route.regular_vehicle_id(d)) && Vehicle.find_by(id:)
      end

      # A leg's row on the School page: label, "HH:MM", status (Not Required, On the way, Ended, Scheduled) or not on a route.
      def leg(session)
        p = place(session)
        off = absence
        base = { session:, label: LABELS[session] }
        return base.merge(main: "Not on a route yet", time: nil, status: "Not on a route", tone: "neutral") unless p

        time = p[:stop]&.scheduled_time_hm
        main = "#{LABELS[session]} · #{time}"
        if off&.covers?(session)
          return base.merge(main:, time:, status: "Not Required", tone: "neutral", note: off.reason_text, route: p[:route].title, stop: p[:stop]&.name)
        end

        st, tone = state(p[:route])
        base.merge(main:, time:, status: st, tone:, route: p[:route].title, stop: p[:stop]&.name,
                   school_time: session == "am" ? p[:route].end_time_hm : p[:route].start_time_hm)
      end

      def state(route)
        occ = occurrence(route)
        return %w[Scheduled neutral] unless occ && @date == @today
        return %w[Ended neutral] if occ.ended_at.present? || occ.completed?
        return [ "On the way", "info" ] if occ.started_at.present?

        %w[Scheduled neutral]
      end

      # Track Bus: the morning leg on today's bus day, not marked Bus Not Required.
      def can_track? = @date == @today && place("am").present? && !absence&.covers?("am")

      def crew(route)
        occ = occurrence(route)
        v = vehicle(route)
        driver = occ&.driver || occ&.operator_driver
        list = []
        if driver || v&.driver_name.present?
          list << { role: "Driver", name: driver&.name || v.driver_name, phone: driver&.phone || v&.driver_phone, relief: false }
        end
        list << { role: "Bus Attendant", name: route.attendant.name, phone: route.attendant.phone, relief: false } if route.attendant
        list
      end
    end
  end
end
