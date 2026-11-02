require "rails_helper"

# HR > Points (lots used oldest-expiring first, expiry only takes what is left) and Rewards.
RSpec.describe "HR points and rewards" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, name: "Marcus Lim", permissions: %w[finance]) }
  let!(:eric) { within_tenant(company) { create(:driver, name: "Eric Pang") } }

  before { sign_in_as(user) }

  def adjust(kind, points, reason = "Good conduct") = post(api_v1_pay_points_driver_path(eric), params: { kind:, points:, reason: }, as: :json)

  it "awards, deducts from the oldest lot, and expires only what is left" do
    travel_to Time.zone.local(2024, 11, 10, 9, 0) do
      sign_in_as(user)
      adjust("award", 100, "Old lot")
    end
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
    adjust("award", 50, "New lot")
    expect(json[:data]).to include(balance: 150, expiring_soon: 100)

    adjust("deduct", 120)
    expect(json[:data]).to include(balance: 30, used: 120)
    adjust("deduct", 31)
    expect(json.dig(:error, :message)).to eq("Eric Pang has only 30 points")

    travel_to Time.zone.local(2026, 11, 11, 9, 0) # the old lot (fully used) expired: nothing lost
    sign_in_as(user)
    get api_v1_pay_points_driver_path(eric)
    expect(json[:data]).to include(balance: 30, expired: 0, earned: 150)
    expect(json.dig(:data, :history).map { |h| [ h[:kind], h[:points], h[:status] ] })
      .to eq([ [ "deduct", -120, "used" ], [ "award", 50, "active" ], [ "award", 100, "used" ] ])

    get api_v1_pay_points_path
    expect(json[:data].first).to include(name: "Eric Pang", balance: 30)

    adjust("award", 0)
    expect(json.dig(:error, :message)).to eq("Enter the number of points")
  end

  it "keeps rewards with a photo" do
    post api_v1_pay_rewards_path, params: { reward: { title: "S$50 NTUC Voucher", points_required: 500, status: "active",
                                                      photo: fixture_file_upload("photo.png", "image/png") } }
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(title: "S$50 NTUC Voucher", points_required: 500, status: "active")
    expect(json.dig(:data, :photo, :thumb_url)).to be_present

    post api_v1_pay_rewards_path, params: { reward: { title: "", points_required: 0 } }, as: :json
    expect(json.dig(:error, :details).keys).to include(:title, :points_required)
  end
end
