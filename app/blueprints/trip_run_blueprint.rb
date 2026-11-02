# A shuttle run: key d1r0, times in travel order of its direction (as the form sends them), its vehicle per slot.
class TripRunBlueprint < ApplicationBlueprint
  fields :key, :direction, :position, :trip_value, :standby_needed
  field(:start_time) { |r| r.start_time_hm }
  field(:end_time) { |r| r.end_time_hm }
  field(:times) { |r| r.stop_minutes.map { |m| Clock.hm(m) } }
  field(:slots) do |r|
    r.slots.map do |s|
      { id: s.id, key: s.key, slot_no: s.slot_no, vehicle_id: s.vehicle_id, plate: s.vehicle&.plate, unassigned: s.unassigned,
        group_key: s.trip_run_group_id && "g#{s.trip_run_group_id}" }
    end
  end
end
