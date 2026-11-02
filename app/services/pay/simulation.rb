# HR > Salary Simulator: a made-up month on one pay scheme and vehicle type. Nothing is saved. Jobs come as
# { "2026-11-03" => [{ type: trip, start_time, tv } | { type: disposal, start_time, end_time }] }; without the route
# retainer, each school route is driven as a trip on school weekdays (as the prototype does).
module Pay
  class Simulation < ApplicationService
    def initialize(scheme:, vehicle_type_id:, month:, jobs:, routes: [], school_holidays: nil, rejected: 0, on_time: nil, attendance: nil)
      @scheme = scheme
      @type_id = vehicle_type_id
      @month = month.beginning_of_month
      @raw_jobs = jobs
      @routes = routes
      @school_holidays = school_holidays
      @rejected = rejected
      @on_time = on_time
      @attendance = attendance
      @holidays = PublicHoliday.between(@month, @month.end_of_month).to_h { |h| [ h.date, h.name ] }
    end

    def call
      result = Month.call(month: @month, schemes: ->(_d) { @scheme }, jobs: jobs + route_trips, holidays: @holidays.keys.to_set,
                          routes: @routes, school_holidays: @school_holidays, rejected: @rejected)
      { result:, holidays: @holidays, bonuses: Bonuses.call(result:, on_time: @on_time || 100, attendance: @attendance || 100) }
    end

    # Fill Sample Month (DriverPay.sampleJobs): weekday trips at 06:00, 07:00 (1.5 on Wednesdays), 13:00, 15:00, 16:00,
    # a 17:00–23:00 disposal on the first weekday, 08:00–15:00 disposals on the first Saturday and Sunday, two trips on PH weekdays.
    def self.sample(month)
      holidays = PublicHoliday.between(month, month.end_of_month).pluck(:date).to_set
      first_weekday = sat = sun = nil
      (month..month.end_of_month).each_with_object({}) do |d, out|
        list = []
        if holidays.include?(d)
          list = [ trip("07:00"), trip("13:00") ] if (1..5).cover?(d.wday)
        elsif (1..5).cover?(d.wday)
          list = %w[06:00 07:00 13:00 15:00 16:00].map { |t| trip(t, d.wednesday? && t == "07:00" ? 1.5 : 1) }
          unless first_weekday
            first_weekday = d
            list << hours("17:00", "23:00")
          end
        elsif d.saturday? && !sat
          sat = d
          list << hours("08:00", "15:00")
        elsif d.sunday? && !sun
          sun = d
          list << hours("08:00", "15:00")
        end
        out[d.iso8601] = list if list.any?
      end
    end

    def self.trip(at, tv = 1) = { type: "trip", start_time: at, tv: }
    def self.hours(from, to) = { type: "disposal", start_time: from, end_time: to }

    private

    def jobs
      @raw_jobs.flat_map do |date, list|
        d = Date.parse(date.to_s)
        next [] unless (@month..@month.end_of_month).cover?(d)

        Array(list).map do |j|
          j = j.to_h.symbolize_keys
          hourly = j[:type].to_s == "disposal"
          Engine::Job.new(date: d, kind: hourly ? :hours : :trip, start: Clock.minutes(j[:start_time]), finish: hourly ? Clock.minutes(j[:end_time].presence || "23:59") : nil,
                          tv: j[:tv].presence || 1, vehicle_type_id: @type_id)
        end
      end
    rescue ArgumentError, Date::Error
      raise ApplicationService::Error, "Check the dates and times of the jobs"
    end

    def route_trips
      return [] if @routes.empty? || @scheme&.school_routes_pay?

      (@month..@month.end_of_month).flat_map do |d|
        next [] if !(1..5).cover?(d.wday) || @holidays.key?(d) || @school_holidays&.cover?(d)

        @routes.map { |r| Engine::Job.new(date: d, kind: :trip, start: Clock.minutes(r[:start].presence || "07:00"), tv: 1, vehicle_type_id: @type_id, route: true) }
      end
    end
  end
end
