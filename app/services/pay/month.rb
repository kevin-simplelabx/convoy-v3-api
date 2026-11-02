# A month of pay: splits the month into parts by pay scheme (schemes: a lambda date → PayScheme or nil) and runs
# Pay::Engine on each part, then adds them up. One scheme for the whole month gives one part.
module Pay
  class Month < ApplicationService
    Result = Struct.new(:month, :total, :parts, :job_pay, :trips, keyword_init: true)

    def initialize(month:, schemes:, jobs:, holidays: nil, routes: [], school_holidays: nil, rejected: 0, from: nil, to: nil, route_days: true)
      @month = month.beginning_of_month
      @schemes = schemes
      @jobs = jobs
      @holidays = holidays || PublicHoliday.between(@month, @month.end_of_month).pluck(:date).to_set
      @routes = routes
      @school_holidays = school_holidays
      @rejected = rejected
      @route_days = route_days
      @from = [ from || @month, @month ].max
      @to = [ to || @month.end_of_month, @month.end_of_month ].min
    end

    def call
      parts = segments.map do |scheme, from, to|
        Engine.new(scheme:, from:, to:, month_days: @month.end_of_month.day, holidays: @holidays, jobs: @jobs.select { |j| (from..to).cover?(j.date) },
                   routes: @routes, school_holidays: @school_holidays, rejected: @rejected, route_days: @route_days).call
      end
      Result.new(month: @month, total: parts.sum(0.to_d, &:total), parts:, job_pay: parts.map(&:job_pay).reduce({}, :merge),
                 trips: parts.sum(0.to_d, &:trips))
    end

    private

    # [[scheme, from, to]] runs of days on the same scheme (a driver who joins or leaves mid-month only has their days).
    def segments
      return [] if @from > @to

      (@from..@to).slice_when { |a, b| @schemes.call(a)&.id != @schemes.call(b)&.id }.map { |days| [ @schemes.call(days.first), days.first, days.last ] }
    end
  end
end
