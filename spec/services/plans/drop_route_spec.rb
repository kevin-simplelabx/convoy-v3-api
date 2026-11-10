require "rails_helper"

# Deleting a plan route: every child table cleaned (no FK error), runs not started deleted, a route whose runs are
# history refused.
RSpec.describe Plans::DropRoute do
  let(:company) { create(:company) }
  let!(:school) { school_with_stops(company) }

  before { travel_to Time.zone.local(2026, 11, 2, 9, 0) }

  it "deletes a route with its buses, prices, replacements, notice targets and runs not started; charges keep their row" do
    within_tenant(company) do
      plan = engine_plan(school)
      route = plan.routes.first
      bus = create(:vehicle)
      route.vehicle_changes.create!(vehicle: bus, effective_from: Date.current)
      route.prices.create!(effective_from: Date.current.beginning_of_month, mode: "fixed", monthly: 3000)
      route.replacements.create!(vehicle: create(:vehicle), starts_on: Date.current + 1, ends_on: Date.current + 2, arranged_by: "operator")
      charge = RouteCharge.create!(school:, school_route: route, starts_on: Date.current, kind: "amt", value: 50, reason: "Long route")
      plan.update!(in_use: true)
      Occurrences::Sync.call(routes: [ route.id ], from: Date.current + 1, to: Date.current + 2)
      plan.update!(in_use: false)

      described_class.call(route)
      expect(SchoolRoute.exists?(route.id)).to be(false)
      expect([ TripOccurrence, SchoolRouteStop, SchoolRouteVehicleChange, SchoolRoutePrice, SchoolRouteReplacement ].map { it.where(school_route_id: route.id).count })
        .to eq([ 0, 0, 0, 0, 0 ])
      expect(charge.reload.school_route_id).to be_nil
    end
  end

  it "refuses a route whose runs started or have records" do
    within_tenant(company) do
      plan = engine_plan(school)
      route = plan.routes.first
      plan.update!(in_use: true)
      Occurrences::Sync.call(routes: [ route.id ], from: Date.current + 1, to: Date.current + 1)
      run = TripOccurrence.where(school_route_id: route.id).first
      note = OccurrenceNote.create!(occurrence_id: run.id, occurrence_date: run.date, body: "Gate B closed")
      expect { described_class.call(route) }.to raise_error(ApplicationService::Error, "AM 1 has runs on the Scheduler that started or have records, so it cannot be removed")

      note.destroy!
      travel_to run.starts_at + 1.minute
      expect { described_class.call(route) }.to raise_error(ApplicationService::Error, /AM 1 has runs/)
    end
  end
end
