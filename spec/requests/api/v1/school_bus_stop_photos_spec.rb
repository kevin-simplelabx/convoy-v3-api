require "rails_helper"

# School Bus › Stop Library › photo requests: Ask for Photos (one open request per point), accept a photo from the app
# (becomes the point's photo, credited, Street View kept), reject, close, and automatic requests.
RSpec.describe "School Bus stop photo requests" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      stop = Stop.new(code: "BDSZ03-0001", subzone_code: "BDSZ03", name: "Blk 101")
      stop.all_points.build(suffix: "A", usage: "both", sizes: %w[S], primary: true, lat: 1.33, lng: 103.93)
      stop.all_points.build(suffix: "B", usage: "both", sizes: %w[S], lat: 1.331, lng: 103.931)
      stop.save!
      SchoolStop.create!(school:, stop:)
      { stop:, a: stop.points.first, b: stop.points.second }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  it "asks for photos, accepts one as the point's photo, rejects another and closes the request" do
    post api_v1_stop_photo_requests_path, params: { stop_point_id: f[:a].id, audience: "parents", max_submissions: 20 }
    req = json[:data]
    expect(req).to include(pudo_code: "BDSZ03-0001A", audience: "parents", max_submissions: 12, status: "open", live: 0)
    post api_v1_stop_photo_requests_path, params: { stop_point_id: f[:a].id, audience: "driver" }
    expect(json.dig(:error, :message)).to eq("BDSZ03-0001A already has an open photo request")

    subs = within_tenant(company) do
      r = StopPhotoRequest.find(req[:id])
      [ [ "Mrs Tan", "parent", "https://maps.app.goo.gl/abc" ], [ "Kumar", "driver", nil ] ].map do |name, role, sv|
        r.submissions.create!(submitted_by_name: name, role:, street_view_url: sv, submitted_at: Time.current,
                              photo: Rack::Test::UploadedFile.new(file_fixture("photo.png"), "image/png"))
      end
    end
    get api_v1_stop_photo_requests_path
    expect(json[:meta]).to include(pending_photos: 2, auto: { driver: false, parent: false })
    expect(json.dig(:data, 0, :submissions).map { |s| s[:by] }).to eq([ "Mrs Tan", "Kumar" ])

    post accept_submission_api_v1_stop_photo_requests_path(id: subs.first.id), params: { annotations: [ { x1: 1, y1: 2, x2: 3, y2: 4, color: "#FF3D17" } ].to_json }
    expect(json[:data]).to include(photo_credit: "Mrs Tan (parent)", street_view_url: "https://maps.app.goo.gl/abc")
    expect(json.dig(:data, :photo, :url)).to be_present
    expect(json.dig(:data, :photo_annotations, 0)).to include(color: "#FF3D17")

    post reject_submission_api_v1_stop_photo_requests_path(id: subs.second.id)
    get api_v1_stop_photo_requests_path
    expect(json.dig(:data, 0, :submissions).map { |s| s[:status] }).to eq(%w[accepted rejected])
    expect(json.dig(:data, 0, :live)).to eq(1)

    delete api_v1_stop_photo_request_path(req[:id])
    get api_v1_stop_photo_requests_path
    expect(json[:data]).to be_empty
  end

  it "opens automatic requests for points with no photo and removes unanswered ones when turned off" do
    put auto_api_v1_stop_photo_requests_path, params: { driver: true, parent: true }
    expect(json[:data]).to include(driver: true, parent: true, changed: 2)
    get api_v1_stop_photo_requests_path
    expect(json[:data].map { |r| [ r[:pudo_code], r[:audience], r[:auto] ] }).to contain_exactly([ "BDSZ03-0001A", "both", true ], [ "BDSZ03-0001B", "both", true ])

    put auto_api_v1_stop_photo_requests_path, params: { driver: true, parent: false }
    expect(json.dig(:data, :changed)).to eq(2)
    put auto_api_v1_stop_photo_requests_path, params: { driver: false, parent: false }
    get api_v1_stop_photo_requests_path
    expect(json[:data]).to be_empty
  end
end
