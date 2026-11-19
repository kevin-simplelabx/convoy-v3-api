require "rails_helper"

# Convoy Admin > Discover: Resume a paused placement (live or scheduled by its dates), Convoy Admin only.
RSpec.describe "Discover resume" do
  let(:operator) { create(:company, name: "SimpleDrive") }
  let(:advertiser) { DiscoverAdvertiser.create!(name: "Mandai Wildlife Group", kind: "attr", listing_fee: 800, commission_pct: 8) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, :convoy_admin))
  end

  def placement(**attrs)
    DiscoverPlacement.create!({ kind: "trip", title: "Mandai Zoo day trip", starts_on: Date.new(2026, 11, 1), ends_on: Date.new(2026, 12, 10),
                                audiences: %w[parents], advertiser:, price: 58, run_by_company_id: operator.id, status: "paused" }.merge(attrs))
  end

  it "takes a paused placement back to live, or scheduled when it starts later" do
    live = placement
    post api_v1_discover_placement_resume_path(live)
    expect(response).to have_http_status(:ok)
    expect(json[:data]).to include(id: live.id, state: "live")
    expect(live.reload.status).to eq("live")

    later = placement(title: "Night Safari", starts_on: Date.new(2026, 12, 1))
    post api_v1_discover_placement_resume_path(later)
    expect(json[:data]).to include(state: "scheduled")

    get api_v1_discover_placements_path, params: { tab: "live" }
    expect(json[:meta][:counts]).to eq(live: 1, scheduled: 1, draft: 0, ended: 0)
  end

  it "keeps an ended placement ended" do
    ended = placement(ended_at: 1.day.ago)
    post api_v1_discover_placement_resume_path(ended)
    expect(json[:data]).to include(state: "ended")
  end

  it "is for Convoy Admin only" do
    p = placement
    sign_in_as(create(:user, :admin, company: operator))
    post api_v1_discover_placement_resume_path(p)
    expect(response).to have_http_status(:forbidden)
    expect(p.reload.status).to eq("paused")
  end

  it "answers 404 for an unknown placement" do
    post api_v1_discover_placement_resume_path(0)
    expect(response).to have_http_status(:not_found)
  end
end
