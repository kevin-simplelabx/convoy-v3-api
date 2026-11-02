class FuelCompanyBlueprint < ApplicationBlueprint
  fields :name, :kind, :position
  field(:entries_count) { |c, options| options[:usage]&.dig(c.id).to_i }
end
