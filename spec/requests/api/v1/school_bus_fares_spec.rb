require "rails_helper"

# School Bus › Year Setup › Bus Fares: wizard checks (with their step), Save & Lock (school days frozen per bill; tiers and
# surcharges kept by id), drawn zone areas, the fare table worked out per tier and bill (equal / prorated spread, 1-way %,
# Small Bus), a draft preview, per-bus rates (runs in the route plans, student seats), copy from another year, and
# Extra Charges (targets, checks, preview).
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
    expect(json[:error]).to include(message: "Tier 2 must end further out than tier 1", details: { step: 2, step_name: "Fares" })
    put api_v1_academic_year_fares_path(year), params: table.merge(one_way: { type: "pct" }), as: :json
    expect(json[:error]).to include(message: "Enter the 1-way fare percentage", details: { step: 1, step_name: "Billing" })
    put api_v1_academic_year_fares_path(year), params: table.merge(tiers: [ { max_km: 3, fare: 1200 }, {} ]), as: :json
    expect(json.dig(:error, :message)).to eq("Above 3 km: enter the 2-way fare")

    put api_v1_academic_year_fares_path(year), params: table, as: :json
    d = json[:data]
    expect(d[:locked]).to be_present
    expect(d[:periods].map { |p| [ p[:label], p[:school_days] ] }).to eq([ [ "Semester 1", 105 ], [ "Semester 2", 40 ] ])
    near = d[:fares].first
    expect(near[:label]).to eq("0 to 3 km")
    expect(near.dig(:std, :two)).to eq(annual: "1200.00", periods: %w[600.00 600.00])
    expect(near.dig(:std, :one)).to eq(annual: "720.00", periods: %w[360.00 360.00])
    expect(near.dig(:small, :two, :annual)).to eq("1320.00")
    expect(d[:fares].last[:label]).to eq("Above 3 km")
    expect(d.dig(:table, :tiers, 0)).to include(max_km: "3.0", fare: "1200.00", areas: [])

    put api_v1_academic_year_fares_path(year), params: table, as: :json
    expect(json.dig(:error, :message)).to eq("Bus Fares is locked. Unlock to edit")

    # A holiday added later does not change the frozen bills
    within_tenant(company) { year.holidays.create!(name: "Extra", starts_on: "2027-07-05", ends_on: "2027-07-09") }
    get api_v1_academic_year_fares_path(year)
    expect(json.dig(:data, :periods, 1, :school_days)).to eq(40)

    post unlock_api_v1_academic_year_path(year), params: { section: "fares" }
    put api_v1_academic_year_fares_path(year), params: table.merge(distribution: "prorated"), as: :json
    expect(json.dig(:data, :periods, 1, :school_days)).to eq(35)
    expect(json.dig(:data, :fares, 0, :std, :two)).to eq(annual: "1200.00", periods: %w[900.00 300.00]) # 105 : 35
  end

  it "bills the school per bus, and copies a table from another year" do
    put api_v1_academic_year_fares_path(year), params: { payer: "bus", cycle: "period", bus_rates: [ { bus_type: "SMALL_13", rate: 1500 } ] }, as: :json
    expect(json[:error]).to include(message: "Enter who the school bill goes to", details: { step: 0, step_name: "Who Pays" })
    put api_v1_academic_year_fares_path(year), params: { payer: "bus", cycle: "month", months: [ 1 ], bill_to: { name: "SSS", email: "fin@sss.edu.sg" } }, as: :json
    expect(json[:error]).to include(message: "Enter a rate for at least one bus size", details: { step: 2, step_name: "Bus Rates" })
    put api_v1_academic_year_fares_path(year), params: { payer: "bus", cycle: "month", months: [ 1, 2, 3 ], bill_to: { name: "SSS Finance", email: "fin@sss.edu.sg" },
                                                         bus_rates: [ { bus_type: "SMALL_13", rate: 1500 } ] }, as: :json
    expect(json.dig(:data, :periods).map { |p| p[:label] }).to eq([ "Jan 2027", "Feb 2027", "Mar 2027" ])
    expect(json.dig(:data, :fares, 0)).to include(bus_type: "SMALL_13", label: "13-seater")
    expect(json.dig(:data, :fares, 0, :std, :two)).to eq(annual: "4500.00", periods: %w[1500.00 1500.00 1500.00])

    other = within_tenant(company) { AcademicYears::Create.call(school: f[:school], start_year: 2028, start_month: 1) }
    get copy_api_v1_academic_year_fares_path(other), params: { from_id: year.id }
    expect(json[:data]).to include(payer: "bus", months: [ 1, 2, 3 ], bus_rates: [ { bus_type: "SMALL_13", rate: "1500.00", booked_runs: nil } ])
  end

  it "keeps tiers and surcharges by id on a new Save & Lock, so Extra Charge targets keep working" do
    put api_v1_academic_year_fares_path(year), params: table.merge(surcharges: [ { name: "Sentosa", sectors: "09", amount: 200 } ]), as: :json
    tiers = json.dig(:data, :table, :tiers)
    sentosa = json.dig(:data, :table, :surcharges, 0)
    expect(sentosa).to include(name: "Sentosa", sectors: [ "09" ], areas: [], id: kind_of(Integer))
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Toll", kind: "amt", value: 20, from_month: "2027-06", tier_ids: [ tiers[1][:id] ] }, as: :json
    expect(json[:data]).to include(tier_ids: [ tiers[1][:id] ], bus_types: [], value: "20.00")

    post unlock_api_v1_academic_year_path(year), params: { section: "fares" }
    sent = tiers.map { it.slice(:id, :max_km, :fare) }
    put api_v1_academic_year_fares_path(year), params: table.merge(tiers: sent + [ { fare: 1800 } ], surcharges: [ sentosa.merge(amount: 250) ]).tap { it[:tiers][1][:max_km] = 6 }, as: :json
    after = json.dig(:data, :table, :tiers)
    expect(after.first(2).pluck(:id)).to eq(tiers.pluck(:id))
    expect(after.last[:id]).not_to be_in(tiers.pluck(:id))
    expect(json.dig(:data, :table, :surcharges, 0)).to include(id: sentosa[:id], amount: "250.0")
    get api_v1_academic_year_extra_charges_path(year)
    expect(json.dig(:data, 0, :tier_ids)).to eq([ tiers[1][:id] ])

    # A tier an Extra Charge targets cannot go
    post unlock_api_v1_academic_year_path(year), params: { section: "fares" }
    put api_v1_academic_year_fares_path(year), params: table.merge(tiers: [ after[0].slice(:id, :max_km, :fare), after[2].slice(:id, :fare) ]), as: :json
    expect(json.dig(:error, :message)).to eq('Tier 2 is used by the Extra Charge "Toll". Keep it, or remove it from that charge first')
    # Copy leaves the ids out
    other = within_tenant(company) { AcademicYears::Create.call(school: f[:school], start_year: 2028, start_month: 1) }
    get copy_api_v1_academic_year_fares_path(other), params: { from_id: year.id }
    expect(json.dig(:data, :tiers).map { it.key?(:id) }.uniq).to eq([ false ])
  end

  it "keeps drawn zone areas with cut-outs and finds a rider's zone by them" do
    ring = [ [ 1.30, 103.80 ], [ 1.30, 103.90 ], [ 1.40, 103.90 ], [ 1.40, 103.80 ] ]
    hole = [ [ 1.34, 103.84 ], [ 1.34, 103.86 ], [ 1.36, 103.86 ], [ 1.36, 103.84 ] ]
    zones = table.merge(basis: "zone", tiers: [ { name: "North", areas: [ { latlngs: ring }, { latlngs: hole, exclude: true } ], fare: 1200 }, { name: "Rest", sectors: "01", fare: 1500 } ])
    put api_v1_academic_year_fares_path(year), params: zones.merge(tiers: [ { name: "North", area: ring, fare: 1200 } ]), as: :json
    expect(json.dig(:error, :message)).to eq("area is replaced by areas: [{ latlngs, exclude }]")
    put api_v1_academic_year_fares_path(year), params: zones.merge(tiers: [ { name: "North", areas: [ { latlngs: ring.first(2) } ], fare: 1200 } ]), as: :json
    expect(json.dig(:error, :message)).to eq("Zone 1: area 1 needs at least 3 corners")
    put api_v1_academic_year_fares_path(year), params: zones.merge(tiers: [ { name: "North", areas: [ { latlngs: hole, exclude: true } ], fare: 1200 } ]), as: :json
    expect(json[:error]).to include(message: "North: add postal sectors or draw the area", details: { step: 2, step_name: "Fares" })

    put api_v1_academic_year_fares_path(year), params: zones, as: :json
    expect(json.dig(:data, :table, :tiers, 0, :areas)).to eq([ { latlngs: ring, exclude: false }, { latlngs: hole, exclude: true } ])
    within_tenant(company) do
      t = year.reload.fare_table
      home = ->(lat, lng) { Struct.new(:postal, :lat, :lng).new("010101", lat, lng) }
      zone = ->(r) { FareTables::RiderFare.tier_index(t, f[:school], r, t.tiers.includes(:areas).to_a) }
      expect([ zone.(home.(1.32, 103.82)), zone.(home.(1.35, 103.85)), zone.(home.(1.50, 103.85)) ]).to eq([ 0, 1, 1 ])
    end
  end

  it "previews a draft table: bills with school days, fares and the first failing step, nothing saved" do
    post preview_api_v1_academic_year_fares_path(year), params: table.merge(tiers: [ { max_km: 3, fare: 1200 }, {} ]), as: :json
    d = json[:data]
    expect(d[:periods].map { |p| [ p[:label], p[:school_days] ] }).to eq([ [ "Semester 1", 105 ], [ "Semester 2", 40 ] ])
    expect(d.dig(:fares, 0, :std, :two)).to eq(annual: "1200.00", periods: %w[600.00 600.00])
    expect(d[:problem]).to eq(message: "Above 3 km: enter the 2-way fare", step: 2, step_name: "Fares")
    post preview_api_v1_academic_year_fares_path(year), params: table.merge(by_size: true, size_columns: [ { max_seats: 15 }, {} ],
                                                                             tiers: [ { fare: 1200, sizes: [ { fare: 1500 } ] } ]), as: :json
    expect(json.dig(:data, :problem)).to be_nil
    expect(json.dig(:data, :fares, 0, :sizes, 0, :fares, :two, :annual)).to eq("1500.00")
    get api_v1_academic_year_fares_path(year)
    expect(json.dig(:data, :table)).to be_nil
  end

  it "counts the runs per bus size in the route plans in use and the student seats of each size" do
    within_tenant(company) do
      school = f[:school]
      school.create_attendant_policy!(needs: "selected", sizes: [ "SMALL_13" ])
      am = school.plans.create!(name: "AM", session: "am", effective_from: Date.new(2026, 10, 1), in_use: true)
      pm = school.plans.create!(name: "PM", session: "pm", effective_from: Date.new(2026, 10, 1), in_use: true)
      school.plans.create!(name: "Draft", session: "am", effective_from: Date.new(2026, 10, 1), in_use: false)
            .routes.create!(number: 1, label: "AM 9", start_time: "07:00", end_time: "07:30", bus_type: "SMALL_13")
      [ [ am, "LARGE_40" ], [ am, "SMALL_13" ], [ pm, "SMALL_13" ] ].each_with_index do |(p, type), i|
        p.routes.create!(number: i + 1, label: "#{p.session.upcase} #{i + 1}", start_time: "07:00", end_time: "07:30", bus_type: type)
      end
    end
    get api_v1_academic_year_fares_path(year)
    expect(json.dig(:data, :plan_runs)).to eq(LARGE_40: 1, SMALL_13: 2)
    types = json.dig(:data, :bus_types).index_by { it[:key] }
    expect(types["LARGE_40"]).to include(seats: 40, student_seats: 39)
    expect(types["SMALL_13"]).to include(seats: 13, student_seats: 12)
    expect(types["MEDIUM_23"]).to include(seats: 23, student_seats: 23)
  end

  it "adds extra charges on top of locked fares, previews bills, and carries open-ended ones into later years" do
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Fuel Surcharge", kind: "pct", value: 10, from_month: "2027-01" }, as: :json
    expect(json.dig(:error, :message)).to eq("Save and lock the Bus Fares first")
    put api_v1_academic_year_fares_path(year), params: table, as: :json
    tiers = json.dig(:data, :table, :tiers).pluck(:id)

    # The preview takes the first picked tier (Above 3 km: 1500 a year)
    post preview_api_v1_academic_year_extra_charges_path(year), params: { kind: "pct", value: 10, from_month: "2027-01", tier_ids: [ tiers[1] ] }, as: :json
    expect(json[:data]).to eq([ { bill: "Semester 1", before: "750.00", after: "825.00", change: "75.00" },
                                { bill: "Semester 2", before: "750.00", after: "825.00", change: "75.00" } ])
    expect(json.dig(:meta, :example)).to eq("Above 3 km, 2-way rider")
    post preview_api_v1_academic_year_extra_charges_path(year), params: { kind: "pct", value: 10, from_month: "2027-01", targets: [ tiers[1].to_s ] }, as: :json
    expect(json.dig(:error, :message)).to eq("targets is replaced by tier_ids and bus_types")

    base = { name: "Fuel Surcharge", kind: "pct", value: 10, from_month: "2027-01" }
    { { name: " " } => "Give the charge a name", { value: 0 } => "Enter an amount above 0", { value: 150 } => "Percentage must be 100 or less",
      { from_month: "" } => "Pick the start month", { from_month: "2026-10" } => "Bills before this month are already raised. Pick this month or later",
      { kind: "once", from_month: "2027-03" } => "No bill is raised in that month", { to_month: "2026-12" } => "End month must be on or after the start month",
      { tier_ids: [ 0 ] } => "Pick tiers of this year's Bus Fares", { bus_types: [ "SMALL_13" ] } => "Pick bus sizes only when the school pays per bus" }.each do |change, message|
      post api_v1_academic_year_extra_charges_path(year), params: base.merge(change), as: :json
      expect(json.dig(:error, :message)).to eq(message)
    end
    post api_v1_academic_year_extra_charges_path(year), params: base, as: :json
    fuel = json[:data]
    expect(fuel).to include(state: "scheduled", can_edit: true, can_end: false, to_month: nil, tier_ids: [], bus_types: [])
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Camp", kind: "amt", value: 30, from_month: "2027-02", to_month: "2027-05" }, as: :json
    expect(json.dig(:meta, :warning)).to eq("No AY 2027 bills fall between February 2027 and May 2027")
    patch api_v1_academic_year_extra_charge_path(year, fuel[:id]), params: { name: "Fuel Surcharge", kind: "amt", value: 25, from_month: "2027-01", tier_ids: tiers }, as: :json
    expect(json[:data]).to include(kind: "amt", value: "25.00", tier_ids: tiers)
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

  it "targets bus sizes when the school pays per bus" do
    put api_v1_academic_year_fares_path(year), params: { payer: "bus", cycle: "period", bill_to: { name: "SSS Finance", email: "fin@sss.edu.sg" },
                                                         bus_rates: [ { bus_type: "SMALL_13", rate: 1500 }, { bus_type: "LARGE_40", rate: 3000 } ] }, as: :json
    post preview_api_v1_academic_year_extra_charges_path(year), params: { kind: "amt", value: 100, from_month: "2027-01", bus_types: [ "SMALL_13" ] }, as: :json
    expect(json.dig(:data, 0)).to include(before: "1500.00", after: "1600.00")
    expect(json.dig(:meta, :example)).to eq("13-seater, 2-way rider")
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Toll", kind: "amt", value: 100, from_month: "2027-01", tier_ids: [ 1 ] }, as: :json
    expect(json.dig(:error, :message)).to eq("The school pays per bus. Pick bus sizes, not tiers")
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Toll", kind: "amt", value: 100, from_month: "2027-01", bus_types: [ "MEDIUM_23" ] }, as: :json
    expect(json.dig(:error, :message)).to eq("Pick bus sizes the fares have a rate for")
    post api_v1_academic_year_extra_charges_path(year), params: { name: "Toll", kind: "amt", value: 100, from_month: "2027-01", bus_types: [ "SMALL_13" ] }, as: :json
    expect(json[:data]).to include(bus_types: [ "SMALL_13" ], tier_ids: [])
  end

  it "needs the finance permission to save fares" do
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    put api_v1_academic_year_fares_path(year), params: table, as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
