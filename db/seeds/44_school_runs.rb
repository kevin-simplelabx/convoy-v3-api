# A School Run we run for Eastern Coaches (main contractor): AM to Red Swastika School, 3 stops with students, paid
# 10 months with June and December at half, a Saved Pick-up Point, and last week's Passenger List marked.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  next if Trip.kept.exists?(label: "seed-school-run")

  moe = Calendar.kept.find_by!(name: "MOE School Calendar")
  PickupPoint.find_or_create_by!(name: "Bedok Court Main Gate") do |p|
    p.assign_attributes(postal_codes: %w[469592 469593], lat: 1.3266, lng: 103.9370, note: "Wait at the guardhouse, not on the road")
  end
  students = lambda do |*rows|
    rows.each_with_index.map { |(name, cls, parent, phone), i| { position: i, name:, class_name: cls, parent_name: parent, phone: } }
  end

  result = Trips::Save.call(trip: Trip.new(label: "seed-school-run"), user: admin, attributes: {
    kind: "school_run", session: "am", client_id: Client.kept.find_by!(name: "Eastern Coaches").id, title: "Red Swastika AM 13",
    starts_on: Date.current - 28, days: [ 1, 2, 3, 4, 5 ], end_mode: "never", calendar_id: moe.id, skip_public_holidays: true,
    price: 2400, price_basis: "month", paid_months_mode: "part", unpaid_months: [ 6, 12 ], unpaid_month_share: 50,
    charge_no_school_days: false, contractor_contact_name: "Mr Goh", contractor_contact_phone: "+65 6345 6789",
    route_list_name: "AM13 route list Nov.pdf", route_list_imported_at: Time.current - 28.days,
    vehicle_requirements_attributes: [ { vehicle_type_id: VehicleType.find_by!(key: "van").id, count: 1 } ],
    vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: Vehicle.kept.find_by!(plate: "PD4472H").id } ],
    stops_attributes: [
      { position: 0, name: "Bedok Court Main Gate", use: "pu", scheduled_time: "06:35", lat: 1.3266, lng: 103.9370,
        driver_note: "Wait at the guardhouse, not on the road",
        students_attributes: students.([ "Lim Jia Hui", "P3", "Mdm Lim", "91234567" ], [ "Goh Mei Ling", "P2", "Mr Goh", "92345678" ]) },
      { position: 1, name: "Blk 120 Bedok North St 2", use: "pu", scheduled_time: "06:48", lat: 1.3311, lng: 103.9366,
        students_attributes: students.([ "Ali Hassan", "P5", "Pn Hassan", "93456789" ], [ "Chen Yu Xuan", "P1", "Ms Chen", "94567890" ]) },
      { position: 2, name: "Blk 538 Bedok North St 3", use: "pu", scheduled_time: "06:58", lat: 1.3334, lng: 103.9272,
        students_attributes: students.([ "Nur Aisyah", "P4", "Mdm Rahmah", "95678901" ]) },
      { position: 3, name: "Red Swastika School", use: "do", scheduled_time: "07:15", lat: 1.3305, lng: 103.9418,
        address: "350 Bedok North Avenue 3, Singapore 469719" }
    ]
  })

  # Last school day's Passenger List: everyone boarded and alighted, one absent.
  trip = result.trip
  occ = TripOccurrence.where(trip:).where(date: ...Date.current).order(date: :desc).first
  if occ
    SchoolRuns::Passengers.call(occ)[:stops].flat_map { |s| s[:students] }.each do |s|
      mark = s[:name] == "Chen Yu Xuan" ? "absent" : "alighted"
      SchoolRuns::MarkAttendance.call(occurrence: occ, student_key: s[:key], mark:, user: admin)
    end
  end
end
