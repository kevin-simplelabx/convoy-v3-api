require "rails_helper"

RSpec.describe Calendars::Context, :tenant do
  let(:company) { ActsAsTenant.current_tenant }
  let(:school) { create(:calendar, kind: :school) }
  let(:general) { create(:calendar, kind: :general, observed_holidays: :work) }
  let(:ctx) { described_class.for(company, from: Date.new(2026, 1, 1), to: Date.new(2027, 12, 31)) }

  before do
    create(:public_holiday, date: "2026-08-10", name: "National Day Holiday", observed: true)
    create(:public_holiday, date: "2026-12-25", name: "Christmas Day")
    school.days.create!(kind: :hol, starts_on: "2026-11-21", ends_on: "2026-12-31", label: "Year-End Holidays")
    school.days.create!(kind: :early, starts_on: "2026-11-20", usual_time: "13:30", new_time: "11:30")
    school.days.create!(kind: :late, starts_on: "2026-11-19", usual_time: "07:30", new_time: "09:00")
    general.days.create!(kind: :work, starts_on: "2026-12-25")
    general.days.create!(kind: :shift, starts_on: "2026-12-31", shift_minutes: -60)
  end

  it "skips public holidays unless the calendar works or treats observed days as working" do
    expect(ctx.skips_public_holiday?(true, nil, Date.new(2026, 12, 25))).to be(true)
    expect(ctx.skips_public_holiday?(false, nil, Date.new(2026, 12, 25))).to be(false)
    expect(ctx.skips_public_holiday?(true, general.id, Date.new(2026, 12, 25))).to be(false)
    expect(ctx.skips_public_holiday?(true, general.id, Date.new(2026, 8, 10))).to be(false)
    expect(ctx.skips_public_holiday?(true, school.id, Date.new(2026, 8, 10))).to be(true)
  end

  it "knows calendar days off" do
    expect(ctx.day_off(school.id, Date.new(2026, 12, 1))).to eq("Year-End Holidays")
    expect(ctx.day_off(school.id, Date.new(2026, 11, 20))).to be_nil
  end

  it "moves afternoon trips on early dismissal, morning trips on late arrival, every trip on changed times" do
    expect(ctx.time_shift(school.id, Date.new(2026, 11, 20), Clock.minutes("13:45"))).to eq(-120)
    expect(ctx.time_shift(school.id, Date.new(2026, 11, 20), Clock.minutes("07:00"))).to eq(0)
    expect(ctx.time_shift(school.id, Date.new(2026, 11, 19), Clock.minutes("07:00"))).to eq(90)
    expect(ctx.time_shift(school.id, Date.new(2026, 11, 19), Clock.minutes("07:00"), "pm")).to eq(0)
    expect(ctx.time_shift(general.id, Date.new(2026, 12, 31), 600)).to eq(-60)
  end

  it "finds the n-th run date" do
    d = ctx.nth_run_date(Date.new(2026, 12, 21), days: [ 1, 2, 3, 4, 5 ], count: 5, skip_public_holidays: true, calendar_id: nil)
    expect(d).to eq(Date.new(2026, 12, 28)) # 21 22 23 24 (25 PH) 28
  end
end
