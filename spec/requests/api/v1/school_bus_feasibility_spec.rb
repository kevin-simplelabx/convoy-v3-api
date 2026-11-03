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

    post rows_api_v1_feasibility_study_path(study[:id]), params: { text: "460102" }
    expect(json.dig(:data, :scenarios, 0, :stale)).to be(true)
  end
end
