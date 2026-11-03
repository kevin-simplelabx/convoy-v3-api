# School Live Ops sample for St. Stephen's School: map points for the Term 4 route stops (made without them), and Bus Not
# Required from the Convoy App — two children today (one only for the afternoon), one tomorrow. The children's attendance
# on today's runs comes with the live data (98_live_map, `bin/rails live_map:simulate`).
with_company("SD") do
  school = School.find_by!(name: "St. Stephen's School")
  points = { "Blk 101 Bedok North" => [ 1.3305, 103.9373 ], "Blk 216 Bedok North" => [ 1.3267, 103.9498 ], "Blk 32 Siglap" => [ 1.3136, 103.9247 ],
             "Kembangan MRT" => [ 1.3210, 103.9129 ], "Opp Blk 7 Joo Chiat" => [ 1.3126, 103.9011 ], "Blk 640 Tampines" => [ 1.3541, 103.9456 ],
             "Blk 860 Tampines" => [ 1.3551, 103.9369 ] }
  SchoolRouteStop.joins(route: :plan).where(school_plans: { school_id: school.id }, lat: nil, name: points.keys).find_each do |s|
    s.update!(lat: points[s.name][0], lng: points[s.name][1])
  end

  rids = SchoolRouteRider.joins(school_route: :plan).where(school_plans: { school_id: school.id, session: "am" }).order(:rid).distinct.pluck(:rid)
  [ [ rids[1], 0, "both", "sick", "Fever" ], [ rids[4], 0, "pm", "parent", nil ], [ rids[2], 1, "both", "leave", "Family trip" ] ].each do |rid, d, trip, reason, note|
    next unless rid

    school.rider_absences.find_or_create_by!(rid:, date: Date.current + d) { it.assign_attributes(trip:, reason:, note:, reported_by: "Parent") }
  end
end
