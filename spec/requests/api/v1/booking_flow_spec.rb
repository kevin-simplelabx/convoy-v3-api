require "rails_helper"

RSpec.describe "Booking approval flow and notifications" do
  let(:company) { create(:company, code: "SD") }
  let(:user) { create(:user, :admin, company:) }
  let!(:f) do
    within_tenant(company) do
      small = create(:vehicle_type, name: "13-seater", seats: 13)
      RateCards::Save.call(card: RateCard.new, params: RateCards::Standard.params(name: "Standard Rates", types: [ small ]).merge(stop_fees: true))
      { small:, client: create(:client, name: "Google", email: "ops@google.com"), bus: create(:vehicle, plate: "PD1A", seats: 13) }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
  end

  def pt(name, use = "both") = { name:, use: }
  def one_way(start = "09:00", **extra)
    { kind: "one_way", start_time: start, pax: 10, points: [ pt("Changi", "pu"), pt("Marina", "do") ],
      vehicles: [ { vehicle_type_id: f[:small].id, count: 1 } ] }.merge(extra)
  end
  def two_way = one_way("08:00", kind: "two_way", return_time: "18:00", points: [ pt("Office", "pu"), pt("Stop A"), pt("Venue", "do") ])

  def record(trips, date: "2026-11-04")
    post api_v1_bookings_path, params: { booking: { client_id: f[:client].id, coordinator_name: "Alex", coordinator_org: "Google Asia",
                                                    po_number: "PO-1", days: [ { date:, trips: } ] } }, as: :json
    expect(response).to have_http_status(:created), response.body
    json[:data]
  end

  def trip_of(data, i = 0) = data.dig(:days, 0, :trips, i)

  it "approves trips into Unassigned Scheduler trips, Two Way as a pair, then shows Assigned once a bus is on" do
    data = record([ one_way, two_way ])
    ow, tw = data.dig(:days, 0, :trips)

    post approve_api_v1_booking_trip_path(ow[:id]), params: {}, as: :json
    expect(json.dig(:error, :message)).to eq("Enter the trip value")
    post approve_api_v1_booking_trip_path(ow[:id]), params: { trip_value: 1.5 }, as: :json
    expect(response).to have_http_status(:ok), response.body
    ow = trip_of(json[:data])
    expect(ow).to include(status: "approved", status_label: "Approved, Unassigned", locked: true, can_approve: false)
    expect(ow[:approval]).to include(by: user.name, how: nil)
    expect(ow[:scheduler_trips].pluck(:title)).to eq([ "Google Asia to Marina" ])
    expect(json[:data]).to include(tab: "pending", status_label: "Ready for Approval")

    post approve_api_v1_booking_trip_path(tw[:id]), params: { trip_value: 1 }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter the trip value")
    post approve_api_v1_booking_trip_path(tw[:id]), params: { trip_value: 1, return_trip_value: 1.2 }, as: :json
    expect(json[:data]).to include(tab: "approved", status_label: "Unassigned")

    within_tenant(company) do
      out = Trip.find_by!(booking_trip_id: tw[:id], is_return: false)
      ret = out.pair
      expect([ out.kind, out.price, out.trip_value, out.booking_ref, out.start_time_hm ]).to eq([ "ad_hoc", 65.to_d, 1, "SD26000001", "08:00" ])
      expect([ ret.price, ret.trip_value, ret.start_time_hm, ret.stops.map(&:name) ]).to eq([ 65.to_d, 1.2.to_d, "18:00", [ "Venue", "Stop A", "Office" ] ])
      single = Trip.find_by!(booking_trip_id: ow[:id])
      expect(single.notes).to eq("Vehicles requested: 1 x 13-seater\nPO PO-1\nBooking SD26000001")
      expect(TripOccurrence.where(trip_id: [ out.id, ret.id, single.id ]).pluck(:vehicle_id).uniq).to eq([ nil ])
      TripOccurrence.where(trip_id: [ out.id, ret.id, single.id ]).update_all(vehicle_id: f[:bus].id)
    end
    get api_v1_booking_path(data[:id])
    expect(json[:data][:status_label]).to eq("Assigned")
    expect(trip_of(json[:data])[:status_label]).to eq("Approved, Assigned")
  end

  it "waits for the client to acknowledge an edit, or approves without waiting" do
    data = record([ one_way ])
    day = data[:days][0]
    edit = lambda do |start|
      patch api_v1_booking_path(data[:id]), params: { lock_version: json.dig(:data, :lock_version), booking: {
        client_id: f[:client].id, coordinator_name: "Alex", days: [ { id: day[:id], date: day[:date], trips: [ one_way(start).merge(id: trip_of(data)[:id]) ] } ]
      } }, as: :json
      expect(response).to have_http_status(:ok), response.body
      trip_of(json[:data])
    end

    trip = edit.("09:00")
    expect(trip[:status]).to eq("pending") # nothing changed
    trip = edit.("10:30")
    expect(trip).to include(status: "awaiting_ack", status_label: "Pending Client Acknowledgement")
    expect(trip[:changes].first).to include(by: user.name, items: [ "Pick-up time: 09:00 to 10:30" ])
    expect(json[:data][:status_label]).to eq("Pending Client Acknowledgement")

    patch acknowledge_api_v1_booking_trip_path(trip[:id]), params: { how: "Email", by_name: "Alex" }, as: :json
    expect(trip_of(json[:data])).to include(status: "pending", acknowledgement: hash_including(by: "Alex", how: "Email"))

    trip = edit.("11:00")
    post approve_api_v1_booking_trip_path(trip[:id]), params: { trip_value: 1 }, as: :json
    expect(json.dig(:error, :message)).to eq("Say how the client agreed to the changes")
    post approve_api_v1_booking_trip_path(trip[:id]), params: { trip_value: 1, how: "Phone", note: "Spoke to Alex" }, as: :json
    expect(trip_of(json[:data])[:approval]).to include(how: "Phone", note: "Spoke to Alex")
    expect(trip_of(json[:data])[:acknowledgement]).to be_nil
  end

  it "rejects with a reason and records the client's own approval or decline" do
    data = record([ one_way, one_way("13:00"), one_way("15:00") ])
    a, b, c = data.dig(:days, 0, :trips)
    patch reject_api_v1_booking_trip_path(a[:id]), params: { reason: " " }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter the reason, the client sees it")
    patch reject_api_v1_booking_trip_path(a[:id]), params: { reason: "No bus that day" }, as: :json
    expect(trip_of(json[:data])).to include(status: "rejected", rejection: hash_including(by: user.name, by_client: false, reason: "No bus that day"))
    expect(json[:data][:estimate_amount]).to eq("110.0")

    within_tenant(company) { BookingTrip.where(id: [ b[:id], c[:id] ]).update_all(status: "awaiting_client") }
    patch client_approve_api_v1_booking_trip_path(b[:id]), params: { by_name: "Priya (Finance)" }, as: :json
    expect(trip_of(json[:data], 1)[:status]).to eq("pending")
    patch client_decline_api_v1_booking_trip_path(c[:id]), params: { by_name: "Priya (Finance)", reason: "Over budget" }, as: :json
    expect(trip_of(json[:data], 2)).to include(status: "rejected", rejection: hash_including(by: "Priya (Finance)", by_client: true))
    patch client_approve_api_v1_booking_trip_path(a[:id]), as: :json
    expect(json.dig(:error, :message)).to eq("This trip is rejected, so it can't be changed here")
  end

  it "records a client's cancellation request, then cancels the trip and its runs when accepted" do
    data = record([ one_way, one_way("13:00") ])
    a, b = data.dig(:days, 0, :trips)
    post approve_api_v1_booking_trip_path(a[:id]), params: { trip_value: 1 }, as: :json

    post api_v1_booking_cancel_requests_path(data[:id]), params: { booking_trip_id: a[:id], reason: "Event moved", requested_by_name: "Alex" }, as: :json
    expect(response).to have_http_status(:created)
    req = json.dig(:data, :cancel_requests, 0)
    expect(req).to include(status: "open", trip_date: "2026-11-04", requested_by_name: "Alex")

    patch api_v1_booking_cancel_request_path(data[:id], req[:id]), params: { decision: "accept", note: "Told Alex" }, as: :json
    expect(json.dig(:data, :cancel_requests, 0)).to include(status: "accepted", resolved_by: user.name)
    expect(trip_of(json[:data])).to include(status: "cancelled", status_label: "Cancelled")
    within_tenant(company) do
      expect(TripOccurrence.where(trip: Trip.where(booking_trip_id: a[:id])).pluck(:status)).to eq(%w[cancelled])
    end

    post api_v1_booking_cancel_requests_path(data[:id]), params: { reason: "Changed plans" }, as: :json
    req = json.dig(:data, :cancel_requests, 1)
    expect(req).to include(booking_trip_id: nil, requested_by_name: "Alex")
    patch api_v1_booking_cancel_request_path(data[:id], req[:id]), params: { decision: "decline" }, as: :json
    expect(trip_of(json[:data], 1)[:status]).to eq("pending")
    patch api_v1_booking_cancel_request_path(data[:id], req[:id]), params: { decision: "accept" }, as: :json
    expect(json.dig(:error, :message)).to eq("This request is declined already")
    expect(b[:status]).to eq("pending")
  end

  it "rings the bell for the events each coordinator wants, and records the emails" do
    data = record([ one_way, one_way("13:00") ])
    a, b = data.dig(:days, 0, :trips)
    post api_v1_booking_cancel_requests_path(data[:id]), params: { booking_trip_id: a[:id], requested_by_name: "Alex" }, as: :json
    travel 1.hour
    within_tenant(company) { BookingTrip.where(id: b[:id]).update_all(status: "awaiting_client") }
    patch client_approve_api_v1_booking_trip_path(b[:id]), params: { by_name: "Priya" }, as: :json

    get api_v1_booking_notifications_path
    expect(json[:data].pluck(:kind, :message)).to eq([ [ "client_approved", "Approved by Priya, sent to you" ],
                                                       [ "cancel_request", "Alex asks to cancel the trip on Wed 4/11" ] ])
    expect(json[:data].first).to include(booking_number: "SD26000001", client_name: "Google", unseen: true, tab: "pending")
    expect(json[:meta][:unseen_count]).to eq(2)
    within_tenant(company) { expect(NotificationEmail.pluck(:to, :subject)).to include([ user.email, "Cancellation request: SD26000001" ]) }

    patch seen_api_v1_booking_notifications_path, as: :json
    get api_v1_booking_notifications_path
    expect(json[:meta][:unseen_count]).to eq(0)

    patch preferences_api_v1_booking_notifications_path, params: { cancel_request: false, email: false }, as: :json
    expect(json[:data][:kinds].find { |k| k[:kind] == "cancel_request" }).to include(on: false, label: "Cancellation request")
    get api_v1_booking_notifications_path
    expect(json[:data].pluck(:kind)).to eq(%w[client_approved])
    within_tenant(company) do
      expect { Bookings::Notify.call(booking: Booking.last, kind: "acknowledged", message: "x") }.not_to change(NotificationEmail, :count)
    end

    travel 15.days
    get api_v1_booking_notifications_path
    expect(json[:data]).to eq([])
  end
end
