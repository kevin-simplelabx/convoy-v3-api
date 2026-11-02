# First / Last Period options of a bonus (prototype payPeriods): weekly — 40 Mondays from 4 weeks before this week;
# monthly — last month and the next 24; quarterly 12; half-yearly 8; yearly 6. Daily bonuses pick dates instead.
module Pay
  class BonusPeriods < ApplicationService
    def initialize(frequency:, today: Date.current)
      @frequency = frequency.to_s
      @today = today
    end

    def call
      case @frequency
      when "weekly"
        monday = @today.beginning_of_week - 28
        40.times.map { |i| d = monday + (7 * i); { value: d, label: "Week of Mon #{d.strftime('%-d %b %Y')}" } }
      when "monthly" then months(@today.prev_month.beginning_of_month, 25, 1) { |d| d.strftime("%b %Y") }
      when "quarterly"
        months(@today.beginning_of_quarter, 12, 3) { |d| "Q#{((d.month - 1) / 3) + 1} #{d.year}, #{d.strftime('%b')} to #{(d >> 2).strftime('%b')}" }
      when "half_yearly"
        start = Date.new(@today.year, @today.month <= 6 ? 1 : 7, 1)
        months(start, 8, 6) { |d| "H#{d.month == 1 ? 1 : 2} #{d.year}, #{d.strftime('%b')} to #{(d >> 5).strftime('%b')}" }
      when "yearly" then months(@today.beginning_of_year, 6, 12) { |d| d.year.to_s }
      else raise ApplicationService::Error, "Daily bonuses pick dates"
      end
    end

    private

    def months(start, count, step) = count.times.map { |i| d = start >> (i * step); { value: d, label: yield(d) } }
  end
end
