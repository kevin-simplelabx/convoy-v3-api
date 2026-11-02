require "rails_helper"

RSpec.describe "Bookings" do
  let(:company) { create(:company, code: "SD") }
  let(:user) { create(:user, company:) }
  let!(:f) do
    within_tenant(company) do
      small = create(:vehicle_type, name: "13-seater", seats: 13)
      big = create(:vehicle_type, name: "45-seater", seats: 45)
      params = RateCards::Standard.params(name: "Standard Rates", types: [ small, big ])
                                  .merge(distance_pricing: true, stop_fees: true, meet_and_greet: true, meet_and_greet_fee: 25)
      RateCards::Save.call(card: RateCard.new, params:)
      { small:, big:, client: create(:client, name: "Google", email: "ops@google.com") }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0) # Monday
    sign_in_as(user)
  end

  def pt(name, use = "both", lat: nil, lng: nil) = { name:, use:, lat:, lng: }

  def one_way(start = "09:00", **extra)
    { kind: "one_way", start_time: start, pax: 10, points: [ pt("Changi", "pu"), pt("Marina", "do") ],
      vehicles: [ { vehicle_type_id: f[:small].id, count: 1 } ] }.merge(extra)
  end

  def booking(days, **extra)
    { client_id: f[:client].id, coordinator_name: "Alex Hwang", coordinator_email: "alex@google.com", coordinator_phone: "+6596783393",
      po_number: "PO-1", cost_centre: "CC-9", days: }.merge(extra)
  end

  def record(days, **extra)
    post api_v1_bookings_path, params: { booking: booking(days, **extra) }, as: :json
    expect(response).to have_http_status(:created), response.body
    json[:data]
  end

  it "records a booking with its days and trips, numbers it and estimates each trip from the rate card" do
    data = record([
      { date: "2026-11-04", trips: [
        one_way("09:00", distance_km: 30),
        { kind: "two_way", start_time: "08:00", return_time: "18:00", pax: 30, distance_km: 10,
          points: [ pt("Office", "pu"), pt("Stop A"), pt("Venue", "do") ], standby: { location: "Car park", minutes: 15 },
          vehicles: [ { vehicle_type_id: f[:big].id, count: 1 } ] }
      ] },
      { date: "2026-11-05", trips: [
        { kind: "disposal", start_time: "10:00", hours: 4, points: [ pt("Hotel", "pu") ], vehicles: [ { vehicle_type_id: f[:small].id, count: 2 } ] },
        { kind: "airport", airport_direction: "arrival", flight_number: "SQ321", terminal: "T3", meet_and_greet: true, signboard_name: "Mr Tan",
          start_time: "07:30", points: [ pt("Changi Airport T3", "pu"), pt("Hotel", "do") ], vehicles: [ { vehicle_type_id: f[:small].id, count: 1 } ] }
      ] }
    ])

    expect(data[:number]).to eq("SD26000001")
    expect(data).to include(tab: "pending", status_label: "Ready for Approval", coordinator_name: "Alex Hwang", created_by: user.name)
    day1, day2 = data[:days]
    ow, tw = day1[:trips]
    # One Way 09:00 Mon-Fri = Off Peak 55, 30 km = band 2 (25).
    expect(ow).to include(estimate_amount: "80.0", status: "pending", start_time: "09:00")
    expect(ow[:estimate_lines].first[:lines].pluck(:text)).to eq([ "One Way, Off Peak", "Distance 30.0 km" ])
    # Two Way 45-seater: out 08:00 Off Peak 135, back 18:00 Off Peak 135, 10 km band 1 (0) x2, 1 stop 23 x2.
    expect(tw[:estimate_lines].first[:lines].pluck(:text, :amount)).to eq([ [ "Out, Off Peak", "135.0" ], [ "Return, Off Peak", "135.0" ],
                                                                            [ "1 extra stop, both ways", "46.0" ] ])
    expect(tw[:back_points].pluck(:name, :use)).to eq([ %w[Venue pu], [ "Stop A", "both" ], %w[Office do] ])
    expect(tw[:standby]).to include(location: "Car park", minutes: 15)
    expect(tw[:seats_warning]).to be_nil
    disp, air = day2[:trips]
    expect(disp[:estimate_lines].first).to include(text: "2 x 13-seater", amount: "360.0")
    expect(air[:estimate_lines].pluck(:text, :amount)).to eq([ [ "1 x 13-seater", "55.0" ], [ "Meet and Greet", "25.0" ] ])
    expect(data[:estimate_amount]).to eq((80 + 316 + 360 + 80).to_d.to_s)

    get api_v1_bookings_path
    expect(json[:data].first).to include(number: "SD26000001", kinds: [ "Ad Hoc / Charter", "Ad Hoc / Charter, Two Way", "Disposal", "Airport Transfer" ],
                                         dates: %w[2026-11-04 2026-11-05], trips_count: 4)
    expect(json[:meta][:counts]).to eq(pending: 1, approved: 0, rejected: 0, completed: 0)
    get api_v1_bookings_path, params: { q: "alex" }
    expect(json[:meta][:count]).to eq(1)
    get api_v1_bookings_path, params: { q: "nobody" }
    expect(json[:meta][:count]).to eq(0)
    expect(record([ { date: "2026-11-06", trips: [ one_way ] } ])[:number]).to eq("SD26000002")
  end

  it "prices a two-way trip whose way back strays from the way there as two one-way trips" do
    trip = { kind: "two_way", start_time: "08:00", return_time: "18:00", distance_km: 30, return_distance_km: 50,
             points: [ pt("A", "pu", lat: 1.30, lng: 103.80), pt("B", "do", lat: 1.35, lng: 103.90) ],
             back_points: [ pt("B", "pu", lat: 1.35, lng: 103.90), pt("Far away", "do", lat: 1.40, lng: 103.70) ],
             vehicles: [ { vehicle_type_id: f[:small].id, count: 1 } ] }
    post estimate_api_v1_bookings_path, params: { client_id: f[:client].id, date: "2026-11-04", trip: }, as: :json
    expect(json.dig(:data, :lines, 0, :lines).pluck(:text, :amount)).to eq([
      [ "Out, Off Peak", "55.0" ], [ "Return, priced as a one-way trip, Off Peak", "55.0" ],
      [ "Distance 30.0 km, way there", "25.0" ], [ "Distance 50.0 km, way back", "50.0" ]
    ])
    expect(json[:data]).to include(amount: "185.0", without_rate: 0, card: hash_including(name: "Standard Rates"))
  end

  it "checks the booking form rules" do
    day = ->(trip) { [ { date: "2026-11-04", trips: [ trip ] } ] }
    {
      booking(day.(one_way), client_id: nil) => "Pick the client",
      booking(day.(one_way), coordinator_name: "") => "Enter the booking coordinator",
      booking([ { date: "2026-11-04", trips: [ one_way ] }, { date: "2026-11-04", trips: [ one_way ] } ]) => "Two days have the same date",
      booking([ { date: "2026-11-04", trips: [ one_way ] }, { date: "2026-11-16", trips: [ one_way ] } ]) => "Days must be no more than 10 days apart",
      booking([ { date: "2026-11-04", trips: [] } ]) => "04/11/2026: add at least one trip",
      booking(day.(one_way(points: [ pt("Changi", "pu") ]))) => "04/11/2026: enter the drop-off point",
      booking(day.(one_way(points: [ pt("", "pu"), pt("B", "do") ]))) => "04/11/2026: enter the pick-up point",
      booking(day.(one_way(kind: "two_way", return_time: "08:00"))) => "04/11/2026: the return time must be after the pick-up time",
      booking(day.(one_way(kind: "disposal", points: [ pt("Hotel", "pu") ]))) => "04/11/2026: enter the disposal hours",
      booking(day.(one_way(standby: { location: "" }))) => "04/11/2026: enter the standby area, or turn it off",
      booking(day.(one_way(vehicles: []))) => "04/11/2026: request at least one vehicle",
      booking(day.(one_way(vehicles: [ { vehicle_type_id: f[:small].id, count: 11 } ]))) => "04/11/2026: no more than 10 vehicles a trip",
      booking(day.(one_way(points: [ pt("A", "pu"), *Array.new(6) { |i| pt("S#{i}") }, pt("B", "do") ]))) => "04/11/2026: up to 5 stops"
    }.each do |body, message|
      post api_v1_bookings_path, params: { booking: body }, as: :json
      expect(json.dig(:error, :message)).to eq(message)
    end
  end

  it "saves changes: moves a day, edits and removes trips, keeps locked trips, refuses a stale save" do
    data = record([ { date: "2026-11-04", trips: [ one_way("09:00"), one_way("14:00") ] }, { date: "2026-11-05", trips: [ one_way("07:00") ] } ])
    d1, d2 = data[:days]
    within_tenant(company) { BookingTrip.find(d2[:trips][0][:id]).update!(status: "approved") }

    patch api_v1_booking_path(data[:id]), params: { lock_version: data[:lock_version], booking: booking([
      { id: d1[:id], date: "2026-11-05", trips: [ one_way("10:00").merge(id: d1[:trips][0][:id], pax: 12) ] },
      { id: d2[:id], date: "2026-11-04", trips: [ { id: d2[:trips][0][:id], kind: "one_way", start_time: "23:00" } ] }
    ]) }, as: :json
    expect(response).to have_http_status(:ok), response.body
    days = json.dig(:data, :days)
    expect(days.pluck(:date)).to eq(%w[2026-11-04 2026-11-05])
    expect(days[0][:trips].first).to include(id: d2[:trips][0][:id], start_time: "07:00", status: "approved", locked: true)
    expect(days[1][:trips].map { |t| t.slice(:id, :start_time, :pax) }).to eq([ { id: d1[:trips][0][:id], start_time: "10:00", pax: 12 } ])
    expect(json[:data]).to include(tab: "pending")

    patch api_v1_booking_path(data[:id]), params: { lock_version: data[:lock_version], booking: booking([ { date: "2026-11-04", trips: [ one_way ] } ]) }, as: :json
    expect(response).to have_http_status(:conflict)
    patch api_v1_booking_path(data[:id]), params: { lock_version: data[:lock_version] + 1, booking: booking([ { id: d1[:id], date: "2026-11-05", trips: [ one_way ] } ]) }, as: :json
    expect(json.dig(:error, :message)).to eq("An approved or rejected trip can't be removed")
  end

  it "puts bookings in tabs by their trips" do
    pending = record([ { date: "2026-11-04", trips: [ one_way ] } ])
    approved = record([ { date: "2026-11-04", trips: [ one_way, one_way ] } ])
    rejected = record([ { date: "2026-11-04", trips: [ one_way ] } ])
    completed = record([ { date: "2026-11-03", trips: [ one_way ] } ])
    within_tenant(company) do
      Booking.find(approved[:id]).trips.each_with_index { |t, i| t.update!(status: i.zero? ? "approved" : "rejected") }
      Booking.find(rejected[:id]).trips.update_all(status: "rejected")
      Booking.find(completed[:id]).trips.update_all(status: "approved")
    end
    travel_to Time.zone.local(2026, 11, 4, 9, 0)

    get api_v1_bookings_path, params: { tab: "approved" }
    expect(json[:data].pluck(:id, :status_label)).to eq([ [ approved[:id], "Assigned" ] ]) # no Scheduler trips here: nothing waits for a bus
    expect(json[:meta]).to include(tab: "approved", counts: { pending: 1, approved: 1, rejected: 1, completed: 1 })
    get api_v1_bookings_path, params: { tab: "completed" }
    expect(json[:data].pluck(:id, :status_label)).to eq([ [ completed[:id], "Completed" ] ])
    get api_v1_bookings_path
    expect(json[:data].pluck(:id)).to eq([ pending[:id] ])
  end

  it "keeps files on a booking" do
    data = record([ { date: "2026-11-04", trips: [ one_way ] } ])
    post api_v1_booking_attachments_path(data[:id]), params: { file: fixture_file_upload("sample.pdf", "application/pdf") }
    expect(response).to have_http_status(:created)
    get api_v1_booking_path(data[:id])
    expect(json.dig(:data, :attachments, 0, :name)).to eq("sample.pdf")
    delete api_v1_booking_attachment_path(data[:id], json.dig(:data, :attachments, 0, :id))
    expect(response).to have_http_status(:no_content)
  end
end
