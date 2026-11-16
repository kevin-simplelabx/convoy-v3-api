# Convoy App › CCA Bus: one school's week (Next Week, or This Week for late adds): the price and rules, the Family's credit,
# the deadline, and for each child the CCA bus days with what can be done on each (Add Ride, Booked, Not Riding, Not Running,
# No School, Closed, Full), Same Days Every Week, and the ways to pay. Any adult sees it; only the Billing Contact pays.
module ConvoyApp
  module Cca
    class Week < ApplicationService
      Ctx = Data.define(:setting, :today, :upcoming, :bookings, :off, :taken, :standing, :calendar)

      def initialize(member:, school_id: nil, tab: "next")
        @member = member
        @household = member.household
        @school_id = school_id
        @tab = tab.to_s == "this" ? "this" : "next"
      end

      def call
        offers = Cca.offers(@household)
        return { schools: [] } if offers.empty?

        offer = @school_id.blank? ? offers.first : offers.find { it.school.id == @school_id.to_i } or raise ActiveRecord::RecordNotFound
        schools = offers.map { { id: it.school.id, name: it.school.name, company: Parents.company_json(it.company) } }
        Parents.within(offer.company) { build(offer, schools) }
      end

      private

      def build(offer, schools)
        s = offer.setting
        today = Date.current
        next_mon = CcaRides.monday(today) + 7
        nxt = @tab == "next"
        mon = nxt ? next_mon : CcaRides.monday(today)
        range = mon..(mon + 6)
        cut = CcaRides.cutoff(next_mon)
        ctx = Ctx.new(setting: s, today:, upcoming: nxt, calendar: calendar(offer.school, range),
                      bookings: CcaBooking.includes(:credit).where(family: offer.family, date: range).index_by { [ it.child_name, it.date ] },
                      off: offer.school.cca_off_days.where(date: range).index_by(&:date),
                      taken: offer.school.cca_bookings.where(date: range, not_riding: false).group(:date).count,
                      standing: CcaStandingDay.where(family: offer.family).index_by(&:school_rider_id))
        credit = CcaRides.credit(offer.family)
        { schools:, school: { id: offer.school.id, name: offer.school.name }, company: Parents.company_json(offer.company),
          price: s.price, days: s.days.sort, days_text: Cca.days_text(s.days), seats: s.seats,
          rule: "#{Cca.days_text(s.days)}. Book next week by Saturday 23:59 and pay to confirm. After that, a ride can be added if the bus has a seat.",
          credit: credit.positive? ? { amount: credit, text: "#{Cca.money(credit)} credit", sub: "From rides the bus did not run. Used first when you pay." } : nil,
          tab: @tab, week_of: mon, week_text: "Week of #{CcaRides.label(mon)}", deadline: deadline(nxt, cut, today),
          kids: offer.kids.map { kid(it, mon, ctx) }, methods: Cca.methods(offer.school).map(&:json),
          can_pay: Parents.billing?(@member), note: Cca::NOTE }
      end

      def deadline(nxt, cut, today)
        return { open: false, text: "Closed for changes. A ride can still be added if the bus has a seat.", closes_at: nil, urgent: false } unless nxt && today <= cut

        left = (cut - today).to_i
        { open: true, closes_at: Time.zone.local(cut.year, cut.month, cut.day, 23, 59, 59), urgent: left <= 1,
          text: "Book and pay by #{CcaRides.label(cut)}, 23:59 · #{left <= 0 ? 'closes tonight' : left == 1 ? 'closes tomorrow' : "closes in #{left} days"}" }
      end

      # date -> why the bus cannot run (public holiday, no service, school holiday, outside the CCA periods), else nil.
      def calendar(school, range)
        years = school.academic_years.includes(:holidays, :special_days, :terms).to_a
        holidays = PublicHoliday.where(date: range).index_by(&:date)
        ->(d) { (c = CcaRides.calendar(years, d, holidays)) && !c[:run] ? c : nil }
      end

      def kid(kid, mon, ctx)
        sd = ctx.standing[kid.rider.id]&.days.to_a & ctx.setting.days
        first = kid.dependant.first_name
        { dependant_id: kid.dependant.id, school_rider_id: kid.rider.id, name: kid.dependant.name, class: kid.rider.grade || kid.dependant.level,
          same_days: { shown: ctx.upcoming, on: sd.any?, days: sd.sort,
                       text: sd.any? ? "#{Cca.days_text(sd)} are picked for #{first} each week. Still pay by Saturday 23:59 to confirm" : "Pick the same days for #{first} each week" },
          days: ctx.setting.days.sort.map { day(kid, mon + (it - 1), sd, ctx) } }
      end

      def day(kid, date, standing, ctx)
        s = ctx.setting
        b = ctx.bookings[[ kid.rider.name, date ]]
        off = ctx.off[date]
        ns = ctx.calendar.(date)
        ph = CcaRides.phase(date, ctx.today)
        left = [ s.seats - ctx.taken[date].to_i, 0 ].max
        can = b.nil? && off.nil? && ns.nil? && (ph == "open" || (ph == "late" && left.positive?))
        picked = can && ctx.upcoming && standing.include?(date.cwday)
        row = { date:, label: CcaRides.label(date), phase: ph, seats_left: left, can_pick: can, picked_by_same_days: picked, tag: nil, tone: "neutral", sub: nil,
                booking: b && { id: b.id, paid_on: b.paid_on, method: b.method, late: b.late, not_riding: b.not_riding, price: b.price, bill_id: b.school_bill_id },
                can_not_riding: false, not_riding_label: nil }
        if off
          row.merge(tag: "Not Running", tone: "warning", sub: off.reason + (b ? " · #{Cca.money(b.price)} credit" : ""))
        elsif ns
          row.merge(tag: "No School", sub: ns[:label] + (ns[:sub].present? ? " · #{ns[:sub]}" : ""))
        elsif b
          row.merge(tag: ph == "past" ? (b.not_riding ? "Did Not Ride" : "Rode") : (b.not_riding ? "Not Riding" : "Booked"), tone: b.not_riding ? "neutral" : "success",
                    sub: (b.not_riding ? "Charged · the bus will not wait" : "Paid #{b.paid_on.strftime('%-d %b %Y')} · #{b.method}") + (b.late ? " · added after the cut-off" : ""),
                    can_not_riding: ph != "past", not_riding_label: b.not_riding ? "Riding After All" : "Not Riding")
        elsif %w[past today].include?(ph)
          row.merge(tag: ph == "today" ? "Closed" : "Not Booked", sub: ph == "today" ? "Rides for today can no longer be added" : "Not booked")
        elsif !can
          row.merge(tag: "Full", tone: "danger", sub: "No seats left on the CCA bus")
        else
          row.merge(sub: ph == "late" ? "After the cut-off · #{left} #{left == 1 ? 'seat' : 'seats'} left · paid at once" : Cca.money(s.price) + (picked ? " · picked by Same Days Every Week" : ""))
        end
      end
    end
  end
end
