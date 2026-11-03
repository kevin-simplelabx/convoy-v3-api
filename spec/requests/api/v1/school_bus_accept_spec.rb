require "rails_helper"

# School Bus › Bus Service Requests › Accept: Route Fit on the running AM routes (same block fits, a new stop, bus full
# once the seat is held), the Bus Fares quote, the first invoice, the child on the rider list and in a family, Lapsed
# after the confirm hours, Re-offer, Record First Invoice Paid, bulk accept and the auto-accept banner.
RSpec.describe "School Bus request accept" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, permissions: %w[plans]) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School", lat: 1.3138, lng: 103.9283)
      year = AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
      year.terms.first.update!(starts_on: "2027-01-04", ends_on: "2027-05-28")
      year.terms.second.update!(starts_on: "2027-06-28", ends_on: "2027-11-19")
      SchoolSetup.lock!(school:, year:, section: :calendar, user:)
      FareTables::Save.call(year, { payer: "parents", basis: "distance", trip: "both", cycle: "period", distribution: "equal",
                                    one_way: { type: "pct", value: 60 }, tiers: [ { max_km: 3, fare: 1680 }, { max_km: 6, fare: 1920 }, { fare: 2400 } ],
                                    small: { on: false }, express: { on: false }, cca: { on: false } }, user:)
      rider = school.riders.create!(rid: "R1", name: "Lim Kai", grade: "P3", postal: "460101", lat: 1.33, lng: 103.93, source: "manual",
                                    parent_contact: "+65 9000 1111")
      plan = school.plans.create!(name: "AM Plan 1", session: "am", effective_from: Date.new(2026, 10, 1))
      route = plan.routes.create!(number: 1, label: "AM 1", start_time: "07:00", end_time: "07:30", student_seats: 2)
      stop = route.stops.create!(position: 0, name: "Blk 101 Bedok North", scheduled_time: "07:00", lat: 1.33, lng: 103.93)
      SchoolRouteRider.create!(school_route: route, stop:, rid: rider.rid)
      mk = lambda do |child, postal, lat, lng, phone|
        school.bus_requests.create!(academic_year: year, child_name: child, parent_name: "Ng Mei Ling", parent_phone: phone, postal:, lat:, lng:,
                                    pm: false, start_on: "2027-01-04", submitted_at: 2.days.ago, level: "P1", source: "console")
      end
      { school:, year:, route:, same: mk.("Ng Jun Jie", "460101", 1.3301, 103.9301, "+65 8123 4410"),
        near: mk.("Ng Xin Yi", "460216", 1.335, 103.935, "8123-4410"), sib: mk.("Tan Ryan", "460300", 1.36, 103.96, "+65 9000 1111") }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
  end

  def detail(req) = get(api_v1_bus_request_path(req)).then { json[:data] }

  it "quotes from Bus Fares, accepts with a first invoice, lapses, re-offers and records the payment" do
    d = detail(f[:same])
    expect(d[:check]).to include(code: "covered", label: "Fits", free: 1)
    expect(d[:route_fit][:AM]).to include(kind: "fits", label: "AM 1", stop: "Blk 101 Bedok North", tm: "07:00")
    expect(d[:quote_default]).to include(amount: "504.0", unit: "semester", start_on: "2027-01-04")
    expect(d[:quote_default][:text]).to include("Route Fit: AM Fits on AM 1", "Bus Fares AY 2027: 1.8 km from school, 0 to 3 km, one way")
    expect(detail(f[:near])[:check]).to include(kind: "new", label: "New Stop")

    post accept_api_v1_bus_request_path(f[:same]), params: { amount: 900, start_on: "2027-01-04" }, as: :json
    expect(json.dig(:error, :message)).to eq("Add a note for the parent: the fare differs from Bus Fares")
    post accept_api_v1_bus_request_path(f[:same]), params: { amount: 504, start_on: "2027-01-04" }, as: :json
    d = json[:data]
    expect(d).to include(status: "Accepted", offer_by: "2026-11-04T09:00:00.000+08:00", hours_left: 48)
    expect(d[:quote]).to include(amount: "504.0", base: "504.0", unit: "semester", by: user.name)
    expect(d[:first_bill]).to include(number: "INV-2026-000001", period: "Semester 1", total: "504.0", status: "open")
    expect(d[:places]).to eq([ { session: "AM", route_id: f[:route].id, route: "AM 1", kind: "fits", stop: "Blk 101 Bedok North", delta_minutes: "0.0" } ])
    expect(d[:rider]).to include(rid: "M-0001")
    expect(d[:family]).to include(code: "FAM-0001", name: "NG Family")
    expect(d[:events].first[:text]).to eq("Ng Jun Jie added to the rider list as M-0001 (Unpaid) and linked to NG Family (FAM-0001)")
    expect(d[:events].second[:text]).to eq("Accepted at S$504.00 a semester. First invoice INV-2026-000001 sent. Parent has 48 hours to pay")

    # The held seat fills AM 1, so the other child no longer fits
    expect(detail(f[:near])[:check]).to include(kind: "full", label: "Bus Full")

    travel_to Time.zone.local(2026, 11, 4, 10, 0)
    sign_in_as(user)
    expect(detail(f[:same])).to include(status: "Lapsed", can: hash_including(reoffer: true, record_payment: true, accept: false))
    post reoffer_api_v1_bus_request_path(f[:same])
    expect(json[:data]).to include(status: "Accepted", offer_by: "2026-11-06T10:00:00.000+08:00")
    expect(json.dig(:data, :first_bill, :number)).to eq("INV-2026-000001")
    post record_payment_api_v1_bus_request_path(f[:same]), params: { method: "PayNow" }, as: :json
    expect(json[:data]).to include(status: "Active")
    expect(json.dig(:data, :first_bill)).to include(status: "paid", method: "PayNow")
    expect(json[:data][:events].second[:text]).to eq("First invoice paid by PayNow. Service is active")
    expect(json.dig(:data, :planned, :lines)).to eq([ "AM from 04/01/2027: joins AM 1, Blk 101 Bedok North. Nothing changes for the other children" ])

    # Bulk: the sibling of the first child (same phone) joins the same family
    post accept_api_v1_school_bus_requests_path(f[:school]), params: { ids: [ f[:near].id ] }, as: :json
    expect(json[:data]).to eq(updated: 1)
    expect(detail(f[:near])).to include(status: "Accepted", family: hash_including(code: "FAM-0001"))
    expect(within_tenant(company) { SchoolBill.pluck(:number).sort }).to eq(%w[INV-2026-000001 INV-2026-000002])
  end

  it "lists requests the scheduled registration would auto-accept" do
    within_tenant(company) do
      SchoolRegistrations.build(f[:year]).tap { it.assign_attributes(status: "scheduled", auto_siblings: true, siblings_need_cover: false) }.save!
    end
    get api_v1_school_bus_requests_path(f[:school]), params: { academic_year_id: f[:year].id }
    expect(json.dig(:meta, :auto_accept)).to eq(count: 1, ids: [ f[:sib].id ])
    expect(json[:data].to_h { [ it[:child_name], it.dig(:check, :label) ] }).to eq("Ng Jun Jie" => "Fits", "Ng Xin Yi" => "New Stop", "Tan Ryan" => "New Stop")
    get api_v1_school_bus_requests_path(f[:school]), params: { academic_year_id: f[:year].id, check: "covered" }
    expect(json[:data].size).to eq(1)
  end
end
