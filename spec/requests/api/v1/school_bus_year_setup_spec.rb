require "rails_helper"

# School Bus › Year Setup: School Levels (suggested from rider data, Save & Lock), Bus Sessions (needs the calendar
# locked; days, times, variants; copy from another year), Bus Attendants, and the setup steps.
RSpec.describe "School Bus year setup" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      [ [ "S1", "P3" ], [ "S2", "p3" ], [ "S3", "P6" ], [ "S4", "Pre-U" ] ].each do |rid, grade|
        school.riders.create!(rid:, name: rid, grade:, postal: "460101", source: "manual")
      end
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      { school:, year: }
    end
  end
  let(:school) { f[:school] }
  let(:year) { f[:year] }
  let(:am) { { name: "AM Arrival", direction: "to_school", service: "d2d", max_journey_minutes: 60, days: [ 1, 2, 3, 4, 5 ], arrive_from: "07:00", arrive_to: "07:25" } }
  let(:pm) do
    { name: "PM Departure", direction: "to_home", service: "d2d", max_journey_minutes: 60, days: [ 1, 2, 3, 4, 5 ], dismissal: "13:30", depart: "13:45",
      arrive_from: "14:00", arrive_to: "15:00", variants: [ { days: [ 3 ], dismissal: "12:00", depart: "12:15", arrive_from: "12:30", arrive_to: "13:30" } ] }
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  it "suggests levels from rider data, saves and locks them" do
    get api_v1_school_levels_path(school)
    d = json[:data]
    expect(d[:saved]).to be(false)
    expect(d[:levels].map { |l| [ l[:name], l[:riders] ] }).to eq([ [ "P1", 0 ], [ "P2", 0 ], [ "P3", 2 ], [ "P4", 0 ], [ "P5", 0 ], [ "P6", 1 ] ])
    expect(d[:levels].last[:final]).to be(true)
    expect(d[:unknown]).to eq([ { grade: "Pre-U", riders: 1 } ])
    expect(d[:sections].map { |s| s[:key] }).to eq(%w[pre pri sec jc grd yr])

    put api_v1_school_levels_path(school), params: { levels: [ { name: "P1" }, { name: "p1" } ] }, as: :json
    expect(json.dig(:error, :message)).to eq("P1 is listed twice")
    put api_v1_school_levels_path(school), params: { levels: [ { name: "P5", section: "pri" }, { name: "P6", section: "pri", final: true }, { name: "Pre-U" } ] }, as: :json
    expect(json[:data]).to include(saved: true, unknown: [ { grade: "P3", riders: 2 } ])
    expect(json.dig(:data, :locked, :by)).to be_present
    put api_v1_school_levels_path(school), params: { levels: [ { name: "P1" } ] }, as: :json
    expect(json.dig(:error, :message)).to eq("School Levels is locked. Unlock to edit")
    post unlock_api_v1_school_path(school), params: { section: "levels" }
    expect(response).to have_http_status(:no_content)
  end

  it "saves bus sessions once the calendar is locked, checks their times, and copies them to another year" do
    put api_v1_academic_year_sessions_path(year), params: { sessions: [ am ] }, as: :json
    expect(json.dig(:error, :message)).to eq("Save and lock the Terms & Semesters first")
    within_tenant(company) { SchoolSetup.lock!(school:, year:, section: :calendar, user: nil) }

    put api_v1_academic_year_sessions_path(year), params: { sessions: [ am.merge(days: [ 1, 6 ]) ] }, as: :json
    expect(json.dig(:error, :message)).to eq("AM Arrival: pick operating days only")
    put api_v1_academic_year_sessions_path(year), params: { sessions: [ pm.merge(depart: "13:00") ] }, as: :json
    expect(json.dig(:error, :message)).to eq("PM Departure: departure must be at or after dismissal")
    put api_v1_academic_year_sessions_path(year), params: { sessions: [ am, am ] }, as: :json
    expect(json.dig(:error, :message)).to eq("Session names must be different")

    put api_v1_academic_year_sessions_path(year), params: { sessions: [ am, pm ] }, as: :json
    expect(json[:data].map { |s| s[:name] }).to eq([ "AM Arrival", "PM Departure" ])
    expect(json.dig(:data, 1, :variants)).to eq([ { days: [ 3 ], arrive_from: "12:30", arrive_to: "13:30", dismissal: "12:00", depart: "12:15" } ])
    expect(json.dig(:meta, :locked)).to be_present

    other = within_tenant(company) { AcademicYears::Create.call(school:, start_year: 2027, start_month: 1).tap { it.update!(operating_days: [ 1, 2, 4, 5 ]) } }
    get copy_api_v1_academic_year_sessions_path(other), params: { from_id: year.id }
    expect(json.dig(:data, 1)).to include(name: "PM Departure", days: [ 1, 2, 4, 5 ], variants: [ hash_including(days: []) ])
  end

  it "does not save or lock Bus Attendants from an empty body" do
    patch api_v1_school_bus_attendants_path(school), params: {}, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(json.dig(:error, :message)).to eq("Send needs, sizes or provided_by")
    get api_v1_school_bus_attendants_path(school)
    expect(json[:data]).to include(saved: false, locked: nil)
  end

  it "rejects a Bus Attendants pick with no bus size" do
    put api_v1_school_bus_attendants_path(school), params: { needs: "selected", sizes: [] }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Pick at least one bus size")
    get api_v1_school_bus_attendants_path(school)
    expect(json[:data]).to include(saved: false, locked: nil)
  end

  it "shows the setup strip of a school without a year and counts a policy only once it is in use" do
    other = within_tenant(company) { School.create!(name: "No Year School") }
    get setup_api_v1_school_path(other)
    expect(response).to have_http_status(:ok)
    steps = json.dig(:data, :steps).index_by { it[:key] }
    expect(json[:data]).to include(year: nil, done: 0, total: 7)
    expect(steps.values_at("levels", "calendar", "sessions", "holidays").pluck(:detail))
      .to eq([ "Not set up yet", "Not started", "Needs the calendar first", "Needs the calendar first" ])

    within_tenant(company) { Policies::Publish.call(school, Policies.default.merge(effective_on: Date.new(2027, 1, 1)), user: nil) }
    get setup_api_v1_school_path(school)
    expect(json[:data]).to include(year: "2026")
    expect(json.dig(:data, :steps).find { it[:key] == "policy" }).to include(done: false, detail: "Not set up yet")
    get setup_api_v1_academic_year_path(year)
    expect(json.dig(:data, :steps).find { it[:key] == "policy" }).to include(done: false)

    travel_to Time.zone.local(2027, 1, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    get setup_api_v1_school_path(school)
    expect(json.dig(:data, :steps).find { it[:key] == "policy" }).to include(done: true, detail: "Version 1 from 01/01/2027")
  end

  it "describes each step of the strip like the prototype" do
    within_tenant(company) do
      school.levels.create!(name: "P1", position: 0)
      school.levels.create!(name: "P6", position: 1)
      SchoolSetup.lock!(school:, section: "levels", user: nil)
      SchoolSetup.lock!(school:, year:, section: "calendar", user: nil)
      SchoolSetup.lock!(school:, section: "attendants", user: nil)
    end
    put api_v1_school_bus_attendants_path(school), params: { needs: "all" }, as: :json
    get setup_api_v1_academic_year_path(year)
    d = json.dig(:data, :steps).index_by { it[:key] }
    expect(d["levels"][:detail]).to eq("2 levels, P1 to P6")
    expect(d["calendar"][:detail]).to eq("Locked 02/11/2026")
    expect(d["sessions"][:detail]).to eq("Not set up yet")
    expect(d["fares"][:detail]).to eq("Not set up yet")
    expect(d["holidays"][:detail]).to eq("0 holidays, 0 special days")
  end

  it "sets which buses need an attendant and shows the setup steps" do
    put api_v1_school_bus_attendants_path(school), params: { needs: "selected", sizes: [ "MEDIUM_23" ], provided_by: "us" }, as: :json
    expect(json[:data]).to include(needs: "selected", sizes: %w[LARGE_40 LARGE_45 MEDIUM_23], provided_by: "us", saved: true)
    expect(json.dig(:data, :bus_types).find { |t| t[:key] == "LARGE_45" }).to include(required_by_law: true)

    get setup_api_v1_academic_year_path(year)
    d = json[:data]
    expect(d).to include(year: "2026", done: 1, total: 7, complete: false)
    expect(d[:steps].map { |s| [ s[:key], s[:done], s[:available] ] }.first(7))
      .to eq([ [ "levels", false, true ], [ "calendar", false, true ], [ "sessions", false, true ], [ "fares", false, true ],
               [ "policy", false, true ], [ "attendants", true, true ], [ "operator_pay", false, true ] ])
  end
end
