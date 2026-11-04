require "rails_helper"

# Convoy Admin > Discover: advertisers, placements (publish checks, state by date), pause / resume / end / duplicate, KPIs.
RSpec.describe "Discover" do
  let!(:operator) { create(:company, name: "SimpleDrive") }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, :convoy_admin))
  end

  def placement(**attrs)
    post api_v1_discover_placements_path, params: { placement: { kind: "trip", title: "Mandai Zoo day trip", starts_on: "2026-11-01", ends_on: "2026-12-10",
                                                                 audiences: %w[parents public] }.merge(attrs) }, as: :json
  end

  it "keeps advertisers and placements, and works out their state and money" do
    post api_v1_discover_advertisers_path, params: { advertiser: { name: "Mandai Wildlife Group", kind: "attr", listing_fee: 800, commission_pct: 8 } }, as: :json
    expect(json[:data]).to include(kind_label: "Attraction", live_count: 0)
    adv = json.dig(:data, :id)

    placement(status: "live")
    expect(json.dig(:error, :message)).to include("Pick the advertiser", "Enter the price", "Pick the transport company that runs the bus")
    placement(discover_advertiser_id: adv, price: 58, run_by_company_id: operator.id, status: "live")
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(state: "live", listing_fee: "800.0", commission_pct: "8.0", advertiser: hash_including(name: "Mandai Wildlife Group"))
    live = json.dig(:data, :id)
    DiscoverPlacement.find(live).update!(views: 1000, taps: 50, sold: 10)

    placement(discover_advertiser_id: adv, title: "Night Safari", starts_on: "2026-12-01", ends_on: "2026-12-31")
    expect(json[:data]).to include(state: "draft")
    patch api_v1_discover_placement_path(json.dig(:data, :id)), params: { placement: { status: "live", price: 40, run_by_company_id: operator.id } }, as: :json
    expect(json[:data]).to include(state: "scheduled")

    post api_v1_discover_placement_pause_path(live)
    expect(json[:data]).to include(state: "paused")
    get api_v1_discover_placements_path, params: { tab: "live" }
    expect(json[:meta][:counts]).to include(live: 1, scheduled: 1)
    expect(json[:meta][:kpis]).to include(live: 1, views: 1000, taps: 50, tap_rate: 5.0, sold: 10, commission: "46.4", revenue: "846.4")

    post api_v1_discover_placement_duplicate_path(live)
    expect(json[:data]).to include(title: "Mandai Zoo day trip (copy)", state: "draft", views: 0)
    post api_v1_discover_placement_end_path(live)
    expect(json[:data]).to include(state: "ended")
    delete api_v1_discover_placement_path(live)
    expect(json.dig(:error, :message)).to eq("Only drafts can be deleted. End it instead")
  end

  it "lets Convoy publish its own news without an advertiser" do
    placement(kind: "news", title: "Convoy is in Malaysia", status: "live", discover_advertiser_id: 99)
    expect(json[:data]).to include(kind_label: "From Convoy", advertiser: nil, state: "live")
  end

  it "reads empty multipart fields: terms from the advertiser on create, unchanged on edit, cleared prices" do
    adv = create_advertiser_via_form(listing_fee: "", commission_pct: "")
    expect(json[:data]).to include(listing_fee: "0.0", commission_pct: "0.0")
    patch api_v1_discover_advertiser_path(adv), params: { advertiser: { listing_fee: 800, commission_pct: 8 } }
    patch api_v1_discover_advertiser_path(adv), params: { advertiser: { listing_fee: "", commission_pct: "" } }
    expect(json[:data]).to include(listing_fee: "800.0", commission_pct: "8.0")

    empty = { listing_fee: "", commission_pct: "", price: "", child_price: "", seats: "" }
    post api_v1_discover_placements_path, params: { placement: { kind: "trip", title: "Zoo", starts_on: "2026-11-01", ends_on: "2026-12-10",
                                                                 discover_advertiser_id: adv, audiences: %w[parents] }.merge(empty) }
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(listing_fee: "800.0", commission_pct: "8.0", price: nil, child_price: nil, seats: nil)
    id = json.dig(:data, :id)

    patch api_v1_discover_placement_path(id), params: { placement: { listing_fee: 500, commission_pct: 5, price: 40 } }
    patch api_v1_discover_placement_path(id), params: { placement: empty }
    expect(json[:data]).to include(listing_fee: "500.0", commission_pct: "5.0", price: nil)

    other = create_advertiser_via_form(name: "Bird Paradise", listing_fee: 300, commission_pct: 3)
    patch api_v1_discover_placement_path(id), params: { placement: { discover_advertiser_id: other, listing_fee: "" } }
    expect(json[:data]).to include(listing_fee: "300.0", commission_pct: "3.0")

    patch api_v1_discover_placement_path(id), params: { placement: { commission_pct: 120 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Commission must be between 0 and 100%")

    patch api_v1_discover_placement_path(id), params: { placement: { cta: "", starts_on: "" } }
    expect(json.dig(:error, :message)).to eq("Pick the start and end dates")
    patch api_v1_discover_placement_path(id), params: { placement: { cta: "" } }
    expect(json[:data]).to include(cta: "Book Now")
  end

  def create_advertiser_via_form(**attrs)
    post api_v1_discover_advertisers_path, params: { advertiser: { name: "Mandai Wildlife Group", kind: "attr" }.merge(attrs) }
    json.dig(:data, :id)
  end
end
