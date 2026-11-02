# Sample trips of every non-shuttle kind for the coming days (shuttles and School Runs come with their phases).
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  type = ->(key) { VehicleType.find_by!(key:) }
  bus = ->(plate) { Vehicle.kept.find_by!(plate:) }
  client = ->(name) { Client.kept.find_by!(name:) }
  monday = Date.current.next_occurring(:monday)

  places = {
    changi_t3: [ "Changi Airport T3", "65 Airport Boulevard, Singapore 819663", 1.3554, 103.9862 ],
    mbs: [ "Marina Bay Sands", "10 Bayfront Avenue, Singapore 018956", 1.2834, 103.8607 ],
    mbc: [ "Mapletree Business City", "70 Pasir Panjang Road, Singapore 117371", 1.2747, 103.7993 ],
    sentosa: [ "Resorts World Sentosa", "8 Sentosa Gateway, Singapore 098269", 1.2540, 103.8238 ],
    dbs: [ "DBS Asia Central", "12 Marina Boulevard, Singapore 018982", 1.2795, 103.8540 ],
    gardens: [ "Gardens by the Bay", "18 Marina Gardens Drive, Singapore 018953", 1.2816, 103.8636 ],
    bedok: [ "Bedok North Street 2", "Blk 123 Bedok North Street 2, Singapore 460123", 1.3311, 103.9366 ],
    nyp: [ "Nanyang Polytechnic", "180 Ang Mo Kio Avenue 8, Singapore 569830", 1.3801, 103.8490 ],
    jurong: [ "Jurong East MRT", "10 Jurong East Street 12, Singapore 609690", 1.3331, 103.7422 ]
  }.freeze

  stops = lambda do |*keys, notes: {}|
    keys.each_with_index.map do |k, i|
      name, address, lat, lng = places.fetch(k)
      use = i.zero? ? "pu" : (i == keys.size - 1 ? "do" : "both")
      { position: i, name:, address:, lat:, lng:, use:, driver_note: notes[k] }
    end
  end

  trip = lambda do |key, attrs, return_trip: nil|
    next if Trip.kept.exists?(label: key)

    t = Trip.new(label: key)
    Trips::Save.call(trip: t, attributes: attrs, return_attributes: return_trip, user: admin)
  end

  trip.("seed-airport-arrival", {
    kind: "airport_transfer", client_id: client.("Dr Rachel Lim").id, starts_on: monday, start_time: "07:40", end_time: "08:40",
    airport_direction: "arrival", flight_number: "SQ 321", flight_time: "07:10", terminal: "T3", wait_minutes: 30,
    meet_and_greet: true, signboard_name: "Dr Rachel Lim", meet_and_greet_fee: 25, pax: 1, luggage_on: true, luggage_large: 2,
    price: 85, stops_attributes: stops.(:changi_t3, :bedok, notes: { changi_t3: "Meet at Arrival Hall, Door 3" }),
    vehicle_requirements_attributes: [ { vehicle_type_id: type.("mpv").id, count: 1 } ]
  })

  trip.("seed-gala-two-way", {
    kind: "ad_hoc", client_id: client.("Marina Bay Sands").id, title: "MBS Gala Dinner Guests", starts_on: monday + 3,
    start_time: "17:30", end_time: "18:15", pax: 80, vehicles_count: 2, price: 1200, price_per: "route",
    stops_attributes: stops.(:mbc, :mbs),
    vehicle_requirements_attributes: [ { vehicle_type_id: type.("c45").id, count: 2 } ],
    vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PE1290S").id }, { slot_no: 2, vehicle_id: bus.("PD2030P").id } ],
    standby_attributes: { location: "MBC Tower 1 Bus Bay", minutes: 15, lat: 1.2752, lng: 103.7989, note: "Driver waits beside the taxi stand" },
    requestor_name: "Rebecca Chua", requestor_phone: "+65 6688 8888"
  }, return_trip: {
    start_time: "22:30", end_time: "23:15",
    stops_attributes: stops.(:mbs, :mbc)
  })

  trip.("seed-disposal", {
    kind: "disposal", client_id: client.("DBS Bank").id, title: "DBS Client Visit", starts_on: monday + 1, start_time: "09:00",
    hours: 6, end_time: nil, hourly_rate: true, price: 75, pax: 8,
    stops_attributes: stops.(:dbs), vehicle_requirements_attributes: [ { vehicle_type_id: type.("van").id, count: 1 } ],
    vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PD997M").id } ]
  })

  trip.("seed-charter-unassigned", {
    kind: "ad_hoc", client_id: client.("Google Asia Pacific").id, title: "Google Offsite: Sentosa", starts_on: monday + 2,
    start_time: "08:30", end_time: "09:10", pax: 40, price: 650,
    stops_attributes: stops.(:mbc, :sentosa, notes: { sentosa: "Coach drop-off at the B1 bus bay" }),
    vehicle_requirements_attributes: [ { vehicle_type_id: type.("c45").id, count: 1 } ]
  })

  trip.("seed-subcontract", {
    kind: "ad_hoc", client_id: client.("Eastern Coaches").id,
    client_end_customer_id: Client.kept.find_by!(name: "Eastern Coaches").end_customers.find_by!(name: "Nanyang Polytechnic").id,
    starts_on: monday + 4, start_time: "13:00", end_time: "14:00", pax: 38, operator_cost: nil, price: 320,
    contractor_contact_name: "Mr Goh", contractor_contact_phone: "+65 6345 6789", require_contractor_app: true,
    stops_attributes: stops.(:nyp, :gardens), vehicle_requirements_attributes: [ { vehicle_type_id: type.("c40").id, count: 1 } ],
    vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PD6604E").id } ]
  })

  trip.("seed-recurring-staff", {
    kind: "ad_hoc", client_id: client.("Google Asia Pacific").id, title: "Jurong East Staff Pick-up", starts_on: monday - 28,
    days: [ 1, 2, 3, 4, 5 ], end_mode: "never", calendar_id: Calendar.kept.find_by!(name: "Google Office Calendar").id,
    start_time: "07:45", end_time: "08:30", pax: 12, price: 2400, price_basis: "month", trip_value: 1,
    stops_attributes: stops.(:jurong, :mbc), vehicle_requirements_attributes: [ { vehicle_type_id: type.("van").id, count: 1 } ],
    vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: bus.("PD3318K").id } ]
  })
end
