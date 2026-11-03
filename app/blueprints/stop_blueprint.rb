# A Stop Library stop: list row, and (view :detail) the schools that use it with their riders and the coverage table.
class StopBlueprint < ApplicationBlueprint
  fields :code, :name, :subzone_code, :library_status, :former_codes, :requested_at
  field(:subzone) { |s, o| o[:subzones]&.dig(s.subzone_code) }
  field(:owner_school) { |s| s.owner_school&.slice(:id, :name) }
  field(:requested_by) { |s| s.requested_by&.name }
  field(:points) { |s| StopPointBlueprint.render_as_hash(s.points) }
  field(:used_by) { |s| s.school_stops.size }
  field(:linked) { |s, o| o[:school_id] ? s.school_stops.any? { it.school_id == o[:school_id] } : nil }
  field(:needs_attention) { |s| s.needs_attention? }
  field(:coverage_warnings) { |s| s.coverage[:warnings] }
  field(:archived) { |s| s.discarded? }

  view :detail do
    field(:coverage) { |s| s.coverage[:rows] }
    field(:schools) do |s|
      s.school_stops.map { |ss| { id: ss.school_id, name: ss.school.name, riders: SchoolStops.riders_covered(ss).size } }
    end
  end
end
