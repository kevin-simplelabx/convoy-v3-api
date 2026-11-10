require "rails_helper"

RSpec.describe Stops::Archive do
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

  it "archives the stop and unassigns riders left on its points" do
    within_tenant(company) do
      school.rider_assignments.create!(rid: "R1", stop_point: stop.points.first)
      expect(described_class.call(stop)).to eq(1)
      expect([ stop.reload.discarded?, RiderAssignment.count ]).to eq([ true, 0 ])
    end
  end

  it "refuses while a school uses the stop, changing nothing" do
    within_tenant(company) do
      SchoolStop.create!(school:, stop:)
      school.rider_assignments.create!(rid: "R1", stop_point: stop.points.first)
      expect { described_class.call(stop) }.to raise_error(ApplicationService::Error, "Unlink BDSZ03-0001 from every school first")
      expect([ stop.reload.discarded?, RiderAssignment.count ]).to eq([ false, 1 ])
    end
  end
end
