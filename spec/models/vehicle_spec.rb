require "rails_helper"

RSpec.describe Vehicle, :tenant do
  let(:managed) { create(:operator) }
  let(:external) { create(:operator, :external) }

  it "normalises plate and tags" do
    v = create(:vehicle, plate: "pd 3318 k", tags: "Coach, VIP ,, Coach")
    expect([ v.plate, v.tags ]).to eq([ "PD3318K", %w[Coach VIP] ])
  end

  it "keeps plates unique among kept vehicles" do
    create(:vehicle, plate: "PD1A").discard!
    expect(build(:vehicle, plate: "PD1A")).to be_valid
    create(:vehicle, plate: "PD1A")
    expect(build(:vehicle, plate: "pd1a")).not_to be_valid
  end

  it "works out ownership, size and VIP" do
    own = create(:vehicle, seats: 6, model: "Alphard")
    m = create(:vehicle, seats: 23, operator: managed)
    x = create(:vehicle, seats: 45, operator: external, tags: %w[vip])

    expect([ own, m, x ].map(&:ownership)).to eq(%w[own managed external])
    expect([ own, m, x ].map(&:size)).to eq(%w[mpv medium large])
    expect(described_class.vip).to contain_exactly(own, x)
    expect(described_class.of_size(%w[mpv large])).to contain_exactly(own, x)
    expect(described_class.of_ownership(%w[own external])).to contain_exactly(own, x)
    expect(described_class.by_type.to_a).to eq([ own, m, x ])
  end

  it "finds the default driver on a date" do
    v = create(:vehicle)
    a = create(:driver)
    b = create(:driver)
    v.driver_schedules.create!(driver: a, starts_on: Date.current - 10)
    v.driver_schedules.create!(driver: b, starts_on: Date.current + 5)

    expect(v.reload.default_driver_on(Date.current)).to eq(a)
    expect(v.default_driver_on(Date.current + 5)).to eq(b)
    expect(VehicleDriverSchedule.current_on(Date.current).pluck(:driver_id)).to eq([ a.id ])
  end
end
