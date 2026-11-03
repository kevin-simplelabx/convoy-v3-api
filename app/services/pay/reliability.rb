# A driver's on-time and attendance rates for a reliability bonus (HR › Bonuses › On-Time Performance / Attendance),
# from what the Convoy Driver app recorded, over the bonus's days in the month (from its start, to its end) less its
# Excluded Days, up to now:
#   on_time     of the completed runs with arrivals recorded, the share that reached their stops within the company's
#               On Time allowance (the same figure as Trip History and the Dashboard); runs with no arrival recorded do
#               not count against the driver
#   attendance  of the runs given to the driver (not cancelled by the office or the client; a trip the driver skipped
#               counts as missed), the share the driver started in the app
# A percentage with one decimal, or nil when there is nothing to count.
module Pay
  class Reliability < ApplicationService
    def initialize(driver:, month:, bonus:, now: Time.current)
      @driver = driver
      @month = month.beginning_of_month
      @bonus = bonus
      @now = now
    end

    def call
      runs = TripOccurrence.where(driver_id: @driver.id, date: days).visible.where(starts_at: ..@now).to_a
      @bonus.reliability_otp? ? on_time(runs) : attendance(runs)
    end

    def days
      from = [ @month, @bonus.starts_on ].max
      to = [ @month.end_of_month, @bonus.ends_on, @now.to_date ].compact.min
      (from..to).reject { |d| @bonus.excluded_periods.any? { |p| d.between?(p.starts_on, p.ends_on) } }
    end

    private

    def on_time(runs)
      known = runs.select { it.completed? && it.max_delay_minutes }
      allowance = ActsAsTenant.current_tenant.on_time_minutes
      percent(known.count { it.max_delay_minutes <= allowance }, known.size)
    end

    def attendance(runs)
      given = runs.reject { it.cancelled? && it.driver_end != "skipped" }
      percent(given.count(&:started_at), given.size)
    end

    def percent(part, whole) = whole.zero? ? nil : (part * 100.0 / whole).round(1)
  end
end
