# Break-month retainer earned by a route (port of servicePeriod / earned in Convoy OS): the service period is the latest
# term that ended before the month, with the terms before it that follow on within 21 days. By terms: the share of those
# terms the route ran in (one term: its halves). By school days: days run out of the period's school days, a start within
# the grace days counting from the period start, less the deducted days.
module OperatorPays
  class Earned
    GAP_DAYS = 21

    def initialize(school, settings)
      @settings = settings
      @terms = school.academic_years.includes(:terms, :holidays).flat_map { |y| y.terms.select { it.starts_on && it.ends_on }.map { [ y, it ] } }
                     .sort_by { |_, t| t.starts_on }
    end

    # running: lambda(date) → did the route run that day.
    def call(month_start, running)
      period = service_period(month_start)
      return 1.to_d if period.empty?

      @settings.earn_by == "days" ? by_days(period, running) : by_terms(period, running)
    end

    def service_period(date)
      before = @terms.select { |_, t| t.ends_on < date }
      return [] if before.empty?

      out = [ before.last ]
      before[0...-1].reverse_each do |pair|
        break if (out.first.last.starts_on - pair.last.ends_on).to_i >= GAP_DAYS

        out.unshift(pair)
      end
      out
    end

    def school_days(year, term) = (term.starts_on..term.ends_on).select { year.school_day?(it) }

    private

    def by_days(period, running)
      days = period.flat_map { |y, t| school_days(y, t) }
      return 1.to_d if days.empty?

      first = days.index { running.(it) }
      grace = [ @settings.grace_start_days.to_i, 0 ].max
      counts = first && first < grace ? ->(d) { d < days[first] || running.(d) } : running
      got = days.count { counts.(it) }
      return 1.to_d if got >= days.size

      [ got - [ @settings.deduct_days.to_i, 0 ].max, 0 ].max.to_d / days.size
    end

    def by_terms(period, running)
      if period.size == 1
        days = school_days(*period.first)
        return 1.to_d if days.empty?

        half = (days.size / 2.0).ceil
        return [ days.first(half), days.drop(half) ].count { |part| part.any? { running.(it) } }.to_d / 2
      end
      period.count { |y, t| school_days(y, t).any? { running.(it) } }.to_d / period.size
    end
  end
end
