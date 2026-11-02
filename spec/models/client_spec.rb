require "rails_helper"

RSpec.describe Client, :tenant do
  it "takes the next client code" do
    expect([ create(:client).code, create(:client).code ]).to eq(%w[CL00001 CL00002])
  end

  it "needs a mobile or email for an individual" do
    expect(build(:client, kind: :individual)).not_to be_valid
    expect(build(:client, kind: :individual, phone: "+6591234567")).to be_valid
  end
end
