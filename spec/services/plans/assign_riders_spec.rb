require "rails_helper"

# An AM plan writes its riders' PUDO points when it starts (Convoy OS promotePlan): Adopt from today at once, a scheduled
# adoption on its start day (daily job), once per plan; Cancel of a scheduled plan leaves the current plan's points.
RSpec.describe Plans::AssignRiders do
  let(:company) { create(:company) }
  let!(:school) { school_with_stops(company) }
  let(:user) { within_tenant(company) { create(:user, company:) } }

  before { travel_to Time.zone.local(2026, 11, 2, 9, 0) }

  def plan_of(id) = school.rider_assignments.distinct.pluck(:school_plan_id) == [ id ]

  it "assigns at adoption from today, not for a scheduled adoption, and leaves them on Cancel" do
    within_tenant(company) do
      first = engine_plan(school)
      second = engine_plan(school)
      Plans::Adopt.call(first, from: Date.current, user:)
      expect(school.rider_assignments.count).to eq(12)
      expect(plan_of(first.id)).to be(true)
      expect(first.reload.riders_assigned_at).to be_present

      Plans::Adopt.call(second, from: Date.current + 14, user:)
      expect(plan_of(first.id)).to be(true)
      expect(second.reload.riders_assigned_at).to be_nil

      Plans::Adopt.cancel(second.reload)
      expect(plan_of(first.id)).to be(true)
    end
  end

  it "assigns a scheduled AM plan on its start day once" do
    within_tenant(company) do
      first = engine_plan(school)
      second = engine_plan(school)
      Plans::Adopt.call(first, from: Date.current, user:)
      Plans::Adopt.call(second, from: Date.current + 14, user:)
      described_class.due
      expect(plan_of(first.id)).to be(true)

      travel_to Time.zone.local(2026, 11, 16, 1, 30)
      described_class.due
      expect(plan_of(second.id)).to be(true)
      stamp = second.reload.riders_assigned_at
      school.rider_assignments.delete_all
      described_class.due
      expect([ school.rider_assignments.count, second.reload.riders_assigned_at ]).to eq([ 0, stamp ])
    end
  end
end
