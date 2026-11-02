require "rails_helper"

RSpec.describe "Calendars and public holidays" do
  let(:company) { create(:company) }

  before { sign_in_as(create(:user, company:)) }

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
end
