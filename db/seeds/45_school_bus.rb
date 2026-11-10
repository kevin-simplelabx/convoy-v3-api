# School Bus routes shown on the Scheduler: St. Stephen's School with an AM and a PM plan (3 routes each, stops with
# riders), regular buses over time, a replacement next week and a regular bus change next month.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  bus = ->(plate) { Vehicle.kept.find_by!(plate:) }
  school = School.find_or_create_by!(name: "St. Stephen's School") do |s|
    s.assign_attributes(short_name: "SSS", address: "20 Siglap View, Singapore 455789", lat: 1.3138, lng: 103.9283,
                        calendar: Calendar.kept.find_by!(name: "MOE School Calendar"))
  end
  # Routes seeded before they had a bus type: the size of the regular bus.
  size = ->(vehicle) { SchoolBus::BUS_TYPES.min_by { |_, t| (t[:seats] - vehicle.seats.to_i).abs }.first }
  SchoolRoute.joins(:plan).where(school_plans: { school_id: school.id }, bus_type: nil).find_each do |r|
    vehicle = Vehicle.find_by(id: r.regular_vehicle_id(Date.current)) or next
    r.update_columns(bus_type: size.(vehicle))
  end
  next if school.plans.exists?

  term = Date.current.beginning_of_month - 1.month
  attendants = Attendant.kept.order(:id).to_a
  plans = {
    "am" => [ [ "06:30", "07:20", "PD6604E", [ [ "Blk 101 Bedok North", "06:30", 9 ], [ "Blk 216 Bedok North", "06:42", 8 ], [ "Blk 32 Siglap", "07:02", 6 ] ] ],
              [ "06:35", "07:20", "PE1290S", [ [ "Kembangan MRT", "06:35", 11 ], [ "Opp Blk 7 Joo Chiat", "06:55", 10 ] ] ],
              [ "06:40", "07:15", "PD2030P", [ [ "Blk 640 Tampines", "06:40", 12 ], [ "Blk 860 Tampines", "06:52", 9 ] ] ] ],
    "pm" => [ [ "13:40", "14:30", "PD6604E", [ [ "Blk 32 Siglap", "13:58", 6 ], [ "Blk 216 Bedok North", "14:15", 8 ], [ "Blk 101 Bedok North", "14:30", 9 ] ] ],
              [ "13:40", "14:20", "PE1290S", [ [ "Opp Blk 7 Joo Chiat", "14:00", 10 ], [ "Kembangan MRT", "14:20", 11 ] ] ],
              [ "13:45", "14:25", "PD2030P", [ [ "Blk 860 Tampines", "14:10", 9 ], [ "Blk 640 Tampines", "14:25", 12 ] ] ] ]
  }
  plans.each do |session, routes|
    plan = school.plans.create!(name: "Term 4 #{session.upcase}", session:, effective_from: term, in_use: true)
    routes.each_with_index do |(start, finish, plate, stops), i|
      route = plan.routes.create!(bus_type: size.(bus.(plate)), number: i + 1, label: "#{session == 'am' ? 'AM' : 'PM'} #{i + 1}", start_time: start, end_time: finish,
                                  riders_count: stops.sum(&:last), attendant: attendants[i % attendants.size])
      stops.each_with_index { |(name, time, riders), k| route.stops.create!(position: k, name:, scheduled_time: time, riders_count: riders) }
      route.vehicle_changes.create!(vehicle: bus.(plate), effective_from: term, created_by: admin)
    end
  end

  am1 = school.plans.find_by!(session: "am").routes.find_by!(number: 1)
  monday = Date.current.next_occurring(:monday)
  am1.replacements.create!(vehicle: bus.("PD1125G"), starts_on: monday + 1, ends_on: monday + 2, arranged_by: "operator",
                           reason: "PD6604E in the workshop", created_by: admin)
  am1.vehicle_changes.create!(vehicle: bus.("PC8841T"), effective_from: Date.current.next_month.beginning_of_month, created_by: admin)
end
