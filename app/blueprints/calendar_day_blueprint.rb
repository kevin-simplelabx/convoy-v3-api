class CalendarDayBlueprint < ApplicationBlueprint
  fields :calendar_id, :kind, :kind_name, :starts_on, :ends_on, :label, :shift_minutes, :in_place_of, :notify_drivers
  field(:usual_time) { |d| d.usual_time_hm }
  field(:new_time) { |d| d.new_time_hm }
  field(:time_change) { |d| d.time_change }
end
