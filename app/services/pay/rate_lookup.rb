# Which period of a rate plan pays a moment, and its rate for a vehicle type (port of DriverPay.period).
# A date is "ph" when it is a public holiday (then only PH periods match), else its weekday. A range past midnight
# belongs to its start day: its early part matches when yesterday's label is in the period's days. Minutes past 1440
# belong to the next day. Where periods overlap, the first with takes_priority wins, else the first in order.
module Pay
  class RateLookup
    WDAYS = %w[sun mon tue wed thu fri sat].freeze

    # holidays: a Set of public holiday dates.
    def initialize(plan, holidays: Set.new)
      @periods = plan.periods.to_a
      @holidays = holidays
    end

    def label(date) = @holidays.include?(date) ? "ph" : WDAYS[date.wday]

    def period(date, minutes)
      date += minutes / 1440
      minutes %= 1440
      cover(label(date), label(date - 1), minutes)
    end

    # The period for a day label and minute (Coverage grid: the day before a PH is treated as PH too).
    def cover(today, yesterday, minutes)
      hits = @periods.select do |p|
        p.ranges.any? do |r|
          if r.overnight?
            (p.days.include?(today) && minutes >= r.start_time) || (p.days.include?(yesterday) && minutes < r.end_minute)
          else
            p.days.include?(today) && minutes >= r.start_time && minutes < r.end_minute
          end
        end
      end
      hits.find(&:takes_priority?) || hits.first
    end

    # { period:, per_trip:, per_hour: } for a vehicle type at a moment; missing rates are 0.
    def rate(date, minutes, vehicle_type_id)
      p = period(date, minutes)
      r = p&.rates&.find { |x| x.vehicle_type_id == vehicle_type_id }
      { period: p, per_trip: r&.per_trip.to_d, per_hour: r&.per_hour.to_d }
    end
  end
end
