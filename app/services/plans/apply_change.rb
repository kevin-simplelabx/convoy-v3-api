# A confirmed bus request written into the route plans of its session from its date (port of logic/plan-changes.js):
# the plan in use that day is split (it ends the day before; a copy with the change runs from the date to where it
# ran) and every later adopted plan of the session gets the change too. join (a new child or a session added) and
# move (a new address) place the child with Route Fit — the same block's stop, or a new stop at the child's block with
# the times around it moved; drop (a session removed) and leave (after the last day) take the child off (an empty stop
# goes). Nothing changes when the child does not fit the plan in use that day. Runs on the Scheduler re-sync.
module Plans
  class ApplyChange < ApplicationService
    OPS = %w[join move drop leave].freeze

    # change: { session: "AM" | "PM", from:, rid:, op:, home: { ll: [lat, lng], postal: }, stop_name: }
    def initialize(school, change, request: nil)
      @school = school
      @c = change
      @request = request
    end

    def call
      d = @c[:from]
      key = @c[:session].downcase
      plans = @school.plans.where(session: key, in_use: true).includes(routes: [ { stops: :riders }, :vehicle_changes, :prices ]).order(:effective_from).to_a
      cur = plans.find { it.routes.any? && it.effective_from <= d && (it.effective_to.nil? || it.effective_to >= d) }
      return { ok: false, txt: "No #{@c[:session]} route plan in use on #{fmt(d)}. Add the child when planning" } unless cur

      out = nil
      SchoolPlan.transaction do
        tgt = cur.effective_from == d ? cur : split(cur, d)
        later = plans.select { it != cur && it.effective_from > d && it.routes.any? }
        res = nil
        touched = [ cur, tgt ]
        [ tgt, *later ].each do |p|
          if %w[leave drop].include?(@c[:op])
            had = remove(p)
            res = { kind: had ? "off" : "none" } if p == tgt
            touched << p if had
            next
          end
          r1 = nil
          SchoolPlan.transaction(requires_new: true) do
            remove(p) if @c[:op] == "move"
            r1 = add(p)
            raise ActiveRecord::Rollback unless r1
          end
          if r1.nil? && p == tgt
            out = { ok: false, txt: @c[:op] == "move" ? "The new address does not fit a running #{@c[:session]} route, so the old pick-up stays until replanned" : "Does not fit a running #{@c[:session]} route. Add the child when planning" }
            raise ActiveRecord::Rollback
          end
          next unless r1

          touched << p
          res = r1 if p == tgt || res.nil?
        end
        if res && res[:kind] == "none"
          out = { ok: false, txt: "Not on a #{@c[:session]} route, nothing to change" }
          raise ActiveRecord::Rollback
        end

        verb = { "join" => "joins", "move" => "moves to" }[@c[:op]]
        txt = "#{@c[:session]} from #{fmt(d)}: #{verb ? "#{verb} #{res[:label]}, #{res[:stop]}" : 'off the route'}"
        SchoolPlanChange.create!(school_plan: tgt, bus_request: @request, from_date: d, rid: @c[:rid], op: @c[:op], text: txt, created_at: Time.current)
        n = SchoolPlanChange.where(school_plan_id: tgt.id).count
        tgt.update!(name: "#{base(tgt.name)} · from #{fmt(d)} · #{n} #{n == 1 ? 'change' : 'changes'}")
        out = { ok: true, txt:, impact: res[:impact] || [], plans: touched.uniq }
      end
      Plans.resync(*out[:plans]) if out[:ok]
      out
    end

    private

    def fmt(d) = d.strftime("%d/%m/%Y")
    def base(name) = name.split(" · from ").first

    # The plan in use from the date: a copy with its routes, stops, riders, vehicles and prices; the original ends the day before.
    def split(cur, d)
      copy = cur.dup
      copy.assign_attributes(effective_from: d, effective_to: cur.effective_to, adopted_at: Time.current)
      copy.save!
      cur.update!(effective_to: d - 1)
      cur.routes.each do |r|
        nr = r.dup
        nr.plan = copy
        nr.save!
        r.vehicle_changes.each { nr.vehicle_changes.create!(it.attributes.except("id", "school_route_id", "created_at", "updated_at")) }
        r.prices.each { nr.prices.create!(it.attributes.except("id", "school_route_id", "created_at", "updated_at")) }
        r.stops.each do |s|
          ns = s.dup
          ns.route = nr
          ns.save!
          s.riders.each { SchoolRouteRider.create!(school_route: nr, stop: ns, rid: it.rid) }
        end
      end
      copy.routes.reset
      copy
    end

    def routes_of(plan) = plan.routes.includes(stops: :riders).reject(&:hidden)

    def remove(plan)
      rows = SchoolRouteRider.where(school_route_id: plan.routes.select(:id), rid: @c[:rid]).includes(stop: :riders, school_route: [])
      return false if rows.empty?

      rows.each do |row|
        stop = row.stop
        route = row.school_route
        row.destroy!
        left = stop.riders.reload.size
        left.zero? ? stop.destroy! : stop.update!(riders_count: left)
        route.update!(riders_count: SchoolRouteRider.where(school_route: route).count)
      end
      true
    end

    def add(plan)
      postals = SchoolRider.where(school: @school).pluck(:rid, :postal).to_h
      list = routes_of(plan)
      shapes = list.map do |r|
        stops = r.stops.select { it.lat && it.scheduled_time }
        { id: r.id, label: r.label, free: (r.student_seats || r.seats || r.capacity).to_i - r.stops.sum { it.riders.size }, start: r.start_time, end: r.end_time,
          stops: stops.map { |s| { name: s.name, ll: [ s.lat.to_f, s.lng.to_f ], tm: s.scheduled_time, n: s.riders.size, postals: s.riders.filter_map { postals[it.rid] }.uniq } } }
      end
      rt = RouteFit::Routes.new(@school).for(@c[:session], @c[:from])
      f = RouteFit.fit(session: @c[:session], home: @c[:home], school: [ @school.lat.to_f, @school.lng.to_f ], p: rt ? rt[:p] : {}, routes: shapes)
      return unless %w[fits new].include?(f[:kind])

      route = list.find { it.id == f[:route] }
      if f[:kind] == "fits"
        stop = route.stops.find { it.name == f[:stop] }
        SchoolRouteRider.create!(school_route: route, stop:, rid: @c[:rid])
        stop.update!(riders_count: stop.riders.size + 1)
      else
        insert(route, f[:x])
      end
      route.update!(riders_count: SchoolRouteRider.where(school_route: route).count)
      { kind: f[:kind], label: f[:label], stop: f[:kind] == "fits" ? f[:stop] : "a new stop at the child’s block", impact: f[:impact] || [] }
    end

    def insert(route, x)
      am = @c[:session] == "AM"
      stops = route.stops.to_a
      timed = stops.each_index.select { stops[it].lat && stops[it].scheduled_time }
      at = x[:j] < timed.size ? timed[x[:j]] : timed.last + 1
      stops.each_with_index do |s, i|
        next unless s.scheduled_time

        shift = if am
                  (x[:j].positive? && i < at && x[:earlier_by].positive? ? -x[:earlier_by] : 0) +
                    (x[:j].positive? && i >= at && x[:later_by].positive? ? x[:later_by] : 0)
        else
                  i >= at && x[:later_by].positive? ? x[:later_by] : 0
        end
        s.update!(scheduled_time: (s.scheduled_time + shift).round, position: i >= at ? s.position + 1 : s.position) if shift != 0 || i >= at
      end
      postal = @c[:home][:postal].to_s
      ns = route.stops.create!(name: @c[:stop_name].presence || "New stop at #{postal.present? ? "S#{postal}" : 'the child’s block'}",
                               position: at, lat: @c[:home][:ll][0], lng: @c[:home][:ll][1], scheduled_time: x[:tm].round, dwell_seconds: 40, riders_count: 1)
      SchoolRouteRider.create!(school_route: route, stop: ns, rid: @c[:rid])
      times = route.stops.reload.filter_map(&:scheduled_time)
      if am
        route.end_time = (route.end_time + x[:later_by]).round if x[:later_by].positive?
        route.start_time = times.first
      else
        route.end_time = times.last
      end
      route.save!
    end
  end
end
