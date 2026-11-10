require "rails_helper"

RSpec.describe SchoolStops::Unlink do
  let(:company) { create(:company) }
  let(:school) { within_tenant(company) { School.create!(name: "St. Stephen's School") } }
  let(:stop) do
    within_tenant(company) do
      Stop.new(code: "BDSZ03-0001", subzone_code: "BDSZ03", name: "Blk 101").tap do |s|
        s.all_points.build(suffix: "A", usage: "both", sizes: %w[S], primary: true, lat: 1.33, lng: 103.93)
        s.save!
      end
    end
  end

  it "removes the link, the hand links and the assignments at the stop's points in one go" do
    within_tenant(company) do
      SchoolStop.create!(school:, stop:)
      school.rider_assignments.create!(rid: "R1", stop_point: stop.points.first)
      school.rider_point_links.create!(rid: "R1", stop_point: stop.points.first, kind: "alternative")
      expect(described_class.call(school, stop)).to eq(1)
      expect([ school.school_stops.count, school.rider_assignments.count, school.rider_point_links.count ]).to eq([ 0, 0, 0 ])
    end
  end

  it "raises not found when the school does not use the stop" do
    within_tenant(company) { expect { described_class.call(school, stop) }.to raise_error(ActiveRecord::RecordNotFound) }
  end
end
