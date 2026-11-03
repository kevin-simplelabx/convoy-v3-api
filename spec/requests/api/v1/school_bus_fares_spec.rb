require "rails_helper"

# School Bus › Year Setup › Bus Fares: wizard checks, Save & Lock (school days frozen per bill), the fare table worked out
# per tier and bill (equal / prorated spread, 1-way %, Small Bus), per-bus rates, copy from another year.
RSpec.describe "School Bus fares" do
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
  let(:year) { f[:year] }
  let(:table) do
    { payer: "parents", basis: "distance", trip: "both", cycle: "period", distribution: "equal", one_way: { type: "pct", value: 60 },
      tiers: [ { max_km: 3, fare: 1200 }, { fare: 1500 } ], small: { on: true, type: "pct", value: 10, seats: 15 } }
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[finance]))
  end

  it "checks the table, saves and locks it, and works out each tier's fares per bill" do
    put api_v1_academic_year_fares_path(year), params: table.merge(tiers: [ { max_km: 3, fare: 1200 }, { max_km: 2, fare: 1300 }, { fare: 1500 } ]), as: :json
    expect(json.dig(:error, :message)).to eq("Tier 2 must end further out than tier 1")
    put api_v1_academic_year_fares_path(year), params: table.merge(one_way: { type: "pct" }), as: :json
    expect(json.dig(:error, :message)).to eq("Enter the 1-way fare percentage")
    put api_v1_academic_year_fares_path(year), params: table.merge(tiers: [ { max_km: 3, fare: 1200 }, {} ]), as: :json
    expect(json.dig(:error, :message)).to eq("Above 3 km: enter the 2-way fare")

    put api_v1_academic_year_fares_path(year), params: table, as: :json
    d = json[:data]
    expect(d[:locked]).to be_present
    expect(d[:periods].map { |p| [ p[:label], p[:school_days] ] }).to eq([ [ "Semester 1", 105 ], [ "Semester 2", 40 ] ])
    near = d[:fares].first
    expect(near[:label]).to eq("0 to 3 km")
    expect(near.dig(:std, :two)).to eq(annual: "1200.0", periods: %w[600.0 600.0])
    expect(near.dig(:std, :one)).to eq(annual: "720.0", periods: %w[360.0 360.0])
    expect(near.dig(:small, :two, :annual)).to eq("1320.0")
    expect(d[:fares].last[:label]).to eq("Above 3 km")
    expect(d.dig(:table, :tiers, 0)).to include(max_km: "3.0", fare: "1200.0")

    put api_v1_academic_year_fares_path(year), params: table, as: :json
    expect(json.dig(:error, :message)).to eq("Bus Fares is locked. Unlock to edit")

    # A holiday added later does not change the frozen bills
    within_tenant(company) { year.holidays.create!(name: "Extra", starts_on: "2027-07-05", ends_on: "2027-07-09") }
    get api_v1_academic_year_fares_path(year)
    expect(json.dig(:data, :periods, 1, :school_days)).to eq(40)

    post unlock_api_v1_academic_year_path(year), params: { section: "fares" }
    put api_v1_academic_year_fares_path(year), params: table.merge(distribution: "prorated"), as: :json
    expect(json.dig(:data, :periods, 1, :school_days)).to eq(35)
    expect(json.dig(:data, :fares, 0, :std, :two)).to eq(annual: "1200.0", periods: %w[900.0 300.0]) # 105 : 35
  end

  it "bills the school per bus, and copies a table from another year" do
    put api_v1_academic_year_fares_path(year), params: { payer: "bus", cycle: "period", bus_rates: [ { bus_type: "SMALL_13", rate: 1500 } ] }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter who the school bill goes to")
    put api_v1_academic_year_fares_path(year), params: { payer: "bus", cycle: "month", months: [ 1, 2, 3 ], bill_to: { name: "SSS Finance", email: "fin@sss.edu.sg" },
                                                         bus_rates: [ { bus_type: "SMALL_13", rate: 1500 } ] }, as: :json
    expect(json.dig(:data, :periods).map { |p| p[:label] }).to eq([ "Jan 2027", "Feb 2027", "Mar 2027" ])
    expect(json.dig(:data, :fares, 0)).to include(bus_type: "SMALL_13", label: "13-seater")
    expect(json.dig(:data, :fares, 0, :std, :two)).to eq(annual: "4500.0", periods: %w[1500.0 1500.0 1500.0])

    other = within_tenant(company) { AcademicYears::Create.call(school: f[:school], start_year: 2028, start_month: 1) }
    get copy_api_v1_academic_year_fares_path(other), params: { from_id: year.id }
    expect(json[:data]).to include(payer: "bus", months: [ 1, 2, 3 ], bus_rates: [ { bus_type: "SMALL_13", rate: "1500.0", booked_runs: nil } ])
  end

  it "adds extra charges on top of locked fares, previews bills, and carries open-ended ones into later years" do
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Fuel Surcharge", kind: "pct", value: 10, from_month: "2027-01" }, as: :json
    expect(json.dig(:error, :message)).to eq("Save and lock the Bus Fares first")
    put api_v1_academic_year_fares_path(year), params: table, as: :json
    tier = json.dig(:data, :table, :tiers, 0, :id).to_s

    post preview_api_v1_academic_year_extra_charges_path(year), params: { kind: "pct", value: 10, from_month: "2027-01", targets: [ tier ] }, as: :json
    expect(json[:data]).to eq([ { bill: "Semester 1", before: "600.0", after: "660.0", change: "60.0" },
                                { bill: "Semester 2", before: "600.0", after: "660.0", change: "60.0" } ])

    post api_v1_academic_year_extra_charges_path(year), params: { name: "Fuel Surcharge", kind: "pct", value: 10, from_month: "2026-10" }, as: :json
    expect(json.dig(:error, :message)).to eq("The first month cannot be in the past")
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Fuel Surcharge", kind: "pct", value: 10, from_month: "2027-01" }, as: :json
    fuel = json[:data]
    expect(fuel).to include(state: "scheduled", can_edit: true, can_end: false, to_month: nil)
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Excursion", kind: "once", value: 30, from_month: "2027-03" }, as: :json
    expect(json.dig(:meta, :warning)).to eq("No bill falls in these months, so no one is charged yet")
    patch api_v1_academic_year_extra_charge_path(year, fuel[:id]), params: { name: "Fuel Surcharge", kind: "amt", value: 25, from_month: "2027-01" }, as: :json
    expect(json[:data]).to include(kind: "amt", value: "25.0")
    post end_api_v1_academic_year_extra_charge_path(year, fuel[:id]), params: { to_month: "2027-06" }
    expect(json.dig(:error, :message)).to eq("Only an active charge can be ended")

    later = within_tenant(company) { AcademicYears::Create.call(school: f[:school], start_year: 2028, start_month: 1) }
    get api_v1_academic_year_extra_charges_path(later)
    expect(json[:data]).to contain_exactly(hash_including(name: "Fuel Surcharge", carried_from: "2027", can_edit: false))

    travel_to Time.zone.local(2027, 2, 1, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[finance])) # the earlier token has expired
    post end_api_v1_academic_year_extra_charge_path(year, fuel[:id]), params: { to_month: "2027-06" }
    expect(json[:data]).to include(state: "active", to_month: "2027-06")
    delete api_v1_academic_year_extra_charge_path(year, fuel[:id])
    expect(json.dig(:error, :message)).to eq("Only a charge that has not started can be deleted")
  end

  it "needs the finance permission to save fares" do
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    put api_v1_academic_year_fares_path(year), params: table, as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
