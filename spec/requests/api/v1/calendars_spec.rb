require "rails_helper"

RSpec.describe "Calendars and public holidays" do
  let(:company) { create(:company) }

  before { sign_in_as(create(:user, company:, permissions: %w[vehicles])) }

  it "creates a school calendar from the MOE preset and copies it" do
    post api_v1_calendars_path, params: { calendar: { name: "MOE", kind: "school" }, start_from: "moe" }, as: :json
    expect(response).to have_http_status(:created)
    moe = json[:data]
    expect(moe[:days].size).to eq(Calendar::MOE_PRESET.size)

    post api_v1_calendars_path, params: { calendar: { name: "Copy", kind: "school" }, start_from: moe[:id].to_s }, as: :json
    expect(json.dig(:data, :days).size).to eq(moe[:days].size)
  end

  it "adds a day (Change a Day) with HH:MM times" do
    cal = within_tenant(company) { create(:calendar, kind: :school) }
    post api_v1_calendar_days_path(cal),
         params: { calendar_day: { kind: "late", starts_on: "2026-11-12", usual_time: "07:30", new_time: "09:00" } }, as: :json
    expect(response).to have_http_status(:created)
    expect(json[:data]).to include(kind_name: "Late Arrival", usual_time: "07:30", time_change: 90)
  end

  it "imports the MOM dates once and lists them by year" do
    post import_api_v1_public_holidays_path, params: { year: 2027 }, as: :json
    expect(json.dig(:meta, :added)).to eq(12)
    post import_api_v1_public_holidays_path, params: { year: 2027 }, as: :json
    expect(json.dig(:meta, :added)).to eq(0)

    get api_v1_public_holidays_path, params: { year: 2027 }
    expect(json[:data].first).to include(date: "2027-01-01", name: "New Year's Day")
    expect(json[:data].find { |h| h[:date] == "2027-02-08" }).to include(observed: true)
  end

  it "adds the observed Monday for a Sunday holiday, with the year's card numbers" do
    post api_v1_public_holidays_path, params: { public_holiday: { date: "2026-08-09", name: "National Day" } }, as: :json
    expect(response).to have_http_status(:created)
    expect(json.dig(:meta, :observed)).to include(date: "2026-08-10", name: "National Day Holiday", observed: true)
    post api_v1_public_holidays_path, params: { public_holiday: { date: "2026-08-10", name: "Again" } }, as: :json
    expect(json.dig(:error, :details, :date)).to eq([ "Date is already a public holiday" ])

    get api_v1_public_holidays_path, params: { year: 2026 }
    expect(json[:meta]).to include(year: 2026, count: 2, weekdays: 1, preset_available: true)
    expect(json.dig(:meta, :preset_missing)).to be > 0
  end

  it "lists calendars with trips counts, filters days by year and shows the trips using a calendar" do
    cal = within_tenant(company) do
      cal = create(:calendar, name: "Google Office")
      create(:calendar_day, calendar: cal, starts_on: Date.new(2026, 12, 25))
      create(:calendar_day, calendar: cal, starts_on: Date.new(2027, 1, 4))
      create(:trip, title: "Office Shuttle", days: [ 1, 2, 3, 4, 5 ], end_mode: "never", calendar: cal, starts_on: Date.new(2026, 11, 2))
      PublicHoliday.create!(date: Date.new(2026, 12, 25), name: "Christmas Day")
      cal
    end

    get api_v1_calendars_path
    expect(json[:data].first).to include(name: "Google Office", trips_count: 1)

    get api_v1_calendar_path(cal), params: { year: 2027 }
    expect(json.dig(:data, :days).pluck(:starts_on)).to eq([ "2027-01-04" ])

    get trips_api_v1_calendar_path(cal), params: { year: 2026 }
    expect(json[:meta]).to eq(year: 2026)
    expect(json[:data].first).to include(title: "Office Shuttle", repeat_text: "Every weekday", start_time: "08:00",
                                         runs_skipped: 1, skipped: [ { date: "2026-12-25", reason: "Public holiday: Christmas Day" } ])

    post api_v1_calendars_path, params: { calendar: { name: "public holidays", kind: "general" } }, as: :json
    expect(json.dig(:error, :details, :name)).to eq([ "Name is the built-in calendar's name" ])
    patch api_v1_calendar_path(cal), params: { calendar: { name: "google office", kind: "school" } }, as: :json
    expect(json.dig(:error, :details, :kind)).to eq([ "Kind can't be changed" ])
  end

  it "lets only users with the vehicles or finance permission change calendars" do
    sign_in_as(create(:user, company:, permissions: %w[finview]))
    get api_v1_calendars_path
    expect(response).to have_http_status(:ok)
    post api_v1_public_holidays_path, params: { public_holiday: { date: "2026-12-25", name: "Christmas Day" } }, as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
