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
        earned = @s.break_pay == "earned" ? @earned.call(month, running) : 1.to_d
        pct = (rate * earned).round(4)
        { month: month.strftime("%Y-%m"), label: month.strftime("%b %Y"), rate:, earned: earned.round(4), pct: (pct * 100).round, note: note(month, running, rate),
          amount: price && (price.to_d * pct).round(2) }
      end
    end

    private

    def note(month, running, rate)
      text = served(month, running)
      rate < 1 ? "#{text}, at #{(rate * 100).round}% part pay" : text
    end

    def served(month, running)
      return "Full pay for any route on contract" if @s.break_pay != "earned"

      period = @earned.service_period(month)
      return "No earlier term in the calendar, so paid in full" if period.empty?

      ran = ->(days) { days.any? { running.(it) } }
      if @s.earn_by == "days"
        days = period.flat_map { |y, t| @earned.school_days(y, t) }
        return "Ran #{days.count { running.(it) }} of #{days.size} school days"
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
