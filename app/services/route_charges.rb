# School Bus Route Charges: carried to a newly adopted plan, and each run's charge on a date.
module RouteCharges
  module_function

  # The charge in force on a route on a date (nil when none or ended by a 0).
  def on(route, date)
    c = route.charges.select { it.starts_on <= date }.max_by { [ it.starts_on, it.id ] }
    c&.value&.positive? ? c : nil
  end

  # When a plan replaces another from a date: each old route's charge in force then moves to the new route sharing the most
  # riders (then stops) with it — status "check" for an Admin — or stays with no route ("Charges With No Matching Run").
  def carry(old_plan, new_plan, from)
    new_routes = new_plan.routes.includes(:riders, :stops).to_a
    old_plan.routes.includes(:riders, :stops, :charges).find_each do |old|
      charge = on(old, from) or next
      riders = old.riders.map(&:rid).to_set
      points = old.stops.map(&:stop_point_id).compact.to_set
      score = ->(r) { [ r.riders.to_a.count { riders.include?(it.rid) }, r.stops.to_a.count { points.include?(it.stop_point_id) } ] }
      best = new_routes.max_by(&score)
      best = nil if best && score.(best) == [ 0, 0 ]
      RouteCharge.create!(school: new_plan.school, school_route: best, starts_on: from, kind: charge.kind, value: charge.value, reason: charge.reason,
                          note: charge.note, status: "check", carried_from: charge)
    end
  end
end
