# Which dates a trip runs and how its times move, from the company's public holidays and calendars
# (port of logic/calendars.js). Built once for a date range, then asked many times without queries.
module Calendars
  class Context
    # One date on one calendar: off = label of the day off (nil when it runs), ns = No School, work = Working Holiday,
    # shifts = the days that move times (early, late, shift).
    Day = Struct.new(:off, :ns, :work, :shifts)
    Cal = Data.define(:observed_holidays, :morning_time, :afternoon_time, :days)

    attr_reader :holidays

    # Context for a company and range: loads its holidays and calendar days once. Whole months are loaded, because
    # monthly prices are spread over every run day of the month.
    def self.for(company, from:, to:)
      from = from.beginning_of_month
      to = to.end_of_month
      holidays = PublicHoliday.where(company:, date: from..to).to_h { |h| [ h.date, h ] }
      days = CalendarDay.where(company:).overlapping(from, to).to_a.group_by(&:calendar_id)
      calendars = Calendar.where(company:).to_h do |c|
        [ c.id, Cal.new(c.observed_holidays, c.morning_time, c.afternoon_time, expand(days[c.id] || [], from, to)) ]
      end
      new(holidays:, calendars:, observed_holidays: company.observed_holidays)
    end

    # { date => Day } for a calendar's entries within from..to.
    def self.expand(entries, from, to)
      map = Hash.new { |h, d| h[d] = Day.new(nil, false, false, []) }
      entries.each do |x|
        ([ x.starts_on, from ].max..[ x.ends_on, to ].min).each do |d|
          day = map[d]
          if x.off? then day.off ||= x.label.presence || x.kind_name
          elsif x.work? then day.work = true
          else day.shifts << x
          end
          day.ns = true if x.ns?
        end
      end
      map.default_proc = nil
      map
    end

    def initialize(holidays: {}, calendars: {}, observed_holidays: "off")
      @holidays = holidays
      @calendars = calendars
      @observed_holidays = observed_holidays
    end

    def holiday?(date) = @holidays.key?(date)

    # Does a trip skip the date because it is a public holiday? A Working Holiday on its calendar runs;
    # an observed holiday runs when the calendar (or the company, for trips without one) treats it as a working day.
    def skips_public_holiday?(skip, calendar_id, date)
      holiday = @holidays[date]
      return false unless skip && holiday

      cal = @calendars[calendar_id]
      return false if cal&.days&.dig(date)&.work
      return false if holiday.observed && (cal ? cal.observed_holidays : @observed_holidays) == "work"

      true
    end

    # Label of the calendar's day off, or nil when the calendar runs that day.
    def day_off(calendar_id, date) = calendar_id && @calendars[calendar_id]&.days&.dig(date)&.off

    def no_school?(calendar_id, date) = !!(calendar_id && @calendars[calendar_id]&.days&.dig(date)&.ns)

    # Is a trip starting at start_min in the morning session? A School Run's own session wins; otherwise the
    # regular session it starts nearer to.
    def morning?(calendar_id, start_min, session = nil)
      return session == "am" if session.present?

      cal = @calendars[calendar_id]
      am, pm = cal ? [ cal.morning_time, cal.afternoon_time ] : [ 450, 810 ]
      (start_min || 480) < (pm > am ? (am + pm) / 2.0 : 720)
    end

    # Minutes a trip starting at start_min moves on a date: Changed Times move every trip,
    # Early Dismissal afternoon trips, Late Arrival morning trips.
    def time_shift(calendar_id, date, start_min, session = nil)
      day = calendar_id && @calendars[calendar_id]&.days&.dig(date)
      return 0 if day.nil? || day.off || day.shifts.empty?

      am = morning?(calendar_id, start_min, session)
      day.shifts.sum do |x|
        if x.shift? then x.shift_minutes.to_i
        elsif x.early? && !am then x.time_change
        elsif x.late? && am then x.time_change
        else 0
        end
      end
    end

    # Does a recurring pattern run on the date? (weekday, public holidays, calendar days off; not the date range)
    def runs_on?(days:, skip_public_holidays:, calendar_id:, date:)
      days.include?(date.wday) && !skips_public_holiday?(skip_public_holidays, calendar_id, date) && !day_off(calendar_id, date)
    end

    # Dates between from and to (inclusive) on which a trip runs. A one-off trip gives its own date when inside.
    def trip_dates(trip, from, to)
      return (from..to).cover?(trip.starts_on) ? [ trip.starts_on ] : [] unless trip.recurring?

      first = [ from, trip.starts_on ].max
      last = trip.last_date ? [ to, trip.last_date ].min : to
      return [] if first > last

      (first..last).select do |d|
        runs_on?(days: trip.days, skip_public_holidays: trip.skip_public_holidays, calendar_id: trip.calendar_id, date: d)
      end
    end

    # Dates a recurring trip would run on (its weekdays, inside its dates) but the calendar skips, with why:
    # { date => "Public holiday: Deepavali" | the calendar's day off label }.
    def trip_skips(trip, from, to)
      return {} unless trip.recurring?

      first = [ from, trip.starts_on ].max
      last = trip.last_date ? [ to, trip.last_date ].min : to
      return {} if first > last

      (first..last).each_with_object({}) do |d, out|
        next unless trip.days.include?(d.wday)

        if skips_public_holiday?(trip.skip_public_holidays, trip.calendar_id, d)
          out[d] = "Public holiday: #{@holidays[d].name}"
        elsif (off = day_off(trip.calendar_id, d))
          out[d] = off
        end
      end
    end

    # No School days in the range that fall on the trip's weekdays inside its dates (runs lost to the calendar).
    def no_school_days(trip, from, to)
      first = [ from, trip.starts_on ].max
      last = trip.last_date ? [ to, trip.last_date ].min : to
      return 0 if first > last || trip.calendar_id.nil?

      (first..last).count { |d| trip.days.include?(d.wday) && no_school?(trip.calendar_id, d) }
    end

    # Date of the n-th run from start (End: After N occurrences).
    def nth_run_date(start, days:, count:, skip_public_holidays:, calendar_id:, limit: 3660)
      return nil if start.nil? || days.empty? || count.to_i < 1

      seen = 0
      (start..start + limit).each do |d|
        next unless runs_on?(days:, skip_public_holidays:, calendar_id:, date: d)

        seen += 1
        return d if seen >= count
      end
      nil
    end
  end
end
