require "rails_helper"

RSpec.describe "Notices page" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:) }
  let(:client) { within_tenant(company) { create(:client, name: "Google") } }
  let(:type) { within_tenant(company) { create(:vehicle_type) } }

  def trip(title)
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", title:, client_id: client.id, starts_on: "2026-11-02", start_time: "08:00", end_time: "09:00",
      stops_attributes: [ { position: 0, name: "A", use: "pu" }, { position: 1, name: "B", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: type.id, count: 1 } ]
    } }, as: :json
    expect(response).to have_http_status(:created), response.body
    json.dig(:data, :id)
  end

  def notice(trip_id, message, start: "now", starts_at: nil, ends_at: nil)
    post api_v1_notices_path, params: { notice: { trip_id:, to_riders: true, banner: true, message:, starts_at:, ends_at: },
                                        start:, period_minutes: (30 if start == "now") }, as: :json
    expect(response).to have_http_status(:created), response.body
    json[:data]
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 7, 0)
    sign_in_as(user)
  end

  it "shows the tabs with counts, searches the message and audience, and sorts each tab" do
    shuttle = trip("MBC Shuttle")
    airport = trip("Airport Run")
    active = notice(shuttle, "Running late")
    notice(airport, "Road closure", start: "at", starts_at: "2026-11-02T10:00", ends_at: "2026-11-02T11:00")
    notice(shuttle, "Heavy rain", start: "at", starts_at: "2026-11-02T08:00", ends_at: "2026-11-02T09:00")
    old = notice(airport, "Old news")
    patch end_now_api_v1_notice_path(old[:id]), as: :json

    get api_v1_notices_path, params: { state: "scheduled" }
    expect(json[:data].pluck(:message)).to eq([ "Heavy rain", "Road closure" ])
    expect(json[:meta][:counts]).to eq(active: 1, scheduled: 2, ended: 1)
    expect(json[:data].first).to include(client_name: "Google", trip_title: "MBC Shuttle", run_times: [], ended_by: nil)

    get api_v1_notices_path, params: { state: "ended" }
    expect(json[:data].first).to include(message: "Old news", ended_by: user.name)

    get api_v1_notices_path, params: { state: "scheduled", q: "airport" }
    expect(json[:data].pluck(:message)).to eq([ "Road closure" ])
    expect(json[:meta][:counts]).to eq(active: 0, scheduled: 1, ended: 1)
    get api_v1_notices_path, params: { q: "rain" }
    expect(json[:data].pluck(:message)).to eq([ "Heavy rain" ])

    delete api_v1_notice_path(active[:id])
    expect(json.dig(:error, :message)).to eq("An active notice can't be deleted. End it first")
    delete api_v1_notice_path(old[:id])
    expect(response).to have_http_status(:no_content)
    later = notice(shuttle, "Later", start: "at", starts_at: "2026-11-03T08:00", ends_at: "2026-11-03T09:00")
    patch end_now_api_v1_notice_path(later[:id]), as: :json
    expect(json.dig(:error, :message)).to eq("Only an active notice can be ended")
  end

  describe "templates" do
    it "adds, renames, rewrites and removes templates, keeping one" do
      post api_v1_notice_templates_path, as: :json
      first = json[:data]
      expect(first).to include(name: "New Template", message: "")
      post api_v1_notice_templates_path, as: :json
      second = json[:data]
      expect(second[:name]).to eq("New Template 2")

      patch api_v1_notice_template_path(first[:id]), params: { notice_template: { name: "Delay", message: "About {min} minutes late" } }, as: :json
      expect(json[:data]).to include(name: "Delay", message: "About {min} minutes late")
      patch api_v1_notice_template_path(second[:id]), params: { notice_template: { name: "Delay" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)

      shuttle = trip("MBC Shuttle")
      post api_v1_notices_path, params: { notice: { trip_id: shuttle, to_riders: true, banner: true, notice_template_id: second[:id], message: "Hi" },
                                          period_minutes: 15 }, as: :json
      delete api_v1_notice_template_path(second[:id])
      expect(response).to have_http_status(:no_content)
      expect(within_tenant(company) { Notice.last.notice_template_id }).to be_nil

      delete api_v1_notice_template_path(first[:id])
      expect(json.dig(:error, :message)).to eq("Keep at least one template")
      get api_v1_notice_templates_path
      expect(json[:data].pluck(:name)).to eq(%w[Delay])
    end
  end
end
