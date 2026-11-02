# Fleet facts the generator asks for many rows at once, loaded in a few queries: who drives a vehicle on a date
# (own: default driver schedule; managed: its operator driver), whose vehicle it is.
module Occurrences
  class Fleet
    def initialize
      @vehicles = Vehicle.with_discarded.select(:id, :operator_id).index_by(&:id)
      @schedules = VehicleDriverSchedule.includes(:driver).order(:starts_on).group_by(&:vehicle_id)
      @operator_drivers = OperatorDriver.active.where.not(vehicle_id: nil).index_by(&:vehicle_id)
    end

    def driver_on(vehicle_id, date)
      return @operator_drivers[vehicle_id] if @vehicles[vehicle_id]&.operator_id

      @schedules[vehicle_id]&.select { |s| s.starts_on <= date }&.last&.driver
    end

    def operator_of(vehicle_id) = vehicle_id && @vehicles[vehicle_id]&.operator_id
    def own?(vehicle_id) = @vehicles[vehicle_id]&.operator_id.nil?
  end
end
