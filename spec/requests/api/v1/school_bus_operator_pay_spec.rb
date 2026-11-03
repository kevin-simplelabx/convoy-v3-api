require "rails_helper"

# School Bus › Year Setup › Operator Pay: settings and prices per bus size (Save & Lock), the BA prices on Bus
# Attendants, and the Break Month Calculator (part pay × retainer earned by the terms served).
RSpec.describe "School Bus operator pay" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      year = AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
      AcademicYears::SaveCalendar.call(year, { operating_days: [ 1, 2, 3, 4, 5 ], structure: "semester", period_count: 2, cca_same_as_terms: true,
                                               terms: [ { starts_on: "2027-01-04", ends_on: "2027-05-28" }, { starts_on: "2027-06-28", ends_on: "2027-08-20" } ] }, user: nil)
      { school:, year: }
    end
  end
  let(:school) { f[:school] }
  let(:settings) do
    { scheme: "part", paid_months: [ 1, 2, 3, 4, 5, 7, 8, 9, 10, 11 ], part_pct: 50, part_basis: "school", break_months: [ 6, 12 ], break_pay: "earned",
      earn_by: "terms", rates: [ { bus_type: "SMALL_13", fixed_on: true, monthly: 2000, rider_on: true, base_price: 1500, riders_included: 10, per_rider: 50,
                                   default_mode: "rider", ba_operator: 600, ba_us: 450 } ] }
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[finance]))
  end

  it "saves and locks the settings, shows BA prices, and works out break-month pay" do
    put api_v1_school_operator_pay_path(school), params: settings.merge(scheme: "some", paid_months: []), as: :json
    expect(json.dig(:error, :message)).to eq("Pick at least one paid month")
    put api_v1_school_operator_pay_path(school), params: settings.merge(part_pct: 120), as: :json
    expect(json.dig(:error, :message)).to eq("Enter a percentage from 0 to 100")
    put api_v1_school_operator_pay_path(school), params: settings.merge(rates: [ { bus_type: "SMALL_13", rider_on: true, base_price: 1500 } ]), as: :json
    expect(json.dig(:error, :message)).to eq("13-seater: enter the base price, riders included and extra per rider")

    put api_v1_school_operator_pay_path(school), params: settings, as: :json
    d = json[:data]
    expect(d).to include(saved: true, scheme: "part", part_pct: "50.0", break_months: [ 6, 12 ])
    expect(d[:locked]).to be_present
    expect(d[:rates].find { |r| r[:bus_type] == "SMALL_13" }).to include(monthly: "2000.0", default_mode: "rider", ba_operator: "600.0")

    get api_v1_school_bus_attendants_path(school)
    expect(json.dig(:data, :bus_types).find { |t| t[:key] == "SMALL_13" }).to include(ba_operator: "600.0", ba_us: "450.0")

    # From 1 Apr: only the second half of Semester 1 → 50% earned for June at 50% part pay; Semester 2 in full for December
    post calculator_api_v1_school_operator_pay_path(school), params: { academic_year_id: f[:year].id, start_date: "2027-04-01", price: 2000 }
    expect(json[:data].map { |r| [ r[:month], r[:pct], r[:amount] ] }).to eq([ [ "2027-06", 25, "500.0" ], [ "2027-12", 50, "1000.0" ] ])
    expect(json[:data].map { |r| r[:note] }).to eq([ "Ran in 1 of 2 halves of the term, at 50% part pay", "Ran in 2 of 2 halves of the term, at 50% part pay" ])

    get setup_api_v1_academic_year_path(f[:year])
    expect(json.dig(:data, :steps).find { |s| s[:key] == "operator_pay" }).to include(done: true, available: true)
  end

  it "is hidden without finance or finview" do
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    get api_v1_school_operator_pay_path(school)
    expect(response).to have_http_status(:forbidden)
  end
end
