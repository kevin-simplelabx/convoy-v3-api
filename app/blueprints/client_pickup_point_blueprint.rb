class ClientPickupPointBlueprint < ApplicationBlueprint
  fields :client_id, :name, :address, :postal_code, :lat, :lng, :note, :created_at

  field(:created_by) { |p| p.created_by && { id: p.created_by.id, name: p.created_by.shown_name } }
end
