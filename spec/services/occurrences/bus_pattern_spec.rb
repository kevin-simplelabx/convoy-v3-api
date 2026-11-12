require "rails_helper"

RSpec.describe Occurrences::BusPattern, :tenant do
  let(:trip) { instance_double(Trip, corporate_shuttle?: true, recurring?: true, no_fixed_bus: false, id: 1) }
  let(:scope) { instance_double(ActiveRecord::Relation) }
  let(:top) { create(:vehicle, plate: "PD1125G") }

  def run(vehicle_id, moved:) = instance_double(TripOccurrence, vehicle_id:, overridden?: moved)

  def pattern_for(current_vehicle_id, rows)
    occ = instance_double(TripOccurrence, trip:, persisted?: true, trip_run_id: 5, slot_no: 1, date: Date.new(2026, 11, 17), vehicle_id: current_vehicle_id)
    allow(TripOccurrence).to receive(:visible).and_return(scope)
    allow(scope).to receive_messages(where: scope, order: scope, limit: scope, to_a: rows)
    described_class.call(occ)
  end

  it "suggests the bus most hand moves went to while the run is on another bus" do
    rows = [ run(top.id, moved: true), run(top.id, moved: true), run(top.id, moved: true), run(9, moved: false) ]
    expect(pattern_for(9, rows)).to include(suggest: true, moved: 3, top_vehicle_id: top.id, top_plate: "PD1125G")
  end

  it "stops suggesting once the run is on that bus (after Make it the Regular Bus)" do
    rows = [ run(top.id, moved: true), run(top.id, moved: true), run(top.id, moved: true), run(top.id, moved: true) ]
    expect(pattern_for(top.id, rows)).to include(suggest: false, moved: 0, top_vehicle_id: nil)
  end
end
