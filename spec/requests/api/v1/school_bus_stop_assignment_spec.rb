require "rails_helper"

# School Bus › Stop Assignment: a school's catchments (postal codes, areas with an exclude area, points off), riders'
# PUDO points (catchment, hand links, cut-offs) with none / one / conflict, Import from Another School, Unlink.
RSpec.describe "School Bus stop assignment" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      sss = School.create!(name: "St. Stephen's School")
      opera = School.create!(name: "Opera Estate Primary")
      mk = lambda do |code, lat|
        stop = Stop.new(code:, subzone_code: "BDSZ03", name: code)
        stop.all_points.build(suffix: "A", usage: "pickup", sizes: %w[S M L], primary: true, lat:, lng: 103.93)
        stop.all_points.build(suffix: "B", usage: "dropoff", sizes: %w[S M L], lat:, lng: 103.9302)
        stop.tap(&:save!)
      end
      s1 = mk.("BDSZ03-0001", 1.3301)
      s2 = mk.("BDSZ03-0002", 1.3341)
      riders = [ [ "R1", "460101", 1.3300, 103.9300 ], [ "R2", "460216", 1.3340, 103.9340 ], [ "R3", "460300", 1.3500, 103.9500 ], [ "R4", "460101", 1.3301, 103.9301 ] ]
                 .map { |rid, postal, lat, lng| sss.riders.create!(rid:, name: "Rider #{rid}", postal:, lat:, lng:, source: "manual") }
      { sss:, opera:, s1:, s2:, riders: }
    end
  end
  let(:sss) { f[:sss] }
  let(:square) { [ [ 1.333, 103.933 ], [ 1.333, 103.936 ], [ 1.336, 103.936 ], [ 1.336, 103.933 ] ] }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  def assignment = get(api_v1_school_stop_assignment_path(sss)).then { json[:data].index_by { |r| r[:rid] } }

  it "links stops with catchments and works out each rider's PUDO points" do
    put api_v1_school_stop_path(sss, f[:s1]), params: { postal_codes: "460101, 46010, 460216" }, as: :json
    expect(json[:meta]).to include(invalid: [ "46010" ], shared: [])
    expect(json[:data]).to include(postal_codes: %w[460101 460216], riders: 3)

    put api_v1_school_stop_path(sss, f[:s2]), params: { postal_codes: [ "460216" ], areas: [ { name: "Blk 2xx", latlngs: square } ] }, as: :json
    expect(json[:meta][:shared]).to eq([ { postal: "460216", stop_code: "BDSZ03-0001" } ])

    a = assignment
    expect(a["R1"]).to include(status: "one")
    expect(a["R1"][:candidates].map { |c| [ c[:pudo_code], c[:how] ] }).to eq([ %w[BDSZ03-0001A postal], %w[BDSZ03-0001B postal] ])
    expect(a["R2"][:status]).to eq("conflict")
    expect(a["R3"]).to include(status: "none", candidates: [])
    expect(json.dig(:meta, :counts)).to eq(riders: 4, with_pudo: 3, conflicts: 1, no_stop: 1, assigned: 0, notified: 0)

    # Exclude area cuts R2 out of stop 2's drawn area; turn off point B of stop 1 for this school
    put api_v1_school_stop_path(sss, f[:s2]), params: { postal_codes: [], areas: [ { latlngs: square }, { latlngs: square, exclude: true } ] }, as: :json
    put api_v1_school_stop_path(sss, f[:s1]), params: { off_point_ids: [ f[:s1].points.second.id ] }, as: :json
    a = assignment
    expect(a["R2"]).to include(status: "one")
    expect(a["R2"][:candidates].map { |c| c[:pudo_code] }).to eq(%w[BDSZ03-0001A])

    # Hand links: R3 may use stop 2 point A; R1 is cut off from stop 1 point A
    post api_v1_school_rider_links_path(sss), params: { stop_point_id: f[:s2].points.first.id, rids: %w[R3] }
    post api_v1_school_remove_rider_links_path(sss), params: { links: [ { rid: "R1", point_id: f[:s1].points.first.id } ] }, as: :json
    a = assignment
    expect(a["R3"][:candidates]).to contain_exactly(hash_including(pudo_code: "BDSZ03-0002A", how: "manual"))
    expect(a["R1"]).to include(status: "none", cut_point_ids: [ f[:s1].points.first.id ]) # linking it again restores it
    expect(a["R4"][:candidates].map { |c| c[:pudo_code] }).to eq(%w[BDSZ03-0001A])

    get api_v1_school_stops_path(sss)
    expect(json[:data].map { |r| [ r.dig(:stop, :code), r[:riders] ] }).to eq([ [ "BDSZ03-0001", 3 ], [ "BDSZ03-0002", 0 ] ])
    expect(json.dig(:meta, :counts)).to eq(school_stops: 2, needs_attention: 0)
    expect(json.dig(:meta, :stops_changed_at)).to be_present
  end

  it "imports another school's stops, with or without their catchments, and unlinks a stop" do
    within_tenant(company) do
      SchoolStop.create!(school: f[:opera], stop: f[:s1], postal_codes: %w[460101])
      SchoolStop.create!(school: f[:opera], stop: f[:s2])
    end
    post import_api_v1_school_stops_path(sss), params: { from_school_id: f[:opera].id, with_catchments: true }
    expect(json[:data]).to eq(added: 2)
    get api_v1_school_stops_path(sss)
    expect(json[:data].map { |r| r[:postal_codes] }).to eq([ %w[460101], [] ])

    post api_v1_school_rider_links_path(sss), params: { stop_point_id: f[:s1].points.first.id, postals: %w[460300] }
    delete api_v1_school_stop_path(sss, f[:s1])
    expect(json[:data]).to eq(unassigned: 0)
    expect(within_tenant(company) { sss.rider_point_links.count }).to eq(0)
  end

  it "removes a rider link for a whole postal code and unassigns every rider of that code" do
    within_tenant(company) do
      sss.riders.where(rid: "R1").update_all(postal: "460101")
      sss.rider_assignments.create!(rid: "R1", stop_point: f[:s1].points.first)
      sss.rider_assignments.create!(rid: "R2", stop_point: f[:s1].points.first)
    end
    post api_v1_school_remove_rider_links_path(sss), params: { links: [ { postal: "460101", point_id: f[:s1].points.first.id } ] }, as: :json
    expect(json[:data]).to eq(unassigned: 1)
    expect(within_tenant(company) { sss.rider_point_links.pluck(:kind, :postal) }).to eq([ %w[disconnected 460101] ])
    post api_v1_school_remove_rider_links_path(sss), params: { links: [ { point_id: f[:s1].points.first.id } ] }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "unassigns the riders of the stop's points when it is unlinked, and only those" do
    within_tenant(company) do
      [ f[:s1], f[:s2] ].each { |st| SchoolStop.create!(school: sss, stop: st, postal_codes: %w[460101]) }
      sss.rider_assignments.create!(rid: "R1", stop_point: f[:s1].points.first)
      sss.rider_assignments.create!(rid: "R4", stop_point: f[:s1].points.second)
      sss.rider_assignments.create!(rid: "R2", stop_point: f[:s2].points.first)
    end
    delete api_v1_school_stop_path(sss, f[:s1])
    expect(json[:data]).to eq(unassigned: 2)
    expect(within_tenant(company) { sss.rider_assignments.pluck(:rid) }).to eq(%w[R2])
    get api_v1_school_stop_assignment_path(sss)
    expect(json[:meta][:counts][:assigned]).to eq(1)
  end

  it "unassigns a rider when the link to the point they ride is removed" do
    point = f[:s1].points.first
    post api_v1_school_rider_links_path(sss), params: { stop_point_id: point.id, rids: %w[R3 R1] }
    within_tenant(company) do
      sss.rider_assignments.create!(rid: "R3", stop_point: point, manual: true)
      sss.rider_assignments.create!(rid: "R1", stop_point: f[:s1].points.second)
    end
    post api_v1_school_remove_rider_links_path(sss), params: { links: [ { rid: "R3", point_id: point.id }, { rid: "R1", point_id: point.id } ] }, as: :json
    expect(json[:data]).to eq(unassigned: 1)
    expect(within_tenant(company) { sss.rider_assignments.pluck(:rid) }).to eq(%w[R1])
  end

  it "shows the subzone in the school's stops and in the PUT answer, like the library" do
    put api_v1_school_stop_path(sss, f[:s1]), params: { postal_codes: %w[460101] }, as: :json
    expect(json.dig(:data, :stop)).to include(subzone_code: "BDSZ03")
    expect(json.dig(:data, :stop)).to have_key(:subzone)
    get api_v1_school_stops_path(sss)
    expect(json[:data].first[:stop]).to have_key(:subzone)
  end

  it "archives a stop, unassigning riders an earlier unlink left on its points" do
    within_tenant(company) { sss.rider_assignments.create!(rid: "R1", stop_point: f[:s2].points.first) }
    delete api_v1_stop_path(f[:s2])
    expect(json[:data]).to eq(unassigned: 1)
    expect(within_tenant(company) { [ sss.rider_assignments.count, Stop.discarded.count ] }).to eq([ 0, 1 ])

    within_tenant(company) { SchoolStop.create!(school: sss, stop: f[:s1]) }
    delete api_v1_stop_path(f[:s1])
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Unlink BDSZ03-0001 from every school first")
  end

  it "reads the Content-Disposition header across origins" do
    get api_v1_school_stops_path(sss), headers: { "Origin" => "http://localhost:3000" }
    expect(response.headers["Access-Control-Expose-Headers"]).to include("Content-Disposition")
  end
end
