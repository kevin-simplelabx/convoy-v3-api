require "rails_helper"

# Settings > Users: role presets, Add / Edit, schools, Suspend / Delete and the Super Admin rules.
RSpec.describe "Settings users" do
  let(:company) { create(:company) }
  let!(:owner) { create(:user, :owner, company:, name: "Olivia Owner") }
  let(:schools) do
    within_tenant(company) { %w[Alpha Beta].map { |n| School.create!(name: "#{n} School", short_name: n) } }
  end

  def save_user(id: nil, **attrs)
    body = { user: attrs }
    id ? patch(api_v1_user_path(id), params: body, as: :json) : post(api_v1_users_path, params: body, as: :json)
  end

  context "as the Super Admin" do
    before { sign_in_as(owner) }

    it "lists the role presets and permissions" do
      get roles_api_v1_users_path
      expect(json.dig(:data, :permissions).first).to eq(id: "users", label: "Users")
      expect(json.dig(:data, :roles).pluck(:name)).to include("Super Admin", "Admin", "Planner", "Viewer")
      expect(json.dig(:data, :roles).find { |r| r[:id] == "finops" }).to include(permissions: %w[finance finview], owner: false, all_permissions: false)
    end

    it "adds a user from a role, names the role from the permissions, and limits schools" do
      save_user(name: "Paula Planner", email: " Paula@Example.com ", password: "secret123", permissions: %w[schools plans planview],
                all_schools: false, school_ids: [ schools.first.id ])
      expect(response).to have_http_status(:created), json.inspect
      expect(json[:data]).to include(email: "paula@example.com", role: "member", role_label: "Planner", all_schools: false,
                                     every_school: false, schools: [ { id: schools.first.id, name: "Alpha" } ],
                                     created_by: { id: owner.id, name: "Olivia Owner" }, can_edit: true, can_act: true)
      id = json.dig(:data, :id)

      save_user(id:, permissions: %w[schools plans planview vehicles])
      expect(json[:data]).to include(role_label: "Custom", schools: [ { id: schools.first.id, name: "Alpha" } ])

      save_user(id:, permissions: User::PERMISSIONS, name: "Ignored")
      expect(json[:data]).to include(name: "Paula Planner", role: "admin", role_label: "Admin", all_schools: true, every_school: true, schools: [])

      save_user(id:, permissions: [], all_schools: true)
      expect(json[:data]).to include(role: "member", role_label: "Viewer", permissions: [])
    end

    it "checks the password, email and permissions" do
      save_user(name: "A", email: owner.email.upcase, password: "short", permissions: %w[nope])
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :details).keys).to include(:email, :password, :permissions)
    end

    it "suspends (signing the user out) and turns back on" do
      member = create(:user, company:)
      Auth::IssueToken.call(user: member, name: "phone")

      post suspend_api_v1_user_path(member)
      expect(json[:data]).to include(status: "suspended")
      expect(member.allowlisted_jwts.count).to eq(0)

      post activate_api_v1_user_path(member)
      expect(json[:data]).to include(status: "active")
    end

    it "deletes softly: gone from the list, cannot sign in, and the email can be used again" do
      member = create(:user, company:, email: "gone@example.com")
      delete api_v1_user_path(member)
      expect(response).to have_http_status(:no_content)
      expect(member.reload).to be_discarded

      get api_v1_users_path
      expect(json[:data].pluck(:id)).to eq([ owner.id ])
      expect(json[:meta][:counts]).to eq(all: 1, active: 1, suspended: 0)

      save_user(name: "New Person", email: "gone@example.com", password: "Password1!", permissions: [])
      expect(response).to have_http_status(:created)
      expect(json.dig(:data, :id)).not_to eq(member.id)
    end

    it "never lets the company lose its last Super Admin or act on itself" do
      post suspend_api_v1_user_path(owner)
      expect(json.dig(:error, :message)).to eq("You can't suspend yourself")

      save_user(id: owner.id, owner: false, permissions: %w[users vehicles])
      expect(json.dig(:error, :message)).to eq("There must always be at least one active Super Admin")

      other = create(:user, company:)
      save_user(id: other.id, owner: true)
      expect(json[:data]).to include(owner: true, role_label: "Super Admin")
      save_user(id: owner.id, owner: false, permissions: %w[users vehicles])
      expect(json[:data]).to include(owner: false, role_label: "Custom")
    end

    it "lists with counts, status filter and search" do
      create(:user, company:, name: "Sam Suspended", status: :suspended)
      create(:user, company: create(:company), name: "Elsewhere")
      get api_v1_users_path, params: { status: "suspended", q: { name_or_email_i_cont: "sam" } }
      expect(json[:data].pluck(:name)).to eq([ "Sam Suspended" ])
      expect(json[:meta][:counts]).to eq(all: 2, active: 1, suspended: 1)
    end
  end

  context "as an Admin with the Users permission" do
    let(:admin) { create(:user, :admin, company:, permissions: User::PERMISSIONS) }
    before { sign_in_as(admin) }

    it "cannot touch a Super Admin or make one" do
      get api_v1_users_path
      expect(json[:data].find { |u| u[:id] == owner.id }).to include(can_edit: false, can_act: false)
      expect(json[:data].find { |u| u[:id] == admin.id }).to include(can_edit: true, can_act: false)

      delete api_v1_user_path(owner)
      expect(json.dig(:error, :message)).to eq("Only a Super Admin can change a Super Admin")
      save_user(name: "X", email: "x@example.com", password: "Password1!", owner: true)
      expect(json.dig(:error, :message)).to eq("Only a Super Admin can make a Super Admin")
    end

    it "cannot remove their own Users permission" do
      save_user(id: admin.id, permissions: %w[vehicles])
      expect(json.dig(:error, :message)).to eq("You can't remove your own Users permission")
    end
  end

  it "is closed to users without the Users permission, and view only for Convoy Admin" do
    sign_in_as(create(:user, company:, permissions: %w[vehicles]))
    get api_v1_users_path
    expect(response).to have_http_status(:forbidden)

    convoy = create(:user, :convoy_admin)
    sign_in_as(convoy)
    patch api_v1_session_path, params: { company_id: company.id }, as: :json
    get api_v1_users_path
    expect(json[:data].pluck(:id)).to include(owner.id)
    post suspend_api_v1_user_path(owner)
    expect(response).to have_http_status(:forbidden)
  end

  it "stops a suspended or deleted user from signing in" do
    member = create(:user, company:, status: :suspended)
    post api_v1_session_path, params: { email: member.email, password: "Password1!" }, as: :json
    expect(response).to have_http_status(:unauthorized)

    member.update!(status: :active)
    member.discard!
    post api_v1_session_path, params: { email: member.email, password: "Password1!" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
