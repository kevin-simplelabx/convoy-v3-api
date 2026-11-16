# School Bus run alerts for the Families of linked children, from today's runs in the current company (AppAlertsJob, every
# minute). Lateness, ETA and the stops come from SchoolLive::Run (attendance, stop events, GPS). A child marked Bus Not
# Required (parent) or not boarding (attendant) is left out.
#   started   morning run started by the driver: "Morning trip started"
#   near      morning bus 10 minutes or less from the child's stop (the Live map opens then)
#   late      5+ minutes late before reaching the child's stop, again at every 5 more minutes (one per Family adult and step)
#   bus       not the route's regular bus that day: from 1 hour before the child's stop until the run ends (once per bus)
# Late and different-bus alerts show on Home as banners until the run ends.
module ConvoyApp
  module Alerts
    class SchoolRuns < ApplicationService
      LEAD = 1.hour
      NEAR = 10.minutes
      LATE_STEP = 5
      INCLUDES = [ :driver, :operator_driver, :stop_events, :passenger_marks, { vehicle: :live_position },
                   { school_route: [ { plan: :school }, { stops: %i[riders stop_point] }, { vehicle_changes: :vehicle } ] } ].freeze

      def initialize(now: Time.current)
        @now = now
      end

      def call
        linked = Alerts.linked_pairs.to_set
        return 0 if linked.empty?

        runs = runs(linked)
        return 0 if runs.empty?

        on_runs = runs.flat_map { |o| o.school_route.stops.flat_map { |s| s.riders.map { [ o.school_route.plan.school_id, it.rid ] } } }.select { linked.include?(it) }
        @kids = Alerts.kids(on_runs)
        absences = SchoolRiderAbsence.where(date: @today, school_id: on_runs.map(&:first).uniq, rid: on_runs.map(&:last).uniq).to_a.group_by(&:school_id)
        Alerts.write(runs.flat_map do |occ|
          school = occ.school_route.plan.school
          run = SchoolLive::Run.new(occ, school:, names: {}, absences: (absences[school.id] || []).index_by(&:rid), now: @now)
          rows(occ, run, school)
        end)
      end

      private

      # Today's runs of routes with a linked child, from 1 hour before they start until they end.
      def runs(linked)
        @today = Time.zone.today
        routes = SchoolRouteRider.joins(school_route: :plan).where(rid: linked.map(&:last).uniq, school_plans: { school_id: linked.map(&:first).uniq })
                                 .distinct.pluck(:school_route_id)
        TripOccurrence.where(school_route_id: routes, date: @today).where.not(status: LiveMap::NOT_DRIVEN)
                      .where("starts_at <= ? AND COALESCE(ended_at, ends_at) > ?", @now + LEAD, @now).includes(*INCLUDES).to_a
      end

      def rows(occ, run, school)
        return [] if run.done?

        run.riders.flat_map do |r|
          kid = @kids[[ school.id, r[:rid] ]]
          next [] if kid.nil? || r[:status] == "not_required"

          stop = run.stops[r[:stop][:index]]
          ctx = { occ:, run:, kid:, stop: }
          [ *(run.am? ? [ started(**ctx), near(**ctx) ] : []), late(**ctx), bus(**ctx) ].compact.flat_map { |row| Alerts.rows_for(kid.account_ids, **row) }
        end
      end

      def base(occ, kid, am)
        { company_id: occ.company_id, occurrence_id: occ.id, occurrence_date: occ.date, dependant_id: kid.dependant.id,
          target: am ? "live" : nil, target_id: am ? kid.dependant.id : nil }
      end

      def plate(occ) = occ.vehicle&.plate || "on the route"

      def started(occ:, run:, kid:, stop:)
        return unless occ.started_at

        base(occ, kid, true).merge(kind: "school_started", title: "Morning trip started", body: "Bus #{plate(occ)} left on #{occ.school_route.title}.",
                                   dedupe_key: "school:started:#{occ.id}:#{occ.date}")
      end

      def near(occ:, run:, kid:, stop:)
        eta = run.expected_at(stop)
        return unless run.running? && !stop[:reached] && eta && eta - @now <= NEAR

        mins = [ ((eta - @now) / 60.0).ceil, 1 ].max
        base(occ, kid, true).merge(kind: "school_near", title: "Bus #{plate(occ)} is #{mins} min from #{stop[:name]}",
                                   body: "The map is open now. Track the bus until #{kid.dependant.first_name} is on board.",
                                   dedupe_key: "school:near:#{occ.id}:#{occ.date}:#{stop[:index]}")
      end

      def late(occ:, run:, kid:, stop:)
        late = run.late_minutes
        return unless run.running? && !stop[:reached] && late >= LATE_STEP

        step = late / LATE_STEP * LATE_STEP
        what = run.am? ? "pick-up" : "drop-off"
        base(occ, kid, run.am?).merge(kind: "school_late", title: "Bus #{plate(occ)} running #{late} min late",
                                      body: "New #{what} ETA #{Alerts.hm(run.expected_at(stop))} at #{stop[:name]}.", banner_until: occ.ends_at,
                                      dedupe_key: "school:late:#{occ.id}:#{occ.date}:#{step}")
      end

      def bus(occ:, run:, kid:, stop:)
        route = occ.school_route
        regular = route.vehicle_changes.select { it.effective_from <= occ.date }.last&.vehicle
        return if occ.vehicle.nil? || regular.nil? || occ.vehicle_id == regular.id
        return if stop[:planned_at] && @now < stop[:planned_at] - LEAD

        relief = occ.original_driver_id && occ.driver ? ", with a relief driver, #{occ.driver.name}" : ""
        same = run.am? ? "Pick-up" : "Drop-off"
        base(occ, kid, run.am?).merge(kind: "school_bus_change", title: "Different bus for #{kid.dependant.first_name} today",
                                      body: "Today #{occ.vehicle.plate} instead of #{regular.plate}#{relief}. #{same} time is the same.",
                                      banner_until: occ.ends_at, dedupe_key: "school:bus:#{occ.id}:#{occ.date}:#{occ.vehicle_id}")
      end
    end
  end
end
