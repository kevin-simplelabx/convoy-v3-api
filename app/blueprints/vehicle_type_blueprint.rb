class VehicleTypeBlueprint < ApplicationBlueprint
  fields :key, :name, :seats, :label, :tyre_layout, :tyre_text, :position, :custom
  field(:enabled) { |t, options| options[:disabled_ids] ? options[:disabled_ids].exclude?(t.id) : true }
  # Vehicle Types page: own buses and operator buses with this type's seats.
  field(:own_count) { |t, options| options[:fleet]&.dig([ t.seats, true ]).to_i }
  field(:operator_count) { |t, options| options[:fleet]&.dig([ t.seats, false ]).to_i }
end
