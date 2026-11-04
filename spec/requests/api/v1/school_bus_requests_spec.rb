require "rails_helper"

# School Bus › Bus Service Requests: Add Application (checks, map location), the list (renewals first, tiles, filters,
# search), opening a request, Waitlist / Decline / Message in bulk, and mid-year requests (acknowledge within working
# days, answer date moved with a reason, overdue first).
RSpec.describe "School Bus requests" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, permissions: %w[plans]) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      %w[P5 P6].each_with_index { |n, i| school.levels.create!(name: n, position: i, final: n == "P6") }
      this = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      nxt = AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
      rider = school.riders.create!(rid: "R1", name: "Tan Wei Ming", grade: "P5", postal: "460101", lat: 1.33, lng: 103.93, source: "manual")
      school.riders.create!(rid: "R2", name: "Lim Xin Yi", grade: "P5", postal: "460102", source: "manual")
      school.riders.create!(rid: "R3", name: "Goh Kai", grade: "P6", postal: "460103", source: "manual")
      app = lambda do |child, year, at, **o|
        school.bus_requests.create!(academic_year: year, child_name: child, parent_name: "Parent of #{child}", submitted_at: at, **o)
              .tap { it.log!("Requested in the Convoy App", by: "Parent", at:) }
      end
      { school:, this:, nxt:, rider:, app: }
    end
  end
  let(:school) { f[:school] }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
  end

  def board(**q) = get(api_v1_school_bus_requests_path(school), params: q).then { json }

  it "adds applications, lists renewals first with tiles and filters, opens and decides" do
    fake_one_map.add("460216", 1.334, 103.934, "Blk 216 Bedok North")
    path = api_v1_school_bus_requests_path(school)
    post path, params: { academic_year_id: f[:nxt].id, child_name: "Ng Jun Jie", parent_name: "Ng Mei", postal: "4602" }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter a 6-digit postal code")
    post path, params: { academic_year_id: f[:nxt].id, child_name: "Ng Jun Jie", parent_name: "Ng Mei", postal: "460216", am: false, pm: false }, as: :json
    expect(json.dig(:error, :message)).to eq("Pick AM, PM or both")
    post path, params: { academic_year_id: f[:nxt].id, child_name: "Ng Jun Jie", parent_name: "Ng Mei", parent_phone: "+65 9123 4567", postal: "460216",
                         level: "Sec 1", pm: false, fee_paid: false }, as: :json
    expect(response).to have_http_status(:created)
    added = json[:data]
    expect(added).to include(code: "REQ-0001", source: "console", status: "Requested", address: "Blk 216 Bedok North", located: true, am: true, pm: false,
                             tags: %w[New], academic_year: "2027")
    expect(added[:events].first[:text]).to eq("Added by #{user.name} on the parent's behalf. Registration fee not yet received")

    within_tenant(company) do
      f[:app].("Tan Wei Ming", f[:nxt], 3.days.ago, school_rider: f[:rider], renew: true, tags: %w[Renewing], level: "P6")
      f[:app].("Chua Hui Min", f[:nxt], 2.days.ago, level: "P5")
    end
    d = board
    expect(d[:data].map { it[:child_name] }).to eq([ "Tan Wei Ming", "Chua Hui Min", "Ng Jun Jie" ])
    expect(d[:meta]).to include(year: "2027", count: 3, service_check: { none: true, plan: nil }) # "No AM route plan with routes yet"
    tiles = d[:meta][:tiles].to_h { [ it[:label], it[:count] ] }
    expect(tiles).to include("Requested" => 3, "From the App" => 2, "Renewing" => 1, "New" => 2, "Not Yet Renewed" => 1)
    expect(tiles).not_to have_key("Mid-Year")
    expect(d[:meta][:years].map { [ it[:key], it[:tag], it[:to_review] ] }).to eq([ [ "2026", "This Year", 0 ], [ "2027", "Next Year", 3 ] ])
    expect(board(tag: "Renewing")[:data].size).to eq(1)
    expect(board(session: "PM")[:data].size).to eq(2)
    expect(board(q: "9123")[:data].map { it[:code] }).to eq(%w[REQ-0001])

    ids = d[:data].map { it[:id] }
    post open_api_v1_bus_request_path(ids[0])
    expect(json[:data]).to include(status: "Under Review", can: hash_including(waitlist: true, acknowledge: false))

    post decide_api_v1_school_bus_requests_path(school), params: { ids: ids.last(2), to: "Waitlisted", reason: "Sold out" }, as: :json
    expect(json.dig(:error, :message)).to eq("Pick a reason from the list")
    post decide_api_v1_school_bus_requests_path(school), params: { ids: ids.last(2), to: "Waitlisted", reason: "New area", note: "Check in March" }, as: :json
    expect(json[:data]).to eq(updated: 2)
    post decide_api_v1_school_bus_requests_path(school), params: { ids: ids.last(1), to: "Waitlisted" }, as: :json
    expect(json.dig(:error, :message)).to eq("Ng Jun Jie cannot be waitlisted now")
    post message_api_v1_school_bus_requests_path(school), params: { ids: ids.last(1), text: "We will call you" }, as: :json
    get api_v1_bus_request_path(ids.last)
    expect(json[:data]).to include(status: "Waitlisted", reason: "New area")
    expect(json[:data][:events].first(2).map { it[:text] }).to eq([ "Message sent: \"We will call you\"", "Waitlisted. New area. Note: Check in March" ])
    expect(board(status: "Waitlisted")[:data].size).to eq(2)
  end

  it "acknowledges mid-year requests within working days and moves the answer date" do
    late, soon = within_tenant(company) do
      [ f[:app].("Lee Ryan", f[:this], Time.zone.local(2026, 10, 20, 10)), f[:app].("Ho Chloe", f[:this], Time.zone.local(2026, 10, 28, 10), start_when: "fixed",
                                                                                start_on: "2026-11-16", fix_why: "move") ]
    end
    d = board(academic_year_id: f[:this].id)
    expect(d[:data].map { [ it[:child_name], it.dig(:deadline, :stage), it.dig(:deadline, :by), it.dig(:deadline, :tone) ] })
      .to eq([ [ "Lee Ryan", "ack", "2026-10-23", "over" ], [ "Ho Chloe", "ack", "2026-11-02", "soon" ] ])
    expect(d[:meta][:tiles].to_h { [ it[:label], it[:count] ] }).to include("Mid-Year" => 2, "Overdue" => 1)
    expect(d[:data].last).to include(tags: [ "New", "Mid-Year", "Fixed Start", "From the App" ], start_text: "From 16/11/2026, not earlier (moving house)")

    post open_api_v1_bus_request_path(soon)
    expect(json[:data]).to include(status: "Requested", answer_default: "2026-11-23", can: hash_including(acknowledge: true))
    post acknowledge_api_v1_bus_request_path(soon), params: { answer_by: "2026-11-01" }, as: :json
    expect(json.dig(:error, :message)).to eq("The answer date cannot be in the past")
    post acknowledge_api_v1_bus_request_path(soon), params: { answer_by: "2026-11-13", note: "Bus 3 has room" }, as: :json
    expect(json[:data]).to include(status: "Under Review", deadline: hash_including(stage: "answer", by: "2026-11-13", left: 9, tone: "ok"))
    expect(json[:data][:ack]).to include(answer_by: "2026-11-13", note: "Bus 3 has room", by: user.name, plan_weeks: 3)

    post move_answer_api_v1_bus_request_path(soon), params: { answer_by: "2026-11-20" }, as: :json
    expect(json.dig(:error, :message)).to eq("Add the reason. The parent sees it")
    post move_answer_api_v1_bus_request_path(soon), params: { answer_by: "2026-11-20", reason: "Waiting for a bigger bus" }, as: :json
    expect(json.dig(:data, :ack, :moves)).to match([ hash_including(from: "2026-11-13", to: "2026-11-20", reason: "Waiting for a bigger bus") ])
    post move_answer_api_v1_bus_request_path(late), params: { answer_by: "2026-11-20", reason: "x" }, as: :json
    expect(json.dig(:error, :message)).to eq("Only a mid-year request under review has an answer date to move")
  end
end
