# School Bus › Dashboard of a school (port of dashVals): Operations (today, its sessions and routes, what needs attention,
# what is coming up, the students) and, for finance users, Finance (a month's revenue, operator cost and profit, bills
# and collections, the year by month, money changes ahead).
module SchoolDashboard
  module_function

  # The academic year a day falls in.
  def year_on(school, day) = school.academic_years.includes(:terms, :holidays, :special_days, bus_sessions: :variants).covering(day).first

  # Route plans running on a day (every session).
  def plans_on(school, day)
    school.plans.where(in_use: true).where(effective_from: ..day).where("school_plans.effective_to IS NULL OR school_plans.effective_to >= ?", day)
  end

  # rids of the riders on the route plans running on a day (and on the rider list then).
  def riders_on(school, day)
    on_list = SchoolRider.of_school_on(school, day).pluck(:rid).to_set
    SchoolRouteRider.joins(school_route: :plan).merge(plans_on(school, day)).distinct.pluck(:rid).select { on_list.include?(it) }.to_set
  end

  # Straight-line km from the school, plus a 0.05 km buffer, rounded up to 0.1 km (as on bills).
  def km(school, rider)
    return nil unless school.lat && rider.lat

    ((Geo.metres([ school.lat, school.lng ], [ rider.lat, rider.lng ]) / 1000.0) + 0.05).ceil(1)
  end

  def plural(n, word) = "#{n} #{word}#{'s' unless n == 1}"
end
