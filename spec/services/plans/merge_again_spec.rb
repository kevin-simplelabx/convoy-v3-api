require "rails_helper"

# Route Again: routes matched by number and updated in place, leftovers dropped with their runs, locked routes kept with
# their engine original, the summary rebuilt; never on an adopted plan.
RSpec.describe Plans::MergeAgain do
  let(:company) { create(:company) }
  let!(:school) { school_with_stops(company) } # 4 stops x 3 riders: AM 1 = Stop 1 + 2, AM 2 = Stop 3 + 4

  before { travel_to Time.zone.local(2026, 11, 2, 9, 0) }

  # A Route Again run of the plan as the controller makes it: riders on locked routes left out.
  def again(plan)
    keep = plan.routes.where(locked: true).joins(:riders).pluck("school_route_riders.rid")
    input = Routing::Input.new(school, plan.session, plan.effective_from).call
    input[:groups] = input[:groups].filter_map { |g| g.merge(riders: g[:riders] - keep).then { it[:riders].empty? ? nil : it } }
    run = RoutingRun.create!(school:, session: plan.session, plan_date: plan.effective_from, params: input[:params], input:, kind: "again", target_plan: plan,
                             result: fake_routing.solve(input), status: "running")
    described_class.call(run)
  end

  it "updates the unlocked route with the same number in place and keeps the locked one" do
    within_tenant(company) do
      plan = engine_plan(school)
      am1, am2 = plan.routes.to_a
      am1.update!(locked: true)
      am2.update!(hidden: true, edited: true, vias: [ [ [ 1.33, 103.93 ] ] ])
      bus = create(:vehicle)
      am2.vehicle_changes.create!(vehicle: bus, effective_from: Date.current)
      am2.prices.create!(effective_from: Date.current.beginning_of_month, mode: "fixed", monthly: 3000)

      again(plan)
      plan.reload
      expect(plan.routes.map(&:id)).to eq([ am1.id, am2.id ])
      expect(am2.reload).to have_attributes(number: 2, label: "AM 2", route_key: "R02", hidden: false, edited: false, vias: [], riders_count: 6)
      expect([ am2.vehicle_changes.count, am2.prices.count ]).to eq([ 1, 1 ])
      expect(plan.routing_run.result["routes"].map { it["id"] }).to eq(%w[R01 R02]) # the locked route's original stays for Reset
      expect { Plans::Edit.new(plan).reset(am1.reload) }.not_to raise_error
      expect(plan.summary).to include("routes" => 2, "assigned" => 12, "fixed" => 960.0, "run" => 40.0, "overtime" => 0.0, "floor" => 0.0,
                                      "stability" => 0.0, "total" => 1000.0, "slots" => { "07:10" => 2 })
    end
  end

  it "drops unlocked routes the run no longer needs, with their runs that have not started" do
    within_tenant(company) do
      plan = engine_plan(school)
      am2 = plan.routes.second
      am2.prices.create!(effective_from: Date.current.beginning_of_month, mode: "fixed", monthly: 3000)
      plan.update!(in_use: true) # runs made while it was adopted, then back to draft
      Occurrences::Sync.call(routes: [ am2.id ], from: Date.current + 1, to: Date.current + 3)
      plan.update!(in_use: false)
      expect(TripOccurrence.where(school_route_id: am2.id).count).to be_positive
      school.riders.where("rid LIKE 'R3%' OR rid LIKE 'R4%'").delete_all # the run plans one route now

      again(plan)
      expect(plan.reload.routes.map(&:label)).to eq([ "AM 1" ])
      expect([ TripOccurrence.where(school_route_id: am2.id).count, SchoolRoutePrice.where(school_route_id: am2.id).count ]).to eq([ 0, 0 ])
    end
  end

  it "refuses an adopted plan" do
    within_tenant(company) do
      plan = engine_plan(school)
      plan.update!(in_use: true)
      expect { again(plan) }.to raise_error(ApplicationService::Error, "Make a new plan to route again")
    end
  end
end
