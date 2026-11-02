require "rails_helper"

RSpec.describe CalendarDay, :tenant do
  let(:school) { create(:calendar, kind: :school) }
  let(:general) { create(:calendar, kind: :general) }

  it "accepts HH:MM times and works out the change" do
    day = school.days.create!(kind: :early, starts_on: "2026-11-20", usual_time: "13:30", new_time: "11:30")
    expect([ day.usual_time, day.new_time_hm, day.time_change ]).to eq([ 810, "11:30", -120 ])
  end

  it "rejects a bad time" do
    day = school.days.build(kind: :early, starts_on: "2026-11-20", usual_time: "1:3pm", new_time: "11:30")
    expect(day).not_to be_valid
    expect(day.errors[:usual_time]).to be_present
  end

  it "only takes kinds of its calendar type" do
    expect(general.days.build(kind: :hol, starts_on: "2026-12-01")).not_to be_valid
    expect(school.days.build(kind: :shift, starts_on: "2026-12-01", shift_minutes: 30)).not_to be_valid
  end

  it "defaults the end to the start and rejects a reversed range" do
    expect(general.days.create!(kind: :off, starts_on: "2026-12-24").ends_on).to eq(Date.new(2026, 12, 24))
    expect(general.days.build(kind: :off, starts_on: "2026-12-24", ends_on: "2026-12-01")).not_to be_valid
  end

  it "fills a school calendar from the MOE preset" do
    school.apply_moe_preset!
    expect(school.days.hol.count).to eq(Calendar::MOE_PRESET.size)
  end
end
