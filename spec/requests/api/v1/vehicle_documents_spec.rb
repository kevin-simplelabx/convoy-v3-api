require "rails_helper"

RSpec.describe "Vehicle documents (Edit Vehicle)" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let(:user) { create(:user, :admin, company:) }
  let!(:vehicle) { within_tenant(company) { create(:vehicle, plate: "PD3318K", make: nil, seats: 13) } }
  let(:pdf) { fixture_file_upload("sample.pdf", "application/pdf") }

  before { sign_in_as(user) }

  def read!(kind, reply)
    fake_claude.reply = reply
    perform_enqueued_jobs { post api_v1_document_reads_path, params: { kind:, file: pdf } }
    expect(response).to have_http_status(:accepted)
    json.dig(:data, :id)
  end

  describe "document reads" do
    it "reads in the background and is polled" do
      id = read!("log_card", { is_log_card: true, plate: "PD3318K", make: "Toyota", model: "HiAce" })
      get api_v1_document_read_path(id)
      expect(json[:data]).to include(status: "done")
      expect(json.dig(:data, :result)).to include(make: "Toyota")
    end

    it "keeps the error when the file is not what was expected" do
      id = read!("log_card", { is_log_card: false })
      get api_v1_document_read_path(id)
      expect(json[:data]).to include(status: "failed", error: "This does not look like a log card")
    end

    it "is private to the user who started it" do
      id = read!("log_card", { is_log_card: true })
      sign_in_as(create(:user, :admin, company:))
      get api_v1_document_read_path(id)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "log cards" do
    it "attaches a read card, fills empty fields and moves the old card to the past" do
      id = read!("log_card", { is_log_card: true, plate: "PD3318K", make: "Toyota", seats: "23", chassis_number: "ABC123" })
      post api_v1_vehicle_log_cards_path(vehicle), params: { document_read_id: id }
      expect(response).to have_http_status(:created)
      expect(json.dig(:meta, :filled)).to eq(%w[make chassis_number])
      expect(vehicle.reload).to have_attributes(make: "Toyota", seats: 13, chassis_number: "ABC123")

      post api_v1_vehicle_log_cards_path(vehicle), params: { file: pdf }
      get api_v1_vehicle_log_cards_path(vehicle)
      expect(json[:data].pluck(:current)).to eq([ true, false ])
      current, past = json[:data].pluck(:id)

      delete api_v1_vehicle_log_card_path(vehicle, current)
      expect(response).to have_http_status(:forbidden)
      delete api_v1_vehicle_log_card_path(vehicle, past)
      expect(response).to have_http_status(:no_content)
    end

    it "blocks saving the vehicle until the plate is picked" do
      id = read!("log_card", { is_log_card: true, plate: "PD3318X" })
      post api_v1_vehicle_log_cards_path(vehicle), params: { document_read_id: id }
      card = json.dig(:data, :id)
      expect(json.dig(:data, :plate_conflict)).to be(true)

      patch api_v1_vehicle_path(vehicle), params: { vehicle: { notes: "x" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :details, :plate).first).to include("PD3318X")

      patch resolve_plate_api_v1_vehicle_log_card_path(vehicle, card), params: { use: "card" }, as: :json
      expect(vehicle.reload.plate).to eq("PD3318X")
      patch api_v1_vehicle_path(vehicle), params: { vehicle: { notes: "x" } }, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "insurance" do
    it "adds read files to the current policy, fills it, and renews" do
      id = read!("insurance", { is_insurance: true, kind: "policy", plate: "PD3318K", insurer: "Income", ends_on: "2027-03-31",
                                premium: "2450", gst: "220.5", total: "2670.5" })
      post api_v1_vehicle_insurance_documents_path(vehicle), params: { document_read_id: id }
      expect(response).to have_http_status(:created)
      expect(json.dig(:meta, :filled)).to eq(%w[insurer ends_on premium gst total])

      id2 = read!("insurance", { is_insurance: true, kind: "invoice", plate: "PZ1", insurer: "Other" })
      post api_v1_vehicle_insurance_documents_path(vehicle), params: { document_read_id: id2 }
      expect(json[:data]).to include(kind: "invoice", plate_differs: true)

      get api_v1_vehicle_insurance_policies_path(vehicle)
      policy = json[:data].first
      expect(policy).to include(current: true, insurer: "Income", total: "2670.5", expiry_status: "valid")
      expect(policy[:documents].size).to eq(2)

      post renew_api_v1_vehicle_insurance_policies_path(vehicle)
      expect(json[:data]).to include(current: true, insurer: "Income", starts_on: "2027-04-01", total: nil)
      get api_v1_vehicle_insurance_policies_path(vehicle)
      expect(json[:data].pluck(:current)).to eq([ true, false ])
      expect(json[:data].last[:documents].size).to eq(2)
    end

    it "keeps up to 5 files on a policy" do
      5.times { post api_v1_vehicle_insurance_documents_path(vehicle), params: { file: pdf, kind: "other" } }
      post api_v1_vehicle_insurance_documents_path(vehicle), params: { file: pdf }
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to include("up to 5")
    end

    it "shows the insurance on the vehicle list" do
      within_tenant(company) { vehicle.insurance_policies.create!(insurer: "Income", ends_on: Date.current + 10) }
      get api_v1_vehicles_path
      expect(json[:data].first[:insurance]).to include(insurer: "Income", status: "due_soon")
    end
  end
end

RSpec.describe "Fill from Message" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }

  before { sign_in_as(create(:user, company:)) }

  it "reads a pasted message into trip forms that POST /trips accepts" do
    client, type = within_tenant(company) { [ create(:client, name: "DBS Bank"), create(:vehicle_type, key: "van", seats: 13) ] }
    fake_claude.reply = {
      is_trip: true, client: "DBS Bank", client_raw: "DBS", contact: { name: "Daniel Ng", phone: "98765432", email: "", org: "DBS" },
      notes: "", assume: [ "tmr read as Tue 3 Nov 2026" ], miss: [],
      trips: [ { type: "adhoc", date: "2026-11-03", time: "09:00", return_time: "", hours: 0, direction: "arr", terminal: "",
                 flight: "", flight_time: "", pickup: "DBS Asia Central", stops: [], dropoff: "Changi Business Park", pax: 10,
                 bags: 0, luggage: { cabin: 0, medium: 0, large: 0, xl: 0, oversized: 0 }, vehicles: [ { type: "van", n: 1 } ],
                 guest_name: "", guest_phone: "", signboard: "", label: "", price: 0, price_for: "trip", mg_fee: 0, notes: "" } ]
    }
    perform_enqueued_jobs { post api_v1_document_reads_path, params: { kind: "trip_message", input_text: "Pls arrange combi tmr 9am" } }
    get api_v1_document_read_path(json.dig(:data, :id))
    result = json.dig(:data, :result)
    expect(result).to include(client_id: client.id, assume: [ "tmr read as Tue 3 Nov 2026" ])

    form = result[:forms].first[:trip].merge(end_time: "09:45")
    post api_v1_trips_path, params: { trip: form }, as: :json
    expect(response).to have_http_status(:created)
    expect(json[:data]).to include(title: "DBS Bank", pax: 10, route_text: "DBS Asia Central to Changi Business Park")
    expect(json.dig(:data, :vehicle_requirements).first).to include(vehicle_type_id: type.id)
  end
end
