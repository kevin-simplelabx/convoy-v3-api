# The bus a driver is on at a company. Own drivers: the default driver schedule in force (from a date and time of day);
# managed drivers: their operator's bus. Switches: the buses the driver takes over later (the Switch Vehicle card),
# from the schedule entries naming them that start after now (today and tomorrow).
module DriverApp
  module Vehicles
    module_function

    # { vehicle:, since:, since_time:, schedule: } or nil.
    def current(member, at: Time.current)
      return member.vehicle && { vehicle: member.vehicle, since: nil, since_time: nil, schedule: nil } if member.is_a?(OperatorDriver)

      entry = VehicleDriverSchedule.current_at(at.to_date, minute(at)).includes(:vehicle).where(driver_id: member.id).max_by(&:sort_key)
      entry && { vehicle: entry.vehicle, since: entry.starts_on, since_time: entry.start_time.positive? ? entry.start_time_hm : nil, schedule: entry }
    end

    # [{ schedule:, vehicle:, starts_at: }] starting after `at` up to the end of `to`.
    def switches(member, at: Time.current, to: at.to_date + 1)
      return [] unless member.is_a?(Driver)

      VehicleDriverSchedule.where(driver_id: member.id, starts_on: at.to_date..to).includes(:vehicle).sort_by(&:sort_key)
                           .map { { schedule: it, vehicle: it.vehicle, starts_at: it.starts_on.in_time_zone + it.start_time.minutes } }
                           .select { it[:starts_at] > at }
    end

    def minute(at) = (at.hour * 60) + at.min
  end
end
