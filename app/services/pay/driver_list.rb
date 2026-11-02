# HR > Drivers (and the driver lists of Earnings and Points): active own drivers with their bus today, age, the pay
# scheme and vehicle type in force today, and a warning when the scheme's rate plan has no rate for that type.
module Pay
  class DriverList < ApplicationService
    def initialize(drivers:, date: Date.current)
      @drivers = drivers.to_a
      @date = date
    end

    def call
      ids = @drivers.map(&:id)
      buses = VehicleDriverSchedule.current_on(@date).where(driver_id: ids).includes(:vehicle).index_by(&:driver_id)
      schemes = DriverPayScheme.on(@date).where(driver_id: ids).includes(pay_scheme: { rate_plan: { periods: :rates } }).index_by(&:driver_id)
      with_rows = DriverPayScheme.where(driver_id: ids).distinct.pluck(:driver_id).to_set
      types = DriverVehicleType.on(@date).where(driver_id: ids).index_by(&:driver_id)
      enabled = VehicleType.enabled_for(ActsAsTenant.current_tenant).to_a
      default = PayScheme.kept.includes(rate_plan: { periods: :rates }).find_by(is_default: true)

      @drivers.map do |d|
        bus = buses[d.id]&.vehicle
        scheme = with_rows.include?(d.id) ? schemes[d.id]&.pay_scheme : default
        type_id = types[d.id]&.vehicle_type_id || VehicleType.for_seats(enabled, bus&.seats)&.id
        { driver: d, vehicle: bus, scheme:, vehicle_type: enabled.find { |t| t.id == type_id } || VehicleType.find_by(id: type_id),
          warning: Pay::DriverList.rate_warning(scheme, type_id) }
      end
    end

    # "Rate plan Standard of Basic + Trips has no rates for Coach, so these jobs are paid S$0"
    def self.rate_warning(scheme, type_id)
      plan = scheme&.rate_plan
      return nil if plan.nil? || type_id.nil?
      return nil if plan.periods.any? { |p| p.rates.any? { |r| r.vehicle_type_id == type_id && r.per_trip } }

      "Rate plan #{plan.name} of #{scheme.name} has no rates for #{VehicleType.find(type_id).name}, so these jobs are paid S$0"
    end
  end
end
