# School Live Ops sample for St. Stephen's School: Bus Not
# Required from the Convoy App — two children today (one only for the afternoon), one tomorrow. The children's attendance
# on today's runs comes with the live data (98_live_map, `bin/rails live_map:simulate`).
with_company("SD") do
  school = School.find_by!(name: "St. Stephen's School")
  rids = SchoolRouteRider.joins(school_route: :plan).where(school_plans: { school_id: school.id, session: "am" }).order(:rid).distinct.pluck(:rid)
  [ [ rids[1], 0, "both", "sick", "Fever" ], [ rids[4], 0, "pm", "parent", nil ], [ rids[2], 1, "both", "leave", "Family trip" ] ].each do |rid, d, trip, reason, note|
    next unless rid

    school.rider_absences.find_or_create_by!(rid:, date: Date.current + d) { it.assign_attributes(trip:, reason:, note:, reported_by: "Parent") }
  end
end
