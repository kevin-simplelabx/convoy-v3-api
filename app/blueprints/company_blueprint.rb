class CompanyBlueprint < ApplicationBlueprint
  fields :name, :short_name, :display_name, :code, :country, :timezone, :theme_color,
         :date_format, :time_format, :observed_holidays, :business_units_enabled, :status

  field(:logo) { |company| company.logo_info }

  view :platform do
    fields :school_run_enabled, :route_list_import_enabled, :external_vehicle_cap, :created_at
  end
end
