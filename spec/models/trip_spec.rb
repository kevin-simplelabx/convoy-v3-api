require "rails_helper"

RSpec.describe Trip, :tenant do
  it "numbers trips from 100001 and gives a recurring trip one number per day" do
    a = create(:trip)
    b = create(:trip, :weekdays, starts_on: Date.new(2026, 11, 2), end_mode: :date, ends_on: Date.new(2026, 11, 11))
    c = create(:trip)

    expect([ a.trip_no, b.trip_no, b.trip_no_count, c.trip_no ]).to eq([ 100_001, 100_002, 10, 100_012 ])
    expect(b.trip_id_on(Date.new(2026, 11, 4))).to eq("TID100004")
  end

  it "suffixes the vehicle when there are several" do
    t = create(:trip, vehicles_count: 2)
    expect(t.trip_id_on(t.starts_on, 2)).to eq("TID#{t.trip_no}-2")
  end

  it "takes a new block when the series grows past its numbers" do
    t = create(:trip, :weekdays, end_mode: :date, ends_on: Date.new(2026, 11, 6))
    first = t.trip_no
    t.update!(ends_on: Date.new(2026, 12, 31))
    expect(t.trip_no).not_to eq(first)
    expect(t.trip_no_count).to eq(60)
  end

  it "defaults the title to the client, or the Service For customer when sub-contracted" do
    client = create(:client, name: "Eastern Coaches", kind: :transport_company)
    expect(create(:trip, title: "", client: create(:client, name: "DBS")).title).to eq("DBS")
    sub = create(:trip, title: "", client:, service_for: "Mapletree")
    expect([ sub.subcontracted, sub.title ]).to eq([ true, "Mapletree" ])
  end

  it "works out the end of a disposal and of a trip past midnight" do
    expect(create(:trip, kind: :disposal, start_time: "09:00", end_time: nil, hours: 4.5).end_time_hm).to eq("13:30")
    late = create(:trip, start_time: "23:00", end_time: "01:30")
    expect([ late.end_time, late.end_time_hm ]).to eq([ 1530, "01:30" ])
  end

  it "works out the last date of After N occurrences" do
    create(:public_holiday, date: "2026-11-04")
    t = create(:trip, :weekdays, end_mode: :count, occurrence_count: 3)
    expect(t.ends_on).to eq(Date.new(2026, 11, 5))
  end

  it "checks the form like the trip form does" do
    expect(build(:trip, end_time: "08:00")).not_to be_valid
    expect(build(:trip, :weekdays, end_mode: :date, ends_on: Date.new(2026, 1, 1))).not_to be_valid
    expect(build(:trip, kind: :airport_transfer, airport_direction: :arrival, wait_minutes: 0)).not_to be_valid
    expect(build(:trip, kind: :disposal, hours: nil)).not_to be_valid
    no_drop = build(:trip)
    no_drop.stops = [ no_drop.stops.first ]
    expect(no_drop).not_to be_valid
    expect(no_drop.errors[:base]).to include("Enter the drop-off point")
  end

  it "keeps changes to its stops in the trip's history" do
    t = create(:trip)
    t.stops.first.update!(driver_note: "Wait at the taxi stand")
    expect(t.associated_audits.last).to have_attributes(auditable_type: "TripStop", action: "update")
    expect(t.associated_audits.last.audited_changes).to include("driver_note")
  end
end
