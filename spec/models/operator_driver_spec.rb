require "rails_helper"

RSpec.describe OperatorDriver, :tenant do
  let(:operator) { create(:operator) }
  let(:bus1) { create(:vehicle, operator:) }
  let(:bus2) { create(:vehicle, operator:) }

  it "swaps with the driver already on the bus" do
    a = create(:operator_driver, operator:, vehicle: bus1)
    b = create(:operator_driver, operator:, vehicle: bus2)

    a.assign_vehicle!(bus2)
    expect([ a.reload.vehicle, b.reload.vehicle ]).to eq([ bus2, bus1 ])
  end

  it "only sits on a bus of its own operator" do
    other = create(:vehicle, operator: create(:operator))
    expect(build(:operator_driver, operator:, vehicle: other)).not_to be_valid
  end

  it "leaves the bus when no longer active" do
    a = create(:operator_driver, operator:, vehicle: bus1)
    a.update!(status: :past)
    expect(a.vehicle).to be_nil
  end
end
