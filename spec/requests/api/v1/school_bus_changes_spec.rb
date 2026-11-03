require "rails_helper"

# School Bus › Bus Service Requests › changes: a paid new child, a change of address, a change of service and a stop
# written into the route plans as versions from their dates; a higher fare waiting for the parent, Not Agreed (keep the
# old pick-up), End Rider after the last day, and the rider record patched on the day.
RSpec.describe "School Bus request changes" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, permissions: %w[plans]) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School", lat: 1.3138, lng: 103.9283)
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      r1 = school.riders.create!(rid: "R1", name: "Lim Kai", grade: "P3", postal: "460101", lat: 1.33, lng: 103.93, source: "manual", address: "Blk 101")
      r2 = school.riders.create!(rid: "R2", name: "Goh Mei", grade: "P4", postal: "460102", lat: 1.331, lng: 103.931, source: "manual")
      plans = { "am" => [ "07:00", "07:30", "07:00" ], "pm" => [ "14:00", "14:40", "14:20" ] }.to_h do |session, (from, to, at)|
        plan = school.plans.create!(name: "#{session.upcase} Plan 1", session:, effective_from: Date.new(2026, 10, 1))
        route = plan.routes.create!(number: 1, label: "#{session.upcase} 1", start_time: from, end_time: to, student_seats: 4)
        stop = route.stops.create!(position: 0, name: "Blk 101 Bedok North", scheduled_time: at, lat: 1.33, lng: 103.93)
        %w[R1 R2].each { SchoolRouteRider.create!(school_route: route, stop:, rid: it) }
        [ session, plan ]
      end
      base = { submitted_at: 1.day.ago, source: "app", parent_name: "Lim Wei" }
      { school:, year:, r1:, r2:, plans:,
        fresh: school.bus_requests.create!(base.merge(academic_year: year, child_name: "Ng Jun Jie", postal: "460101", lat: 1.3301, lng: 103.9301,
                                                      start_on: "2026-11-16", source: "console")),
        adr: school.bus_requests.create!(base.merge(kind: "adr", school_rider: r1, child_name: r1.name, effective_on: "2026-11-23", old_address: "Blk 101",
                                                    address: "Blk 216 Bedok North", postal: "460216", lat: 1.335, lng: 103.935, current_fare: 200)),
        svc: school.bus_requests.create!(base.merge(kind: "svc", school_rider: r2, child_name: r2.name, effective_on: "2026-11-30", old_am: true, old_pm: true,
                                                    am: true, pm: false, current_fare: 200)),
        stop: school.bus_requests.create!(base.merge(kind: "stop", school_rider: r1, child_name: r1.name, last_on: "2026-12-04", stop_why: "move",
                                                     notice_n: 1, notice_unit: "months", earliest_on: "2026-12-11", early: true)),
        up: school.bus_requests.create!(base.merge(kind: "adr", school_rider: r2, child_name: r2.name, effective_on: "2026-12-01", address: "Blk 9",
                                                   postal: "460300", lat: 1.34, lng: 103.94, current_fare: 200)) }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
  end

  def plans(session) = within_tenant(company) { f[:school].plans.where(session:).order(:effective_from).map { [ it.name, it.effective_from.iso8601, it.effective_to&.iso8601 ] } }
  def riders_on(plan_name) = within_tenant(company) { SchoolPlan.find_by!(name: plan_name).routes.flat_map { |r| r.stops.map { [ it.name, it.riders.map(&:rid).sort ] } } }

  it "writes confirmed requests into route plan versions and ends the rider" do
    post accept_api_v1_bus_request_path(f[:fresh]), params: { amount: 300, start_on: "2026-11-16", note: "No Bus Fares yet" }, as: :json
    post record_payment_api_v1_bus_request_path(f[:fresh]), params: { method: "Cash" }, as: :json
    expect(json.dig(:data, :planned)).to include(ok: true, lines: [ "AM from 16/11/2026: joins AM 1, Blk 101 Bedok North. Nothing changes for the other children",
                                                                     "PM from 16/11/2026: joins PM 1, Blk 101 Bedok North. Nothing changes for the other children" ])
    expect(plans("am")).to eq([ [ "AM Plan 1", "2026-10-01", "2026-11-15" ], [ "AM Plan 1 · from 16/11/2026 · 1 change", "2026-11-16", nil ] ])
    expect(riders_on("AM Plan 1")).to eq([ [ "Blk 101 Bedok North", %w[R1 R2] ] ])
    expect(riders_on("AM Plan 1 · from 16/11/2026 · 1 change")).to eq([ [ "Blk 101 Bedok North", [ "M-0001", "R1", "R2" ] ] ])

    # Change of address at the same fare: Active, R1 moves to a new stop from 23/11
    post confirm_change_api_v1_bus_request_path(f[:adr]), params: { amount: 180 }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter the new pick-up point")
    post confirm_change_api_v1_bus_request_path(f[:adr]), params: { amount: 180, stop: "Blk 216 Bedok North" }, as: :json
    expect(json[:data]).to include(status: "Active", change: hash_including(new_stop: "Blk 216 Bedok North", current_fare: "200.0"))
    expect(json.dig(:data, :planned, :lines).first).to start_with("AM from 23/11/2026: moves to AM 1, a new stop at the child’s block")
    expect(plans("am").map(&:first)).to eq([ "AM Plan 1", "AM Plan 1 · from 16/11/2026 · 1 change", "AM Plan 1 · from 23/11/2026 · 1 change" ])
    am = riders_on("AM Plan 1 · from 23/11/2026 · 1 change")
    expect(am).to contain_exactly([ "Blk 216 Bedok North", %w[R1] ], [ "Blk 101 Bedok North", %w[M-0001 R2] ])

    # Change of service to mornings only from 30/11: R2 comes off the PM routes from then
    post confirm_change_api_v1_bus_request_path(f[:svc]), params: { amount: 150 }, as: :json
    expect(json[:data]).to include(status: "Active", change: hash_including(from_service: "Two ways", to_service: "Morning only"))
    expect(json.dig(:data, :planned, :lines)).to eq([ "PM from 30/11/2026: off the route" ])
    expect(riders_on("PM Plan 1 · from 30/11/2026 · 1 change").flat_map(&:last)).not_to include("R2")

    # A higher fare waits for the parent; Not Agreed, then keep the old pick-up
    post confirm_change_api_v1_bus_request_path(f[:up]), params: { amount: 260, stop: "Blk 9" }, as: :json
    expect(json[:data]).to include(status: "Accepted", status_label: "Waiting for Parent")
    within_tenant(company) { BusRequests::Agree.call(f[:up].reload, yes: false) }
    post not_agreed_api_v1_bus_request_path(f[:up]), params: { choice: "keep" }, as: :json
    expect(json[:data]).to include(status: "Declined", reason: "Kept the old pick-up", planned: nil)

    # Stop: last day before the notice ends, fees to the end of the notice; off the routes from the next day
    post confirm_stop_api_v1_bus_request_path(f[:stop]), params: { last_on: "2026-12-04" }, as: :json
    expect(json[:data]).to include(status: "Stopping", change: hash_including(pay_to: "2026-12-11", stop_reason: "Moving house"))
    expect(json.dig(:data, :planned, :lines)).to eq([ "AM from 05/12/2026: off the route", "PM from 05/12/2026: off the route" ])

    travel_to Time.zone.local(2026, 12, 7, 9, 0)
    sign_in_as(user)
    get api_v1_bus_request_path(f[:stop])
    expect(json[:data]).to include(status: "Stopped", end_action: hash_including(end: "2026-12-04", button: "End Rider"))
    post end_rider_api_v1_bus_request_path(f[:stop])
    expect(json[:data]).to include(end_action: nil, can: hash_including(end_rider: false))
    expect(f[:r1].reload.ends_on).to eq(Date.new(2026, 12, 4))

    within_tenant(company) { BusRequests::RiderSync.call }
    expect(f[:r1].reload).to have_attributes(address: "Blk 216 Bedok North", postal: "460216")
    expect(f[:r2].reload).to have_attributes(am: true, pm: false)
    get api_v1_school_bus_requests_path(f[:school]), params: { kind: "adr" }
    expect(json[:data].map { it[:status_label] }).to eq(%w[Declined Active])
    expect(json[:meta][:tabs].to_h { [ it[:kind], it[:open] ] }).to include("adr" => 0, "svc" => 0, "stop" => 0)
  end
end
