class ClientSiteBlueprint < ApplicationBlueprint
  fields :client_id, :name, :address, :lat, :lng, :own_billing, :billing_name, :billing_uen, :billing_address, :created_at

  field(:school) { |s| s.school && { id: s.school.id, name: s.school.name } }
  field(:shuttle_trips_count) { |s| s.shuttle_trips_count }
  association :billing_contacts, blueprint: ClientBillingContactBlueprint
end
