require "rails_helper"

RSpec.describe "Rate Cards page" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:) }
  let!(:f) do
    within_tenant(company) do
      { small: create(:vehicle_type, name: "13-seater", seats: 13), big: create(:vehicle_type, name: "45-seater", seats: 45),
        google: create(:client, name: "Google"), dbs: create(:client, name: "DBS", kind: "company"), ann: create(:client, name: "Ann Tan", kind: "individual", email: "ann@mail.sg") }
    end
  end

  before { sign_in_as(user) }

  def new_card(name)
    get new_api_v1_rate_card_path
    card = json[:data].merge(name:)
    post api_v1_rate_cards_path, params: { rate_card: card.except(:warnings) }, as: :json
    expect(response).to have_http_status(:created), response.body
    json[:data]
  end

  it "starts from the standard card, saves it (first card is the default) and shows it in the same shape" do
    get new_api_v1_rate_card_path
    expect(json.dig(:data, :periods).pluck(:name)).to eq([ "Off Peak", "Peak", "Night", "Weekend and PH" ])
    expect(json.dig(:data, :warnings)).to eq(overlaps: [], gaps: [])
    rates = json.dig(:data, :periods, 0, :rates)
    expect(rates).to eq([ { vehicle_type_id: f[:small].id, trip_rate: 55, hourly_rate: 45 }, { vehicle_type_id: f[:big].id, trip_rate: 135, hourly_rate: 93 } ])

    card = new_card("Standard Rates")
    expect(card).to include(default_card: true, archived: false, clients_count: 3, vehicle_type_ids: [ f[:small].id, f[:big].id ])
    expect(card[:periods].first).to include(name: "Off Peak", days: %w[mon tue wed thu fri], ranges: [ { starts_at: "07:00", ends_at: "19:00" } ])
    expect(card[:distance_bands].pluck(:up_to_km)).to eq([ "20.0", "40.0", nil ])
    expect(card[:clients].pluck(:name)).to eq([ "Ann Tan", "DBS", "Google" ])

    second = new_card("Contract")
    expect(second).to include(default_card: false, clients_count: 0)
  end

  it "edits the whole card, checks the rules and warns about overlaps and gaps" do
    card = new_card("Standard Rates")
    body = card.slice(*%i[name description vehicle_type_ids wait_free_minutes wait_fee wait_block_minutes periods distance_bands
                          stop_fee_amounts disposal_km_amounts]).merge(vehicle_type_ids: [ f[:small].id ])
    body[:periods] = [
      { name: "Day", days: %w[mon tue wed thu fri sat sun ph], ranges: [ { starts_at: "06:00", ends_at: "20:00" } ],
        rates: [ { vehicle_type_id: f[:small].id, trip_rate: 60, hourly_rate: 40 } ] },
      { name: "Evening", days: %w[mon], ranges: [ { starts_at: "19:00", ends_at: "23:00" } ], rates: [] }
    ]

    post check_api_v1_rate_cards_path, params: { rate_card: body }, as: :json
    expect(json[:data][:overlaps]).to eq([ "Day and Evening overlap on MON" ])
    expect(json[:data][:gaps]).to eq([ "MON from 00:00", "TUE from 00:00", "WED from 00:00", "THU from 00:00" ])

    patch api_v1_rate_card_path(card[:id]), params: { rate_card: body, lock_version: card[:lock_version] }, as: :json
    expect(response).to have_http_status(:ok)
    expect(json[:data]).to include(vehicle_type_ids: [ f[:small].id ], periods_count: 2)
    expect(json.dig(:data, :periods, 1, :rates)).to eq([ { vehicle_type_id: f[:small].id, trip_rate: "0.0", hourly_rate: "0.0" } ])
    expect(json.dig(:data, :warnings, :overlaps)).to eq([ "Day and Evening overlap on MON" ])

    patch api_v1_rate_card_path(card[:id]), params: { rate_card: body, lock_version: card[:lock_version] }, as: :json
    expect(response).to have_http_status(:conflict)

    { { name: " " } => "Enter the card name", { vehicle_type_ids: [] } => "Keep at least one vehicle type", { periods: [] } => "Add at least one period",
      { periods: [ body[:periods][0].merge(days: []) ] } => "Every period needs at least one day",
      { periods: [ body[:periods][0].merge(ranges: [ { starts_at: "08:00", ends_at: "08:00" } ]) ] } => "A time range can't start and end at the same time",
      { distance_pricing: true, distance_bands: [ { up_to_km: 40 }, { up_to_km: 20 }, { up_to_km: nil } ] } => "Distance bands must go up in km" }.each do |change, message|
      post api_v1_rate_cards_path, params: { rate_card: body.merge(name: "Other").merge(change) }, as: :json
      expect(json.dig(:error, :message)).to eq(message)
    end
    post api_v1_rate_cards_path, params: { rate_card: body.merge(name: "standard rates") }, as: :json
    expect(json.dig(:error, :message)).to eq("Another card has this name")
  end

  it "makes a card the default, archives and unarchives it, and assigns clients" do
    standard = new_card("Standard Rates")
    contract = new_card("Contract")

    get api_v1_rate_card_assignments_path
    expect(json[:data].pluck(:name, :rate_card_name, :on_default)).to eq([ [ "Ann Tan", "Standard Rates", true ], [ "DBS", "Standard Rates", true ],
                                                                            [ "Google", "Standard Rates", true ] ])
    patch api_v1_rate_card_assignment_path(f[:google].id), params: { rate_card_id: contract[:id] }, as: :json
    expect(json[:data]).to include(rate_card_id: contract[:id], on_default: false)

    get api_v1_rate_card_assignments_path, params: { rate_card_id: contract[:id] }
    expect(json[:data].pluck(:name)).to eq(%w[Google])
    expect(json[:meta][:cards]).to eq([ { id: standard[:id], name: "Standard Rates", default_card: true, clients_count: 2 },
                                        { id: contract[:id], name: "Contract", default_card: false, clients_count: 1 } ])
    get api_v1_rate_card_assignments_path, params: { kind: "individual", q: "ann" }
    expect(json[:data].pluck(:name)).to eq([ "Ann Tan" ])

    patch archive_api_v1_rate_card_path(contract[:id]), as: :json
    expect(json.dig(:error, :message)).to eq("Contract is assigned to clients. Assign them another card first")
    patch archive_api_v1_rate_card_path(standard[:id]), as: :json
    expect(json.dig(:error, :message)).to eq("Make another card the default before archiving this one")

    patch api_v1_rate_card_assignment_path(f[:google].id), params: { rate_card_id: standard[:id] }, as: :json
    expect(within_tenant(company) { f[:google].reload.rate_card_id }).to be_nil
    patch archive_api_v1_rate_card_path(contract[:id]), as: :json
    expect(json[:data]).to include(archived: true)
    patch make_default_api_v1_rate_card_path(contract[:id]), as: :json
    expect(json.dig(:error, :message)).to eq("Unarchive the card before making it the default")
    patch api_v1_rate_card_assignment_path(f[:google].id), params: { rate_card_id: contract[:id] }, as: :json
    expect(response).to have_http_status(:not_found)

    patch unarchive_api_v1_rate_card_path(contract[:id]), as: :json
    patch make_default_api_v1_rate_card_path(contract[:id]), as: :json
    expect(json[:data]).to include(default_card: true, clients_count: 3)

    get api_v1_rate_cards_path
    expect(json[:data].pluck(:name, :default_card, :clients_count)).to eq([ [ "Contract", true, 3 ], [ "Standard Rates", false, 0 ] ])
  end

  it "prices a quote from the edited card" do
    new_card("Standard Rates")
    post api_v1_rate_card_quote_path, params: { client_id: f[:google].id, date: "2026-11-02", start_time: "08:00", vehicle_type_id: f[:small].id }, as: :json
    expect(json[:data]).to include(amount: "55.0", missing: nil)
  end
end
