require "rails_helper"

RSpec.describe Occurrences::Sync, :tenant do
  include ActiveJob::TestHelper

  let(:company) { ActsAsTenant.current_tenant }
  let(:bus) { create(:vehicle, plate: "PD1A") }
  let(:other_bus) { create(:vehicle, plate: "PD2B") }
  let(:driver) { create(:driver, name: "Eric") }

  # Monday 2 Nov 2026, 06:00 in Singapore
  before { travel_to Time.zone.local(2026, 11, 2, 6, 0) }

  def weekday_trip(**attrs)
    create(:trip, :weekdays, starts_on: Date.new(2026, 10, 26), start_time: "08:00", end_time: "09:00", price: 100, **attrs).tap do |t|
      t.vehicle_slots.create!(slot_no: 1, vehicle: bus)
    end
  end

  def runs(trip) = TripOccurrence.where(trip:).order(:date)

  it "stores every run up to the horizon, past dates too, and changes nothing when run again" do
    bus.driver_schedules.create!(driver:, starts_on: Date.new(2026, 10, 1))
    trip = weekday_trip
    described_class.call(trips: [ trip ])

    expect(runs(trip).first.date).to eq(Date.new(2026, 10, 26))
    expect(runs(trip).maximum(:date)).to be <= described_class.horizon
    occ = runs(trip).find_by(date: Date.new(2026, 11, 3))
    expect(occ).to have_attributes(trip_label: "TID#{trip.trip_no + 8}", start_time_hm: "08:00", vehicle_id: bus.id,
                                   driver_id: driver.id, price: 100, status: "scheduled")
    expect(occ.starts_at).to eq(Time.zone.local(2026, 11, 3, 8, 0))
    expect(described_class.call(trips: [ trip ])).to eq([])
  end

  it "changes future runs when the trip changes, never runs that have started" do
    trip = weekday_trip
    described_class.call(trips: [ trip ])
    past = runs(trip).find_by(date: Date.new(2026, 10, 30))

    trip.update!(start_time: "07:30", end_time: "08:30", price: 120)
    described_class.call(trips: [ trip ])

    expect(past.reload).to have_attributes(start_time_hm: "08:00", price: 100)
    expect(runs(trip).find_by(date: Date.new(2026, 11, 2))).to have_attributes(start_time_hm: "07:30", price: 120)
  end

  it "keeps a vehicle moved by hand and a cancelled run" do
    trip = weekday_trip
    described_class.call(trips: [ trip ])
    moved = runs(trip).find_by(date: Date.new(2026, 11, 4))
    moved.update!(vehicle: other_bus, overridden_fields: %w[vehicle_id])
    cancelled = runs(trip).find_by(date: Date.new(2026, 11, 5))
    Occurrences::Edit.new(cancelled, nil).cancel!

    trip.update!(price: 150)
    described_class.call(trips: [ trip ])

    expect(moved.reload).to have_attributes(vehicle_id: other_bus.id, price: 150)
    expect(cancelled.reload).to have_attributes(status: "cancelled", price: 150)
  end

  it "deletes future runs the trip no longer makes, keeping ones with something on them as removed" do
    trip = weekday_trip
    described_class.call(trips: [ trip ])
    wed = runs(trip).find_by(date: Date.new(2026, 11, 4))
    wed.update!(issue_reason: "Late", issue_raised_at: Time.current)

    trip.update!(days: [ 1, 2 ])
    described_class.call(trips: [ trip ])

    expect(runs(trip).find_by(date: Date.new(2026, 11, 5))).to be_nil
    expect(wed.reload.status).to eq("removed")
    expect(runs(trip).find_by(date: Date.new(2026, 10, 29))).to be_present # past Thursday kept
  end

  it "applies calendar shifts and Every Run From This Date" do
    cal = create(:calendar, kind: :general)
    cal.days.create!(kind: :shift, starts_on: "2026-11-03", shift_minutes: -30)
    trip = weekday_trip(calendar: cal)
    trip.time_changes.create!(effective_from: Date.new(2026, 11, 4), minutes: 15)
    described_class.call(trips: [ trip.reload ])

    expect(runs(trip).where(date: [ Date.new(2026, 11, 2), Date.new(2026, 11, 3), Date.new(2026, 11, 4) ]).map(&:start_time_hm))
      .to eq(%w[08:00 07:30 08:15])
  end

  it "re-syncs after a public holiday is added and after the default driver changes" do
    trip = weekday_trip
    described_class.call(trips: [ trip ])
    holiday = perform_enqueued_jobs { create(:public_holiday, date: "2026-11-09", name: "Deepavali Holiday") }
    skipped = runs(trip).find_by(date: Date.new(2026, 11, 9))
    expect(skipped).to have_attributes(status: "skipped", skip_reason: "Public holiday: Deepavali Holiday", price: 0)
    expect(runs(trip).visible.where(date: Date.new(2026, 11, 9))).to be_empty
    perform_enqueued_jobs { holiday.destroy! }
    expect(skipped.reload).to have_attributes(status: "scheduled", skip_reason: nil)

    perform_enqueued_jobs { bus.driver_schedules.create!(driver:, starts_on: Date.new(2026, 11, 10)) }
    expect(runs(trip).find_by(date: Date.new(2026, 11, 10)).driver_id).to eq(driver.id)
    expect(runs(trip).find_by(date: Date.new(2026, 11, 6)).driver_id).to be_nil
  end

  it "keeps a Driver Away when the default driver changes" do
    trip = weekday_trip
    away = create(:driver, name: "Daniel")
    Replacement.create!(kind: :drv, scope: :range, original_vehicle: bus, starts_on: "2026-11-11", ends_on: "2026-11-11", driver: away)
    described_class.call(trips: [ trip ])

    perform_enqueued_jobs { bus.driver_schedules.create!(driver:, starts_on: Date.new(2026, 11, 10)) }
    expect(runs(trip).where(date: [ Date.new(2026, 11, 10), Date.new(2026, 11, 11) ]).map(&:driver_id)).to eq([ driver.id, away.id ])
  end

  it "gives runs on a managed bus the operator driver put on it" do
    operator = create(:operator)
    managed = create(:vehicle, operator:)
    trip = weekday_trip.tap { |t| t.vehicle_slots.first.update!(vehicle: managed) }
    described_class.call(trips: [ trip ])
    od = create(:operator_driver, operator:)

    perform_enqueued_jobs { od.assign_vehicle!(managed) }
    expect(runs(trip).find_by(date: Date.new(2026, 11, 3)).operator_driver_id).to eq(od.id)
    perform_enqueued_jobs { od.assign_vehicle!(nil) }
    expect(runs(trip).find_by(date: Date.new(2026, 11, 3)).operator_driver_id).to be_nil
  end

  it "labels shuttle runs by run and vehicle" do
    t = build(:trip, :weekdays, kind: :corporate_shuttle, starts_on: Date.new(2026, 11, 2), vehicles_count: 2, pax: 25)
    t.stops.each_with_index { |s, i| s.position = i }
    t.runs.build(direction: 1, position: 0, times: %w[07:30 08:00])
    t.runs.build(direction: 1, position: 1, times: %w[08:30 09:00])
    t.save!
    Trips::Timetable.call(t)
    described_class.call(trips: [ t ])

    day = TripOccurrence.where(trip: t, date: Date.new(2026, 11, 3)).order(:start_time, :slot_no)
    expect(day.map(&:trip_label)).to eq(%W[TID#{t.trip_no + 1}-1 TID#{t.trip_no + 1}-2 TID#{t.trip_no + 1}-3 TID#{t.trip_no + 1}-4])
    expect(day.map(&:pax)).to eq([ 13, 12, 13, 12 ])
    expect(day.map(&:start_time_hm).uniq).to eq(%w[07:30 08:30])
  end

  it "completes runs that ended and pushes the horizon each day" do
    trip = weekday_trip
    described_class.call(trips: [ trip ])
    travel_to Time.zone.local(2026, 11, 3, 10, 0)
    Occurrences::Daily.call
    expect(runs(trip).find_by(date: Date.new(2026, 11, 3)).status).to eq("completed")
    last_weekday = described_class.horizon.downto(described_class.horizon - 6).find(&:on_weekday?)
    expect(runs(trip).maximum(:date)).to eq(last_weekday)
  end

  # Horizon on Mon 2 Nov 2026 = Tue 2 Mar 2027. Rules for later dates are kept and used when the daily job reaches them.
  it "stores nothing past the horizon, then applies a one-off trip and an assignment booked there as the horizon moves" do
    trip = weekday_trip
    far = Date.new(2027, 3, 5)
    one_off = create(:trip, starts_on: far).tap { |t| t.vehicle_slots.create!(slot_no: 1, vehicle: bus) }
    Assignments::Create.call(trip:, effective_from: Date.new(2027, 3, 3), slots: [ [ nil, 1 ] ], assignee: :own, vehicle: other_bus, user: nil)
    described_class.call(trips: [ trip, one_off ])
    expect(TripOccurrence.maximum(:date)).to eq(Date.new(2027, 3, 2))

    (3..5).each do |day|
      travel_to Time.zone.local(2026, 11, day, 1, 30)
      Occurrences::Daily.call
    end
    expect(runs(trip).where(date: Date.new(2027, 3, 2)..).map { |o| [ o.date.day, o.vehicle_id ] })
      .to eq([ [ 2, bus.id ], [ 3, other_bus.id ], [ 4, other_bus.id ], [ 5, other_bus.id ] ])
    expect(runs(one_off).pluck(:date)).to eq([ far ])
  end
end
