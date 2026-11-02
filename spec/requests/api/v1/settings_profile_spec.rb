require "rails_helper"

# Profile dialog: picture, display name and mobile of the signed-in user; name and email stay as the Admin set them.
RSpec.describe "Profile" do
  let(:user) { create(:user, company: create(:company), name: "Rachel Tan", email: "rachel@example.com") }

  before { sign_in_as(user) }

  it "saves the display name, mobile and picture, and the session shows them" do
    patch api_v1_profile_path, params: { profile: { display_name: "  Rach  ", mobile: "9123 4567", name: "Hacker",
                                                    avatar: fixture_file_upload("photo.png", "image/png") } }
    expect(response).to have_http_status(:ok), json.inspect
    expect(json[:data]).to include(name: "Rachel Tan", email: "rachel@example.com", display_name: "Rach", shown_name: "Rach",
                                   mobile: "+6591234567", mobile_display: "+65 9123 4567", initials: "R")
    expect(json.dig(:data, :avatar, :thumb_url)).to start_with("/api/v1/downloads/")

    get api_v1_session_path
    expect(json.dig(:data, :user)).to include(shown_name: "Rach", role_label: "Viewer")

    patch api_v1_profile_path, params: { profile: { display_name: "", remove_avatar: true } }, as: :json
    expect(json[:data]).to include(display_name: nil, shown_name: "Rachel Tan", avatar: nil)
  end

  it "checks the mobile" do
    patch api_v1_profile_path, params: { profile: { mobile: "12" } }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :details)).to have_key(:mobile)
  end
end
