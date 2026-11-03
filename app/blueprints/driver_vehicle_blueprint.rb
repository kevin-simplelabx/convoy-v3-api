# A bus in the Driver app (My Vehicle Today, Switch Vehicle). Render { vehicle: (decorated), since:, since_time: }.
class DriverVehicleBlueprint < Blueprinter::Base
  field(:id) { |r| r[:vehicle].id }
  field(:plate) { |r| r[:vehicle].plate }
  field(:name) { |r| [ r[:vehicle].object.make, r[:vehicle].object.model ].compact_blank.join(" ").presence }
  field(:seats) { |r| r[:vehicle].seats }
  field(:photo) { |r| r[:vehicle].photo_info }
  field(:since) { |r| r[:since] }
  field(:since_time) { |r| r[:since_time] }
end
