require "rails_helper"

RSpec.describe "School Bus routes on the Scheduler" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      create(:public_holiday, date: "2026-11-09", name: "Deepavali Holiday")
      hup = create(:operator, name: "Hup Seng")
      kumar = create(:driver, name: "Kumar")
      a = create(:vehicle, plate: "PD6604E", seats: 40)
      a.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      b = create(:vehicle, plate: "PD1125G", seats: 13)
      c = create(:vehicle, plate: "PC7475L", seats: 23, operator: hup)
      school = School.create!(name: "St. Stephen's School", short_name: "SSS")
      # Academic year: Term 4 ends 19 Nov; Deepavali on the school's holiday list; a Late Arrival does not move the runs.
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      year.terms.first.update!(starts_on: "2026-01-02", ends_on: "2026-05-29")
      year.terms.second.update!(starts_on: "2026-06-29", ends_on: "2026-11-19")
      year.holidays.create!(name: "Deepavali Holiday", starts_on: "2026-11-09", ends_on: "2026-11-09")
      year.special_days.create!(date: "2026-11-04", kind: "late_arrival", time: "09:00")
      plan = school.plans.create!(name: "Term 4 AM", session: "am", effective_from: Date.new(2026, 10, 1))
      route = plan.routes.create!(number: 1, label: "AM 1", start_time: "06:30", end_time: "07:20", riders_count: 23)
      route.stops.create!(position: 0, name: "Blk 101 Bedok North", scheduled_time: "06:30", riders_count: 23)
      route.vehicle_changes.create!(vehicle: a, effective_from: Date.new(2026, 10, 1))
      pm = school.plans.create!(name: "Term 4 PM", session: "pm", effective_from: Date.new(2026, 10, 1))
      pm_route = pm.routes.create!(number: 1, label: "PM 1", start_time: "13:40", end_time: "14:30", riders_count: 23)
      { a:, b:, c:, hup:, kumar:, school:, route:, pm_route: }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 5, 0)
    within_tenant(company) { Occurrences::Sync.call(routes: [ f[:route], f[:pm_route] ]) }
    sign_in_as(create(:user, company:))
  end

  def route_runs(from, to, route: f[:route])
    get api_v1_occurrences_path, params: { from:, to: }
    json[:data].select { |o| o[:school_route_id] == route.id }
  end

  it "runs on the school days of the academic year only, with the regular bus and its driver" do
    runs = route_runs("2026-11-02", "2026-11-23")
    expect(runs.pluck(:date)).not_to include("2026-11-07", "2026-11-09", "2026-11-20", "2026-11-23") # Saturday, holiday, after the term
    wed = runs.find { |o| o[:date] == "2026-11-04" }
    expect(wed).to include(start_time: "06:30", plate: "PD6604E", trip_label: "SSS AM 1", school_name: "SSS", pax: 23,
                           key: "r#{f[:route].id}|2026-11-04|0|1|1")
    expect(wed.dig(:driver, :name)).to eq("Kumar")

    get api_v1_occurrences_path, params: { driver_id: f[:kumar].id, date: "2026-11-03" }
    expect(json[:data].pluck(:trip_label)).to eq([ "SSS AM 1" ])
  end

  it "shows the route in the drawer and on the grid" do
    get api_v1_scheduler_path, params: { from: "2026-11-03" }
    expect(json.dig(:data, :occurrences).pluck(:title)).to include("SSS AM 1")
    expect(json.dig(:data, :unassigned).pluck(:title)).to eq([ "SSS PM 1" ]) # no regular bus yet

    id = route_runs("2026-11-03", "2026-11-03").first[:id]
    get api_v1_occurrence_path(id)
    expect(json.dig(:data, :route)).to include(label: "AM 1", riders: 23, regular_plate: "PD6604E")
    expect(json.dig(:data, :route, :school)).to include(short_name: "SSS")
    expect(json.dig(:data, :trip)).to be_nil
  end

  describe "drops" do
    let(:tue) { route_runs("2026-11-03", "2026-11-03").first[:id] }

    it "Just This Trip puts a replacement bus on that day, leaving a ghost of the regular one" do
      get move_preview_api_v1_occurrence_path(tue), params: { vehicle_id: f[:b].id }
      expect(json[:data]).to include(scopes: %w[one range perm], regular: "PD6604E", ask_who_arranges: false)

      post move_api_v1_occurrence_path(tue), params: { vehicle_id: f[:b].id, scope: "one" }, as: :json
      expect(json.dig(:data, 0)).to include(plate: "PD1125G", original_plate: "PD6604E")
      expect(route_runs("2026-11-04", "2026-11-04").first[:plate]).to eq("PD6604E")
    end

    it "a date range on an operator's bus we arrange needs the cost per day, and later drops cut it" do
      post move_api_v1_occurrence_path(tue), params: { vehicle_id: f[:c].id, scope: "range", starts_on: "2026-11-03", ends_on: "2026-11-06", arranged_by: "us" }, as: :json
      expect(json.dig(:error, :message)).to include("Daily rate must be entered")

      post move_api_v1_occurrence_path(tue), params: { vehicle_id: f[:c].id, scope: "range", starts_on: "2026-11-03", ends_on: "2026-11-06",
                                                       arranged_by: "us", daily_rate: 180 }, as: :json
      expect(route_runs("2026-11-03", "2026-11-06").pluck(:plate)).to eq(%w[PC7475L PC7475L PC7475L PC7475L])

      thu = route_runs("2026-11-05", "2026-11-05").first[:id]
      post move_api_v1_occurrence_path(thu), params: { vehicle_id: f[:a].id, scope: "one" }, as: :json
      expect(route_runs("2026-11-03", "2026-11-06").pluck(:plate)).to eq(%w[PC7475L PC7475L PD6604E PC7475L])
      expect(within_tenant(company) { f[:route].replacements.order(:starts_on).pluck(:starts_on, :ends_on) })
        .to eq([ [ Date.new(2026, 11, 3), Date.new(2026, 11, 4) ], [ Date.new(2026, 11, 6), Date.new(2026, 11, 6) ] ])
    end

    it "a permanent change makes a new regular bus from the date, or removes the bus" do
      post move_api_v1_occurrence_path(tue), params: { vehicle_id: f[:b].id, scope: "perm", starts_on: "2026-11-05" }, as: :json
      expect(route_runs("2026-11-04", "2026-11-06").pluck(:plate)).to eq(%w[PD6604E PD1125G PD1125G])

      post move_api_v1_occurrence_path(tue), params: { vehicle_id: nil, scope: "perm", starts_on: "2026-11-10" }, as: :json
      expect(route_runs("2026-11-10", "2026-11-10").first[:vehicle_id]).to be_nil
    end
  end

  it "takes a Scheduler replacement (driver unavailable)" do
    tue = route_runs("2026-11-03", "2026-11-03").first[:id]
    post api_v1_replacements_path, params: { occurrence_id: tue, replacement: { kind: "drv", driver_name: "Ah Kow" } }, as: :json
    expect(json.dig(:data, :summary)).to start_with("Ah Kow drives PD6604E")
    expect(route_runs("2026-11-03", "2026-11-03").first.dig(:driver, :name)).to eq("Ah Kow")
  end

  it "sends a school notice to some of its routes" do
    post api_v1_notices_path, params: { notice: { audience: "school", school_id: f[:school].id, to_parents: true, banner: true, message: "Heavy rain, buses may be late" },
                                        period_minutes: 30, route_ids: [ f[:route].id ] }, as: :json
    expect(json[:data]).to include(route_ids: [ f[:route].id ], state: "active")

    get api_v1_occurrence_path(route_runs("2026-11-02", "2026-11-02").first[:id])
    expect(json.dig(:data, :notice, :message)).to eq("Heavy rain, buses may be late")
    get api_v1_occurrence_path(route_runs("2026-11-02", "2026-11-02", route: f[:pm_route]).first[:id])
    expect(json.dig(:data, :notice)).to be_nil
  end

  it "lists the routes in use for the notice's route picker and refuses others" do
    draft = within_tenant(company) do
      f[:school].plans.create!(name: "AM Plan 2", session: "am", effective_from: Date.new(2026, 11, 2), in_use: false)
                .routes.create!(number: 1, label: "AM 1", start_time: "06:40", end_time: "07:30")
    end
    get api_v1_school_routes_path(f[:school]), params: { date: "2026-11-02" }
    expect(json[:data]).to eq([ { id: f[:route].id, label: "AM 1", session: "am", plan_id: f[:route].school_plan_id, riders_count: 23,
                                  start_time: "06:30", end_time: "07:20", vehicle_plate: "PD6604E" },
                                { id: f[:pm_route].id, label: "PM 1", session: "pm", plan_id: f[:pm_route].school_plan_id, riders_count: 23,
                                  start_time: "13:40", end_time: "14:30", vehicle_plate: nil } ])
    get api_v1_school_routes_path(f[:school]), params: { date: "2026-09-30" }
    expect(json[:data]).to eq([])

    post api_v1_notices_path, params: { notice: { audience: "school", school_id: f[:school].id, to_parents: true, banner: true, message: "Late" },
                                        period_minutes: 30, route_ids: [ draft.id ] }, as: :json
    expect(json.dig(:error, :message)).to eq("Pick routes in use at this school")
  end
end
