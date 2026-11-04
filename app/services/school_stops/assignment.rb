# Stop Assignment of a school on a date (port of candidates in Convoy OS): for each rider, the PUDO points they may use —
# every point (not turned off at the school) of a linked stop whose catchment has their home, plus the points linked to
# them or their postal code by hand, less the points cut off from them — and whether that is none, one stop, or more
# than one (a conflict routing has to settle).
module SchoolStops
  class Assignment
    def initialize(school, date: Date.current)
      @school = school
      @date = date
      @stops = school.school_stops.includes(stop: :points).select { it.stop.kept? }
      links = school.rider_point_links.to_a
      @alt = links.select { it.kind == "alternative" }
      @cut = links.select { it.kind == "disconnected" }.group_by(&:rid)
      @assigned = school.rider_assignments.includes(stop_point: :stop).index_by(&:rid)
    end

    def riders = @riders ||= SchoolRider.of_school_on(@school, @date).order(:name).to_a.map { row(it) }

    def counts
      { riders: riders.size, with_pudo: riders.count { it[:candidates].any? }, conflicts: riders.count { it[:status] == "conflict" },
        no_stop: riders.count { it[:status] == "none" }, assigned: riders.count { it[:assigned] }, notified: riders.count { it.dig(:assigned, :notified_at) } }
    end

    def candidates(rider)
      cut = (@cut[rider.rid] || []).map(&:stop_point_id)
      extra = @alt.select { it.rid == rider.rid || it.postal == rider.postal }.map(&:stop_point_id)
      @stops.flat_map do |ss|
        inside = ss.covers?(rider.postal, rider.lat, rider.lng)
        ss.stop.points.filter_map do |p|
          next if ss.off_point_ids.include?(p.id) || cut.include?(p.id)
          next unless inside || extra.include?(p.id)

          how = inside ? (ss.postal_codes.include?(rider.postal) ? "postal" : "area") : "manual"
          { stop_id: ss.stop_id, stop_code: ss.stop.code, point_id: p.id, pudo_code: p.pudo_code, usage: p.usage, how:, manual: how == "manual",
            metres: rider.lat && Geo.metres([ rider.lat, rider.lng ], [ p.lat, p.lng ]).round }
        end
      end
    end

    private

    def row(r)
      list = candidates(r)
      stops = list.map { it[:stop_id] }.uniq.size
      a = @assigned[r.rid]
      { rid: r.rid, name: r.name, grade: r.grade, postal: r.postal, lat: r.lat&.to_f, lng: r.lng&.to_f, am: r.am, pm: r.pm, cca_days: r.cca_days,
        starts_on: r.starts_on, candidates: list, cut_point_ids: (@cut[r.rid] || []).map(&:stop_point_id), status: stops.zero? ? "none" : (stops == 1 ? "one" : "conflict"),
        assigned: a && { point_id: a.stop_point_id, pudo_code: a.stop_point.pudo_code, manual: a.manual, plan_id: a.school_plan_id, notified_at: a.notified_at } }
    end
  end
end
