require "rails_helper"

# Client Portal shell: the account must be picked, works in the client's company, and says what the person may do.
RSpec.describe "Client Portal shell" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:setup) do
    within_tenant(company) do
      google = create(:client, name: "Google")
      tower_a = google.sites.create!(company_id: company.id, name: "Tower A")
      google.sites.create!(company_id: company.id, name: "Tower B")
      { google:, tower_a:,
        admin: portal_user(google, email: "linh@google.com", role: "adm"),
        site_admin: portal_user(google, email: "tan@google.com", role: "sa", sites: [ tower_a ]) }
    end
  end

  it "asks to pick an organisation first (two accounts) and refuses Convoy OS tokens" do
    user = setup[:admin]
    within_tenant(company) { portal_user(create(:client, name: "Mapletree"), email: user.email, role: "member") }
    post api_v1_portal_session_path, params: { email: user.email, password: "Portal123!" }, as: :json
    token = json.dig(:data, :token)

    get api_v1_portal_me_path, headers: as(token), as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json[:error]).to include(code: "pick_account", message: "Pick an organisation first")

    staff = within_tenant(company) { create(:user, company:) }
    sign_in_as(staff)
    get api_v1_portal_me_path, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns the person, the organisation, their sites, what they may do and the rail" do
    token = portal_token(setup[:site_admin])
    get api_v1_portal_me_path, headers: as(token), as: :json
    expect(response).to have_http_status(:ok), json.inspect
    data = json[:data]
    expect(data[:account]).to include(email: "tan@google.com")
    expect(data[:client_user]).to include(role: "sa", role_label: "Site Admin", client: hash_including(name: "Google"))
    expect(data).to include(all_sites: false, sites: [ { id: setup[:tower_a].id, name: "Tower A" } ])
    expect(data[:can]).to include(book: true, approve: true, step_in: false, billing: false, brand: false)
    expect(data[:menu]).to eq(approvals: true, shuttles: false, school_buses: false, invoices: false)

    get api_v1_portal_me_path, headers: as(portal_token(setup[:admin])), as: :json
    expect(json[:data]).to include(all_sites: true)
    expect(json.dig(:data, :sites).pluck(:name)).to eq([ "Tower A", "Tower B" ])
    expect(json.dig(:data, :menu, :invoices)).to be(true)
  end

  it "stops a suspended company or a deleted client" do
    token = portal_token(setup[:admin])
    company.update!(status: "suspended")
    get api_v1_portal_me_path, headers: as(token), as: :json
    expect(json.dig(:error, :code)).to eq("pick_account")
    get api_v1_portal_session_path, headers: as(token), as: :json
    expect(json[:data]).to include(accounts: [], current: nil)

    company.update!(status: "active")
    within_tenant(company) { setup[:google].discard! }
    get api_v1_portal_me_path, headers: as(token), as: :json
    expect(json.dig(:error, :code)).to eq("pick_account")
  end

  it "lists the roles and the Role Permissions table" do
    get api_v1_portal_roles_path, headers: as(portal_token(setup[:site_admin])), as: :json
    expect(json.dig(:data, :roles).pluck(:key)).to eq(%w[super adm fin ssa sa sfin member])
    expect(json.dig(:data, :roles, 4)).to include(label: "Site Admin", wide: false, gives: %w[sa sfin member])
    expect(json.dig(:data, :features).pluck(:group)).to eq([ "Bookings", "Live Map and Shuttles", "Money", "Settings", "Notices" ])
    expect(json.dig(:data, :features, 0, :features, 0)).to include(name: "Make a booking", roles: %w[super adm ssa sa member])
  end
end
