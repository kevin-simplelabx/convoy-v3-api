# Delete Vehicle (Vehicles, Operator Vehicles, External Vehicles): the bus is soft deleted and kept for history.
# Not while it still has runs or a workshop visit from now on: those are moved or cancelled first, so no run
# is left pointing at a bus that is gone. Its operator driver steps off it.
module Vehicles
  class Remove < ApplicationService
    def initialize(vehicle:)
      @vehicle = vehicle
    end

    def call
      runs = TripOccurrence.scheduled.where(vehicle_id: @vehicle.id).where("date >= ? AND ends_at > ?", Date.current, Time.current).count
      visits = @vehicle.maintenance_visits.where(status: "scheduled").where("date >= ?", Date.current).count
      blockers = []
      blockers << "#{runs} #{'run'.pluralize(runs)}" if runs.positive?
      blockers << "#{visits} workshop #{'visit'.pluralize(visits)}" if visits.positive?
      if blockers.any?
        raise Error, "#{@vehicle.plate} still has #{blockers.to_sentence} from now on. Move or cancel them first, then delete the vehicle"
      end

      Vehicle.transaction do
        OperatorDriver.where(vehicle_id: @vehicle.id).find_each { |d| d.update!(vehicle: nil) }
        @vehicle.discard!
      end
    end
  end
end
