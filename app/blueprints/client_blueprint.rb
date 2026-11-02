class ClientBlueprint < ApplicationBlueprint
  fields :code, :kind, :name, :uen, :contact_name, :phone, :email, :billing_address, :on_time_allowance

  view :full do
    association :sites, blueprint: ClientSiteBlueprint
    association :end_customers, blueprint: ClientEndCustomerBlueprint
    association :pickup_points, blueprint: ClientPickupPointBlueprint
  end
end
