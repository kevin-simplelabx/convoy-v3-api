# Convoy Admin (super)
unless User.exists?(email: ENV.fetch("SUPER_EMAIL", "admin@convoy.sg"))
  User.create!(
    name: "Convoy Admin",
    email: ENV.fetch("SUPER_EMAIL", "admin@convoy.sg"),
    password: ENV.fetch("SUPER_PASSWORD", "Convoy123!"),
    role: "super",
    permissions: User::ALL_PERMISSIONS
  )
  puts "Created Convoy Admin: admin@convoy.sg / Convoy123!"
end

# SimpleDrive company + admin
company = Company.find_or_create_by!(name: "SimpleDrive")
unless User.exists?(email: "ops@simpledrive.sg")
  User.create!(
    name: "SimpleDrive Ops",
    email: "ops@simpledrive.sg",
    password: "Simple123!",
    role: "admin",
    permissions: User::ALL_PERMISSIONS,
    company: company
  )
  puts "Created SimpleDrive: ops@simpledrive.sg / Simple123!"
end

# SSS sample school + riders + stops
sss = JSON.parse(File.read(File.join(__dir__, "sss_seed.json")))

school = School.find_or_create_by!(name: sss["school"]["name"], company: company) do |s|
  s.short    = sss["school"]["short"]
  s.address  = sss["school"]["address"]
  s.lat      = sss["school"]["lat"]
  s.lng      = sss["school"]["lng"]
end

unless Dataset.exists?(school: school)
  rows = sss["riders"].map do |r|
    {
      "rid"     => r["rid"],
      "name"    => r["name"],
      "postal"  => r["postal"],
      "address" => r["address"],
      "lat"     => r["lat"],
      "lng"     => r["lng"],
      "level"   => r["level"],
      "am"      => true,
      "pm"      => true,
      "cca_days" => ""
    }
  end
  Dataset.create!(
    school:         school,
    effective_from: Date.today.iso8601,
    file_name:      "sss_sample.csv",
    uploaded_by:    "Seed",
    rows:           rows
  )
  puts "Seeded #{rows.length} riders for #{school.name}"
end

unless StopLibrary.exists?(company: company)
  lib = sss["stops"].map do |stop|
    stop.merge("libStatus" => "approved", "ownerSchool" => school.id)
  end
  StopLibrary.create!(
    company:  company,
    lib:      lib,
    counters: sss["counters"] || {}
  )
  puts "Seeded #{lib.length} stops for #{company.name}"
end

# Sample vehicles for Scheduler
unless company.vehicles.exists?
  vehicles_data = [
    { plate: "PD997M",  vehicle_type: "13-seater", seats: 13, driver_name: "Eric Pang",  driver_contact: "+65 9210 0000", tags: "VIP" },
    { plate: "PC7939R", vehicle_type: "13-seater", seats: 13, driver_name: "Frankie Lim", driver_contact: "+65 9210 1377", tags: "Wheelchair" },
    { plate: "PD1125G", vehicle_type: "13-seater", seats: 13, driver_name: "Ah Beng",     driver_contact: "+65 9210 2755", tags: "" },
    { plate: "PD2185B", vehicle_type: "40-seater", seats: 40, driver_name: "Shao Dong",   driver_contact: "+65 9210 4132", tags: "Coach" },
    { plate: "PC7475L", vehicle_type: "23-seater", seats: 23, driver_name: "Tony Tan",    driver_contact: "+65 9210 5510", tags: "" },
    { plate: "PD2030P", vehicle_type: "40-seater", seats: 40, driver_name: "Ramlee",      driver_contact: "+65 9210 6887", tags: "Coach" },
    { plate: "PA1234X", vehicle_type: "45-seater", seats: 45, driver_name: "Muthu",       driver_contact: "+65 9210 8265", tags: "Coach" },
  ]
  vehicles_data.each { |v| company.vehicles.create!(v.merge(sample: true)) }
  puts "Seeded #{vehicles_data.length} vehicles for #{company.name}"
end

# Sample trips in scheduler (stored in trips table, not settings)
unless company.trips.exists?
  vehicles = company.vehicles.index_by(&:plate)
  t0  = Date.today
  t1  = t0 + 1
  t3  = t0 + 3
  t60 = t0 + 60

  trips_data = [
    { kind: "Corporate Shuttle",  title: "Google Asia Pacific AM",
      customer: "Google Asia Pacific",  trip_date: t0, start_time: "07:30", end_time: "08:15",
      pickup: "Paya Lebar Square",      dropoff: "Mapletree Business City",
      pax: 12, vehicle_id: vehicles["PC7939R"]&.id, price: 120,
      days: [1,2,3,4,5], until_date: t60, end_mode: "date" },
    { kind: "Corporate Shuttle",  title: "Google Asia Pacific PM",
      customer: "Google Asia Pacific",  trip_date: t0, start_time: "17:30", end_time: "18:15",
      pickup: "Mapletree Business City", dropoff: "Paya Lebar Square",
      pax: 12, vehicle_id: vehicles["PC7939R"]&.id, price: 120,
      days: [1,2,3,4,5], until_date: t60, end_mode: "date" },
    { kind: "Corporate Shuttle",  title: "DBS Changi Shuttle",
      customer: "DBS Bank",             trip_date: t0, start_time: "08:00", end_time: "09:00",
      pickup: "Tampines MRT",           dropoff: "Changi Business Park",
      pax: 20, vehicle_id: vehicles["PC7475L"]&.id, price: 85,
      days: [1,2,3,4,5], until_date: t60, end_mode: "date" },
    { kind: "Airport Transfer",   title: "Changi T3 Arrival",
      customer: "Marina Bay Sands",     trip_date: t0, start_time: "10:00", end_time: "11:15",
      pickup: "Changi Airport T3",      dropoff: "Marina Bay Sands",
      pax: 9,  vehicle_id: vehicles["PD997M"]&.id, price: 95,
      extra: { "flight" => "SQ 321" } },
    { kind: "Disposal",           title: "Wedding Disposal",
      customer: "Tan Family",           trip_date: t0, start_time: "13:00", end_time: "17:00",
      pickup: "Shangri-La Hotel",       dropoff: "",
      pax: 35, vehicle_id: vehicles["PD2030P"]&.id, price: 80,
      rate_hr: true, notes: "Billed by the hour" },
    { kind: "Ad Hoc / Charter",   title: "Science Centre Field Trip",
      customer: "Bedok Green Primary",  trip_date: t0, start_time: "09:30", end_time: "12:30",
      pickup: "Bedok Green Primary",    dropoff: "Science Centre",
      pax: 70, buses: 2, vehicle_id: vehicles["PD2185B"]&.id, price: 200 },
    { kind: "Airport Transfer",   title: "Changi T1 Departure",
      customer: "Pan Pacific Hotel",    trip_date: t0, start_time: "20:30", end_time: "21:30",
      pickup: "Pan Pacific Hotel",      dropoff: "Changi Airport T1",
      pax: 6,  price: 80 },
    { kind: "Ad Hoc / Charter",   title: "Company Retreat",
      customer: "Grab",                 trip_date: t1, start_time: "08:00", end_time: "17:30",
      pickup: "One-North",              dropoff: "Sentosa",
      pax: 44, vehicle_id: vehicles["PA1234X"]&.id, price: 450 },
    { kind: "Ad Hoc / Charter",   title: "Night Shift Staff Run",
      customer: "Changi Airport Group", trip_date: t0, start_time: "23:30", end_time: "01:00",
      pickup: "Changi Airport T2",      dropoff: "Jurong West Depot",
      pax: 18, vehicle_id: vehicles["PC7475L"]&.id, price: 140,
      notes: "Ends after midnight" },
    { kind: "Airport Transfer",   title: "Changi T4 Arrival",
      customer: "Raffles Hotel",        trip_date: t3, start_time: "06:45", end_time: "07:45",
      pickup: "Changi Airport T4",      dropoff: "Raffles Hotel",
      pax: 10, price: 90, extra: { "flight" => "TR 101" } },
  ]

  trips_data.each_with_index do |t, i|
    company.trips.create!({
      id:         "t#{SecureRandom.hex(4)}",
      school_id:  school.id,
      sample:     true,
      by_user:    "Seed",
      no:         100001 + i,
      no_from:    t[:trip_date],
      n_n:        1,
      n_r:        true,
      days:       [],
      extra:      {},
    }.merge(t))
  end
  puts "Seeded #{trips_data.length} trips for #{company.name}"
end
