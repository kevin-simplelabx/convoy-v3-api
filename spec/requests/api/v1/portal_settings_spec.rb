require "rails_helper"

# Client Portal › Settings: Users (who manages whom, roles and sites they may give, a Super Admin kept), Teams,
# Logo and Colour, Sites, Billing Details.
RSpec.describe "Client Portal settings" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:s) do
    within_tenant(company) do
      google = create(:client, name: "Google", uen: "200817984R", billing_address: "70 Pasir Panjang Road")
      tower_a = google.sites.create!(company_id: company.id, name: "Tower A")
      tower_b = google.sites.create!(company_id: company.id, name: "Tower B", own_billing: true, billing_name: "Google B Pte Ltd")
      google.billing_contacts.create!(company_id: company.id, name: "AP", email: "ap@google.com", send_as: "to", position: 0)
      google.billing_contacts.create!(company_id: company.id, name: "CFO", email: "cfo@google.com", send_as: "cc", position: 1)
      { google:, tower_a:, tower_b:,
        super: portal_user(google, email: "priya@google.com", role: "super"),
        admin: portal_user(google, email: "linh@google.com", role: "adm"),
        fin: portal_user(google, email: "ken@google.com", role: "fin"),
        sa_a: portal_user(google, email: "tan@google.com", role: "sa", sites: [ tower_a ]),
        sfin_b: portal_user(google, email: "bee@google.com", role: "sfin", sites: [ tower_b ]),
        member_a: portal_user(google, email: "mo@google.com", role: "member", sites: [ tower_a ]) }
    end
  end

  describe "Users" do
    it "lists who the viewer may see, with what they may do to each" do
      get api_v1_portal_users_path, headers: as(portal_token(s[:sa_a])), as: :json
      expect(json[:data].pluck(:email)).to eq(%w[mo@google.com tan@google.com])
      expect(json[:data].find { it[:me] }).to include(can_edit: true, can_remove: false)

      get api_v1_portal_users_path, headers: as(portal_token(s[:member_a])), as: :json
      expect(json[:data].pluck(:email)).to eq(%w[mo@google.com])

      get api_v1_portal_users_path, headers: as(portal_token(s[:admin])), as: :json
      expect(json[:data].size).to eq(6)
      expect(json[:data].find { it[:email] == "priya@google.com" }).to include(can_edit: false, can_remove: false)
    end

    it "adds people with roles and sites the manager may give" do
      token = portal_token(s[:sa_a])
      post api_v1_portal_users_path, params: { user: { name: "Ann", email: "ann@google.com", role: "ssa", site_ids: [ s[:tower_a].id ] } }, headers: as(token), as: :json
      expect(json.dig(:error, :message)).to eq("You cannot give this role")
      post api_v1_portal_users_path, params: { user: { name: "Ann", email: "ann@google.com", role: "member", site_ids: [ s[:tower_b].id ] } }, headers: as(token), as: :json
      expect(json.dig(:error, :message)).to eq("You can only give your own sites")
      post api_v1_portal_users_path, params: { user: { name: "Ann", email: "Ann@Google.com", role: "member", site_ids: [ s[:tower_a].id ] } }, headers: as(token), as: :json
      expect(response).to have_http_status(:created), json.inspect
      expect(json[:data]).to include(email: "ann@google.com", role: "member", signed_in: false, sites: [ { id: s[:tower_a].id, name: "Tower A" } ])
      within_tenant(company) { expect(ClientUser.find(json.dig(:data, :id)).created_by_client_user).to eq(s[:sa_a]) }

      post api_v1_portal_users_path, params: { user: { name: "X", email: "x@google.com", role: "member" } }, headers: as(portal_token(s[:member_a])), as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "changes only people the viewer manages and keeps a Super Admin" do
      token = portal_token(s[:admin])
      patch api_v1_portal_user_path(s[:super]), params: { user: { role: "adm" } }, headers: as(token), as: :json
      expect(response).to have_http_status(:forbidden)

      token = portal_token(s[:super])
      patch api_v1_portal_user_path(s[:super]), params: { user: { role: "adm" } }, headers: as(token), as: :json
      expect(json.dig(:error, :message)).to eq("Keep at least one Super Admin for Google")
      delete api_v1_portal_user_path(s[:super]), headers: as(token), as: :json
      expect(response).to have_http_status(:forbidden) # nobody removes themselves
    end

    it "sets team and manager, and removing a manager clears them" do
      token = portal_token(s[:admin])
      post api_v1_portal_teams_path, params: { team: { name: "Facilities", manager_id: s[:sa_a].id } }, headers: as(token), as: :json
      team_id = json.dig(:data, :id)
      patch api_v1_portal_user_path(s[:member_a]), params: { user: { team_id:, manager_id: s[:member_a].id } }, headers: as(token), as: :json
      expect(json.dig(:error, :details, :manager)).to eq([ "Manager can't be themselves" ])
      patch api_v1_portal_user_path(s[:member_a]), params: { user: { team_id:, manager_id: s[:fin].id } }, headers: as(token), as: :json
      expect(json[:data]).to include(team: { id: team_id, name: "Facilities" }, manager: { id: s[:fin].id, name: "Ken" })
      within_tenant(company) { expect(s[:member_a].reload.manager_for_approval).to eq(s[:fin]) }

      delete api_v1_portal_user_path(s[:fin]), headers: as(token), as: :json
      expect(response).to have_http_status(:no_content)
      delete api_v1_portal_user_path(s[:sa_a]), headers: as(token), as: :json
      within_tenant(company) do
        expect(s[:member_a].reload.manager).to be_nil
        expect(ClientTeam.find(team_id).manager).to be_nil
      end
    end
  end

  describe "Teams" do
    it "lets Super Admins and Admins keep teams; names are unique; removing one takes it off its people" do
      post api_v1_portal_teams_path, params: { team: { name: "Ops" } }, headers: as(portal_token(s[:sa_a])), as: :json
      expect(response).to have_http_status(:forbidden)

      token = portal_token(s[:admin])
      post api_v1_portal_teams_path, params: { team: { name: "Ops" } }, headers: as(token), as: :json
      id = json.dig(:data, :id)
      post api_v1_portal_teams_path, params: { team: { name: " ops " } }, headers: as(token), as: :json
      expect(json.dig(:error, :details, :name)).to eq([ "Name ops is already a team" ])
      patch api_v1_portal_user_path(s[:member_a]), params: { user: { team_id: id } }, headers: as(token), as: :json

      get api_v1_portal_teams_path, headers: as(portal_token(s[:member_a])), as: :json
      expect(json[:data]).to eq([ { id:, name: "Ops", manager: nil, people: 1 } ])

      delete api_v1_portal_team_path(id), headers: as(token), as: :json
      within_tenant(company) { expect(s[:member_a].reload.team).to be_nil }
    end
  end

  describe "Logo and Colour" do
    it "takes a PNG / JPG / WebP logo and a hex colour, shown in the shell" do
      token = portal_token(s[:admin])
      patch api_v1_portal_settings_brand_path, params: { logo: fixture_file_upload("logo.svg", "image/svg+xml") }, headers: as(token)
      expect(response).to have_http_status(:unprocessable_content)
      patch api_v1_portal_settings_brand_path, params: { color: "teal" }, headers: as(token), as: :json
      expect(json.dig(:error, :message)).to include("Enter the colour as a hex code like #004F59")

      patch api_v1_portal_settings_brand_path, params: { logo: fixture_file_upload("photo.png", "image/png"), color: "#004f59" }, headers: as(token)
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to include(color: "#004F59", logo: hash_including(content_type: "image/png"))
      expect(json.dig(:data, :logo_ratio)).to be_positive

      get api_v1_portal_me_path, headers: as(portal_token(s[:member_a])), as: :json
      expect(json.dig(:data, :client_user, :client, :brand, :color)).to eq("#004F59")

      patch api_v1_portal_settings_brand_path, params: { remove_logo: true, color: "" }, headers: as(token), as: :json
      expect(json[:data]).to eq(logo: nil, logo_ratio: nil, color: nil)
      patch api_v1_portal_settings_brand_path, params: { color: "#000000" }, headers: as(portal_token(s[:fin])), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "Sites and Billing Details" do
    it "shows the viewer's sites and who each is billed to" do
      get api_v1_portal_settings_sites_path, headers: as(portal_token(s[:sa_a])), as: :json
      expect(json[:data]).to contain_exactly(hash_including(name: "Tower A", billed_to: { name: "Google", uen: "200817984R", own: false }, shuttle_routes: 0))
    end

    it "lets billing roles edit the organisation (organisation-wide) and sites billed as their own entity" do
      get api_v1_portal_settings_billing_path, headers: as(portal_token(s[:sfin_b])), as: :json
      expect(json[:data].pluck(:kind, :site_name)).to eq([ [ "site", "Tower B" ] ])
      patch api_v1_portal_settings_organisation_billing_path, params: { billing: { legal_name: "X" } }, headers: as(portal_token(s[:sfin_b])), as: :json
      expect(response).to have_http_status(:forbidden)
      patch api_v1_portal_settings_site_billing_path(s[:tower_a]), params: { billing: { legal_name: "X" } }, headers: as(portal_token(s[:sfin_b])), as: :json
      expect(response).to have_http_status(:forbidden) # not billed as its own entity, not their site

      token = portal_token(s[:fin])
      get api_v1_portal_settings_billing_path, headers: as(token), as: :json
      expect(json.dig(:data, 0)).to include(kind: "organisation", legal_name: "Google", billing_email: "ap@google.com", attention: nil)

      patch api_v1_portal_settings_organisation_billing_path, headers: as(token), as: :json,
            params: { billing: { legal_name: "Google Asia Pacific Pte. Ltd.", uen: "12345", billing_email: "ap@google.com", billing_address: "70 PPR" } }
      expect(json.dig(:error, :message)).to eq("Check the UEN")
      patch api_v1_portal_settings_organisation_billing_path, headers: as(token), as: :json,
            params: { billing: { legal_name: "Google Asia Pacific Pte. Ltd.", uen: "200817984r", billing_email: "billing@google.com",
                                 attention: "Wei", billing_address: "70 Pasir Panjang Road" } }
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to include(legal_name: "Google Asia Pacific Pte. Ltd.", billing_email: "billing@google.com", attention: "Wei",
                                     changed: hash_including(by: "Ken", in_portal: true))
      within_tenant(company) do
        google = s[:google].reload
        expect(google.bill_name).to eq("Google Asia Pacific Pte. Ltd.")
        expect(google.name).to eq("Google")
        expect(google.billing_contacts.pluck(:email, :send_as, :attention, :name))
          .to eq([ [ "billing@google.com", "to", false, "AP" ], [ "cfo@google.com", "cc", false, "CFO" ], [ nil, "to", true, "Wei" ] ])
      end

      patch api_v1_portal_settings_site_billing_path(s[:tower_b]), headers: as(token), as: :json,
            params: { billing: { legal_name: "Google B Pte Ltd", billing_email: "b@google.com", billing_address: "1 Tower B" } }
      expect(json[:data]).to include(kind: "site", site_name: "Tower B", billing_email: "b@google.com")
    end
  end
end
