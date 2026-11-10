require "rails_helper"

# School Bus › Feasibility Studies: a prospect school, students pasted by postal code, bus prices, a scenario planned AM
# and PM in the routing service, its monthly cost / break-even / target fare, fares by tier, Use Suggested Fares.
RSpec.describe "School Bus feasibility studies" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    fake_one_map.add("455789", 1.3138, 103.9283, "20 Siglap View")
    { "460101" => [ 1.3240, 103.9300 ], "460102" => [ 1.3300, 103.9400 ], "470300" => [ 1.3600, 103.9600 ] }.each { |pc, (la, lo)| fake_one_map.add(pc, la, lo) }
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  it "shows studies (bus prices, break-even) only with the plans permission" do
    sign_in_as(create(:user, company:, permissions: %w[schools planview]))
    get api_v1_feasibility_studies_path
    expect(response).to have_http_status(:forbidden)
  end

  it "plans a scenario and works out its cost and fares" do
    post api_v1_feasibility_studies_path, params: { study: { name: "Siglap Primary bid", school_mode: "prospect", prospect_name: "Siglap Primary", prospect_postal: "455789" } }
    study = json[:data]
    expect(study[:place]).to include(name: "Siglap Primary", lat: 1.3138)
    expect(study[:scenarios].map { |s| s[:name] }).to eq([ "Scenario 1" ])

    post rows_api_v1_feasibility_study_path(study[:id]), params: { text: "Postal,Count,Session\n460101, 6\n460102,4,AM\nno code here\n470300,2,PM,P4\n460101,2" }
    expect(json[:meta]).to eq(skipped: 1)
    expect(json.dig(:data, :rows).map { |r| [ r[:postal], r[:riders], r[:session], r[:level] ] })
      .to eq([ [ "460101", 8, "both", nil ], [ "460102", 4, "AM", nil ], [ "470300", 2, "PM", "P4" ] ])

    patch api_v1_feasibility_study_path(study[:id]), params: { bus_prices: [ { bus_type: "MEDIUM_23", monthly: 3600, attendant: 450 } ],
                                                               fare_tiers: [ { max_km: 3, fare: 150, one_way_fare: 100 }, { fare: 200, one_way_fare: 120 } ] }, as: :json
    sc = json.dig(:data, :scenarios, 0)
    perform_enqueued_jobs { post run_api_v1_feasibility_scenario_path(sc[:id]) }
    expect(response).to have_http_status(:accepted)

    get api_v1_feasibility_study_path(study[:id])
    sc = json.dig(:data, :scenarios, 0)
    expect(sc).to include(status: "done", stale: false)
    expect(sc.dig(:result, :need)).to eq(14)
    expect(sc.dig(:result, :served)).to eq(14)
    expect(sc[:cost]).to include(buses: 1, runs: 2, total: "7200.0", served: 14, break_even: "514.29", target_fare: "734.69", missing: [])
    expect(sc.dig(:fares, :tiers).map { |t| [ t[:n], t[:n2], t[:n1] ] }).to eq([ [ 12, 8, 4 ], [ 2, 0, 2 ] ])

    post use_suggested_fares_api_v1_feasibility_scenario_path(sc[:id])
    expect(json.dig(:data, :fare_tiers).first[:fare].to_d).to be > 150

    post copy_api_v1_feasibility_study_path(study[:id]) # Copy: everything but the results
    copy = json[:data]
    expect(copy).to include(name: "Siglap Primary bid copy")
    expect(copy[:rows].size).to eq(3)
    expect(copy[:scenarios].sole).to include(status: "idle", result: nil)

    row = json.dig(:data, :rows, 0, :id)
    delete row_api_v1_feasibility_study_path(copy[:id], row)
    expect(json.dig(:data, :rows).size).to eq(2)

    post rows_api_v1_feasibility_study_path(study[:id]), params: { text: "460102" }
    expect(json.dig(:data, :scenarios, 0, :stale)).to be(true)
  end

  describe "checks, stale, geocoding and planning details (API-ISSUES §23, Q4)" do
    def make_study(text: "460101, 6\n460102,4,AM")
      post api_v1_feasibility_studies_path, params: { study: { name: "Siglap bid", school_mode: "prospect", prospect_name: "Siglap Primary", prospect_postal: "455789" } }
      id = json.dig(:data, :id)
      post rows_api_v1_feasibility_study_path(id), params: { text: } if text
      json[:data]
    end

    def run_scenario(sc_id)
      perform_enqueued_jobs { post run_api_v1_feasibility_scenario_path(sc_id) }
    end

    def scenario(study_id, i = 0)
      get api_v1_feasibility_study_path(study_id)
      json.dig(:data, :scenarios, i)
    end

    it "starts a new study with default bus prices, unless prices are sent" do
      study = make_study(text: nil)
      expect(study[:bus_prices].map { [ it[:bus_type], it[:monthly], it[:attendant] ] }).to include([ "MEDIUM_23", "3600.0", "450.0" ], [ "LARGE_45", "5200.0", "900.0" ])
      expect(study[:bus_prices].size).to eq(5)

      post api_v1_feasibility_studies_path, params: { study: { name: "Own prices", prospect_postal: "455789" }, bus_prices: [ { bus_type: "MEDIUM_23", monthly: 3000 } ] }, as: :json
      expect(json.dig(:data, :bus_prices).size).to eq(1)
    end

    it "sends the school's address and when the scenario ran" do
      study = make_study
      expect(study[:place]).to include(address: "20 Siglap View")
      expect(study[:ran_at]).to be_nil

      run_scenario(study.dig(:scenarios, 0, :id))
      sc = scenario(study[:id])
      expect(Time.zone.parse(sc[:ran_at])).to eq(Time.zone.local(2026, 11, 2, 9, 0))
      expect(json.dig(:data, :ran_at)).to eq(sc[:ran_at])

      school = ActsAsTenant.with_tenant(company) { School.create!(name: "Existing Primary", short_name: "EP", postal: "455789", lat: 1.31, lng: 103.9, address: "1 School Road") }
      post api_v1_feasibility_studies_path, params: { study: { name: "Existing", school_mode: "existing", school_id: school.id } }
      expect(json.dig(:data, :place)).to include(name: "Existing Primary", address: "1 School Road")
    end

    it "checks the postal code and name together before asking OneMap" do
      post api_v1_feasibility_studies_path, params: { study: { name: "", school_mode: "prospect", prospect_postal: "99" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :details)).to include(:name, :prospect_postal)
      expect(fake_one_map.searches).to be_empty

      post api_v1_feasibility_studies_path, params: { study: { name: "Nowhere", school_mode: "prospect", prospect_postal: "999999" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Postal code not found on OneMap")
      expect(ActsAsTenant.with_tenant(company) { FeasibilityStudy.where(name: "Nowhere").count }).to eq(0)
    end

    it "clears the place when the prospect's postal code is cleared" do
      study = make_study(text: nil)
      patch api_v1_feasibility_study_path(study[:id]), params: { study: { prospect_postal: "" } }
      expect(json[:data]).to include(place: nil)
    end

    it "refuses a scenario with caps of 0, text or unknown sizes, and parameters it does not know" do
      study = make_study(text: nil)
      sc_id = study.dig(:scenarios, 0, :id)
      [ { hard_cap: 0 }, { target_cap: "abc" }, { hard_cap: -5 }, { sizes: %w[JUMBO_99] }, { params: { ants: 50 } }, { params: { headroom: 2 } },
        { params: { amTarget: "7pm" } }, { params: { effort: "ultra" } } ].each do |bad|
        patch api_v1_feasibility_scenario_path(sc_id), params: { scenario: bad }, as: :json
        expect(response).to have_http_status(:unprocessable_content), bad.inspect
      end
      expect(FeasibilityScenario.find(sc_id)).to have_attributes(hard_cap: 75, target_cap: 50)

      patch api_v1_feasibility_scenario_path(sc_id), params: { scenario: { hard_cap: "80", params: { headroom: "0.2", amTarget: "6:45", baseDwell: "" } } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json.dig(:data, :scenarios, 0)).to include(hard_cap: 80, params: { headroom: 0.2, amTarget: "06:45" })
    end

    it "answers 422 before starting a run that cannot work" do
      study = make_study(text: nil)
      sc_id = study.dig(:scenarios, 0, :id)
      post run_api_v1_feasibility_scenario_path(sc_id)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Add student postal codes first")

      post rows_api_v1_feasibility_study_path(study[:id]), params: { text: "460101" }
      patch api_v1_feasibility_scenario_path(sc_id), params: { scenario: { sizes: [] } }, as: :json
      post run_api_v1_feasibility_scenario_path(sc_id)
      expect(json.dig(:error, :message)).to eq("Pick at least one bus size")

      study2 = make_study(text: "460101")
      study2_sc = study2.dig(:scenarios, 0, :id)
      patch api_v1_feasibility_study_path(study2[:id]), params: { study: { school_mode: "existing", school_id: nil } }
      post run_api_v1_feasibility_scenario_path(study2_sc)
      expect(json.dig(:error, :message)).to eq("Set the school location first")
      expect(FeasibilityScenario.where(status: "running")).to be_empty
      expect(enqueued_jobs.map { it["job_class"] }).not_to include("FeasibilityRunJob")
    end

    it "marks results stale as the prototype does" do
      study = make_study
      id = study[:id]
      sc_id = study.dig(:scenarios, 0, :id)
      run_scenario(sc_id)
      expect(scenario(id)).to include(stale: false)

      patch api_v1_feasibility_study_path(id), params: { study: { name: "Renamed" }, bus_prices: [ { bus_type: "MEDIUM_23", monthly: 3000 } ] }, as: :json
      patch api_v1_feasibility_scenario_path(sc_id), params: { scenario: { name: "Renamed", margin_pct: 20, extra_buses: { AM: { SMALL_13: 1 } } } }, as: :json
      expect(scenario(id)).to include(stale: false) # prices, margin, buffer buses and names only change the cost

      patch api_v1_feasibility_study_path(id), params: { study: { prospect_postal: "455789", walk_m: 600 } }
      expect(scenario(id)).to include(stale: true)

      patch api_v1_feasibility_scenario_path(sc_id), params: { scenario: { name: "Still stale" } }, as: :json
      expect(scenario(id)).to include(stale: true) # a scenario edit never makes a stale result fresh

      run_scenario(sc_id)
      expect(scenario(id)).to include(stale: false)
      patch api_v1_feasibility_scenario_path(sc_id), params: { scenario: { params: { headroom: 0.3 } } }, as: :json
      expect(scenario(id)).to include(stale: true)

      run_scenario(sc_id)
      fake_one_map.add("560200", 1.37, 103.85)
      patch api_v1_feasibility_study_path(id), params: { study: { prospect_postal: "560200" } }
      expect(scenario(id)).to include(stale: true) # the school moved

      run_scenario(sc_id)
      delete rows_api_v1_feasibility_study_path(id)
      expect(scenario(id)).to include(stale: true)
    end

    it "finds each postal code in the background and again on Check Again" do
      study = make_study(text: nil)
      fake_one_map.down = true
      post rows_api_v1_feasibility_study_path(study[:id]), params: { text: "460101\n460102\n999990" }
      study = json[:data]
      expect(study[:rows].map { it[:status] }).to eq(%w[pending pending pending])
      expect(study[:geocode]).to eq(postals: 3, pending: 3, not_found: 0)

      stub_const("Feasibility::Geocode::RETRY_DELAYS", [])
      perform_enqueued_jobs(only: FeasibilityGeocodeJob)
      get api_v1_feasibility_study_path(study[:id])
      expect(json.dig(:data, :geocode)).to include(pending: 3) # OneMap was down: nothing is stored

      fake_one_map.down = false
      perform_enqueued_jobs { post geocode_api_v1_feasibility_study_path(study[:id]) }
      expect(response).to have_http_status(:accepted)
      get api_v1_feasibility_study_path(study[:id])
      rows = json.dig(:data, :rows).index_by { it[:postal] }
      expect(rows["460101"]).to include(status: "found", address: "Blk 460101", lat: 1.324, lng: 103.93)
      expect(rows["999990"]).to include(status: "not_found", address: nil, lat: nil)
      expect(json.dig(:data, :geocode)).to eq(postals: 3, pending: 0, not_found: 1)
      expect(json.dig(:data, :fare_tiers)).to eq([])
    end

    it "stops asking OneMap after codes in a row could not be answered" do
      study = make_study(text: nil)
      fake_one_map.down = true
      allow(fake_one_map).to receive(:search).and_call_original
      post rows_api_v1_feasibility_study_path(study[:id]), params: { text: (460100..460109).map(&:to_s).join("\n") }
      stub_const("Feasibility::Geocode::RETRY_DELAYS", [])
      perform_enqueued_jobs(only: FeasibilityGeocodeJob)
      expect(fake_one_map).to have_received(:search).exactly(Feasibility::Geocode::GIVE_UP_AFTER).times
      ActsAsTenant.with_tenant(company) do
        expect(Feasibility::Geocode.call(FeasibilityStudy.find(study[:id]))[:unreachable].size).to eq(10)
      end
    end

    it "fails the run with a Check Again message when OneMap cannot be reached" do
      study = make_study(text: "460101")
      fake_one_map.down = true
      stub_const("Feasibility::Geocode::RETRY_DELAYS", [])
      run_scenario(study.dig(:scenarios, 0, :id))
      expect(scenario(study[:id])).to include(status: "failed", error: "1 postal code could not be checked on OneMap. Use Check Again, then run")
    end

    it "plans with the scenario's Seat Buffer and time windows, and keeps road, riders and the run time" do
      meta = { "defaults" => { "types" => [ { "type" => "MEDIUM_23", "headroom" => 0.1 }, { "type" => "SMALL_13", "headroom" => 0.05 } ] }, "types" => [] }
      allow(fake_routing).to receive(:meta).and_return(meta)
      study = make_study(text: "460101, 3\n460102, 2\n999990, 2")
      sc_id = study.dig(:scenarios, 0, :id)
      patch api_v1_feasibility_scenario_path(sc_id), params: { scenario: { sizes: %w[MEDIUM_23], params: { headroom: 0.25, amTarget: "07:00", pmTarget: "14:00" } } }, as: :json
      run_scenario(sc_id)

      am = fake_routing.inputs.find { it.dig("params", "session") == "AM" }["params"]
      expect(am["types"]).to eq([ { "type" => "MEDIUM_23", "headroom" => 0.25, "on" => true }, { "type" => "SMALL_13", "headroom" => 0.25, "on" => false } ])
      expect(am).to include("amWin" => %w[06:55 07:10], "pmWin" => %w[13:45 14:00], "amTarget" => "07:00", "headroom" => 0.25)

      result = scenario(study[:id])[:result]
      expect(result.dig(:AM, :road)).to be(true)
      expect(result.dig(:AM, :unassigned)).to eq([ { n: 1, reason: "RIDER_NO_STOP", label: "999990", riders: [ "fz6" ] },
                                                    { n: 1, reason: "RIDER_NO_STOP", label: "999990", riders: [ "fz7" ] } ])
    end

    it "uses the company's own bus types when it has saved them" do
      allow(fake_routing).to receive(:meta).and_return({ "defaults" => { "types" => [ { "type" => "MEDIUM_23" } ] }, "types" => [] })
      ActsAsTenant.with_tenant(company) { RoutingSetting.create!(params: { "types" => [ { "type" => "LARGE_45", "fixed" => 120 } ] }) }
      study = make_study(text: "460101")
      patch api_v1_feasibility_scenario_path(study.dig(:scenarios, 0, :id)), params: { scenario: { sizes: %w[LARGE_45] } }, as: :json
      run_scenario(study.dig(:scenarios, 0, :id))
      expect(fake_routing.inputs.first.dig("params", "types")).to eq([ { "type" => "LARGE_45", "fixed" => 120, "on" => true } ])
    end
  end
end
