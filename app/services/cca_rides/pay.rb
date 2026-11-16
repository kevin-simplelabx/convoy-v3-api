# Pay for picked CCA rides (the Convoy App; seeds and specs use #call): only the school's CCA bus days of next week, not a
# day already gone, not running, without school or booked twice; after the cut-off only while seats are left. One CCA bill
# per payment (rides × price, less the family's credit), paid at once. The Convoy App works out #quote first (the fee of the
# method picked depends on the total), takes the money, then #record under the school's lock, so seats and credit are never
# spent twice.
module CcaRides
  class Pay < ApplicationService
    Quote = Data.define(:rides, :gross, :credit, :total, :late)

    # picks: [{ child_name:, class_name:, school_rider:, date: }]
    def initialize(family, picks:, method: "PayNow", today: Date.current)
      @family = family
      @school = family.school
      @picks = picks
      @method = method
      @today = today
    end

    def call
      ApplicationRecord.transaction do
        @school.lock!
        record(quote, method: @method)
      end
    end

    # Checks the picks and works out the money; raises Error with the HTML's wording when a ride cannot be booked.
    def quote
      s = CcaRides.setting(@school)
      raise Error, "The CCA bus is not charged per ride at this school" unless s.enabled
      raise Error, "Pick at least one day" if @picks.empty?

      calendar = calendar_for(@picks.map { it[:date] })
      per = Hash.new(0)
      next_mon = CcaRides.monday(@today) + 7
      @picks.each do |p|
        d = p[:date]
        ph = CcaRides.phase(d, @today)
        raise Error, "The CCA bus does not run on #{d.strftime('%A')}s" unless s.days.include?(d.cwday)
        raise Error, "#{CcaRides.label(d)} can no longer be booked" if %w[past today].include?(ph)
        raise Error, "Only next week can be booked" if d >= next_mon + 7
        raise Error, "The CCA bus is not running on #{CcaRides.label(d)}" if @school.cca_off_days.exists?(date: d)
        raise Error, "There is no CCA bus on #{CcaRides.label(d)}: #{calendar.(d)[:label]}" if calendar.(d)
        raise Error, "#{p[:child_name]} is already booked on #{CcaRides.label(d)}" if CcaBooking.exists?(family: @family, child_name: p[:child_name], date: d)

        per[d] += 1
        raise Error, "The CCA bus on #{CcaRides.label(d)} is full" if ph == "late" && per[d] > s.seats - CcaRides.taken(@school, d)
      end

      gross = (@picks.size * s.price).round(2)
      used = [ CcaRides.credit(@family), gross ].min.clamp(0, gross)
      Quote.new(rides: @picks.size, gross:, credit: used, total: gross - used, late: @picks.any? { CcaRides.phase(it[:date], @today) == "late" })
    end

    # Writes the CCA bill, its payment (when something is owed after the credit) and the bookings. method is "Credit" when
    # the credit covers it. admin_fee is the method's surcharge, kept on the payment.
    def record(q, method: @method, source: "console", admin_fee: 0, reference: nil)
      s = CcaRides.setting(@school)
      dates = @picks.map { it[:date] }.sort
      method = "Credit" unless q.total.positive?
      week = CcaRides.monday(dates.first)
      period = q.late ? "CCA Bus · Added #{dates.uniq.map { CcaRides.label(it) }.join(', ')}" : "CCA Bus · Week of #{CcaRides.label(week)}"
      bill = SchoolBill.create!(school: @school, family: @family, kind: "cca", status: "issued", number: Finance::Numbering.next!("inv", date: @today),
                                bill_to: @family.name, bill_to_code: @family.code, issued_on: @today, due_on: @today, issued_at: Time.current, gross: q.gross,
                                credit_used: q.credit, subtotal: q.total, total: q.total, week_of: week, period_label: period)
      bill.payments.create!(paid_on: @today, amount: q.total, method:, source:, admin_fee:, reference:) if q.total.positive?
      @picks.group_by { it[:child_name] }.each_with_index do |(child, list), i|
        ds = list.map { it[:date] }.sort
        bill.lines.create!(child_name: child, position: i, amount: (ds.size * s.price).round(2),
                           description: "CCA Bus · #{ds.size} #{ds.size == 1 ? 'ride' : 'rides'} × S$#{format('%.2f', s.price)} · #{ds.map { CcaRides.label(it) }.join(', ')}")
      end
      bill.lines.create!(child_name: "Credit", description: "Rides the bus did not run", amount: -q.credit, position: 99) if q.credit.positive?
      @picks.each do |p|
        @school.cca_bookings.create!(family: @family, school_rider: p[:school_rider], school_bill: bill, child_name: p[:child_name], class_name: p[:class_name],
                                     date: p[:date], price: s.price, paid_on: @today, method:, late: CcaRides.phase(p[:date], @today) == "late")
      end
      bill
    end

    private

    # date -> the calendar note when the bus cannot run that day (public holiday, no service, school holiday, outside the
    # CCA periods), else nil.
    def calendar_for(dates)
      years = @school.academic_years.includes(:holidays, :special_days, :terms).to_a
      holidays = PublicHoliday.where(date: dates).index_by(&:date)
      ->(d) { (c = CcaRides.calendar(years, d, holidays)) && !c[:run] ? c : nil }
    end
  end
end
