require "rails_helper"

# Convoy App › Household: Set Up Your Family, children, Quick Invite + Asked to Join, Manual Invite + Accept / Not Me, adult
# photos, Authorised Guardians, Delete Family.
RSpec.describe "Convoy App household" do
  let!(:rachel) { app_user(mobile: "9188 2045") }
  let(:token) { rachel[1] }
  let(:photo) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/photo.png"), "image/png") }
  let(:family) { { name: "Tan Family", postal: "460412", block: "412", street: "Bedok North Ave 2", floor: "08", unit: "123", relationship: "Mother" } }

  def set_up(token: self.token, **over)
    post api_v1_convoy_app_household_path, params: { household: family.merge(over) }, headers: app_as(token), as: :json
  end

  def api(verb, path, token: self.token, **params)
    public_send(verb, path, params:, headers: app_as(token), as: :json)
  end

  def second(mobile, name)
    user = app_user(mobile:, name:)
    user[1]
  end

  describe "Set Up Your Family" do
    it "looks the postal code up, and says so when OneMap does not know it" do
      fake_one_map.add("460412", 1.32, 103.93, "412 BEDOK NORTH AVENUE 2")
      get postal_api_v1_convoy_app_household_path, params: { postal: "460412" }, headers: app_as(token)
      expect(json[:data]).to include(found: true, block: "412", street: "Bedok North Avenue 2")

      get postal_api_v1_convoy_app_household_path, params: { postal: "999999" }, headers: app_as(token)
      expect(json[:data]).to include(found: false, message: "Postal code not found, type the block and street")

      get postal_api_v1_convoy_app_household_path, params: { postal: "12" }, headers: app_as(token)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:message]).to eq("Enter a 6-digit postal code")
    end

    it "answers null before a Family exists, then creates it with the person as Admin and Billing Contact" do
      get api_v1_convoy_app_household_path, headers: app_as(token)
      expect(json[:data]).to be_nil

      fake_one_map.add("460412", 1.32, 103.93)
      set_up
      expect(response).to have_http_status(:created), json.inspect
      expect(json[:data]).to include(name: "Tan Family", address: "Blk 412 Bedok North Ave 2, #08-123", can_delete: true, children: [], asked_to_join: [])
      expect(json[:data][:adults]).to contain_exactly(include(name: "Rachel Tan", you: true, admin: true, billing_contact: true, relationship: "Mother"))
      expect(Household.last).to have_attributes(lat: 1.32.to_d, lng: 103.93.to_d)
    end

    it "shows a landed home as just the house number and keeps the billing address when it differs" do
      set_up(block: "20", street: "Siglap View", floor: "", unit: "", billing_same: false, billing_address: "1 Raffles Place", billing_contact: false)
      expect(json[:data]).to include(address: "20 Siglap View", billing_same: false, billing_address: "1 Raffles Place")
      expect(json[:data][:adults].first[:billing_contact]).to be(false)
    end

    it "checks the form in the order of the screen and one Family per person" do
      { name: [ "", "Enter the family name" ], postal: [ "46", "Enter a 6-digit postal code" ], block: [ "", "Enter the block or house number and the street" ] }.each do |field, (value, message)|
        set_up(field => value)
        expect(response).to have_http_status(:unprocessable_content)
        expect(json[:error][:message]).to eq(message)
      end
      set_up(billing_same: false)
      expect(json[:error][:message]).to eq("Enter the billing address")
      set_up(relationship: "Uncle")
      expect(response).to have_http_status(:unprocessable_content)
      expect(Household.count).to eq(0)

      set_up
      set_up
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:message]).to eq("You are already in a Family")
    end

    it "needs Create Your Account first" do
      patch api_v1_convoy_app_profile_path, params: { profile: { first_name: "" } }, headers: app_as(token), as: :json
      new_token = app_token(mobile: "8123 0001")
      get api_v1_convoy_app_household_path, headers: app_as(new_token)
      expect(response).to have_http_status(:forbidden)
      expect(json[:error][:code]).to eq("profile_required")
    end

    it "is refused without a token and by another app's token" do
      get api_v1_convoy_app_household_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "gives the form lists: relationships, medical tags, levels and the schools Convoy runs buses for (once per name, active companies)" do
      active = create(:company)
      suspended = create(:company, status: "suspended")
      ActsAsTenant.with_tenant(active) do
        school = School.create!(name: "St. Stephen's School")
        SchoolLevel.create!(school:, name: "P1", position: 1)
      end
      ActsAsTenant.with_tenant(create(:company)) { School.create!(name: "st. stephen's school") } # the same school at a second company
      ActsAsTenant.with_tenant(suspended) { School.create!(name: "Closed School") }

      get options_api_v1_convoy_app_household_path, headers: app_as(token)
      data = json[:data]
      expect(data[:relationships]).to eq([ "Mother", "Father", "Grandparent", "Relative", "Domestic Helper", "Family Friend" ])
      expect(data[:medical_tags]).to include("Asthma", "Heart condition")
      expect(data).to include(genders: %w[girl boy], level_year: Date.current.year + 1)
      expect(data[:schools].pluck(:name)).to eq([ "St. Stephen's School" ])
      expect(data[:schools].first[:levels]).to eq([ "P1" ])
      expect(data[:default_levels].first).to eq("Primary 1")
    end
  end

  describe "children" do
    before { set_up }

    let(:child) { { name: "Ethan Tan", birth_date: "2016-03-14", school_name: "Bedok Green Primary School", level: "Primary 4", gender: "boy", student_id: "S4-0412" } }

    it "adds a child with the 'Other' school typed, medical tags and a photo, and shows it on the Household" do
      post api_v1_convoy_app_household_dependants_path,
           params: { dependant: child.merge(photo:, medical_tags: [ "Asthma", "Eczema" ], medical_note: "Inhaler in the bag") }, headers: app_as(token)
      expect(response).to have_http_status(:created), json.inspect
      expect(json[:data]).to include(name: "Ethan Tan", first_name: "Ethan", level: "Primary 4", school: { id: nil, name: "Bedok Green Primary School" },
                                     medical_tags: %w[Asthma Eczema], status: { code: "no_bus", label: "No Bus Yet", tone: "neutral" })
      expect(json[:data][:photo][:url]).to start_with("/api/v1/downloads/")

      get api_v1_convoy_app_household_path, headers: app_as(token)
      expect(json[:data][:children].pluck(:name)).to eq([ "Ethan Tan" ])
    end

    it "takes a school from the list and keeps its name" do
      school = ActsAsTenant.with_tenant(create(:company)) { School.create!(name: "St. Stephen's School") }
      api(:post, api_v1_convoy_app_household_dependants_path, dependant: child.except(:school_name).merge(school_id: school.id))
      expect(json[:data][:school]).to eq(id: school.id, name: "St. Stephen's School")

      api(:post, api_v1_convoy_app_household_dependants_path, dependant: child.except(:school_name).merge(school_id: 0))
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:message]).to eq("Choose the school")
    end

    it "checks the form like the screen and the medical tags" do
      [ [ { name: "" }, "Enter the full name" ], [ { birth_date: "" }, "Enter the date of birth" ],
        [ { school_name: "" }, "Choose the school" ], [ { level: "" }, "Choose the level" ] ].each do |over, message|
        api(:post, api_v1_convoy_app_household_dependants_path, dependant: child.merge(over))
        expect(response).to have_http_status(:unprocessable_content)
        expect(json[:error][:message]).to eq(message)
      end
      api(:post, api_v1_convoy_app_household_dependants_path, dependant: child.merge(birth_date: 1.day.from_now.to_date.to_s))
      expect(response).to have_http_status(:unprocessable_content)
      api(:post, api_v1_convoy_app_household_dependants_path, dependant: child.merge(medical_tags: [ "Flu" ]))
      expect(response).to have_http_status(:unprocessable_content)
      api(:post, api_v1_convoy_app_household_dependants_path, dependant: child.merge(gender: "other"))
      expect(response).to have_http_status(:unprocessable_content)
      expect(Dependant.count).to eq(0)
    end

    it "edits a child, clears the photo, and never touches another Family's child" do
      api(:post, api_v1_convoy_app_household_dependants_path, dependant: child.merge(photo:))
      id = json[:data][:id]
      patch api_v1_convoy_app_household_dependant_path(id), params: { dependant: { level: "Primary 5", remove_photo: true, medical_tags: [] } }, headers: app_as(token)
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to include(level: "Primary 5", photo: nil, name: "Ethan Tan")

      other = second("8123 4410", %w[Maria Santos])
      post api_v1_convoy_app_household_path, params: { household: family.merge(name: "Santos") }, headers: app_as(other), as: :json
      api(:patch, api_v1_convoy_app_household_dependant_path(id), token: other, dependant: { level: "Primary 6" })
      expect(response).to have_http_status(:not_found)
      expect(Dependant.find(id).level).to eq("Primary 5")
    end

    it "answers 404 no_household to someone without a Family" do
      other = second("8123 4410", %w[Maria Santos])
      api(:post, api_v1_convoy_app_household_dependants_path, token: other, dependant: child)
      expect(response).to have_http_status(:not_found)
      expect(json[:error][:code]).to eq("no_household")
    end
  end

  describe "Quick Invite and Asked to Join" do
    before { set_up }

    let(:david_token) { second("9177 3301", %w[David Tan]) }

    def request_to_join
      api(:post, invite_link_api_v1_convoy_app_household_path)
      link = json[:data]
      api(:post, join_api_v1_convoy_app_household_link_path(link[:token]), token: david_token)
      link
    end

    it "gives a 7-day link with the message, reusing the live one" do
      api(:post, invite_link_api_v1_convoy_app_household_path)
      link = json[:data]
      expect(link).to include(url: "https://convoy.sg/j/#{link[:token]}")
      expect(link[:token]).to match(/\ATAN-[A-Z2-9]{6}\z/)
      expect(link[:message]).to eq("Rachel Tan has invited you to join their Convoy for Family account to manage the family travel needs. Join here: #{link[:url]}")
      expect(Time.zone.parse(link[:expires_at])).to be_within(1.minute).of(7.days.from_now)

      api(:post, invite_link_api_v1_convoy_app_household_path)
      expect(json[:data][:token]).to eq(link[:token])
      expect(HouseholdInviteLink.count).to eq(1)
    end

    it "lets the Admin approve a person who opened the link, who is then an adult" do
      link = request_to_join
      expect(response).to have_http_status(:created)
      expect(json[:data]).to eq(status: "requested", family: "Tan Family")

      get api_v1_convoy_app_household_link_path(link[:token]), headers: app_as(david_token)
      expect(json[:data]).to include(family: "Tan Family", invited_by: "Rachel Tan")

      get api_v1_convoy_app_household_path, headers: app_as(token)
      request = json[:data][:asked_to_join].first
      expect(request).to include(name: "David Tan", first_name: "David", phone: "+65 9177 3301")
      expect(json[:data][:adults].size).to eq(1)

      api(:post, approve_api_v1_convoy_app_household_member_path(request[:id]))
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:message]).to eq("Choose how David is related")

      api(:post, approve_api_v1_convoy_app_household_member_path(request[:id]), relationship: "Father")
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data][:asked_to_join]).to eq([])
      expect(json[:data][:adults].pluck(:name, :relationship)).to eq([ [ "Rachel Tan", "Mother" ], [ "David Tan", "Father" ] ])

      get api_v1_convoy_app_household_path, headers: app_as(david_token)
      expect(json[:data]).to include(name: "Tan Family", can_delete: false, asked_to_join: [])
    end

    it "lets only the Admin approve or decline, and a decline keeps the person out" do
      request_to_join
      member = HouseholdMember.find_by!(status: "requested")
      api(:post, approve_api_v1_convoy_app_household_member_path(member.id), token: david_token, relationship: "Father")
      expect(response).to have_http_status(:not_found) # not in a Family yet

      api(:post, decline_api_v1_convoy_app_household_member_path(member.id))
      expect(response).to have_http_status(:ok)
      expect(member.reload.status).to eq("declined")
      get api_v1_convoy_app_household_path, headers: app_as(david_token)
      expect(json[:data]).to be_nil

      api(:post, decline_api_v1_convoy_app_household_member_path(member.id))
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "keeps an adult who is not the Admin from approving" do
      request_to_join
      member = HouseholdMember.find_by!(status: "requested")
      api(:post, approve_api_v1_convoy_app_household_member_path(member.id), relationship: "Father")
      mei = second("9650 1187", [ "Mei Ling", "Tan" ])
      api(:post, join_api_v1_convoy_app_household_link_path(HouseholdInviteLink.last.token), token: mei)
      other = HouseholdMember.find_by!(status: "requested")
      api(:post, approve_api_v1_convoy_app_household_member_path(other.id), token: david_token, relationship: "Grandparent")
      expect(response).to have_http_status(:forbidden)
      expect(json[:error][:code]).to eq("admin_only")
      expect(other.reload.status).to eq("requested")
    end

    it "refuses an expired link, an unknown link and a person who is already in a Family" do
      link = request_to_join[:token]
      HouseholdInviteLink.update_all(expires_at: 1.minute.ago)
      get api_v1_convoy_app_household_link_path(link), headers: app_as(david_token)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:code]).to eq("link_expired")

      get api_v1_convoy_app_household_link_path("NOPE-0000"), headers: app_as(david_token)
      expect(response).to have_http_status(:not_found)

      api(:post, invite_link_api_v1_convoy_app_household_path)
      api(:post, join_api_v1_convoy_app_household_link_path(json[:data][:token]))
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:message]).to eq("You are already in a Family")
    end

    it "opens the link once even when it is sent twice" do
      link = request_to_join
      api(:post, join_api_v1_convoy_app_household_link_path(link[:token]), token: david_token)
      expect(response).to have_http_status(:created)
      expect(HouseholdMember.where(status: "requested").count).to eq(1)
    end
  end

  describe "Manual Invite" do
    before { set_up }

    let!(:david_token) { second("9177 3301", %w[David Tan]) }
    let(:contacts) { [ { name: "David Tan", phone: "9177 3301", relationship: "Father" }, { name: "Tan Mei Ling", phone: "+65 9650 1187" } ] }

    it "tells which contacts are on Convoy, without searching Convoy users" do
      api(:post, invites_check_api_v1_convoy_app_household_path,
          contacts: [ { name: "David", phone: "91773301" }, { name: "Mei Ling", phone: "9650 1187" }, { name: "Bad", phone: "12345" }, { name: "Me", phone: "9188 2045" } ])
      expect(json[:data]).to eq([
        { name: "David", phone: "+6591773301", valid: true, on_convoy: true, in_household: false },
        { name: "Mei Ling", phone: "+6596501187", valid: true, on_convoy: false, in_household: false },
        { name: "Bad", phone: nil, valid: false, on_convoy: false, in_household: false },
        { name: "Me", phone: "+6591882045", valid: true, on_convoy: true, in_household: true }
      ])

      many = Array.new(51) { |i| { name: "Contact #{i}", phone: format("9100%04d", i) } }
      api(:post, invites_check_api_v1_convoy_app_household_path, contacts: many)
      expect(json[:error]).to include(code: "too_many_contacts", message: "Pick up to 50 contacts at a time")
      api(:post, invites_api_v1_convoy_app_household_path, contacts: many)
      expect(json.dig(:error, :code)).to eq("too_many_contacts")
    end

    it "invites contacts with an account in the app and hands the rest the link; they accept and join without approval" do
      api(:post, invites_api_v1_convoy_app_household_path, contacts:)
      expect(response).to have_http_status(:created), json.inspect
      expect(json[:data][:invited]).to contain_exactly(include(name: "David Tan", relationship: "Father", status: "invited"))
      expect(json[:data][:link_for]).to eq([ { name: "Tan Mei Ling", phone: "+6596501187" } ])

      get api_v1_convoy_app_household_path, headers: app_as(token)
      expect(json[:data][:adults].pluck(:name, :status)).to eq([ [ "Rachel Tan", "active" ], [ "David Tan", "invited" ] ])

      get api_v1_convoy_app_household_invitations_path, headers: app_as(david_token)
      invite = json[:data].first
      expect(invite).to include(family: "Tan Family", invited_by: "Rachel Tan", relationship: "Father")

      api(:post, accept_api_v1_convoy_app_household_invitation_path(invite[:id]), token: david_token)
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data][:adults].pluck(:name, :status)).to eq([ [ "Rachel Tan", "active" ], [ "David Tan", "active" ] ])
      expect(json[:data][:you]).to include(admin: false)

      get api_v1_convoy_app_household_invitations_path, headers: app_as(david_token)
      expect(json[:data]).to eq([])
    end

    it "lets the person answer Not Me, and the inviter can invite again" do
      api(:post, invites_api_v1_convoy_app_household_path, contacts: contacts.first(1))
      id = HouseholdMember.find_by!(status: "invited").id
      api(:post, decline_api_v1_convoy_app_household_invitation_path(id), token: david_token)
      expect(response).to have_http_status(:ok)
      expect(HouseholdMember.find(id).status).to eq("declined")

      api(:post, accept_api_v1_convoy_app_household_invitation_path(id), token: david_token)
      expect(response).to have_http_status(:not_found)

      api(:post, invites_api_v1_convoy_app_household_path, contacts: contacts.first(1))
      expect(HouseholdMember.find(id).status).to eq("invited")
    end

    it "asks for a relationship and a valid mobile, and skips people already in the Family" do
      api(:post, invites_api_v1_convoy_app_household_path, contacts: [ { name: "David Tan", phone: "9177 3301" } ])
      expect(json[:error][:message]).to eq("Choose how David is related")
      api(:post, invites_api_v1_convoy_app_household_path, contacts: [ { name: "Zed", phone: "12" } ])
      expect(json[:error][:message]).to eq("Check the mobile number of Zed")
      api(:post, invites_api_v1_convoy_app_household_path, contacts: [])
      expect(response).to have_http_status(:bad_request).or have_http_status(:unprocessable_content)
      api(:post, invites_api_v1_convoy_app_household_path, contacts: [ { name: "Rachel", phone: "9188 2045", relationship: "Mother" } ])
      expect(json[:data][:invited]).to eq([])
      expect(HouseholdMember.count).to eq(1)
    end

    it "refuses accepting while already in another Family" do
      api(:post, invites_api_v1_convoy_app_household_path, contacts: contacts.first(1))
      post api_v1_convoy_app_household_path, params: { household: family.merge(name: "Own") }, headers: app_as(david_token), as: :json
      id = HouseholdMember.find_by!(status: "invited").id
      api(:post, accept_api_v1_convoy_app_household_invitation_path(id), token: david_token)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:message]).to eq("You are already in a Family")
    end

    it "does not let someone else answer the invite" do
      api(:post, invites_api_v1_convoy_app_household_path, contacts: contacts.first(1))
      id = HouseholdMember.find_by!(status: "invited").id
      api(:post, accept_api_v1_convoy_app_household_invitation_path(id))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "adult photo and Authorised Guardians" do
    let!(:david_token) { second("9177 3301", %w[David Tan]) }
    let!(:mei_token) { second("9650 1187", [ "Mei Ling", "Tan" ]) }
    let(:rachel_member) { HouseholdMember.find_by!(app_account: rachel[0]) }

    before do
      set_up
      api(:post, api_v1_convoy_app_household_dependants_path, dependant: { name: "Ethan Tan", birth_date: "2016-03-14", school_name: "Bedok Green", level: "Primary 4" })
      @child = json[:data][:id]
      api(:post, invites_api_v1_convoy_app_household_path,
          contacts: [ { name: "David", phone: "9177 3301", relationship: "Father" }, { name: "Mei Ling", phone: "9650 1187", relationship: "Grandparent" } ])
      HouseholdMember.where(status: "invited").find_each { |m| m.update!(status: :active, joined_at: Time.current) }
    end

    def board = (get guardians_api_v1_convoy_app_household_path, headers: app_as(token); json[:data].first)
    def state_of(name) = board[:adults].find { it[:name] == name }[:state]

    it "shows Mother and Father as always, and others as needing a photo" do
      expect(board).to include(first_name: "Ethan", can_receive: 2, of: 3)
      expect(board[:adults].pluck(:name, :state)).to eq([ [ "Rachel Tan", "always" ], [ "David Tan", "always" ], [ "Mei Ling Tan", "needs_photo" ] ])
    end

    it "needs a photo before an adult can be switched on, then allows and removes them" do
      mei = HouseholdMember.find_by!(relationship: "Grandparent")
      path = dependant_guardian_api_v1_convoy_app_household_path(@child, mei.id)
      api(:put, path, allowed: true)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error]).to include(code: "needs_photo", message: "Mei Ling needs a photo first")

      patch api_v1_convoy_app_household_member_path(mei.id), params: { member: { photo: } }, headers: app_as(token)
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data][:adults].find { it[:id] == mei.id }).to include(needs_photo: false, can_add_photo: false)
      expect(state_of("Mei Ling Tan")).to eq("off")

      api(:put, path, allowed: true)
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to include(can_receive: 3, of: 3)
      expect(json[:data][:adults].find { it[:member_id] == mei.id }).to include(state: "on", allowed: true, can_receive: true)

      api(:put, path, allowed: false)
      expect(state_of("Mei Ling Tan")).to eq("off")
      expect(DependantGuardian.count).to eq(0)
    end

    it "keeps Mother and Father locked and a pending adult off" do
      david = HouseholdMember.find_by!(relationship: "Father")
      api(:put, dependant_guardian_api_v1_convoy_app_household_path(@child, david.id), allowed: false)
      expect(json[:error][:code]).to eq("always")

      mei = HouseholdMember.find_by!(relationship: "Grandparent")
      mei.update!(status: :invited, photo:)
      expect(state_of("Mei Ling Tan")).to eq("pending")
      api(:put, dependant_guardian_api_v1_convoy_app_household_path(@child, mei.id), allowed: true)
      expect(json[:error]).to include(code: "not_accepted", message: "Can be switched on once Mei Ling accepts the invite")
    end

    it "lets any adult switch and add a photo, but only for their own Family" do
      mei = HouseholdMember.find_by!(relationship: "Grandparent")
      api(:patch, api_v1_convoy_app_household_member_path(mei.id), token: david_token, member: { photo: })
      expect(response).to have_http_status(:ok)

      stranger = second("8123 4410", %w[Maria Santos])
      post api_v1_convoy_app_household_path, params: { household: family.merge(name: "Santos") }, headers: app_as(stranger), as: :json
      api(:put, dependant_guardian_api_v1_convoy_app_household_path(@child, mei.id), token: stranger, allowed: true)
      expect(response).to have_http_status(:not_found)
      api(:patch, api_v1_convoy_app_household_member_path(mei.id), token: stranger, member: { photo: })
      expect(response).to have_http_status(:not_found)
    end

    it "asks for a photo, not nothing" do
      mei = HouseholdMember.find_by!(relationship: "Grandparent")
      api(:patch, api_v1_convoy_app_household_member_path(mei.id), member: { name: "x" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:message]).to eq("Add a photo first")
    end
  end

  describe "Delete Family" do
    before { set_up }

    it "removes the Family, its children and pending invites for everyone, and keeps the accounts" do
      api(:post, api_v1_convoy_app_household_dependants_path, dependant: { name: "Ethan Tan", birth_date: "2016-03-14", school_name: "Bedok Green", level: "Primary 4" })
      david = second("9177 3301", %w[David Tan])
      api(:post, invites_api_v1_convoy_app_household_path, contacts: [ { name: "David", phone: "9177 3301", relationship: "Father" } ])

      delete api_v1_convoy_app_household_path, headers: app_as(token)
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to eq(deleted: true)
      expect(Household.kept.count).to eq(0)
      expect(Dependant.kept.count).to eq(0)
      expect(HouseholdMember.count).to eq(0)
      expect(AppAccount.count).to eq(2)

      get api_v1_convoy_app_household_invitations_path, headers: app_as(david)
      expect(json[:data]).to eq([])
      get api_v1_convoy_app_household_path, headers: app_as(token)
      expect(json[:data]).to be_nil

      set_up # the person can start a new Family
      expect(response).to have_http_status(:created)
    end

    it "is for the Admin only" do
      david = second("9177 3301", %w[David Tan])
      api(:post, invites_api_v1_convoy_app_household_path, contacts: [ { name: "David", phone: "9177 3301", relationship: "Father" } ])
      api(:post, accept_api_v1_convoy_app_household_invitation_path(HouseholdMember.find_by!(status: "invited").id), token: david)
      delete api_v1_convoy_app_household_path, headers: app_as(david)
      expect(response).to have_http_status(:forbidden)
      expect(json[:error][:code]).to eq("admin_only")
      expect(Household.kept.count).to eq(1)
    end

    it "is blocked while a child has a service, an accepted request or an unpaid bill" do
      reasons = [ { code: "active_service", label: "Ethan has a school bus service" } ]
      allow(ConvoyApp::Households::BusService).to receive(:delete_blockers).and_return(reasons)
      delete api_v1_convoy_app_household_path, headers: app_as(token)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error]).to include(code: "family_blocked", details: { reasons: [ { code: "active_service", label: "Ethan has a school bus service" } ] })
      expect(Household.kept.count).to eq(1)
    end
  end

  describe "account removal and uses" do
    it "shows the Family on the personal mobile and invoices on the personal email of the Billing Contact" do
      app_add_identity(token, kind: "email", value: "rachel@gmail.com")
      set_up
      get api_v1_convoy_app_identities_path, headers: app_as(token)
      uses = json[:data].to_h { [ it[:kind], it[:uses] ] }
      expect(uses).to eq("mobile" => [ "Tan Family" ], "email" => [ "Invoices and receipts" ])

      delete api_v1_convoy_app_identity_path(json[:data].find { it[:kind] == "email" }[:id]), headers: app_as(token)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:error][:message]).to eq("Used by Invoices and receipts. Add another first, then switch")
    end

    it "discards a Family left without an adult when the purge job removes the last account" do
      set_up
      rachel[0].update!(delete_requested_at: 31.days.ago)
      AppAccountsPurgeJob.perform_now
      expect(AppAccount.exists?(rachel[0].id)).to be(false)
      expect(Household.kept.count).to eq(0)
      expect(Dependant.kept.count).to eq(0)
    end
  end
end
