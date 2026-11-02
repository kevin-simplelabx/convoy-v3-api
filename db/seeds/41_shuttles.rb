# Corporate Shuttles: Google's MBC campus shuttle (two directions, two buses, runs that move together, price per run
# and vehicle) and a cross-site shuttle with its own return stops.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  google = Client.kept.find_by!(name: "Google Asia Pacific")
  mbc = google.sites.find_by!(name: "Mapletree Business City")
  campus = google.sites.find_by!(name: "Google Asia Pacific (Pasir Panjang)")
  coaster = VehicleType.find_by!(key: "mb23")
  bus = ->(plate) { Vehicle.kept.find_by!(plate:).id }
  monday = Date.current.next_occurring(:monday)

  unless Trip.kept.exists?(label: "seed-mbc-shuttle")
    Trips::Save.call(trip: Trip.new(label: "seed-mbc-shuttle"), user: admin, attributes: {
      kind: "corporate_shuttle", client_id: google.id, title: "MBC Campus Shuttle", starts_on: monday - 56,
      days: [ 1, 2, 3, 4, 5 ], end_mode: "never", vehicles_count: 2, shuttle_return: true, price_by: "direction",
      price_per: "route", price_basis: "month", route_tags: "Campus, Staff", color: "#3267D6", head_count: true,
      trip_value: 1, trip_value_return: 1, calendar_id: Calendar.kept.find_by!(name: "Google Office Calendar").id,
      stops_attributes: [
        { position: 0, name: "Labrador Park MRT Exit A", use: "pu", lat: 1.2722, lng: 103.8026, driver_note: "Exit A, across the road from the bus stop" },
        { position: 1, name: "Alexandra Road (Opp Blk 1)", use: "both", lat: 1.2779, lng: 103.8009 },
        { position: 2, name: "Mapletree Business City", use: "do", lat: 1.2747, lng: 103.7993, client_site_id: mbc.id }
      ],
      vehicle_requirements_attributes: [ { vehicle_type_id: coaster.id, count: 2 } ],
      runs_attributes: [
        { direction: 1, position: 0, times: %w[07:45 07:52 08:00],
          slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PC8841T"), group_key: "am" }, { slot_no: 2, vehicle_id: bus.("PC7475L") } ] },
        { direction: 1, position: 1, times: %w[08:15 08:22 08:30],
          slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PC8841T"), group_key: "am" }, { slot_no: 2, vehicle_id: bus.("PC7475L") } ] },
        { direction: 1, position: 2, times: %w[08:45 08:52 09:00],
          slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PC8841T") }, { slot_no: 2, unassigned: true } ] },
        { direction: 2, position: 0, times: %w[17:30 17:38 17:45], standby_needed: false,
          slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PC8841T") }, { slot_no: 2, vehicle_id: bus.("PC7475L") } ] },
        { direction: 2, position: 1, times: %w[18:15 18:23 18:30], standby_needed: false,
          slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PC8841T") }, { slot_no: 2, vehicle_id: bus.("PC7475L") } ] }
      ],
      standby_attributes: { location: "Labrador Park bus bay", minutes: 10, lat: 1.2725, lng: 103.8021 },
      price_table: [ { row: "d1", col: "all", amount: 9600 }, { row: "d2", col: "all", amount: 6400 } ]
    })
  end

  unless Trip.kept.exists?(label: "seed-cross-site")
    Trips::Save.call(trip: Trip.new(label: "seed-cross-site"), user: admin, attributes: {
      kind: "corporate_shuttle", client_id: google.id, title: "Cross-site Shuttle", starts_on: monday - 56,
      days: [ 1, 2, 3, 4, 5 ], end_mode: "never", vehicles_count: 1, shuttle_return: true, shuttle_separate_return: true,
      price_by: "all", price_basis: "trip", route_tags: "Cross-site",
      stops_attributes: [
        { position: 0, name: "Mapletree Business City", use: "pu", lat: 1.2747, lng: 103.7993, client_site_id: mbc.id },
        { position: 1, name: "Google Asia Pacific (Pasir Panjang)", use: "do", lat: 1.2768, lng: 103.7952, client_site_id: campus.id },
        { direction: 2, position: 0, name: "Google Asia Pacific (Pasir Panjang)", use: "pu", lat: 1.2768, lng: 103.7952, client_site_id: campus.id },
        { direction: 2, position: 1, name: "Pasir Panjang MRT", use: "both", lat: 1.2762, lng: 103.7915 },
        { direction: 2, position: 2, name: "Mapletree Business City", use: "do", lat: 1.2747, lng: 103.7993, client_site_id: mbc.id }
      ],
      vehicle_requirements_attributes: [ { vehicle_type_id: VehicleType.find_by!(key: "van").id, count: 1 } ],
      runs_attributes: [
        { direction: 1, position: 0, times: %w[10:00 10:10], slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PD4472H") } ] },
        { direction: 1, position: 1, times: %w[14:00 14:10], slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PD4472H") } ] },
        { direction: 2, position: 0, times: %w[12:00 12:08 12:15], slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PD4472H") } ] }
      ],
      price_table: [ { row: "all", col: "all", amount: 45 } ]
    })
  end
end
