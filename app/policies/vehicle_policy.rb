class VehiclePolicy < FleetPolicy
  PERMITTED = %i[plate seats make model year_made notes photo remove_photo operator_id vehicle_team_id
                 driver_name driver_phone registered_on chassis_number engine_number coe_expires_on
                 road_tax_expires_on].freeze

  # tags as a list (tags[]=Coach) or as text with commas
  def permitted_attributes = [ *PERMITTED, :tags, { tags: [] } ]
  # New External Vehicle from the Scheduler: anyone who can edit the Scheduler.
  def create_external? = write?
end
