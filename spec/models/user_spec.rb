require "rails_helper"

RSpec.describe User do
  it "gives admins every permission" do
    expect(build(:user, :admin).effective_permissions).to eq(User::PERMISSIONS)
  end

  it "gives members only their own permissions" do
    user = build(:user, permissions: %w[vehicles])
    expect(user.can?(:vehicles)).to be(true)
    expect(user.can?(:finance)).to be(false)
  end

  it "rejects unknown permissions" do
    expect(build(:user, permissions: %w[nope])).not_to be_valid
  end

  it "requires a company except for Convoy Admin" do
    expect(build(:user, company: nil)).not_to be_valid
    expect(build(:user, :convoy_admin)).to be_valid
    expect(build(:user, :convoy_admin, company: build(:company))).not_to be_valid
  end

  it "normalises the email" do
    expect(build(:user, email: "  Ops@Example.COM ").email).to eq("ops@example.com")
  end
end
