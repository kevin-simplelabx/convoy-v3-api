# Pay for picked CCA rides (the Convoy App; used by seeds and specs until its endpoint exists): only the school's CCA bus
# days of next week, not a day already gone or not running, not twice; after the cut-off only while seats are left.
# One CCA bill per payment (rides × price, less the family's credit), paid at once.
module CcaRides
  class Pay < ApplicationService
    # picks: [{ child_name:, class_name:, school_rider:, date: }]
    def initialize(family, picks:, method: "PayNow", today: Date.current)
      @family = family
      @school = family.school
      @picks = picks
      @method = method
      @today = today
    end

    def call
      s = CcaRides.setting(@school)
      raise Error, "The CCA bus is not charged per ride at this school" unless s.enabled
      raise Error, "Pick at least one day" if @picks.empty?

      per = Hash.new(0)
      next_mon = CcaRides.monday(@today) + 7
      @picks.each do |p|
        d = p[:date]
        ph = CcaRides.phase(d, @today)
        raise Error, "The CCA bus does not run on #{d.strftime('%A')}s" unless s.days.include?(d.cwday)
        raise Error, "#{CcaRides.label(d)} can no longer be booked" if %w[past today].include?(ph)
        raise Error, "Only next week can be booked" if d >= next_mon + 7
        raise Error, "The CCA bus is not running on #{CcaRides.label(d)}" if @school.cca_off_days.exists?(date: d)
        raise Error, "#{p[:child_name]} is already booked on #{CcaRides.label(d)}" if CcaBooking.exists?(family: @family, child_name: p[:child_name], date: d)

        per[d] += 1
        raise Error, "The CCA bus on #{CcaRides.label(d)} is full" if ph == "late" && per[d] > s.seats - CcaRides.taken(@school, d)
      end

      gross = (@picks.size * s.price).round(2)
      used = [ CcaRides.credit(@family), gross ].min.clamp(0, gross)
      total = gross - used
      late = @picks.any? { CcaRides.phase(it[:date], @today) == "late" }
      dates = @picks.map { it[:date] }.sort
      method = total.positive? ? @method : "Credit"
      ApplicationRecord.transaction do
        week = CcaRides.monday(dates.first)
        period = late ? "CCA Bus · Added #{dates.uniq.map { CcaRides.label(it) }.join(', ')}" : "CCA Bus · Week of #{CcaRides.label(week)}"
        bill = SchoolBill.create!(school: @school, family: @family, kind: "cca", status: "issued", number: Finance::Numbering.next!("inv", date: @today),
                                  bill_to: @family.name, bill_to_code: @family.code, issued_on: @today, due_on: @today, issued_at: Time.current, gross:, credit_used: used, subtotal: total,
                                  total:, week_of: week, period_label: period)
        bill.payments.create!(paid_on: @today, amount: total, method:, source: "app") if total.positive?
        @picks.group_by { it[:child_name] }.each_with_index do |(child, list), i|
          ds = list.map { it[:date] }.sort
          bill.lines.create!(child_name: child, position: i, amount: (ds.size * s.price).round(2),
                             description: "CCA Bus · #{ds.size} #{ds.size == 1 ? 'ride' : 'rides'} × S$#{format('%.2f', s.price)} · #{ds.map { CcaRides.label(it) }.join(', ')}")
        end
        bill.lines.create!(child_name: "Credit", description: "Rides the bus did not run", amount: -used, position: 99) if used.positive?
        @picks.each do |p|
          @school.cca_bookings.create!(family: @family, school_rider: p[:school_rider], school_bill: bill, child_name: p[:child_name], class_name: p[:class_name],
                                       date: p[:date], price: s.price, paid_on: @today, method:, late: CcaRides.phase(p[:date], @today) == "late")
        end
        bill
      end
    end
  end
end
