require "rails_helper"

# School Bus › Bus Service Registration of an academic year: Convoy OS defaults from the first school day, the checks,
# Schedule only once calendar / sessions / fares are locked and a policy is in use, message timing, Unschedule.
RSpec.describe "School Bus registration settings" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, permissions: %w[plans]) }
  let!(:year) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      %w[P1 P6].each_with_index { |n, i| school.levels.create!(name: n, position: i, final: n == "P6") }
      AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
  end

  it "starts from the defaults, checks the dates and saves a draft with its messages" do
    get api_v1_academic_year_registration_path(year)
    d = json[:data]
    start = Date.parse(d[:service_starts_on])
    expect(d).to include(saved: false, status: "draft", state: "draft", confirm_hours: 48, sessions: %w[AM PM CCA], run_mode: "arrive", run_at: "09:00",
                         renew_from: (start - 122).iso8601, general_to: (start + 242).iso8601, final_levels: %w[P6])
    expect(d[:ready].map { |r| r[:ok] }).to eq([ false, false, false, false ])
    expect(d[:messages].map { |m| m[:key] }).to eq(%w[inv grad rem last open recv offer crem wl lapse rej wel])
    expect(d[:messages].find { it[:key] == "rem" }).to include(offset_days: -7, sends_on: (start - 79 - 7).iso8601)
    expect(d[:messages].find { it[:key] == "wel" }).to include(manual: true, sends_on: nil)

    put api_v1_academic_year_registration_path(year), params: { general_from: d[:renew_to] }, as: :json
    expect(json.dig(:error, :message)).to eq("The general window must open after the early window closes")
    put api_v1_academic_year_registration_path(year), params: { sessions: [] }, as: :json
    expect(json.dig(:error, :message)).to eq("Pick at least one session")

    msgs = [ { key: "rem", offset_days: 10 }, { key: "crem", offset_hours: 12 }, { key: "inv", offset_days: 5, enabled: false },
             { key: "wel", scheduled: true, subject: "Welcome aboard" } ]
    put api_v1_academic_year_registration_path(year), params: { levels: %w[P1 X9], auto_near: true, near_km: 2.5, run_mode: "daily", run_at: "08:30",
                                                                   messages: msgs }, as: :json
    d = json[:data]
    expect(d).to include(saved: true, status: "draft", levels: %w[P1], auto_near: true, near_km: "2.5", run_at: "08:30", saved_by: user.name)
    m = d[:messages].index_by { it[:key] }
    expect(m["rem"]).to include(offset_days: -10)
    expect(m["crem"]).to include(offset_hours: 12)
    expect(m["inv"]).to include(enabled: false, offset_days: 0)
    expect(m["wel"]).to include(scheduled: true, subject: "Welcome aboard", sends_on: (start - 7).iso8601)
    expect(within_tenant(company) { RegistrationMessage.count }).to eq(12)
  end

  it "schedules once the year is set up, shows the window state and moves back to draft" do
    post schedule_api_v1_academic_year_registration_path(year), as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json[:error]).to include(code: "not_ready", message: "Finish Terms & Semesters, Bus Sessions, Bus Fares, Payment & Refund Policy before scheduling")

    within_tenant(company) do
      %w[calendar sessions fares].each { SchoolSetup.lock!(school: year.school, year:, section: it, user:) }
      Policies::Publish.call(year.school, Policies.default.merge(effective_on: Date.current), user:)
    end
    post schedule_api_v1_academic_year_registration_path(year), params: { renew_from: "2026-11-01", renew_to: "2026-11-20", general_from: "2026-11-25" }, as: :json
    expect(json[:data]).to include(status: "scheduled", state: "renewals_open")
    expect(json[:data][:ready].pluck(:ok)).to all(be(true))

    travel_to Time.zone.local(2026, 11, 21, 9, 0)
    sign_in_as(user)
    get api_v1_academic_year_registration_path(year)
    expect(json[:data][:state]).to eq("general_upcoming")

    post unschedule_api_v1_academic_year_registration_path(year), as: :json
    expect(json[:data]).to include(status: "draft", state: "draft")
  end

  it "only releases a manual message of a scheduled registration once, and only unschedules a scheduled one" do
    within_tenant(company) do
      %w[calendar sessions fares].each { SchoolSetup.lock!(school: year.school, year:, section: it, user:) }
      Policies::Publish.call(year.school, Policies.default.merge(effective_on: Date.current), user:)
    end
    post unschedule_api_v1_academic_year_registration_path(year), as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Registration is already a draft")

    put api_v1_academic_year_registration_path(year), params: { messages: [ { key: "wel" } ] }, as: :json
    post release_api_v1_academic_year_registration_path(year), params: { key: "wel" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Schedule the registration before releasing a message")

    post schedule_api_v1_academic_year_registration_path(year), as: :json
    expect(response).to have_http_status(:ok)
    post release_api_v1_academic_year_registration_path(year), params: { key: "wel" }, as: :json
    expect(response).to have_http_status(:ok)
    post release_api_v1_academic_year_registration_path(year), params: { key: "wel" }, as: :json
    expect(json.dig(:error, :message)).to end_with("was already released")

    put api_v1_academic_year_registration_path(year), params: { messages: [ { key: "wel", scheduled: true } ] }, as: :json
    post release_api_v1_academic_year_registration_path(year), params: { key: "wel" }, as: :json
    expect(json.dig(:error, :message)).to end_with("is sent automatically by date")
    post release_api_v1_academic_year_registration_path(year), params: { key: "rem" }, as: :json
    expect(json.dig(:error, :message)).to end_with("goes out by itself")
  end
end
