# Bus Service Requests (Convoy OS requests.js): mid-year deadlines on working days (weekends and public holidays off),
# the parent's start in words, the tags and the year the Requests page opens on.
module BusRequests
  Mid = Data.define(:start, :ack_days, :plan_weeks)
  OPEN = [ "Requested", "Under Review", "Not Agreed" ].freeze
  ACTIONABLE = [ "Requested", "Under Review", "Waitlisted" ].freeze
  WAITLIST_REASONS = [ "Route full", "New area", "Awaiting bus" ].freeze
  DECLINE_REASONS = [ "Outside service area", "Not eligible", "Duplicate application", "Other" ].freeze

  # Working days around today, public holidays read once.
  class Days
    def initialize(today = Date.current)
      @off = PublicHoliday.between(today - 400, today + 400).pluck(:date).to_set
    end

    def working?(d) = !d.saturday? && !d.sunday? && !@off.include?(d)

    def add(d, n)
      n.times { d = next_working(d + 1) }
      d
    end

    def next_working(d)
      d += 1 until working?(d)
      d
    end

    # Working days from a to b: positive when b is later.
    def diff(a, b)
      return -diff(b, a) if b < a

      ((a + 1)..b).count { working?(it) }
    end
  end

  module_function

  # The year's registration: when service starts, days to acknowledge, weeks to answer (first school day, 3, 3 by default).
  def mid_settings(year)
    return Mid.new(start: nil, ack_days: 3, plan_weeks: 3) unless year

    reg = year.registration
    Mid.new(start: reg&.service_starts_on || SchoolRegistrations.first_day(year), ack_days: [ reg&.ack_days || 3, 1 ].max,
            plan_weeks: [ reg&.plan_weeks || 3, 1 ].max)
  end

  # A new service request sent once its year's service had started (or flagged mid-year by the app).
  def mid?(req, set)
    return false unless req.kind == "new" || (req.kind == "svc" && req.adds)

    req.mid || (set.start.present? && req.submitted_at.to_date >= set.start)
  end

  # { stage: ack | answer, by:, left: (working days, negative once overdue), tone: ok | soon | over }, or nil.
  def clock(req, set, today, days)
    return unless mid?(req, set)

    sent = req.submitted_at.to_date
    at = lambda do |by, soon|
      left = today > by ? -days.diff(by, today) : days.diff(today, by)
      { by:, left:, tone: today > by ? "over" : left <= soon ? "soon" : "ok" }
    end
    case req.status
    when "Requested" then { stage: "ack" }.merge(at.(days.add(sent, set.ack_days), 0))
    when "Under Review" then { stage: "answer" }.merge(at.(req.answer_by || days.next_working(days.add(sent, set.ack_days) + (set.plan_weeks * 7)), 3))
    end
  end

  # The answer date offered when acknowledging: the usual planning time from today, on a working day.
  def answer_default(today, set, days) = days.next_working(today + (set.plan_weeks * 7))

  def start_text(req)
    d = req.start_on&.strftime("%d/%m/%Y")
    why = req.fixed_why
    case req.start_when
    when "asap" then "As soon as possible"
    when "first" then "From the first school day, #{d}"
    when "fixed" then "From #{d}, not earlier#{" (#{why})" if why.present?}"
    when "pref" then "From #{d}, earlier is fine"
    else d ? "From #{d}" : "Not given"
    end
  end

  # Later than the family asked (preferred, fixed or first day), so the parent is told why.
  def start_late?(req, date) = %w[pref fixed first].include?(req.start_when) && req.start_on.present? && date.present? && date > req.start_on

  # '' when a start date is fine, else why not (a fixed date cannot start earlier).
  def start_error(req, date)
    return unless req.start_when == "fixed" && req.start_on && date && date < req.start_on

    "The family needs the bus from #{req.start_on.strftime('%d/%m/%Y')}, not earlier#{" (#{req.fixed_why})" if req.fixed_why.present?}"
  end

  def tags(req, set)
    req.tags + [ ("New" if (req.source == "app" && !req.renew) || (req.source != "app" && !req.school_rider_id)),
                 ("Mid-Year" if mid?(req, set)), ("Fixed Start" if req.start_when == "fixed"),
                 { "app" => "From the App", "sample" => "Sample" }[req.source] ].compact
  end

  # The year the Requests page opens on: the one after this year, else the last.
  def default_year(years, today = Date.current)
    i = years.index { it.starts_on <= today && today <= it.ends_on }
    (i && years[i + 1]) || years.last
  end

  def row(req, set, clock, check = nil)
    last = req.events.last
    { id: req.id, code: req.code, kind: req.kind, source: req.source, status: req.live_status, tone: BusRequest::TONES[req.live_status],
      child_name: req.child_name, level: req.level, am: req.am, pm: req.pm, cca: req.cca, parent_name: req.parent_name,
      parent_phone: req.parent_phone, parent_email: req.parent_email, postal: req.postal, lat: req.lat, lng: req.lng, located: !req.lat.nil?,
      submitted_at: req.submitted_at,
      tags: tags(req, set), renew: req.renew, start_when: req.start_when, start_on: req.start_on, start_text: start_text(req), reason: req.reason,
      deadline: clock, check: check&.except(:sessions), offer_by: req.offer_by, quote_amount: req.quote_amount,
      hours_left: (req.live_status == "Accepted" && req.offer_by ? [ ((req.offer_by - Time.current) / 3600).ceil, 0 ].max : nil),
      status_label: req.waiting_for_parent? ? "Waiting for Parent" : req.live_status, end_action: end_of(req),
      change: (change(req) unless req.kind == "new"),
      rider: req.school_rider && { id: req.school_rider.id, rid: req.school_rider.rid },
      family: req.family && { id: req.family.id, code: req.family.code, name: req.family.name },
      last_event: last && { at: last.at, by: last.by_name, text: last.text } }
  end

  def detail(req, today = Date.current)
    set = mid_settings(req.academic_year)
    days = Days.new(today)
    clock = clock(req, set, today, days)
    mid = mid?(req, set)
    check = Check.new(req.school, today:).(req)
    st = req.live_status
    can_accept = req.kind == "new" && Accept::ELIGIBLE.include?(st) && st != "Lapsed"
    row(req, set, clock, check).merge(
      academic_year: req.academic_year&.key, address: req.address, km: req.km,
      estimate: req.estimate, fix_why: req.fix_why, fix_note: req.fix_note, class_name: req.class_name, student_no: req.student_no,
      birth_date: req.birth_date, medical: req.medical, cca_days: req.cca_days, fee_paid: req.fee_paid, policy_version: req.policy_version,
      ack: req.acked_at && { at: req.acked_at, by: req.acked_by&.name, answer_by: req.answer_by, note: req.ack_note, plan_weeks: req.ack_plan_weeks,
                             moves: req.answer_moves.map { { from: it.from_date, to: it.to_date, reason: it.reason, at: it.moved_at, by: it.moved_by&.name } } },
      answer_default: (answer_default(today, set, days) if mid && req.status == "Requested"),
      route_fit: check && check[:sessions],
      quote: req.quote_amount && { amount: req.quote_amount, base: req.quote_base, unit: req.quote_unit, note: req.quote_note, by: req.quoted_by&.name,
                                   at: req.quoted_at },
      quote_default: (quote_default(req, check, today, days) if can_accept),
      places: req.places.map { { session: it.session, route_id: it.school_route_id, route: it.route_label, kind: it.kind, stop: it.stop_name, delta_minutes: it.delta_minutes } },
      first_bill: (b = req.first_bill) && { id: b.id, number: b.number, period: b.period_label, subtotal: b.subtotal, gst: b.gst_amount, total: b.total,
                                            status: b.paid? ? "paid" : "open", issued_on: b.issued_on, due_at: b.due_at,
                                            paid_at: (p = b.payments.reject(&:voided?).last)&.created_at, method: p&.method },
      can: { acknowledge: mid && req.status == "Requested", move_answer: mid && req.status == "Under Review",
             waitlist: req.kind == "new" && ACTIONABLE.include?(st) && st != "Waitlisted",
             decline: req.kind == "new" ? ACTIONABLE.include?(st) : [ "Requested", "Under Review" ].include?(st),
             accept: can_accept, reoffer: req.kind == "new" && st == "Lapsed",
             record_payment: %w[Accepted Lapsed].include?(st) && req.first_bill.present? && !req.first_bill.paid?,
             confirm_change: %w[adr svc].include?(req.kind) && OPEN.include?(st), confirm_stop: req.kind == "stop" && st == "Requested",
             not_agreed: req.kind == "adr" && st == "Not Agreed", end_rider: end_of(req).present? },
      planned: req.planned_at && { at: req.planned_at, ok: req.planned_ok, lines: req.plan_lines },
      events: req.events.reverse.map { { at: it.at, by: it.by_name, text: it.text } }
    )
  end

  # Change of Address / Service / Stop Service: what changes and when.
  def change(req)
    { effective_on: req.effective_on, current_fare: req.current_fare, agree: req.agree, waiting_for_parent: req.waiting_for_parent?,
      old_address: req.old_address, new_address: [ req.address, (req.postal.present? && !req.address.to_s.include?(req.postal) ? "S#{req.postal}" : nil) ].compact_blank.join(", "),
      new_stop: req.new_stop, from_service: BusRequest.service_text(req.old_am, req.old_pm, req.old_cca), to_service: BusRequest.service_text(req.am, req.pm, req.cca),
      adds: req.adds, last_on: req.last_on, stop_reason: (req.stop_reason if req.kind == "stop"), notice: req.notice_n && { n: req.notice_n, unit: req.notice_unit },
      earliest_on: req.earliest_on, early: req.early, pay_to: req.pay_to, confirmed_at: req.confirmed_at, confirm_note: req.confirm_note,
      ended_on: req.ended_on }
  end

  # What the Accept dialog starts from: the Bus Fares quote (with the Route Fit summary) and the start date.
  def quote_default(req, check, today, days)
    b = Fare.base(req)
    { amount: b[:amount], unit: b[:unit], text: [ ("Route Fit: #{check[:summary]}" if check && check[:sessions].present?), b[:text] ].compact.join(". "),
      start_on: req.start_on && req.start_on > today ? req.start_on : days.next_working(today + 1), estimate: req.estimate }
  end

  END_ACTIONS = { "lapsed" => [ "Remove from Rider List", "Offer lapsed", "The first invoice was not paid in time. Take the child off the rider list" ],
                  "withdrawn" => [ "Remove from Rider List", "Withdrawn", "The parent withdrew before paying. Take the child off the rider list" ],
                  "stop" => [ "End Rider", "Leaving", "The last day has passed. End the rider" ],
                  "adr" => [ "End Rider", "Leaving", "The service stopped from the move date. End the rider" ],
                  "declined" => [ "End Rider", "Not renewed", "The renewal was declined and the new year has started. End the rider" ] }.freeze

  # A request whose child should come off the rider list: { end: (last day on the list), why:, button:, label:, text: }, else nil.
  # The company ends the rider with one click; nothing leaves by itself.
  def end_of(req, today = Date.current)
    return if req.ended_at || req.school_rider.nil?

    st = req.live_status
    e = if req.kind == "new" && !req.renew && (st == "Lapsed" || (st == "Withdrawn" && req.first_bill && !req.first_bill.paid?))
          { end: today - 1, why: st == "Lapsed" ? "lapsed" : "withdrawn" }
    elsif req.kind == "stop" && %w[Stopping Stopped].include?(st) && req.last_on && req.last_on < today
          { end: req.last_on, why: "stop" }
    elsif req.kind == "adr" && st == "Stopped" && req.effective_on && req.effective_on <= today
          { end: req.effective_on - 1, why: "adr" }
    elsif req.kind == "new" && req.renew && st == "Declined" && req.start_on && req.start_on <= today
          { end: req.start_on - 1, why: "declined" }
    end
    e && e.merge(%i[button label text].zip(END_ACTIONS[e[:why]]).to_h)
  end

  # What a request needs from the company today (bell, strip, 08:00 email): { kind: end | adr | stop | svc | mid, rank: (0 overdue,
  # 1 soon, 2 waiting), by:, clock:, end: }, else nil.
  def needs(req, set, today, days)
    if (e = end_of(req, today))
      return { kind: "end", rank: 1, by: e[:end], end: e }
    end

    st = req.live_status
    return (st == "Requested" ? { kind: "adr", rank: 2, by: req.effective_on } : nil) if req.kind == "adr"
    return (st == "Requested" ? { kind: "stop", rank: 2, by: req.last_on } : nil) if req.kind == "stop"
    return (st == "Requested" ? { kind: "svc", rank: 2, by: req.effective_on } : nil) if req.kind == "svc" && !req.adds

    c = clock(req, set, today, days)
    return if c.nil? || (c[:stage] == "answer" && c[:tone] == "ok")

    { kind: req.kind == "svc" ? "svc" : "mid", rank: { "over" => 0, "soon" => 1 }.fetch(c[:tone], 2), by: c[:by], clock: c }
  end

  # A deadline in words: "Acknowledge by Tue 27/10", "… today", "… was due …", with working days left when soon.
  def deadline_text(c)
    what = c[:stage] == "ack" ? "Acknowledge" : "Answer"
    day = c[:by].strftime("%a %d/%m")
    return "#{what} was due #{day}" if c[:tone] == "over"
    return "#{what} today" if c[:left].zero?

    "#{what} by #{day}#{", #{c[:left]} working #{c[:left] == 1 ? 'day' : 'days'} left" if c[:tone] == 'soon'}"
  end
end
