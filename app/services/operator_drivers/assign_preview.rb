# Change Driver / Assign Bus dialog of Operator Vehicles and Operator Drivers: what happens when a driver is put on a
# bus, before it is confirmed with PATCH /operator_drivers/:id/assign_vehicle. Give the two sides:
#   driver + vehicle  → the driver goes on the bus (a driver already there takes the driver's old bus, or none)
#   driver, no vehicle → the driver comes off their bus
#   vehicle, no driver → the bus's driver comes off it
# Returns { effects: [sentences], swap:, changed:, apply: { driver_id, vehicle_id } }.
module OperatorDrivers
  class AssignPreview < ApplicationService
    def initialize(driver: nil, vehicle: nil)
      @driver = driver
      @vehicle = vehicle
    end

    def call
      raise Error, "Pick a driver or a bus" if @driver.nil? && @vehicle.nil?
      return take_off(@vehicle.operator_driver, nil) if @driver.nil?
      return take_off(@driver, @driver.vehicle) if @vehicle.nil?

      check!
      return result([], false, false) if @driver.vehicle_id == @vehicle.id

      current = @vehicle.operator_driver
      old = @driver.vehicle
      effects = [ "#{@driver.name} #{old ? "moves from #{old.plate} to" : 'drives'} #{@vehicle.plate}" ]
      if current then effects << (old ? "#{current.name} moves to #{old.plate}" : "#{current.name} is left without a bus")
      elsif old then effects << "#{old.plate} is left without a driver"
      end
      result(effects, current.present? && old.present?, true, @driver.id, @vehicle.id)
    end

    private

    def take_off(driver, vehicle)
      return result([], false, false) if driver.nil? || driver.vehicle.nil?

      result([ "#{driver.name} is taken off #{(vehicle || driver.vehicle).plate}" ], false, true, driver.id, nil)
    end

    def check!
      raise Error, "#{@vehicle.plate} is not a bus of #{@driver.operator.name}" if @vehicle.operator_id != @driver.operator_id
      raise Error, "#{@driver.name} has not accepted the invite yet" unless @driver.active?
    end

    def result(effects, swap, changed, driver_id = nil, vehicle_id = nil)
      { effects:, swap:, changed:, ok_label: swap ? "Swap Drivers" : "Confirm", apply: changed ? { driver_id:, vehicle_id: } : nil }
    end
  end
end
