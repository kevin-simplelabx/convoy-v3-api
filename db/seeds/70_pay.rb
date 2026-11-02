# HR (driver pay) for SimpleDrive. Rate plan "Standard" (as the prototype seeds it): Off Peak, Peak, Night and a
# Weekend and PH period that takes priority; rates by seats (≤6 S$12 / 8 an hour, ≤13 14 / 10, ≤23 16 / 12,
# ≤29 18 / 14, bigger 22 / 16) plus S$2 Peak, S$3 Night, S$4 Weekend and PH.
with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  types = VehicleType.enabled_for(Company.find_by!(code: "SD")).order(:seats).to_a
  base = ->(seats) { seats <= 6 ? [ 12, 8 ] : seats <= 13 ? [ 14, 10 ] : seats <= 23 ? [ 16, 12 ] : seats <= 29 ? [ 18, 14 ] : [ 22, 16 ] }
  weekdays = %w[mon tue wed thu fri]
  periods = [
    [ "Off Peak", weekdays, [ %w[07:00 19:00] ], false, 0 ],
    [ "Peak", weekdays, [ %w[05:00 07:00], %w[19:00 21:00] ], false, 2 ],
    [ "Night", weekdays, [ %w[21:00 05:00] ], false, 3 ],
    [ "Weekend and PH", %w[sat sun ph], [ %w[00:00 23:59] ], true, 4 ]
  ]

  plan = PayRatePlan.kept.find_or_create_by!(name: "Standard") { |p| p.description = "Weekday, peak, night and weekend rates" }
  if plan.periods.empty?
    types.each { |t| plan.plan_vehicle_types.find_or_create_by!(vehicle_type: t) }
    periods.each_with_index do |(name, days, ranges, priority, add), i|
      period = plan.periods.create!(name:, days:, takes_priority: priority, position: i)
      ranges.each { |from, to| period.ranges.create!(start_time: from, end_time: to) }
      types.each do |t|
        trip, hour = base.(t.seats)
        period.rates.create!(vehicle_type: t, per_trip: trip + add, per_hour: hour + add)
      end
    end
    plan.lock!(owner)
  end
end

# Pay schemes: "Basic + Trips" (default, as the prototype seeds it) and "Monthly 2,400" for a contrast.
with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  plan = PayRatePlan.kept.find_by!(name: "Standard")
  basic = PayScheme.kept.find_or_initialize_by(name: "Basic + Trips")
  if basic.new_record?
    basic.update!(description: "Basic pay with 1 trip a day included, topped up to S$2,200", is_default: true, scheme_type: "basic_plus_trips",
                  rate_plan: plan, basic_salary: 500, basic_covers_daily_trips: true, basic_covered_daily_trips: 1,
                  has_guarantee: true, guaranteed_amount: 2200, on_top_ph: true, has_post_guarantee_boost: true,
                  post_guarantee_boost_type: "percentage", post_guarantee_boost_value: 20, has_rejection_penalty: true,
                  rejection_allowed_jobs: 1, has_daily_volume_incentive: true, has_weekly_target_incentive: true,
                  has_monthly_target_incentive: true)
    [ [ 40, 200 ], [ 70, 300 ], [ nil, 350 ] ].each_with_index { |(to, amt), i| basic.route_bands.create!(up_to_minutes: to, monthly_amount: amt, position: i) }
    basic.volume_tiers.create!(from_trip: 7, to_trip: 10, boost_type: "flat", boost_value: 2, position: 0)
    basic.volume_tiers.create!(from_trip: 11, boost_type: "flat", boost_value: 3, position: 1)
    basic.target_tiers.create!(period: "weekly", target_trips: 20, pay_as: "lump_sum", amount: 50)
    basic.target_tiers.create!(period: "monthly", target_trips: 100, pay_as: "lump_sum", amount: 200)
    basic.lock!(owner)
  end
  PayScheme.kept.find_or_create_by!(name: "Monthly 2,400") do |s|
    s.assign_attributes(description: "Fixed pay for 6 trips a weekday, extra trips at plan rates", scheme_type: "monthly_with_minimum",
                        rate_plan: plan, monthly_pay_amount: 2400, monthly_minimum_type: "daily", monthly_daily_trips: 6)
  end
end

# Driver pay assignments: the second active driver moved to Monthly 2,400 on the 1st of this month (the others stay on
# the default scheme); one driver is paid at Coach rates whatever bus they drive.
with_company("SD") do
  drivers = Driver.kept.active.order(:id).to_a
  monthly = PayScheme.kept.find_by!(name: "Monthly 2,400")
  basic = PayScheme.kept.find_by!(name: "Basic + Trips")
  if (d = drivers[1]) && !d.pay_schemes.exists?
    d.pay_schemes.new(company_id: d.company_id, pay_scheme: basic, starts_on: Date.current.beginning_of_month - 1.month).save!(validate: false)
    d.pay_schemes.new(company_id: d.company_id, pay_scheme: monthly, starts_on: Date.current.beginning_of_month).save!(validate: false)
    DriverPayScheme.recut!(d.id)
  end
  coach = VehicleType.enabled_for(Company.find_by!(code: "SD")).where("seats >= 40").first
  if (d = drivers[2]) && coach && !d.pay_vehicle_types.exists?
    d.pay_vehicle_types.new(company_id: d.company_id, vehicle_type: coach, starts_on: Date.current.beginning_of_month - 1.month).save!(validate: false)
  end
end

# Salary Simulator: template 1 = the sample month of this month on Basic + Trips with one school route.
with_company("SD") do
  month = Date.current.beginning_of_month
  PaySimulatorTemplate.find_or_create_by!(slot: 1) do |t|
    t.assign_attributes(name: "Sample month", description: "Weekday trips, a few disposals and the PH week", month:,
                        pay_scheme: PayScheme.kept.find_by!(name: "Basic + Trips"), vehicle_type: VehicleType.find_by(seats: 13),
                        routes: [ { name: "AM1", minutes: 45, start: "06:30" } ], jobs: Pay::Simulation.sample(month),
                        saved_by: User.find_by!(email: "ops@simpledrive.sg"))
  end
end

# Earnings: last month confirmed for the first driver whose month can be confirmed (runs come from the Scheduler seeds).
with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  last = Date.current.prev_month.beginning_of_month
  unless DriverPayMonth.exists?(month: last)
    Driver.kept.active.order(:id).each do |d|
      out = Pay::DriverMonth.call(driver: d, month: last)
      next if Pay::ConfirmMonth.blocker(out) || out.runs.none? { |r| r.status == "completed" }

      Pay::ConfirmMonth.call(driver: d, month: last, user: owner)
      break
    end
  end
end

# Bonuses: a monthly Trip Target from this month to the end of the year (locked, announced), and a quarterly on-time
# bonus that needs sign-up (worked out in the simulator only).
with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  month = Date.current.beginning_of_month
  unless PayBonus.kept.exists?(name: "Year-End Trip Bonus")
    b = PayBonus.create!(name: "Year-End Trip Bonus", description: "More trips, more bonus until the year ends", plan_type: "trip_target",
                         frequency: "monthly", starts_on: month, last_period_on: Date.new(month.year, 12, 1), payout_type: "end_of_period")
    [ [ 80, 100, 50 ], [ 110, 200, 100 ] ].each_with_index { |(target, amount, points), i| b.tiers.create!(target_trips: target, amount:, points:, position: i) }
    b.lock!(owner)
  end
  unless PayBonus.kept.exists?(name: "On-Time Quarter")
    b = PayBonus.create!(name: "On-Time Quarter", plan_type: "reliability_otp", frequency: "quarterly", starts_on: Date.current.beginning_of_quarter,
                         payout_type: "split_trenches", requires_sign_up: true, sign_up_from: month, sign_up_to: month + 14,
                         terms: "Keep on-time at 95% or better for the whole quarter")
    b.tiers.create!(metric_min: 95, metric_max: 100, amount: 150, points: 80)
    b.payments.create!(percentage: 50, months_after: 1, position: 0)
    b.payments.create!(percentage: 50, months_after: 3, position: 1)
  end
end

# Points and rewards: the first two drivers have points (one partly used), three rewards (two active).
with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  drivers = Driver.kept.active.order(:id).first(2)
  drivers.each_with_index do |d, i|
    next if DriverPointLot.exists?(driver: d, source: "manual")

    ledger = Pay::Points.new(d)
    ledger.award!(points: 300 - (i * 100), reason: "Safe driving, Q3 2026", user: owner)
    ledger.award!(points: 50, reason: "Client compliment", user: owner)
    Pay::Points.new(d).deduct!(points: 120, reason: "S$10 Grab voucher", user: owner) if i.zero?
  end
  [ [ "S$10 Grab Voucher", 120, "active" ], [ "S$50 NTUC Voucher", 500, "active" ], [ "Extra Day Off", 800, "inactive" ] ].each do |title, pts, status|
    PayReward.kept.find_or_create_by!(title:) { |r| r.assign_attributes(points_required: pts, status:, description: "Redeem in the driver app") }
  end
end
