require "rails_helper"

RSpec.describe Ai::Readers::TripMessage, :tenant do
  let!(:google) { create(:client, name: "Google Asia Pacific") }
  let!(:van) { create(:vehicle_type, key: "van", name: "Minibus", seats: 13) }
  let!(:coach) { create(:vehicle_type, key: "c45", name: "Coach", seats: 45) }

  before { MessageTerm.create!(term: "Combi", means: "13-seater minibus", kind: "veh") }

  def read(reply, text = "msg")
    fake_claude.reply = { is_trip: true, client: "", client_raw: "", contact: {}, notes: "", assume: [], miss: [] }.merge(reply)
    described_class.read(text:).first
  end

  def trip(**attrs)
    { type: "adhoc", date: "2026-11-04", time: "08:00", return_time: "", hours: 0, direction: "arr", terminal: "", flight: "",
      flight_time: "", pickup: "Jurong East MRT", stops: [], dropoff: "Mapletree Business City", pax: 0, bags: 0,
      luggage: { cabin: 0, medium: 0, large: 0, xl: 0, oversized: 0 }, vehicles: [], guest_name: "", guest_phone: "",
      signboard: "", label: "", price: 0, price_for: "trip", mg_fee: 0, notes: "" }.merge(attrs)
  end

  it "puts today, the clients, vehicle types and terms in the prompt" do
    read({ trips: [ trip ] }, "Need combi tmr 8am Jurong East to MBC")
    content = fake_claude.requests.last[:messages].first[:content].last[:text]
    expect(content).to include("Today is #{Date.current.strftime('%A')} #{Date.current.iso8601}", "Google Asia Pacific",
                               "van = Minibus | 13 seats", "Combi: 13-seater minibus", "Message:\nNeed combi tmr")
  end

  it "matches the client, cleans each trip and drops a guest who is the contact" do
    data = read({ client_raw: "google", contact: { name: "Priya Raman", phone: "+65 9123 4567", email: "", org: "Google" },
                  trips: [ trip(vehicles: [ { type: "van", n: 2 }, { type: "nope", n: 1 } ], guest_name: "Ms Priya Raman", pax: 20) ] })
    expect(data).to include(client_id: google.id, client_name: "Google Asia Pacific")
    t = data[:trips].first
    expect(t).to include(vehicles: [ { type: "van", n: 2 } ], guest_name: nil, pax: 20)
    expect(data[:contact]).to include(phone: "91234567")
  end

  it "builds trip form params with the price read per vehicle or route" do
    data = read({ client: "Google Asia Pacific", trips: [ trip(vehicles: [ { type: "c45", n: 2 } ], price: 900, price_for: "vehicle") ] })
    form = data[:forms].first
    expect(form[:trip]).to include(kind: "ad_hoc", client_id: google.id, starts_on: "2026-11-04", start_time: "08:00",
                                   vehicles_count: 2, price: 900.0, price_per: "vehicle")
    expect(form[:trip][:vehicle_requirements_attributes]).to eq([ { vehicle_type_id: coach.id, count: 2 } ])
    expect(form[:trip][:stops_attributes].pluck(:name, :use)).to eq([ [ "Jurong East MRT", "pu" ], [ "Mapletree Business City", "do" ] ])
    expect(form[:notes]).to eq([ "S$900.00 for each vehicle" ])
    expect(form[:filled]).to include("client", "date", "time", "route", "vehicles", "client_price")
  end

  it "reads an airport arrival with meet and greet" do
    data = read({ trips: [ trip(type: "airport", time: "", flight: "sq 321", flight_time: "07:10", terminal: "t3",
                                pickup: "", dropoff: "Bedok North", signboard: "Dr Lim", mg_fee: 25, price: 85) ] })
    a = data[:forms].first[:trip]
    expect(a).to include(kind: "airport_transfer", airport_direction: "arrival", flight_number: "SQ321", terminal: "T3",
                         start_time: "07:10", meet_and_greet: true, signboard_name: "Dr Lim", meet_and_greet_fee: 25.0, price: 85.0)
    expect(a[:stops_attributes].first[:name]).to eq("Changi Airport T3")
  end

  it "splits a two-way price and a disposal price by the hour" do
    tw = read({ trips: [ trip(type: "twoway", return_time: "17:30", price: 400, price_for: "both") ] })[:forms].first
    expect(tw[:trip][:price]).to eq(200.0)
    expect(tw[:return_trip]).to include(start_time: "17:30")
    expect(tw[:return_trip][:stops_attributes].first[:name]).to eq("Mapletree Business City")

    disp = read({ trips: [ trip(type: "disposal", hours: 4, dropoff: "", price: 300) ] })[:forms].first
    expect(disp[:trip]).to include(kind: "disposal", hours: 4.0, hourly_rate: true, price: 75.0)
    expect(disp[:notes]).to eq([ "S$300.00 for 4.0 h read as S$75.00 an hour" ])
  end

  it "says when there is no trip" do
    expect { read({ is_trip: false }) }.to raise_error(ApplicationService::Error, /trip request/)
    expect { read({ trips: [ trip(pickup: "", dropoff: "", time: "", date: "") ] }) }.to raise_error(ApplicationService::Error, /No trip/)
  end
end
