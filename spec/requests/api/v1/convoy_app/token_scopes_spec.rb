require "rails_helper"

# A Convoy App token only opens /api/v1/app; Convoy OS, Client Portal and Driver tokens are refused there, and the app
# token is refused by each of them.
RSpec.describe "Convoy App token scope" do
  let(:company) { create(:company, name: "SimpleDrive") }

  it "is refused by Convoy OS, the Client Portal and the Driver app" do
    token = app_token(mobile: "9188 2045")
    [ api_v1_scheduler_path, api_v1_portal_session_path, api_v1_driver_app_session_path, api_v1_driver_app_profile_path ].each do |path|
      get path, headers: app_as(token)
      expect(response).to have_http_status(:unauthorized), path
    end
    get api_v1_convoy_app_session_path, headers: app_as(token)
    expect(response).to have_http_status(:ok)
  end

  it "refuses the tokens of the other apps" do
    admin = within_tenant(company) { create(:user, :admin, company:) }
    sign_in_as(admin)
    os_token = integration_session.bearer_token

    portal = within_tenant(company) { portal_user(create(:client, name: "Google"), email: "linh@google.com", role: "adm") }
    portal = portal_token(portal)

    within_tenant(company) { create(:driver, name: "Ahmad", phone: "+6591234567") }
    driver = driver_token("9123 4567")

    { "OS" => os_token, "Portal" => portal, "Driver" => driver }.each do |app, token|
      expect(token).to be_present, app
      get api_v1_convoy_app_session_path, headers: app_as(token)
      expect(response).to have_http_status(:unauthorized), app
      get api_v1_convoy_app_profile_path, headers: app_as(token)
      expect(response).to have_http_status(:unauthorized), app
    end
  end
end
