class CompanyBlueprint < ApplicationBlueprint
  fields :name, :short_name, :display_name, :code, :country, :timezone, :theme_color,
         :date_format, :time_format, :observed_holidays, :business_units_enabled, :status

  field(:logo) { |company| company.logo_info }

  # Company Settings page. Pass actor: (the signed-in user) for can_edit.
  view :settings do
    fields :country_set_at

    field(:country_locked) { |company| company.country_locked? }
    field(:country_set_by) { |company| company.country_set_by && { id: company.country_set_by.id, name: company.country_set_by.shown_name } }
    field(:country_request) do |company|
      r = company.pending_country_request
      r && CompanyCountryRequestBlueprint.render_as_hash(r)
    end
    field(:can_edit) { |company, options| options[:actor] ? Pundit.policy!(options[:actor], company).update? : false }
  end

  view :platform do
    include_view :settings
    fields :school_run_enabled, :route_list_import_enabled, :external_vehicle_cap, :created_at
  end
end
