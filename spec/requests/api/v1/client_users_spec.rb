require "rails_helper"

# Client Users card: Client Portal people with a role and site access, and the rules of the prototype.
RSpec.describe "Client users" do
  let(:company) { create(:company) }
  let(:staff) { create(:user, company:, name: "Rachel Tan", email: "rachel@simpledrive.sg") }
  let!(:data) do
    within_tenant(company) do
      client = create(:client, name: "Bright Steps")
      { client:, punggol: client.sites.create!(name: "Punggol"), sengkang: client.sites.create!(name: "Sengkang"),
        other: create(:client, name: "Other").sites.create!(name: "Elsewhere") }
    end
  end
  let(:client) { data[:client] }

  before { sign_in_as(staff) }

  def add(**attrs)
    post api_v1_client_users_path(client), params: { client_user: { name: "Ann Tan", email: "ann@brightsteps.sg", role: "super" }.merge(attrs) }, as: :json
  end

  it "lists the Client Portal roles" do
    get api_v1_client_user_roles_path
    expect(json[:data].first).to eq(id: "super", label: "Super Admin", tag: "Everything, every site", wide: true)
    expect(json[:data].pluck(:id)).to eq(%w[super adm fin ssa sa sfin member])
  end

  it "adds people with roles and site access, one portal account per email" do
    add(title: "Director")
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(name: "Ann Tan", title: "Director", role_label: "Super Admin", wide: true, sites: [],
                                   created_by: { id: staff.id, name: "Rachel Tan", in_portal: false }, portal: { password_set: false, last_sign_in_at: nil })

    add(name: "Ben", email: "ben@brightsteps.sg", role: "sa")
    expect(json.dig(:error, :message)).to eq("Pick at least one site for a Site Admin")
    add(name: "Ben", email: "ben@brightsteps.sg", role: "sa", site_ids: [ data[:other].id ])
    expect(json.dig(:error, :message)).to eq("Some sites are not sites of Bright Steps")
    add(name: "Ben", email: "Ben@BrightSteps.sg", role: "sa", site_ids: [ data[:punggol].id ])
    expect(json[:data]).to include(email: "ben@brightsteps.sg", role_label: "Site Admin", sites: [ { id: data[:punggol].id, name: "Punggol" } ])
    ben = json.dig(:data, :id)

    add(name: "Ann again")
    expect(json.dig(:error, :details, :email)).to eq([ "Email is already a user of this client" ])
    add(name: "Rachel", email: "rachel@simpledrive.sg")
    expect(json.dig(:error, :message)).to eq("rachel@simpledrive.sg belongs to a Convoy OS user of your company")

    patch api_v1_client_user_path(client, ben), params: { client_user: { role: "fin", name: "Ignored" } }, as: :json
    expect(json[:data]).to include(name: "Ben", role: "fin", wide: true, sites: [])

    within_tenant(company) { create(:client, name: "Second").tap { |c| post api_v1_client_users_path(c), params: { client_user: { name: "Ann", email: "ann@brightsteps.sg", role: "member" } }, as: :json } }
    expect(PortalAccount.where(email: "ann@brightsteps.sg").count).to eq(1)
    expect(ActsAsTenant.without_tenant { PortalAccount.find_by(email: "ann@brightsteps.sg").client_users.count }).to eq(2)

    get api_v1_clients_path
    expect(json[:data].find { |c| c[:name] == "Bright Steps" }).to include(users_count: 2)
  end

  it "keeps a Super Admin" do
    add
    ann = json.dig(:data, :id)
    patch api_v1_client_user_path(client, ann), params: { client_user: { role: "adm" } }, as: :json
    expect(json.dig(:error, :message)).to eq("Keep at least one Super Admin for Bright Steps")
    delete api_v1_client_user_path(client, ann)
    expect(json.dig(:error, :message)).to eq("Keep at least one Super Admin for Bright Steps")

    add(name: "Cara", email: "cara@brightsteps.sg")
    delete api_v1_client_user_path(client, ann)
    expect(response).to have_http_status(:no_content)
    get api_v1_client_users_path(client)
    expect(json[:data].pluck(:name)).to eq([ "Cara" ])
  end
end
