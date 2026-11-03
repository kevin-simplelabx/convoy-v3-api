require "rails_helper"

# School Bus › Dashboard: Operations (today's sessions and routes, a trip without a bus, the calendar ahead, riders
# starting, the students) for everyone; Finance (operator cost, riders, seats, collections, the year by month, money
# setup) only with finance permission.
RSpec.describe "School Bus Dashboard" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      create(:public_holiday, date: "2026-11-09", name: "Deepavali Holiday")
      bus = create(:vehicle, plate: "PD6604E", seats: 40)
      school = School.create!(name: "St. Stephen's School", short_name: "SSS", lat: 1.3138, lng: 103.9283)
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      year.terms.second.update!(starts_on: "2026-06-29", ends_on: "2026-11-19")
      year.special_days.create!(date: "2026-11-13", kind: "early_dismissal", time: "11:30", description: "Prize Giving Day")
      am = year.bus_sessions.create!(name: "AM Arrival", direction: "to_school", days: [ 1, 2, 3, 4, 5 ], arrive_from: "07:00", arrive_to: "07:20", position: 0)
      am.variants.create!(days: [ 3 ], arrive_from: "08:30", arrive_to: "08:50", position: 0)
      year.bus_sessions.create!(name: "PM Departure", direction: "to_home", days: [ 1, 2, 3, 4, 5 ], depart: "13:40", position: 1)
      [ [ "S-1", 1.3305, 103.9373, "P1", nil ], [ "S-2", 1.3136, 103.9247, "P1", nil ], [ "S-3", 1.3541, 103.9456, "P2", nil ],
        [ "S-4", nil, nil, nil, "2026-11-20" ] ].each_with_index do |(rid, lat, lng, grade, start), i|
        school.riders.create!(rid:, name: "Child #{i + 1}", grade:, postal: "46012#{i}", lat:, lng:, am: true, pm: i != 2, starts_on: start, source: "manual")
      end
      school.bus_size_rates.create!(bus_type: "LARGE_40", monthly: 4200)
      plan = school.plans.create!(name: "Term 4 AM", session: "am", effective_from: Date.new(2026, 10, 1), in_use: true)
      r1 = plan.routes.create!(number: 1, label: "AM 1", start_time: "06:30", end_time: "07:20", bus_type: "LARGE_40", riders_count: 2, student_seats: 38)
      s = r1.stops.create!(position: 0, name: "Blk 101 Bedok North", scheduled_time: "06:30")
      %w[S-1 S-2].each { SchoolRouteRider.create!(school_route: r1, stop: s, rid: it) }
      r1.vehicle_changes.create!(vehicle: bus, effective_from: Date.new(2026, 10, 1))
      plan.routes.create!(number: 2, label: "AM 2", start_time: "06:40", end_time: "07:15", bus_type: "SMALL_13", riders_count: 1, student_seats: 12)
      nxt = school.plans.create!(name: "Term 1 AM", session: "am", effective_from: Date.new(2027, 1, 4), in_use: true)
      nxt.routes.create!(number: 1, label: "AM 1", start_time: "06:30", end_time: "07:20", bus_type: "LARGE_40")
      { school: }
    end
  end
  let(:school) { f[:school] }

  before { travel_to Time.zone.local(2026, 11, 3, 9, 0) }

  it "shows Operations to everyone and Finance only with finance permission" do
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    get api_v1_school_dashboard_path(school)
    d = json[:data]
    expect(d).to include(finance_allowed: false)
    get api_v1_school_dashboard_finance_path(school)
    expect(response).to have_http_status(:forbidden)
    ops = d[:operations]
    expect(ops[:day]).to include(kind: "school_day", title: "School day", detail: "Semester 2, AY 2026", runs: true)
    expect(ops[:sessions].map { it.slice(:name, :arrive_from, :depart, :routes, :buses, :riders, :seats, :seats_used_pct, :without_bus) })
      .to eq([ { name: "AM Arrival", arrive_from: "07:00", depart: nil, routes: 2, buses: 1, riders: 3, seats: 50, seats_used_pct: 6, without_bus: 1 },
               { name: "PM Departure", arrive_from: nil, depart: "13:40", routes: 0, buses: 0, riders: 0, seats: 0, seats_used_pct: nil, without_bus: 0 } ])
    expect(ops[:today]).to include(routes_running: 2, buses_assigned: 1)
    expect(ops[:attention].pluck(:kind, :title)).to include([ "no_bus", "1 trip without a bus" ])
    expect(ops[:upcoming].pluck(:date, :kind, :title)).to eq([ [ "2026-11-09", "public_holiday", "Deepavali Holiday" ],
                                                               [ "2026-11-13", "special_day", "Early Dismissal" ], [ "2026-11-19", "term_end", "Semester 2 ends" ] ])
    expect(ops[:ahead].pluck(:date, :kind, :title)).to eq([ [ "2026-11-20", "riders_start", "1 rider start" ],
                                                            [ "2027-01-04", "plan_adopted", "Term 1 AM adopted as the AM plan" ] ])
    st = ops[:students]
    expect(st).to include(total: 3, on_route: { count: 2, pct: 67 }, not_on_route: 1, am_and_pm: { count: 2, pct: 67 }, am_only: { count: 1, pct: 33 })
    expect(st[:distance]).to include(bin: "1", located: 3, furthest: 5.0, median: 2.2)
    expect(st[:distance][:histogram].pluck(:count)).to eq([ 1, 0, 1, 0, 1 ])
    expect(st[:levels]).to eq([ { label: "P1", count: 2 }, { label: "P2", count: 1 } ])

    get api_v1_school_dashboard_path(school), params: { bin: "2" }
    expect(json.dig(:data, :operations, :students, :distance, :histogram).pluck(:count)).to eq([ 1, 1, 1 ])
  end

  it "shows a month of Finance: cost, riders, seats, collections and the year" do
    sign_in_as(create(:user, company:, permissions: %w[finview]))
    get api_v1_school_dashboard_path(school)
    expect(json.dig(:data, :finance_allowed)).to be(true)
    get api_v1_school_dashboard_finance_path(school), params: { month: "2026-11" }
    fin = json[:data]
    expect(fin).to include(month: "2026-11-01", state: "in_progress", reference_day: "2026-11-03")
    expect(fin[:kpis]).to include(revenue: nil, revenue_note: "Bus Fares for AY 2026 not saved yet", operator_cost: "4200.0", profit: nil,
                                  cost_per_rider: "2100.0", riders: 2, seats: { riders: 3, seats: 50, routes: 2, pct: 6.0 })
    expect(fin[:collections]).to include(billed: "0.0", collected: "0.0", overdue: { bills: 0, owed: "0.0" })
    expect(fin[:year].size).to eq(12)
    expect(fin[:year].find { it[:month] == "2026-10-01" }).to include(cost: "4200.0", revenue: "0.0")
    expect(fin[:ahead].sole).to include(date: "2027-01-04", kind: "plan_adopted", cost_change: "0.0")
    expect(fin[:attention].pluck(:kind)).to eq(%w[setup unpriced])

    get api_v1_school_dashboard_finance_path(school), params: { month: "2026-12" }
    expect(json[:data]).to include(state: "forecast")
  end
end
