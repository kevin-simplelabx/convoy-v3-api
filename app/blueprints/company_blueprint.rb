class CompanyBlueprint < ApplicationBlueprint
  fields :name, :short_name, :display_name, :code, :country, :timezone, :theme_color,
         :date_format, :time_format, :observed_holidays, :business_units_enabled, :status

  field(:logo) { |company| company.logo_info }

  # Company Settings page. Pass actor: (the signed-in user) for can_edit.
  view :settings do
    fields :country_set_at
    # Operations contacts drivers see in the Convoy Driver app (Contact Operations).
    fields :ops_phone, :ops_hours, :ops_whatsapp, :ops_email, :depot_address

    field(:country_locked) { |company| company.country_locked? }
    field(:country_set_by) { |company| company.country_set_by && { id: company.country_set_by.id, name: company.country_set_by.shown_name } }
    field(:country_request) do |company|
      r = company.pending_country_request
      r && CompanyCountryRequestBlueprint.render_as_hash(r)
    end
    field(:can_edit) { |company, options| options[:actor] ? Pundit.policy!(options[:actor], company).update? : false }
  end

  # Convoy Admin > Transport Companies. Pass stats: { company_id => { admin:, schools:, users: } } and current_id (the
  # company opened for this sign-in).
  view :platform do
    include_view :settings
    fields :school_run_enabled, :route_list_import_enabled, :external_vehicle_cap, :created_at

    field(:admin) { |c, o| o.dig(:stats, c.id, :admin) }
    field(:schools_count) { |c, o| o.dig(:stats, c.id, :schools).to_i }
    field(:users_count) { |c, o| o.dig(:stats, c.id, :users).to_i }
    field(:is_current) { |c, o| c.id == o[:current_id] }
  end
end
