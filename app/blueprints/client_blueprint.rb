class ClientBlueprint < ApplicationBlueprint
  fields :code, :kind, :name, :uen, :contact_name, :phone, :email, :billing_address, :on_time_allowance

  # List: pass users_count: { client_id => n } (Users column).
  field(:users_count, if: ->(_name, _c, options) { options.key?(:users_count) }) { |c, options| options[:users_count][c.id].to_i }

  view :full do
    field(:school) { |c| c.school && { id: c.school.id, name: c.school.name } }
    field(:school_calendar) { |c| c.school&.calendar && { id: c.school.calendar.id, name: c.school.calendar.name } }
    # Bookable Vehicles: [] = All Vehicle Types.
    field(:bookable_vehicle_type_ids) { |c| c.bookable_vehicle_types.map(&:vehicle_type_id).sort }
    association :sites, blueprint: ClientSiteBlueprint
    association :end_customers, blueprint: ClientEndCustomerBlueprint
    association :pickup_points, blueprint: ClientPickupPointBlueprint
  end
end
