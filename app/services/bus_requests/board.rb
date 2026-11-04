# The Bus Service Requests page of a school: New Service requests of one academic year (urgent mid-year deadlines first,
# then renewals, then oldest), or every Change of Address / Change of Service / Stop Service request (newest first);
# filters, tiles, tab counts, the registration windows and the year cards.
module BusRequests
  class Board
    MAX = 500

    def initialize(school, year:, years:, kind: "new", filters: {}, today: Date.current)
      @school = school
      @year = year
      @years = years
      @kind = BusRequest::KINDS.include?(kind.to_s) ? kind.to_s : "new"
      @f = filters
      @today = today
      @days = Days.new(today)
      @set = BusRequests.mid_settings(year)
      @check = Check.new(school, today:)
    end

    def call
      all = scope(@kind).to_a
      clocks = all.to_h { [ it.id, BusRequests.clock(it, @set, @today, @days) ] }
      @checks = all.to_h { [ it.id, @check.(it) ] }
      rows = @kind == "new" ? sort_new(all, clocks) : all.sort_by { [ -it.submitted_at.to_f, -it.id ] }
      rows = rows.select { match?(it, clocks[it.id]) }
      page = [ @f[:page].to_i, 1 ].max
      limit = (@f[:limit].presence || 150).to_i.clamp(1, MAX)
      { rows: rows.slice((page - 1) * limit, limit).to_a.map { BusRequests.row(it, @set, clocks[it.id], @checks[it.id]) },
        meta: { page:, limit:, count: rows.size, pages: (rows.size.to_f / limit).ceil, kind: @kind, year: @year&.key,
                academic_year_id: @year&.id, tiles: (tiles(all, clocks) if @kind == "new"), tabs:, windows:, years:, levels: levels(all),
                mid: { ack_days: @set.ack_days, plan_weeks: @set.plan_weeks, service_starts_on: @set.start },
                service_check: (plan = @check.plan_text) ? { none: false, plan: } : { none: true, plan: nil },
                auto_accept: (ids = auto_ids(all)) && { count: ids.size, ids: },
                cover: (ids = all.select { it.live_status == "Waitlisted" && @checks[it.id]&.dig(:code) == "covered" }.map(&:id)) && { count: ids.size, ids: } } }
    end

    private

    def scope(kind)
      rel = @school.bus_requests.of_kind(kind).not_withdrawn.includes(:family, :school_rider, :events, :places, first_bill: :payments)
      kind == "new" ? rel.where(academic_year: @year) : rel
    end

    def rank(clock) = clock ? { "over" => 0, "soon" => 1 }.fetch(clock[:tone], 2) : 3

    def sort_new(list, clocks) = list.sort_by { [ rank(clocks[it.id]), it.renewing? ? 0 : 1, it.submitted_at ] }

    def match?(req, clock)
      st = req.live_status
      return false if @f[:deadline].present? && clock&.dig(:tone) != @f[:deadline]
      return false if @f[:status].present? && (@f[:status] == "Accepted+" ? %w[Accepted Active].exclude?(st) : st != @f[:status])
      return false if @f[:tag].present? && BusRequests.tags(req, @set).exclude?(@f[:tag])
      return false if @f[:level].present? && req.level != @f[:level]
      return false if @f[:session] == "AM" && !req.am
      return false if @f[:session] == "PM" && !req.pm
      return false if @f[:check].present? && (@checks[req.id]&.dig(:code) || "none") != @f[:check]

      q = @f[:q].to_s.strip.downcase
      return true if q.empty?

      digits = q.gsub(/\D/, "")
      [ req.child_name, req.parent_name, req.code, req.postal, req.parent_email, req.address ].any? { it.to_s.downcase.include?(q) } ||
        (digits.length >= 3 && req.parent_phone.to_s.gsub(/\D/, "").include?(digits))
    end

    def tiles(list, clocks)
      count = ->(&blk) { list.count(&blk) }
      out = [ [ "Requested", count.() { it.live_status == "Requested" }, { status: "Requested" } ],
              [ "Under Review", count.() { it.live_status == "Under Review" }, { status: "Under Review" } ] ]
      mid = count.() { BusRequests.mid?(it, @set) }
      out += [ [ "Mid-Year", mid, { tag: "Mid-Year" } ], [ "Overdue", count.() { clocks[it.id]&.dig(:tone) == "over" }, { deadline: "over" } ] ] if mid.positive?
      out += [ [ "From the App", count.() { it.source == "app" }, { tag: "From the App" } ], [ "Renewing", count.(&:renewing?), { tag: "Renewing" } ],
               [ "New", count.() { it.school_rider_id.nil? }, { tag: "New" } ], [ "Not Yet Renewed", not_renewed(list), nil ] ]
      out += %w[Accepted Active Waitlisted Lapsed].map { |s| [ s, count.() { it.live_status == s }, { status: s } ] }
      out.map { |label, n, filter| { label:, count: n, filter: } }
    end

    # Current riders with no request this year; final-level riders are not counted.
    def not_renewed(list)
      final = @school.levels.select(&:final).map(&:name)
      asked = list.filter_map(&:school_rider_id).to_set
      SchoolRider.of_school_on(@school, @today).where.not(id: asked.to_a).reject { final.include?(it.grade) }.size
    end

    def tabs
      counts = @school.bus_requests.where(kind: %w[adr svc stop]).group(:kind, :status).count
      open = ->(k, sts) { counts.sum { |(kind, st), n| kind == k && sts.include?(st) ? n : 0 } }
      [ { kind: "new", label: "New Service", open: nil }, { kind: "adr", label: "Change of Address", open: open.("adr", OPEN) },
        { kind: "svc", label: "Change of Service", open: open.("svc", OPEN) }, { kind: "stop", label: "Stop Service", open: open.("stop", [ "Requested" ]) } ]
    end

    def windows
      return [] unless @year

      reg = @year.registration || SchoolRegistrations.build(@year)
      state = ->(from, to) { @today < from ? "upcoming" : @today > to ? "closed" : "open" }
      { registration: reg.persisted? ? reg.status : nil, confirm_hours: reg.confirm_hours,
        list: [ { name: "Early window (renewals)", from: reg.renew_from, to: reg.renew_to, state: state.(reg.renew_from, reg.renew_to) },
                { name: "General window (everyone)", from: reg.general_from, to: reg.general_to, state: state.(reg.general_from, reg.general_to) } ] }
    end

    def years
      list = @years
      cur = list.index { it.starts_on <= @today && @today <= it.ends_on } || list.rindex { it.starts_on <= @today }
      counts = @school.bus_requests.of_kind("new").not_withdrawn.group(:academic_year_id, :status).count
      list.each_with_index.map do |y, i|
        n = ->(sts) { counts.sum { |(ay, st), c| ay == y.id && (sts.nil? || sts.include?(st)) ? c : 0 } }
        tag = cur.nil? ? (i.zero? ? "Next Year" : "Later") : i == cur ? "This Year" : i == cur + 1 ? "Next Year" : i > cur ? "Later" : "Past"
        { id: y.id, key: y.key, tag:, starts_on: y.starts_on, ends_on: y.ends_on, to_review: n.([ "Requested", "Under Review" ]), requests: n.(nil),
          registration: y.registration&.state(@today) || "not_set_up" }
      end
    end

    # Requests the scheduled registration's auto-accept rules would take (the parent app takes them as they arrive; these
    # came in before the rules were on): renewals unchanged, renewing riders at the same address and sessions, siblings
    # of current riders and new families nearby (with a seat beyond the buffer when the rule asks for one).
    def auto_ids(list)
      reg = @year&.registration
      return [] unless reg&.scheduled?

      tails = SchoolRider.of_school_on(@school, @today).pluck(:parent_contact).filter_map { it.to_s.gsub(/\D/, "")[-8..] }.to_set
      school_ll = @school.lat && [ @school.lat.to_f, @school.lng.to_f ]
      list.select do |req|
        next false unless req.status == "Requested"
        next req.renew && req.same && reg.auto_renew if req.source == "app"

        seat = @check.seat?(@checks[req.id], reg.seats_buffer)
        if (r = req.school_rider)
          next false unless reg.auto_renew && req.renewing?
          next false if reg.renew_check_address && r.postal != req.postal
          next false if reg.renew_check_session && ((req.am && !r.am) || (req.pm && !r.pm))

          next true
        end
        next true if reg.auto_siblings && tails.include?(req.parent_phone.to_s.gsub(/\D/, "")[-8..]) && (!reg.siblings_need_cover || seat)

        reg.auto_near && req.lat && school_ll && RouteFit.km(school_ll, [ req.lat.to_f, req.lng.to_f ]) <= reg.near_km.to_f && (!reg.near_needs_cover || seat)
      end.map(&:id)
    end

    def levels(list)
      names = @school.levels.map(&:name)
      names + (list.filter_map(&:level).uniq - names).sort
    end
  end
end
