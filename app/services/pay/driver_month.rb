# HR > Earnings: a driver's month from the Scheduler. Every run the driver drives on an own bus is listed with a pay
# status; only completed runs with no issue raised are paid (Pay::Month on the driver's schemes, vehicle types and
# public holidays). Disposal runs and trips priced by the hour are paid by the hour. School route runs under a route
# retainer count as trips and are paid by the retainer (one per route the driver drove that month).
module Pay
  class DriverMonth < ApplicationService
    Run = Struct.new(:occurrence, :status, :job, :hours, keyword_init: true)
    Out = Struct.new(:driver, :month, :runs, :result, :confirmed, :schemes, :bonuses, keyword_init: true) do
      # Scheme pay plus the bonuses paid this month (Trip Target bonuses the driver can join).
      def total = result.total + bonus_total
      def bonus_total = bonuses.select { |b| b[:paid_now] }.sum(0.to_d) { |b| b[:amount] + b[:adjust].to_d }
    end

    def initialize(driver:, month:, now: Time.current)
      @driver = driver
      @month = month.beginning_of_month
      @now = now
    end

    def call
      terms = DriverTerms.new(@driver, from: @month, to: @month.end_of_month)
      schemes = ->(d) { terms.scheme_on(d) }
      runs = load_runs(terms)
      paid = runs.select { |r| r.status == "completed" }
      result = Month.call(month: @month, schemes:, jobs: paid.map(&:job), routes: routes(paid), route_days: false)
      Out.new(driver: @driver, month: @month, runs:, result:, schemes: terms, bonuses: Bonuses.call(result:, driver: @driver),
              confirmed: DriverPayMonth.includes(:lines, :runs, :confirmed_by).find_by(driver: @driver, month: @month))
    end

    # completed | issue | running | upcoming | cancelled
    def self.status(occ, now)
      return "cancelled" if occ.cancelled?
      return occ.issue_raised_at ? "issue" : "completed" if occ.completed? || occ.ended_at || occ.ends_at <= now
      return "running" if occ.starts_at <= now

      "upcoming"
    end

    private

    def load_runs(terms)
      types = VehicleType.enabled_for(ActsAsTenant.current_tenant).to_a
      TripOccurrence.in_month(@month).visible.where(driver: @driver)
                    .joins("LEFT JOIN vehicles ON vehicles.id = trip_occurrences.vehicle_id").where(vehicles: { operator_id: nil })
                    .includes(:vehicle, :trip).chronological.map do |occ|
        hourly = occ.kind == "disposal" || occ.trip&.trip_value_by_hours?
        hours = hourly ? quarter_hours(occ) : nil
        type_id = terms.vehicle_type_id_on(occ.date) || VehicleType.for_seats(types, occ.vehicle&.seats)&.id
        job = Engine::Job.new(date: occ.date, kind: hourly ? :hours : :trip, start: occ.start_time, finish: hourly ? occ.start_time + (hours * 60).to_i : nil,
                              tv: occ.trip_value, vehicle_type_id: type_id, ref: occ.id, route: occ.school_route_id.present?)
        Run.new(occurrence: occ, status: self.class.status(occ, @now), job:, hours:)
      end
    end

    # Hours of an hourly run, to the quarter hour (rounded as its trip says: up by default).
    def quarter_hours(occ)
      q = (occ.end_time - occ.start_time).to_d / 15
      q = occ.trip&.round_down? ? q.floor : q.ceil
      q.to_d / 4
    end

    # Routes for the retainer: each school route driven (paid) this month, with its length.
    def routes(paid)
      paid.map(&:occurrence).select(&:school_route_id).uniq(&:school_route_id).map { |o| { minutes: o.end_time - o.start_time, start: Clock.hm(o.start_time) } }
    end
  end
end
