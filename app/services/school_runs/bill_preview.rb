# Next 12 Months of a School Run: per month the runs, the No School days, the paid share and what the main contractor
# is billed (monthly price x share; or the runs x the run price when charged per trip). A month with no runs is still
# billed at the monthly price.
module SchoolRuns
  class BillPreview < ApplicationService
    def initialize(trip, from = Date.current)
      @trip = trip
      @from = [ from, trip.starts_on ].max.beginning_of_month
    end

    def call
      to = (@from + 11.months).end_of_month
      ctx = Calendars::Context.for(@trip.company, from: @from, to:)
      pricer = Pricing::TripPrice.new(@trip, ctx)
      (0..11).map do |i|
        month = @from + i.months
        runs = ctx.trip_dates(@trip, month, month.end_of_month)
        factor = pricer.month_factor(month)
        amount = @trip.charge_per_month? ? (@trip.price * factor).round(2) : runs.sum { |d| pricer.run_price(slot: 1, date: d) } * @trip.vehicles_count
        { month: month.strftime("%Y-%m"), runs: runs.size, no_school_days: ctx.no_school_days(@trip, month, month.end_of_month),
          share: factor.round(4), amount: }
      end
    end
  end
end
