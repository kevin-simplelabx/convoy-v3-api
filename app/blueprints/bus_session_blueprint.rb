# A bus session of an academic year with its day variants (times "HH:MM").
class BusSessionBlueprint < ApplicationBlueprint
  fields :position, :name, :direction, :cca, :service, :max_journey_minutes, :days, :notes
  field(:arrive_from) { |s| s.arrive_from_hm }
  field(:arrive_to) { |s| s.arrive_to_hm }
  field(:dismissal) { |s| s.dismissal_hm }
  field(:depart) { |s| s.depart_hm }
  field(:variants) do |s|
    s.variants.map do |v|
      { days: v.days, arrive_from: v.arrive_from_hm, arrive_to: v.arrive_to_hm, dismissal: v.dismissal_hm, depart: v.depart_hm }
    end
  end
end
