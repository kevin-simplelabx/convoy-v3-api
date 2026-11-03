require "rails_helper"

# School Bus › Stop Library: stops and PUDO points (checks, Stop ID from the URA subzone, letters), confirmation before
# changing a stop other schools use, archive, Nearby, and library membership (school-only, pending, approve).
RSpec.describe "School Bus stop library" do
  let(:company) { create(:company) }
  let!(:f) do
    UraSubzone.create!(code: "BDSZ03", name: "Bedok North", planning_area: "Bedok", planning_area_code: "BD", region: "East Region",
                       rings: [ [ [ 1.32, 103.92 ], [ 1.32, 103.94 ], [ 1.34, 103.94 ], [ 1.34, 103.92 ] ] ], min_lat: 1.32, max_lat: 1.34, min_lng: 103.92, max_lng: 103.94)
    within_tenant(company) do
      { sss: School.create!(name: "St. Stephen's School"), opera: School.create!(name: "Opera Estate Primary") }
    end
  end
  let(:points) do
    [ { usage: "pickup", sizes: %w[S M], lat: 1.3301, lng: 103.9301, primary: true, description: "Bus bay outside Blk 101" },
      { usage: "dropoff", sizes: %w[L], lat: 1.3305, lng: 103.9305 } ]
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  it "adds a library stop named after its subzone, checks it, and asks before changing a stop other schools use" do
    post api_v1_stops_path, params: { stop: { name: "", points: } }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter a stop name")
    post api_v1_stops_path, params: { stop: { name: "Blk 101", points: [ points.first.merge(sizes: []) ] } }, as: :json
    expect(json.dig(:error, :message)).to eq("Point A needs at least one bus size")
    post api_v1_stops_path, params: { stop: { name: "Far", points: [ points.first.merge(lat: 1.40) ] } }, as: :json
    expect(json.dig(:error, :message)).to eq("No URA subzone found for Point A. Move it inside Singapore")

    post api_v1_stops_path, params: { stop: { name: "Blk 101 Bedok North", points: } }, as: :json
    expect(response).to have_http_status(:created)
    stop = json[:data]
    expect(stop).to include(code: "BDSZ03-0001", library_status: "approved", subzone: { code: "BDSZ03", name: "Bedok North", planning_area: "Bedok" })
    expect(stop[:points].map { |p| [ p[:suffix], p[:pudo_code], p[:primary] ] }).to eq([ [ "A", "BDSZ03-0001A", true ], [ "B", "BDSZ03-0001B", false ] ])
    expect(stop[:coverage_warnings]).to eq([ "No point serves Large buses for pick-up", "No point serves Small or Medium buses for drop-off" ])

    post api_v1_stops_path, params: { stop: { name: "Blk 216", points: } }, as: :json
    expect(json.dig(:data, :code)).to eq("BDSZ03-0002")

    within_tenant(company) { SchoolStop.create!(school: f[:opera], stop_id: stop[:id]) }
    a, b = stop[:points]
    patch api_v1_stop_path(stop[:id]), params: { stop: { name: "Blk 101", points: [ { id: a[:id], usage: "both", sizes: %w[S M L], lat: 1.3302, lng: 103.9302 } ] },
                                                 school_id: f[:sss].id }, as: :json
    expect(json[:error]).to include(code: "confirm_required", details: { schools: [ { id: f[:opera].id, name: "Opera Estate Primary", riders: 0 } ] })
    patch api_v1_stop_path(stop[:id]), params: { stop: { name: "Blk 101", points: [ { id: a[:id], usage: "both", sizes: %w[S M L], lat: 1.3302, lng: 103.9302 } ] },
                                                 school_id: f[:sss].id, confirmed: true }, as: :json
    expect(json.dig(:data, :points).map { |p| p[:suffix] }).to eq(%w[A])
    expect(json.dig(:data, :schools)).to eq([ { id: f[:opera].id, name: "Opera Estate Primary", riders: 0 } ])
    expect(f[:opera].reload.stops_changed_at).to be_present

    patch api_v1_stop_path(stop[:id]), params: { stop: { name: "Blk 101", points: [ { id: a[:id], usage: "both", sizes: %w[S], lat: 1.3302, lng: 103.9302 }, points.last ] },
                                                 confirmed: true }, as: :json
    expect(json.dig(:data, :points).map { |p| p[:suffix] }).to eq(%w[A C]) # B is retired, not used again

    get nearby_api_v1_stops_path, params: { lat: 1.3303, lng: 103.9303, school_id: f[:sss].id }
    expect(json[:data].map { |s| s[:code] }).to eq(%w[BDSZ03-0001 BDSZ03-0002])
    expect(json.dig(:data, 0, :metres)).to be < 50

    delete api_v1_stop_path(stop[:id])
    expect(json.dig(:error, :message)).to eq("Unlink BDSZ03-0001 from every school first")
    get api_v1_stops_path, params: { q: "0001c" }
    expect(json[:data].map { |s| s[:code] }).to eq(%w[BDSZ03-0001])
  end

  it "keeps a stop made at a school for that school until the library takes it" do
    post api_v1_stops_path, params: { stop: { name: "Gate B", points: }, school_id: f[:sss].id, in_library: false }, as: :json
    stop = json[:data]
    expect(stop).to include(library_status: "school", owner_school: { id: f[:sss].id, name: "St. Stephen's School" }, linked: true)

    get api_v1_stops_path, params: { school_id: f[:opera].id }
    expect(json[:data]).to be_empty

    post library_api_v1_stop_path(stop[:id]), params: { school_id: f[:sss].id }
    expect(json[:data]).to include(library_status: "pending", requested_by: be_present)
    post review_api_v1_stop_path(stop[:id]), params: { status: "approved" }
    expect(response).to have_http_status(:forbidden)

    sign_in_as(create(:user, company:, permissions: %w[plans library]))
    get requests_api_v1_stops_path
    expect(json[:data].map { |s| s[:code] }).to eq([ stop[:code] ])
    post review_api_v1_stop_path(stop[:id]), params: { status: "approved" }
    expect(json[:data]).to include(library_status: "approved")
    get api_v1_stops_path, params: { school_id: f[:opera].id, not_linked: 1 }
    expect(json[:data].map { |s| s[:code] }).to eq([ stop[:code] ])
  end
end
