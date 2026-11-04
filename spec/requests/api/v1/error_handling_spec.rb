require "rails_helper"

# A required column left empty that no validation catches answers 422 with the column, never 500.
RSpec.describe "Error handling: required columns" do
  before { sign_in_as(create(:user, :convoy_admin)) }

  it "turns a NOT NULL violation into a 422" do
    allow(DiscoverAdvertiser).to receive(:create!) { |attrs| DiscoverAdvertiser.new(attrs.merge(listing_fee: nil)).tap { it.save!(validate: false) } }
    post api_v1_discover_advertisers_path, params: { advertiser: { name: "Mandai", kind: "attr" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(json[:error]).to include(code: "invalid", message: "Listing fee can't be empty", details: { listing_fee: [ "can't be empty" ] })
  end
end
