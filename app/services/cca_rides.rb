# School Bus › CCA Rides (port of logic/cca.js): the CCA / ASA bus charged per ride. Parents book next week by the
# Saturday before (23:59) and pay to confirm; after the cut-off a ride is added only while seats are left. A booked
# ride the bus does not run becomes credit, used first at the family's next payment.
module CcaRides
  WHY = { "school" => "CCA cancelled by the school", "weather" => "Bad weather", "bus" => "Bus problem", "other" => "Other" }.freeze

  module_function

  def setting(school) = school.cca_ride_setting || school.build_cca_ride_setting
  def monday(d) = d.beginning_of_week(:monday)
  def cutoff(date) = monday(date) - 2

  # past, today, late (after the cut-off: add while seats last, paid at once), open.
  def phase(date, today)
    return "past" if date < today
    return "today" if date == today

    today > cutoff(date) ? "late" : "open"
  end

  def label(d) = d.strftime("%a %-d %b")

  # The CCA / ASA per-trip fixed fare in this year's Bus Fares, which CCA Rides then charges.
  def fares_price(school, today = Date.current)
    t = school.academic_years.covering(today).first&.fare_table
    t&.cca_on && t.cca_per == "trip" && t.cca_price == "fixed" && t.cca_fixed.to_d.positive? ? t.cca_fixed.to_d : nil
  end

  def credit(family)
    (CcaCredit.where(family:).sum(:amount) - SchoolBill.where(family:, kind: "cca").sum(:credit_used)).round(2)
  end

  def taken(school, date) = school.cca_bookings.where(date:, not_riding: false).count

  # A day's calendar note (port of yearDay, for CCA): { run: false, kind:, label:, sub: } when the bus cannot run (public
  # holiday, not an operating day, school holiday, between terms, outside the CCA / ASA periods), { run: true, … } on a
  # special day, else nil.
  def calendar(years, date, holidays = {})
    if (ph = holidays[date])
      return { run: false, kind: "public_holiday", label: ph.name.presence || "Public Holiday", sub: "Public holiday" }
    end
    y = years.find { it.starts_on <= date && date <= it.ends_on }
    return unless y

    return { run: false, kind: "no_service", label: "No Service", sub: "#{Date::ABBR_DAYNAMES[date.wday]} is not an operating day" } unless y.operating_days.include?(date.cwday)

    if (h = y.holidays.find { it.covers?(date) })
      return { run: false, kind: "school_holiday", label: h.name.presence || "School Holiday", sub: "School holiday" }
    end
    return { run: false, kind: "school_holiday", label: "School Holidays", sub: "Between terms" } unless y.terms.any? { it.covers?(date) }
    return { run: false, kind: "no_cca", label: "No CCA", sub: "Outside the CCA / ASA periods" } unless y.in_cca_period?(date)

    sp = y.special_days.find { it.date == date }
    return unless sp

    detail = [ sp.time_hm, sp.description ].compact_blank.join(" ")
    { run: true, kind: "special_day", label: sp.kind.humanize, sub: detail, detail: }
  end

  # The week page: settings, the CCA bus days of the week from a Monday with their riders, and the week's figures.
  def week(school, week_of, today = Date.current)
    s = setting(school)
    bookings = school.cca_bookings.includes(:family, :credit, :school_bill).where(date: week_of..(week_of + 6)).order(:child_name).to_a
    off = school.cca_off_days.where(date: week_of..(week_of + 6)).index_by(&:date)
    years = school.academic_years.includes(:holidays, :special_days, :terms).to_a
    public_holidays = PublicHoliday.where(date: week_of..(week_of + 6)).index_by(&:date)
    days = s.days.sort.map do |d|
      date = week_of + (d - 1)
      rows = bookings.select { it.date == date }
      o = off[date]
      cal = calendar(years, date, public_holidays)
      ns = cal && !cal[:run] ? cal : nil
      ph = phase(date, today)
      n = rows.count { !it.not_riding }
      status = if o then "Bus Not Running"
      elsif ns then "No School"
      else { "open" => "Open until #{label(cutoff(date))}, 23:59", "late" => "Closed · late adds while seats last", "today" => "Today" }.fetch(ph, "Done")
      end
      { date:, label: label(date), phase: ph, status:, riders: rows.size, taken: n, seats: s.seats, full: n >= s.seats,
        off: o && { reason: o.reason, by: o.by_name, at: o.created_at, credit: rows.sum(0.to_d, &:price) }, no_school: ns, calendar: (cal if cal&.dig(:run)),
        can_not_running: o.nil? && ns.nil? && rows.any?, can_no_school_credit: o.nil? && ns.present? && rows.any?,
        rows: rows.map { { id: it.id, child_name: it.child_name, class_name: it.class_name, family: it.family.name, paid_on: it.paid_on, method: it.method,
                           bill_id: it.school_bill_id, bill_number: it.school_bill&.number, late: it.late, not_riding: it.not_riding } } }
    end
    week = bookings.select { |b| days.any? { it[:date] == b.date } }
    { setting: { enabled: s.enabled, price: s.price, days: s.days.sort, seats: s.seats, saved_at: s.persisted? ? s.updated_at : nil, saved_by: s.saved_by&.name },
      fares_price: fares_price(school, today), week_of:, days:,
      kpis: { rides: week.size, collected: week.sum(0.to_d, &:price), late: week.count(&:late), not_riding: week.count(&:not_riding),
              credit_given: week.filter_map(&:credit).sum(0.to_d, &:amount) } }
  end

  # The week a page opens on: the next week with rides from today, else the last one, else this week.
  def default_week(school, today = Date.current)
    d = school.cca_bookings.where(date: today..).minimum(:date) || school.cca_bookings.maximum(:date) || today
    monday(d)
  end
end
