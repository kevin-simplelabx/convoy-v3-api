# St. Stephen's seeded plans (hand-made, no engine run): the figures a plan shows — route seats / fill / journey from the
# bus type and the stop times, the company's routing parameters and the summary computed from the routes.
with_company("SD") do
  school = School.find_by(name: "St. Stephen's School") or next
  attendant = school.attendant_policy&.needs == "all" ? "ALL_BUSES" : "STATUTORY"
  school.plans.includes(routes: :stops).where(summary: nil).find_each do |plan|
    plan.routes.each do |route|
      seats = SchoolBus::BUS_TYPES.dig(route.bus_type, :seats) or next
      student = seats - (SchoolBus.statutory_sizes.include?(route.bus_type) && attendant == "STATUTORY" ? 1 : 0)
      span = (route.end_time - route.start_time) * 60
      route.update_columns(seats:, student_seats: student, capacity: student, fill: (route.riders_count.to_f / student).round(4), span_seconds: span, ride_minutes: span / 60)
    end
    params = (RoutingSetting.first&.params || {}).merge("session" => Routing::SESSION_KEYS[plan.session], "attendant" => attendant)
    plan.update!(params:, summary: Plans.summary(plan.reload, []))
  end
end
