# School Bus Route Charges (school billed per bus): how the school is billed, adding a change on a run, confirming or
# moving a carried charge, carrying charges to a newly adopted plan, and each run's charge on a date.
module RouteCharges
  module_function

  NOT_PER_BUS = "The school is not billed per bus".freeze

  # How the school is billed on a date (Convoy OS rchVals: F.locked && payer === 'bus'): per_bus when the academic year
  # covering it has its Bus Fares locked and the school pays per bus (even with no rates yet); rates = { bus_type => rate }.
  def billing(school, date)
    table = school.academic_years.covering(date).includes(fare_table: :bus_rates).first&.fare_table
    per_bus = table.present? && table.per_bus? && table.locked?
    { per_bus:, rates: per_bus ? table.bus_rates.to_h { [ it.bus_type, it.rate ] } : {} }
  end

  # A change on a run's charge from a date (value 0 ends it): runs of an AM / PM plan in use, school billed per bus.
  def add(route, attrs, user:)
    from = attrs[:starts_on] or raise ApplicationService::Error, "Pick the start date"
    raise ApplicationService::Error, "Pick a date from the 1st of this month" if from < Date.current.beginning_of_month
    raise ApplicationService::Error, "Route Charges are for runs of an AM or PM plan in use" unless chargeable?(route)
    raise ApplicationService::Error, NOT_PER_BUS unless billing(route.school, from)[:per_bus]

    RouteCharge.create!(school: route.school, school_route: route, starts_on: from, kind: attrs[:kind].presence || "amt", value: attrs[:value],
                        reason: attrs[:reason], note: attrs[:note], created_by: user)
  end

  # Confirm a carried charge (status ok) and / or move it to another run (route id) of the same session in a plan in use.
  def update(charge, route_id:, status:)
    raise ApplicationService::Error, NOT_PER_BUS unless billing(charge.school, charge.starts_on)[:per_bus]

    route = route_id.presence && SchoolRoute.joins(:plan).merge(SchoolPlan.where(school: charge.school)).find_by(id: route_id)
    if route_id.present?
      raise ApplicationService::Error, "Pick a run of an AM or PM plan in use" unless route && chargeable?(route)

      session = (charge.school_route || charge.carried_from&.school_route)&.plan&.session
      raise ApplicationService::Error, "Pick a run of the #{SchoolPlan::SESSIONS[session]} plan" if session && route.plan.session != session
    end
    charge.update!(school_route: route || charge.school_route, status: status == "ok" ? "ok" : charge.status)
    charge
  end

  def chargeable?(route) = route.plan.in_use && %w[am pm].include?(route.plan.session)

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
