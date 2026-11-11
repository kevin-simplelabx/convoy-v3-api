require "rails_helper"

# St-1: staging was seeded before the Q8 fix; `db:seed` must repair the St. Stephen's plans in place (seeds 45, 52, 57).
RSpec.describe "St. Stephen's seed on old data" do
  # The seeds are not request code: Bullet would flag their loops.
  around do |ex|
    Bullet.enable = false
    ex.run
  ensure
    Bullet.enable = true
  end

  it "fills stops, bus types and summaries of existing plans, and a second run changes nothing" do
    Rails.application.load_seed
    company = Company.find_by!(code: "SD")
    ActsAsTenant.with_tenant(company) do
      school = School.find_by!(name: "St. Stephen's School")
      stops = SchoolRouteStop.joins(route: :plan).where(school_plans: { school_id: school.id })
      routes = SchoolRoute.joins(:plan).where(school_plans: { school_id: school.id })
      expect(stops.count).to be > 0
      shape = -> { [ stops.order(:id).pluck(:id, :stop_point_id, :lat, :lng), routes.order(:id).pluck(:id, :bus_type, :seats, :fill), school.plans.order(:id).pluck(:id, :summary) ] }
      good = shape.call

      stops.update_all(stop_point_id: nil, stop_id: nil, lat: nil, lng: nil)
      routes.update_all(bus_type: nil, seats: nil, student_seats: nil, fill: nil)
      school.plans.update_all(summary: nil, params: nil)

      2.times do
        Rails.application.load_seed
        expect(stops.where(stop_point_id: nil).or(stops.where(lat: nil))).to be_none
        expect(routes.where(bus_type: nil)).to be_none
        expect(school.plans.where(summary: nil)).to be_none
        expect(school.plans.map { it.routes.map(&:bus_type) }.flatten).to all(be_present)
      end
      expect(shape.call).to eq(good)
    end
  end
end
