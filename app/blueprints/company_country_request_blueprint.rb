class CompanyCountryRequestBlueprint < ApplicationBlueprint
  fields :company_id, :from_country, :to_country, :reason, :status, :created_at, :decided_at

  field(:company_name) { |r| r.company.name }
  field(:to_country_name) { |r| Country.find(r.to_country)&.name }
  field(:requested_by) { |r| r.requested_by && { id: r.requested_by.id, name: r.requested_by.shown_name } }
  field(:decided_by) { |r| r.decided_by && { id: r.decided_by.id, name: r.decided_by.shown_name } }
end
