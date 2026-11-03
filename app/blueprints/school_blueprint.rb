# A school of the School Bus service (list and record).
class SchoolBlueprint < ApplicationBlueprint
  fields :name, :short_name, :address, :postal
  field(:lat) { |s| s.lat&.to_f }
  field(:lng) { |s| s.lng&.to_f }
  field(:client) { |s| s.client&.slice(:id, :name) }
  # Rider Data: how many lists, and the Effective From of the one in use on the date (today unless given).
  field(:datasets_count) { |s| s.rider_datasets.size }
  field(:rider_data_from) do |s, o|
    date = o[:date] || Date.current
    s.rider_datasets.select { it.effective_from <= date }.max_by { [ it.effective_from, it.id ] }&.effective_from
  end

  view :record do
    field(:route_labels) { |s| s.labels.map { |l| SchoolRouteLabelBlueprint.render_as_hash(l) } }
  end
end
