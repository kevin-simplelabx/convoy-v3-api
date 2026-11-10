# Break Month Calculator: what a route starting on a date at a monthly price is paid for each break month of an academic
# year, with the school's Operator Pay settings (part pay of the scheme × the retainer earned).
module OperatorPays
  class Calculator
    def initialize(school, year, settings)
      @school = school
      @year = year
      @s = settings
      @earned = Earned.new(school, settings)
    end

    def call(start:, price:)
      (0..11).filter_map do |i|
        month = @year.starts_on >> i
        next unless @s.break_months.include?(month.month)

        rate = @s.rate(month.month)
        running = ->(d) { d >= start }
        row = { month: month.strftime("%Y-%m"), label: month.strftime("%b %Y"), rate: }
        if rate.zero? then unpaid(row, "Not a paid month under the Pay Scheme", price)
        elsif start > month.end_of_month then unpaid(row, "Route not started yet", price)
        else
          earned = @s.break_pay == "earned" ? @earned.call(month, running) : 1.to_d
          pct = (rate * earned).round(4)
          row.merge(earned: earned.round(4), pct: (pct * 100).round, note: note(month, running, rate), amount: price && (price.to_d * pct).round(2))
        end
      end
    end

    private

    # A month the route earns nothing in (HTML: "0%" and S$0.00 when a price is entered).
    def unpaid(row, note, price) = row.merge(earned: 0.to_d, pct: 0, note:, amount: price && 0.to_d)

    def note(month, running, rate)
      text = served(month, running)
      rate < 1 ? "#{text}, at #{(rate * 100).round}% part pay" : text
    end

    def days_note(days, running)
      grace = [ @s.grace_start_days.to_i, 0 ].max
      first = days.index { running.(it) }
      return "Started on school day #{first + 1}, inside the #{grace}-day grace period" if first && first < grace

      ran = days.count { running.(it) }
      deduct = @s.deduct_days.to_i
      "Ran #{ran} of #{days.size} school days#{", less #{deduct} days" if ran < days.size && deduct.positive?}"
    end

    def served(month, running)
      return "Full pay for any route on contract" if @s.break_pay != "earned"

      period = @earned.service_period(month)
      return "No earlier term in the calendar, so paid in full" if period.empty?

      ran = ->(days) { days.any? { running.(it) } }
      if @s.earn_by == "days"
        days = period.flat_map { |y, t| @earned.school_days(y, t) }
        return days_note(days, running)
      end
      if period.size == 1
        days = @earned.school_days(*period.first)
        half = (days.size / 2.0).ceil
        return "Ran in #{[ days.first(half), days.drop(half) ].count(&ran)} of 2 halves of the term"
      end
      "Ran in #{period.count { |y, t| ran.(@earned.school_days(y, t)) }} of #{period.size} terms"
    end
  end
end
