# Routes column of Managed Operators: School Bus routes of running plans whose regular bus today belongs to each
# operator. { operator_id => count }.
module Operators
  class RouteCounts < ApplicationService
    def call
      latest = SchoolRouteVehicleChange.where(school_route_id: SchoolRoutes.running_ids, effective_from: ..Date.current)
                                       .select("DISTINCT ON (school_route_id) school_route_id, vehicle_id")
                                       .order(:school_route_id, effective_from: :desc)
      Vehicle.where.not(operator_id: nil).joins("JOIN (#{latest.to_sql}) regular ON regular.vehicle_id = vehicles.id")
             .group(:operator_id).count
    end
  end
end
