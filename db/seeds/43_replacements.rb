# Replacement samples for next week: Driver Away on PD3318K (a spare driver covers), Vehicle Down on PC8841T for a day
# (its runs go to PD5126A with their own driver), and a Crew Swap on the airport arrival.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  monday = Date.current.next_occurring(:monday)
  next if Replacement.exists?(reason: "Seed sample")

  bus = ->(plate) { Vehicle.kept.find_by!(plate:) }
  save = ->(attrs, occ = nil) { Replacements::Save.call(replacement: Replacement.new, attributes: attrs.merge(reason: "Seed sample"), user: admin, occurrence: occ) }

  save.({ kind: "drv", scope: "range", original_vehicle_id: bus.("PD3318K").id, starts_on: monday + 1, ends_on: monday + 2,
          driver_id: Driver.find_by!(name: "Daniel Wong").id })
  save.({ kind: "veh", scope: "range", original_vehicle_id: bus.("PC8841T").id, starts_on: monday + 3, ends_on: monday + 3,
          vehicle_id: bus.("PD5126A").id, eta: "5 min late" })
  arrival = TripOccurrence.joins(:trip).find_by(trips: { label: "seed-airport-arrival" })
  if arrival&.vehicle_id
    save.({ kind: "crew", vehicle_id: bus.("PD997M").id }, arrival)
  end
end
