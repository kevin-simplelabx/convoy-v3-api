require "rails_helper"

# Client Portal permissions (logic/app-feed.js can, covers, rolesToGive, userCan) with v3's site rule.
RSpec.describe ClientUserAccess, :tenant do
  let(:client) { create(:client) }
  let(:tower_a) { client.sites.create!(company_id: client.company_id, name: "Tower A") }
  let(:tower_b) { client.sites.create!(company_id: client.company_id, name: "Tower B") }

  def user(role, sites = [])
    account = PortalAccount.for_email!("#{role}-#{SecureRandom.hex(3)}@x.sg")
    u = client.users.create!(company_id: client.company_id, name: role, email: account.email, role:, portal_account: account)
    sites.each { |s| u.user_sites.create!(client_site: s) }
    u
  end

  it "gives each role its capabilities and the roles it may give" do
    expect(user("fin").can?(:billing)).to be(true)
    expect(user("fin").can?(:book)).to be(false)
    expect(user("member").can?(:approve)).to be(false)
    expect(user("sa").can?(:step_in)).to be(false)
    expect(user("adm").roles_to_give).not_to include("super")
    expect(user("sa").roles_to_give).to eq(%w[sa sfin member])
    expect(user("sfin").roles_to_give).to eq([])
  end

  it "covers sites: every site for organisation-wide roles, picked sites for site roles, nothing when none are left" do
    tower_b
    admin = user("adm")
    site_admin = user("sa", [ tower_a ])
    lost = user("sa")

    expect(admin.covers?(tower_b.id)).to be(true)
    expect(admin.covers?(nil)).to be(true)
    expect(site_admin.covers?(tower_a.id)).to be(true)
    expect(site_admin.covers?(tower_b.id)).to be(false)
    expect(site_admin.covers?(nil)).to be(false) # a booking with no site: organisation-wide roles only
    expect(lost.covers?(tower_a.id)).to be(false)
    expect(site_admin.limit_to_sites(client.sites, :id)).to eq([ tower_a ])
    expect(lost.limit_to_sites(client.sites, :id)).to be_empty
  end

  it "lets site roles cover everything when the client has no sites" do
    member = user("member")
    expect(member.all_sites?).to be(true)
    expect(member.covers?(nil)).to be(true)
  end

  it "decides who manages whom" do
    superadmin = user("super")
    admin = user("adm")
    ssa = user("ssa", [ tower_a, tower_b ])
    sa_a = user("sa", [ tower_a ])
    sa_ab = user("sa", [ tower_a, tower_b ])
    sfin_b = user("sfin", [ tower_b ])
    member_a = user("member", [ tower_a ])

    expect(admin.manages?(superadmin, :see)).to be(true)
    expect(admin.manages?(superadmin, :edit)).to be(false)
    expect(superadmin.manages?(admin, :remove)).to be(true)
    expect(superadmin.manages?(superadmin, :remove)).to be(false)

    expect(sa_a.manages?(admin, :see)).to be(false)
    expect(sa_a.manages?(member_a, :edit)).to be(true)
    expect(sa_a.manages?(sa_ab, :see)).to be(true)
    expect(sa_a.manages?(sa_ab, :edit)).to be(false) # Tower B is not theirs
    expect(sa_a.manages?(sfin_b, :see)).to be(false)
    expect(ssa.manages?(sa_ab, :remove)).to be(true)
    expect(sa_ab.manages?(ssa, :remove)).to be(false) # a Site Admin cannot give Site Super Admin

    expect(member_a.manages?(member_a, :see)).to be(true)
    expect(member_a.manages?(sa_a, :see)).to be(false)
  end
end
