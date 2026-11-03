# Route Fit (port of logic/route-fit.js): does a school bus request fit the routes running for a session?
# fits: a child already rides from the same block (postal code) on a route with a free seat — use that stop.
# new: a route with a free seat can swing by the child's block and still arrive inside the window (AM) and keep within
# the max journey; the impact on the other children is worked out. full: routes can reach the child but none has a seat.
# area: no route can reach the child. Routes: [{ id:, label:, free:, start:, end: (minutes), stops: [{ name:, ll:, tm:, n:, postals: }] }];
# p: { arr_from:, arr_to: (minutes), hard_cap:, base_dwell:, per_student: (seconds) }.
module RouteFit
  ROAD = 1.3
  KINDS = { "fits" => [ "Fits", "success", "covered" ], "new" => [ "New Stop", "warning", "change" ], "full" => [ "Bus Full", "danger", "change" ],
            "area" => [ "New Area", "neutral", "new" ], "none" => [ "Not Checked", "neutral", "none" ] }.freeze
  RANK = { "fits" => 0, "new" => 1, "none" => 2, "full" => 3, "area" => 4 }.freeze

  module_function

  def km(a, b)
    return 0 unless a && b

    r = ->(x) { x * Math::PI / 180 }
    dla = r.(b[0] - a[0])
    dlo = r.(b[1] - a[1])
    x = (Math.sin(dla / 2)**2) + (Math.cos(r.(a[0])) * Math.cos(r.(b[0])) * (Math.sin(dlo / 2)**2))
    2 * 6371 * Math.asin(Math.sqrt(x))
  end

  # Minutes a new stop takes at the kerb.
  def dwell(p) = [ 0.5, ((p[:base_dwell] || 30).to_f + (p[:per_student] || 10).to_f) / 60 ].max

  # The route's own driving speed (km a minute) from its timetable; 0.4 (24 km/h) when it cannot be told.
  def speed(r, school, am, dw)
    list = am ? r[:stops] + [ { ll: school, tm: r[:end] } ] : [ { ll: school, tm: r[:start] } ] + r[:stops]
    d = t = 0.0
    list.each_cons(2) do |a, b|
      next if a[:tm].nil? || b[:tm].nil? || a[:ll].nil? || b[:ll].nil?

      dt = b[:tm] - a[:tm] - dw
      next unless dt.positive?

      d += km(a[:ll], b[:ll]) * ROAD
      t += dt
    end
    (t.positive? ? d / t : 0.4).clamp(0.2, 0.9)
  end

  # The cheapest place to add the child's block on one route, with what it does to everyone else; nil when it cannot
  # keep the window and the max journey.
  def insert(r, o)
    am = o[:session] != "PM"
    p = o[:p] || {}
    dw = dwell(p)
    v = speed(r, o[:school], am, dw)
    tt = ->(a, b) { km(a, b) * ROAD / v }
    h = o[:home][:ll]
    s = r[:stops]
    n = s.size
    return if n.zero?

    a_from = p[:arr_from]
    a_to = p[:arr_to]
    cap = p[:hard_cap].to_f
    sum = ->(list) { list.sum { it[:n].to_i } }
    best = nil
    (0..n).each do |j|
      if am
        prev = j.positive? ? s[j - 1][:ll] : nil
        nxt = j < n ? s[j][:ll] : o[:school]
        d = prev ? tt.(prev, h) + dw + tt.(h, nxt) - tt.(prev, nxt) : tt.(h, nxt) + dw
        first = s[0][:tm]
        span0 = r[:end] - first
        arr1 = r[:end] + (j.positive? ? d : 0)
        shift = 0
        after = j.positive? ? d : 0
        if j.positive? && a_to && arr1 > a_to
          shift = arr1 - a_to
          after = d - shift
        end
        arr = j.positive? ? arr1 - shift : r[:end]
        span = span0 + d
        next if (cap.positive? && span > cap) || (a_from && arr < a_from) || (a_to && arr > a_to + 0.5)

        earlier = shift.positive? ? sum.(s[0...j]) : 0
        tm = j.positive? ? s[j - 1][:tm] - shift + tt.(s[j - 1][:ll], h) + dw : first - d
        info = { j:, d:, tm:, arr:, span:, later: after > 0.5 ? sum.(s[j..]) : 0, later_by: after, earlier: j.zero? ? 0 : earlier,
                 earlier_by: shift, first_earlier: j.zero? ? d : 0, before: j.positive? ? s[j - 1][:name] : "", next: j < n ? s[j][:name] : "school" }
      else
        prev = j.positive? ? s[j - 1][:ll] : o[:school]
        nxt = j < n ? s[j][:ll] : nil
        d = nxt ? tt.(prev, h) + dw + tt.(h, nxt) - tt.(prev, nxt) : tt.(prev, h) + dw
        last = s[n - 1][:tm]
        span = last + (nxt ? d : 0) - r[:start] + (nxt ? 0 : [ 0, (j.positive? ? s[j - 1][:tm] : r[:start]) + d - last ].max)
        next if cap.positive? && span > cap

        tm = (j.positive? ? s[j - 1][:tm] : r[:start]) + tt.(prev, h) + (j.positive? ? dw : 0)
        info = { j:, d:, tm:, arr: nil, span:, later: nxt ? sum.(s[j..]) : 0, later_by: nxt ? d : 0, earlier: 0, earlier_by: 0, first_earlier: 0,
                 before: j.positive? ? s[j - 1][:name] : "school", next: j < n ? s[j][:name] : "" }
      end
      best = info if best.nil? || info[:d] < best[:d]
    end
    best&.merge(d: best[:d].round(1))
  end

  # The impact of a new stop in words.
  def impact(x, am)
    kids = ->(n) { "#{n} #{n == 1 ? 'child' : 'children'}" }
    min = ->(v) { "#{[ 1, v.round ].max} min" }
    out = []
    out << "The bus starts #{min.(x[:first_earlier])} earlier; nobody else changes" if x[:first_earlier].positive?
    out << "#{kids.(x[:later])} #{am ? 'picked up' : 'dropped off'} #{min.(x[:later_by])} later" if x[:later].positive?
    out << "#{kids.(x[:earlier])} picked up #{min.(x[:earlier_by])} earlier" if x[:earlier].positive?
    out << "No other child changes" if out.empty?
    out << "Arrives at school #{Clock.hm(x[:arr].round)}" if am && x[:arr]
    out
  end

  def fit(session:, home:, school:, p:, routes:)
    am = session != "PM"
    pc = home[:postal].to_s.gsub(/\D/, "")
    return { kind: "area", why: "No map location for the address", impact: [ "No map location for the address" ] } unless home[:ll]

    same = routes.flat_map { |r| r[:stops].select { pc.length == 6 && Array(it[:postals]).include?(pc) }.map { [ r, it ] } }
    if (r, s = same.find { it[0][:free].positive? })
      return { kind: "fits", route: r[:id], label: r[:label], stop: s[:name], tm: s[:tm], free: r[:free], txt: "Same stop as a child at the same block",
               impact: [ "Nothing changes for the other children" ] }
    end

    o = { session:, home:, school:, p: }
    ins = routes.filter_map { |r| (x = insert(r, o)) && x.merge(r:) }.sort_by { it[:d] }
    ok = ins.select { it[:r][:free].positive? }
    if (b = ok.first)
      return { kind: "new", route: b[:r][:id], label: b[:r][:label], stop: "New stop at the child’s block, after #{b[:before]}", tm: b[:tm],
               delta: b[:d], free: b[:r][:free], impact: impact(b, am), x: b.except(:r),
               alts: ok[1, 2].map { { route: it[:r][:id], label: it[:r][:label], delta: it[:d], free: it[:r][:free] } } }
    end
    if same.any? || ins.any?
      return { kind: "full", label: (same.first ? same.first[0][:label] : ins.first[:r][:label]),
               routes: (same.map { it[0][:label] } + ins.map { it[:r][:label] }).uniq.first(3), impact: [ "No bus that can reach the child has a free seat" ] }
    end

    { kind: "area", impact: [ "No route can reach the child inside the #{am ? 'arrival window' : 'journey limit'}" ] }
  end
end
