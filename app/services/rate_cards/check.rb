# Warnings for a card (shown, not blocking, as on the Rate Cards page):
# overlaps — two periods of the same kind (both normal or both override) covering the same day and time;
# gaps — weekday times (30-minute steps) no period covers, so a booking then has no rate (first four days).
module RateCards
  class Check
    DAY_KEYS = %w[mon tue wed thu fri sat sun ph].freeze
    GAP_WEEK = Date.new(2026, 1, 5) # a Monday, no public holidays that week

    def self.call(card) = new(card).call

    def initialize(card)
      @periods = card.periods.to_a
    end

    def call = { overlaps:, gaps: }

    private

    def overlaps
      DAY_KEYS.each_with_index.flat_map do |day, i|
        previous = i.zero? ? "sun" : (day == "ph" ? nil : DAY_KEYS[i - 1])
        spans = @periods.flat_map { |p| spans_on(p, day, previous) }.sort_by(&:first)
        spans.each_with_index.flat_map do |(a_start, a_end, a), j|
          spans[(j + 1)..].take_while { |(b_start)| b_start < a_end }.filter_map do |(_, _, b)|
            next if a.override != b.override

            a.equal?(b) ? "Times overlap within #{a.name} on #{day.upcase}" : "#{a.name} and #{b.name} overlap on #{day.upcase}"
          end
        end
      end.uniq
    end

    # [start, end, period] minutes a period covers on a day key; a range past midnight runs into the next day.
    def spans_on(period, day, previous)
      period.ranges.flat_map do |r|
        next [] if r.starts_at.nil? || r.ends_at.nil?

        if r.starts_at < r.ends_at
          period.days.include?(day) ? [ [ r.starts_at, r.ends_at, period ] ] : []
        else
          (period.days.include?(day) ? [ [ r.starts_at, 1440, period ] ] : []) +
            (previous && period.days.include?(previous) ? [ [ 0, r.ends_at, period ] ] : [])
        end
      end
    end

    def gaps
      (0..6).filter_map do |i|
        date = GAP_WEEK + i
        miss = (0...1440).step(30).find { |m| @periods.none? { |p| p.covers?(date, m, holiday: false) } }
        "#{RateCardPeriod::DAYS[date.wday].upcase} from #{Clock.hm(miss)}" if miss
      end.first(4)
    end
  end
end
