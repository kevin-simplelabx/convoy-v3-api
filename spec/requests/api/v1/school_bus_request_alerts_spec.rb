require "rails_helper"

# School Bus › bus request alerts: what needs someone across the user's schools (overdue first), the summary for the
# bell and strip, and the 08:00 email recorded once a day for School Bus admins; Release Now of the welcome message.
RSpec.describe "School Bus request alerts" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, role: "admin") }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      rider = school.riders.create!(rid: "R1", name: "Lim Kai", postal: "460101", source: "manual")
      base = { submitted_at: Time.zone.local(2026, 10, 20, 10), parent_name: "Parent", child_name: "Lee Ryan" }
      school.bus_requests.create!(base.merge(academic_year: year))
      school.bus_requests.create!(base.merge(kind: "adr", child_name: "Lim Kai", school_rider: rider, effective_on: "2026-11-16"))
      school.bus_requests.create!(base.merge(kind: "stop", child_name: "Lim Kai", school_rider: rider, status: "Stopping", last_on: "2026-10-30"))
      create(:user, company:, permissions: %w[finance])
      { school:, year: }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
  end

  it "lists what needs attention, records the 08:00 email once and releases the welcome message" do
    get alerts_api_v1_bus_requests_path
    expect(json[:data].map { [ it[:child_name], it[:what], it[:text], it[:tone] ] }).to eq([
      [ "Lee Ryan", "New bus request", "Acknowledge was due Fri 23/10", "over" ],
      [ "Lim Kai", "Leaving", "The last day has passed. End the rider", "soon" ],
      [ "Lim Kai", "Change of address", "Moves Mon 16/11. Not opened yet", "ok" ]
    ])
    expect(json[:meta]).to include(count: 3, overdue: 1, text: "1 to acknowledge | 1 change of address | 1 to take off the rider list | 1 overdue")

    get digest_api_v1_bus_requests_path
    expect(json[:data]).to include(to: [ user.name ], subject: "Bus requests waiting: 1 to acknowledge, 1 change of address, 1 to take off the rider list, 1 overdue")
    within_tenant(company) do
      expect(BusRequests::Digest.new(company).call).to eq(1)
      expect(BusRequests::Digest.new(company).call).to eq(0)
      expect(NotificationEmail.last.body).to include("St. Stephen's School", "- Lee Ryan, New bus request: Acknowledge was due Fri 23/10")
    end

    put api_v1_academic_year_registration_path(f[:year]), params: { messages: [ { key: "wel", enabled: true } ] }, as: :json
    within_tenant(company) { f[:year].reload.registration.update!(status: "scheduled") }
    post release_api_v1_academic_year_registration_path(f[:year]), params: { key: "inv" }, as: :json
    expect(json.dig(:error, :message)).to eq("#{RegistrationMessage::PRESETS['inv'][:name]} goes out by itself")
    post release_api_v1_academic_year_registration_path(f[:year]), params: { key: "wel" }, as: :json
    expect(json[:data][:messages].find { it[:key] == "wel" }[:released_at]).to be_present
  end
end
