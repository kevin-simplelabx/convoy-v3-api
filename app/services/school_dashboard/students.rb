# School Dashboard › Students (port of dashVals' stu): the school's riders today — on a route or not, AM and PM / AM only /
# PM only / CCA — how far they live (straight-line km as on bills: average, median, furthest, and a histogram by fare
# tier or by 1 or 2 km) and how many per level.
module SchoolDashboard
  class Students
    BINS = %w[tier 1 2].freeze

    def initialize(school, today, year, bin: nil)
      @school = school
      @today = today
      @year = year
      @bin = bin
    end

    def call
      all = SchoolRider.of_school_on(@school, @today).to_a
      on = SchoolDashboard.riders_on(@school, @today)
      n = all.size
      share = ->(x) { n.positive? ? (x * 100.0 / n).round : 0 }
      count = ->(&blk) { all.count(&blk).then { { count: it, pct: share.(it) } } }
      placed = all.count { on.include?(it.rid) }
      km = all.filter_map { SchoolDashboard.km(@school, it) }.sort
      { total: n, on_route: { count: placed, pct: share.(placed) }, not_on_route: n - placed,
        am_and_pm: count.() { it.am && it.pm }, am_only: count.() { it.am && !it.pm }, pm_only: count.() { !it.am && it.pm },
        cca: count.() { it.cca_days.any? }, distance: distance(km, n), levels: levels(all) }
    end

    private

    def tiers
      t = @year&.fare_table
      return [] unless t && !t.zones? && !t.per_bus?

      t.tiers.filter_map { it.max_km&.to_f }.select(&:positive?).sort
    end

    def distance(km, n)
      bin = BINS.include?(@bin) ? @bin : (tiers.any? ? "tier" : "1")
      bin = "1" if bin == "tier" && tiers.empty?
      top = km.last || 0
      edges = if bin == "tier" then tiers
      else
                step = bin.to_f
                (1..20).map { (it * step).round(1) }.take_while { it < top + step }.presence || [ step ]
      end
      ranges = edges.each_with_index.map { |b, i| [ i.zero? ? 0 : edges[i - 1], b ] }
      ranges << [ edges.last, nil ] if bin == "tier" || top > edges.last
      cum = 0
      bins = ranges.each_with_index.map do |(a, b), i|
        c = km.count { (i.zero? ? it >= 0 : it > a) && (b.nil? || it <= b) }
        cum += c
        { from: a, to: b, count: c, pct: pct(c, km.size), cum:, cum_pct: pct(cum, km.size) }
      end
      mid = km.size / 2
      median = km.empty? ? nil : (km.size.odd? ? km[mid] : (km[mid - 1] + km[mid]) / 2.0).round(1)
      { bin:, bins: BINS.reject { it == "tier" && tiers.empty? }, histogram: bins, average: km.empty? ? nil : (km.sum / km.size).round(1),
        median:, furthest: km.last, located: km.size, riders: n }
    end

    def pct(x, n) = n.positive? ? (x * 100.0 / n).round : 0

    # Riders per level in the school's level order, "Not given" last.
    def levels(all)
      counts = all.group_by { it.grade.to_s.strip.presence || "Not given" }.transform_values(&:size)
      order = @school.levels.map(&:name)
      known = counts.keys - [ "Not given" ]
      sorted = known.sort_by { [ order.index(it) || order.size, it ] }
      (sorted + (counts.key?("Not given") ? [ "Not given" ] : [])).map { { label: it, count: counts[it] } }
    end
  end
end
