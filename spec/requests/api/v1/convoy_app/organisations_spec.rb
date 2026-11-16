require "rails_helper"

# Convoy App › Organisations: a verified work email is matched to a client's email domain (staff shuttle) or to a client
# user's email (booking link); the person answers Accept / Not Me; overdue work emails pause links; the office can remove.
RSpec.describe "Convoy App organisations" do
  let!(:company) { create(:company, name: "SimpleDrive") }
  let!(:google) { within_tenant(company) { create(:client, name: "Google Asia Pacific", email_domains: %w[google.com]) } }
  let!(:school) { within_tenant(company) { create(:client, name: "St. Stephen's School") } }
  let(:rachel) { app_user(mobile: "9188 2045") }
  let(:account) { rachel[0] }
  let(:token) { rachel[1] }

  def add_work(email = "rachel.tan@google.com", as: token)
    app_add_identity(as, kind: "email", value: email, tag: "work")
    expect(response).to have_http_status(:ok), json.inspect
  end

  def organisations(as: token)
    get api_v1_convoy_app_organisations_path, headers: app_as(as)
    json[:data]
  end

  def accept_path(kind, id) = "/api/v1/app/organisations/#{kind}/#{id}/accept"
  def decline_path(kind, id) = "/api/v1/app/organisations/#{kind}/#{id}/decline"

  describe "matching a work email" do
    it "invites the person to the client whose domain it is on, and says so when the code is verified" do
      add_work
      expect(json.dig(:data, :invitations)).to contain_exactly(
        a_hash_including(kind: "shuttle", status: "invited", state: "invited", organisation: "Google Asia Pacific", company: "SimpleDrive",
                         role: "Rider", matched_email: "rachel.tan@google.com", added_by: "Your employer")
      )
      rider = ActsAsTenant.without_tenant { ClientRider.sole }
      expect(rider).to have_attributes(client_id: google.id, app_account_id: account.id, company_id: company.id, status: "invited")
      expect(account.notifications.sole).to have_attributes(kind: "invite_employer", title: "Google Asia Pacific added you to its staff shuttle",
                                                            body: "Matched by your work email rachel.tan@google.com.", target: "organisations", target_id: rider.id)
    end

    it "finds nothing for a domain no client holds, and says nothing about whether the company is on Convoy" do
      add_work("rachel@unknown-co.com")
      expect(json.dig(:data, :invitations)).to eq([])
      expect(organisations).to include(invitations: [], links: [],
                                       unlinked: [ a_hash_including(email: "rachel@unknown-co.com", domain: "unknown-co.com", company_guess: "Unknown Co") ])
    end

    it "never matches a personal email or a mobile" do
      app_add_identity(token, kind: "email", value: "rachel@google.com", tag: "personal")
      expect(ActsAsTenant.without_tenant { ClientRider.count }).to eq(0)
    end

    it "offers a client user by their work email" do
      within_tenant(company) { create(:client_user, client: school, email: "priya@moe.edu.sg", name: "Priya Nair") }
      add_work("priya@moe.edu.sg")
      expect(json.dig(:data, :invitations)).to contain_exactly(
        a_hash_including(kind: "bookings", organisation: "St. Stephen's School", role: "Booker", matched_email: "priya@moe.edu.sg")
      )
    end

    it "shows Approver for a client user who approves" do
      within_tenant(company) do
        user = create(:client_user, client: school, email: "priya@moe.edu.sg", name: "Priya Nair")
        step = ClientApprovalFlow.for!(school, nil).rules.first.steps.create!(who: %w[people], need: "any")
        ClientApprovalStepPerson.create!(client_approval_step: step, client_user: user)
      end
      add_work("priya@moe.edu.sg")
      expect(json.dig(:data, :invitations, 0, :role)).to eq("Approver")
    end

    it "finds a domain a client added after the email was verified, when Organisations opens" do
      add_work("rachel@dbs.com")
      expect(organisations[:invitations]).to eq([])
      within_tenant(company) { create(:client, name: "DBS Bank", email_domains: %w[dbs.com]) }
      expect(organisations[:invitations].pluck(:organisation)).to eq([ "DBS Bank" ])
    end

    it "does not offer clients of a suspended company, a discarded client, or an individual" do
      other = create(:company, status: "suspended")
      within_tenant(other) { create(:client, name: "Suspended Co", email_domains: %w[google.com]) }
      within_tenant(company) do
        google.discard!
        create(:client, name: "Person", kind: "individual", phone: "+6591234567", email_domains: %w[google.com])
      end
      add_work
      expect(json.dig(:data, :invitations)).to eq([])
    end

    it "offers the same person once per client, across several companies" do
      other = create(:company, name: "Eastern Coaches")
      within_tenant(other) { create(:client, name: "Google Singapore", email_domains: %w[google.com]) }
      add_work
      expect(json.dig(:data, :invitations).pluck(:organisation, :company)).to contain_exactly([ "Google Asia Pacific", "SimpleDrive" ], [ "Google Singapore", "Eastern Coaches" ])
      organisations
      expect(ActsAsTenant.without_tenant { ClientRider.count }).to eq(2)
    end
  end

  describe "Accept / Not Me" do
    before { add_work }

    let(:rider) { ActsAsTenant.without_tenant { ClientRider.sole } }

    it "Accept links the person: the link shows under links, and the work email is in use" do
      post accept_path("shuttle", rider.id), headers: app_as(token), as: :json
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to include(status: "accepted", state: "active")
      expect(organisations).to include(invitations: [], links: [ a_hash_including(organisation: "Google Asia Pacific") ], unlinked: [])

      get api_v1_convoy_app_identities_path, headers: app_as(token)
      expect(json[:data].find { it[:value] == "rachel.tan@google.com" }[:uses]).to eq([ "Google Asia Pacific shuttle" ])
      delete api_v1_convoy_app_identity_path(account.identities.find_by(value: "rachel.tan@google.com")), headers: app_as(token)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to include("Used by Google Asia Pacific shuttle")
    end

    it "Not Me declines it for good: not listed, not offered again, the email counts as unlinked" do
      post decline_path("shuttle", rider.id), headers: app_as(token), as: :json
      expect(json[:data]).to eq(declined: true)
      expect(rider.reload).to have_attributes(status: "declined")
      expect(organisations).to include(invitations: [], links: [], unlinked: [ a_hash_including(email: "rachel.tan@google.com") ])
      expect(ActsAsTenant.without_tenant { ClientRider.count }).to eq(1)
    end

    it "cannot be answered twice, and an accepted link cannot be declined (ask the office)" do
      post accept_path("shuttle", rider.id), headers: app_as(token), as: :json
      post decline_path("shuttle", rider.id), headers: app_as(token), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(rider.reload).to be_accepted
    end

    it "is the person's own: another account gets 404" do
      other = app_user(mobile: "9177 3301", name: %w[David Tan])[1]
      post accept_path("shuttle", rider.id), headers: app_as(other), as: :json
      expect(response).to have_http_status(:not_found)
      post accept_path("nonsense", rider.id), headers: app_as(token), as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "answers a booking link the same way" do
      within_tenant(company) { create(:client_user, client: school, email: "rachel.tan@google.com", name: "Rachel Tan") }
      organisations
      user = ActsAsTenant.without_tenant { ClientUser.find_by!(email: "rachel.tan@google.com") }
      post accept_path("bookings", user.id), headers: app_as(token), as: :json
      expect(json[:data]).to include(kind: "bookings", status: "accepted", company: "SimpleDrive")
      get api_v1_convoy_app_identities_path, headers: app_as(token)
      expect(json[:data].find { it[:value] == "rachel.tan@google.com" }[:uses]).to include("Bookings with SimpleDrive")
    end

    it "needs authentication" do
      get api_v1_convoy_app_organisations_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "an overdue work email" do
    before do
      add_work
      account.identities.find_by(value: "rachel.tan@google.com").update_columns(verified_at: 13.months.ago) # rubocop:disable Rails/SkipsModelValidations
    end

    let(:rider) { ActsAsTenant.without_tenant { ClientRider.sole } }

    it "pauses the link (read-time) and Accept asks for Verify Again first" do
      expect(organisations[:invitations].first).to include(state: "paused", paused_since: a_kind_of(String))
      post accept_path("shuttle", rider.id), headers: app_as(token), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to include("Verify rachel.tan@google.com again")
    end

    it "keeps an accepted link but paused, and verifying again resumes it" do
      account.identities.find_by(value: "rachel.tan@google.com").update_columns(verified_at: 1.day.ago) # rubocop:disable Rails/SkipsModelValidations
      post accept_path("shuttle", rider.id), headers: app_as(token), as: :json
      account.identities.find_by(value: "rachel.tan@google.com").update_columns(verified_at: 13.months.ago) # rubocop:disable Rails/SkipsModelValidations
      expect(organisations[:links]).to contain_exactly(a_hash_including(state: "paused"))
      app_add_identity(token, kind: "email", value: "rachel.tan@google.com", tag: "work")
      expect(json.dig(:data, :outcome)).to eq("reverified")
      expect(organisations[:links]).to contain_exactly(a_hash_including(state: "active", paused_since: nil))
    end

    it "finds nothing new while paused" do
      within_tenant(company) { create(:client, name: "Google Singapore", email_domains: %w[google.com]) }
      expect(organisations[:invitations].pluck(:organisation)).to eq([ "Google Asia Pacific" ])
    end
  end

  describe "the office" do
    before { add_work }

    let(:staff) { create(:user, company:) }
    let(:rider) { ActsAsTenant.without_tenant { ClientRider.sole } }

    it "ends the link by removing the rider, and the same email is not invited again" do
      post accept_path("shuttle", rider.id), headers: app_as(token), as: :json
      sign_in_as(staff)
      get api_v1_client_riders_path(google)
      expect(json[:data]).to contain_exactly(a_hash_including(name: "Rachel Tan", matched_email: "rachel.tan@google.com", status: "accepted"))
      delete api_v1_client_rider_path(google, rider)
      expect(response).to have_http_status(:no_content)

      expect(rider.reload).to have_attributes(status: "removed", removed_by_id: staff.id)
      expect(organisations(as: token)).to include(invitations: [], links: [])
      expect(ActsAsTenant.without_tenant { ClientRider.count }).to eq(1)
      delete api_v1_client_rider_path(google, rider)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "ends a booking link by removing the client user" do
      user = within_tenant(company) { create(:client_user, client: school, email: "rachel.tan@google.com", name: "Rachel Tan") }
      organisations
      post accept_path("bookings", user.id), headers: app_as(token), as: :json
      sign_in_as(staff)
      delete api_v1_client_user_path(school, user)
      expect(organisations(as: token)[:links]).to eq([])
    end

    it "keeps riders of another company out of the list (tenant)" do
      sign_in_as(create(:user, company: create(:company)))
      get api_v1_client_riders_path(google)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "removing a work email" do
    it "drops the invitations it found" do
      add_work
      identity = account.identities.find_by(value: "rachel.tan@google.com")
      delete api_v1_convoy_app_identity_path(identity), headers: app_as(token)
      expect(response).to have_http_status(:ok)
      expect(ActsAsTenant.without_tenant { ClientRider.count }).to eq(0)
    end
  end
end
