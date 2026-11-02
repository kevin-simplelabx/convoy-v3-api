require "rails_helper"

# Fleet > Fuel & Energy: entries with receipt reading, efficiency between full fills, the log, vehicle cards, companies.
RSpec.describe "Fuel & Energy" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      van = create(:vehicle, plate: "PD1A", make: "Toyota", model: "HiAce")
      ev = create(:vehicle, plate: "PD9E")
      tan = create(:driver, name: "Tan")
      van.driver_schedules.create!(driver: tan, starts_on: Date.new(2026, 10, 1))
      FuelCompany.ensure_defaults!
      { van:, ev:, tan:, esso: FuelCompany.find_by!(name: "Esso"), managed: create(:vehicle, plate: "PC1X", operator: create(:operator)) }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 20, 9, 0)
    sign_in_as(create(:user, :admin, company:))
  end

  def add(**attrs)
    post api_v1_fuel_entries_path, params: { fuel_entry: { vehicle_id: f[:van].id, kind: "diesel", full: true }.merge(attrs) }, as: :json
    expect(response).to have_http_status(:created), json.inspect
    json[:data]
  end

  it "measures km/L from full fill to full fill, adding partial fills in between" do
    add(date: "2026-11-01", time: "08:00", quantity: 50, cost: 120, odometer: 10_000)
    add(date: "2026-11-05", quantity: 20, cost: 48, odometer: 10_200, full: false)
    add(date: "2026-11-09", quantity: 40, cost: 96, odometer: 10_600)
    add(date: "2026-11-10", kind: "def", quantity: 10, cost: 15, odometer: 10_650, full: true)
    add(date: "2026-11-12", quantity: 30, cost: 72, odometer: 10_500)

    get api_v1_fuel_entries_path, params: { month: "2026-11" }
    rows = json[:data].index_by { |r| r[:date] }
    expect(rows["2026-11-09"]).to include(km_since: 400, efficiency: "10.0", driver_name: "Tan", unit_price: "2.4") # 600 km / 60 L
    expect(rows["2026-11-05"]).to include(km_since: 200, efficiency: nil)
    expect(rows["2026-11-10"]).to include(full: false, efficiency: nil, kind_name: "AdBlue (DEF)")
    expect(rows["2026-11-12"]).to include(km_since: nil, odometer_back: 10_650)
    expect(json[:meta]).to eq(month: "2026-11", next_month: false)

    get api_v1_fuel_entries_path, params: { month: "2026-11", kind: "def" }
    expect(json[:data].size).to eq(1)

    # Deleting the partial fill changes the measure: 600 km / 40 L
    delete api_v1_fuel_entry_path(rows["2026-11-05"][:id])
    get api_v1_fuel_entry_path(rows["2026-11-09"][:id])
    expect(json.dig(:data, :efficiency)).to eq("15.0")
  end

  it "measures kWh/100km for charges" do
    post api_v1_fuel_entries_path, params: { fuel_entry: { vehicle_id: f[:ev].id, kind: "elec", date: "2026-11-01", quantity: 60, cost: 30, odometer: 5000, full: true } }, as: :json
    post api_v1_fuel_entries_path, params: { fuel_entry: { vehicle_id: f[:ev].id, kind: "elec", date: "2026-11-03", quantity: 50, cost: 25, odometer: 5200, full: true } }, as: :json
    expect(json[:data]).to include(efficiency: "25.0", unit: "kWh")
  end

  it "fills an entry from a read receipt and warns about the plate" do
    fake_claude.reply = { is_receipt: true, kind: "diesel", brand: "ESSO", station: "Esso Jurong West Ave 2", date: "2026-11-18",
                          time: "07:42", quantity: "45.2", price: "2.65", cost: "", plate: "PD777Z", odometer: "" }
    perform_enqueued_jobs { post api_v1_document_reads_path, params: { kind: "fuel_receipt", file: fixture_file_upload("photo.png", "image/png") } }
    read_id = json.dig(:data, :id)

    post api_v1_fuel_entries_path, params: { fuel_entry: { vehicle_id: f[:van].id, odometer: 11_000 }, document_read_id: read_id }, as: :json
    expect(response).to have_http_status(:created), json.inspect
    expect(json.dig(:meta, :filled)).to eq(%w[kind date time quantity cost station fuel_company])
    expect(json.dig(:meta, :warnings)).to eq([ "The receipt shows PD777Z, but the vehicle picked is PD1A" ])
    expect(json[:data]).to include(date: "2026-11-18", time: "07:42", quantity: "45.2", cost: "119.78", station: "Jurong West Ave 2",
                                   fuel_company_name: "Esso")
    expect(json.dig(:data, :receipt, :url)).to start_with("/api/v1/downloads/")
  end

  it "refuses a bus that is not your own and checks the amounts" do
    post api_v1_fuel_entries_path, params: { fuel_entry: { vehicle_id: f[:managed].id, kind: "diesel", date: "2026-11-01", quantity: 0, cost: 10 } }, as: :json
    expect(json.dig(:error, :details)).to include(vehicle: [ "Vehicle must be one of your own buses" ], quantity: [ "Quantity must be greater than 0" ])
  end

  it "gives a blank form with the bus's last kind and odometer" do
    add(date: "2026-11-02", kind: "petrol", quantity: 40, cost: 100, odometer: 12_345)

    get new_api_v1_fuel_entry_path, params: { vehicle_id: f[:van].id }
    expect(response).to have_http_status(:ok)
    expect(json[:data]).to eq(vehicle_id: f[:van].id, date: "2026-11-20", time: "09:00", kind: "petrol", full: true,
                              last_odometer: 12_345)
  end

  it "gives vehicle cards and the Fuel summary of the vehicle record" do
    add(date: "2026-10-20", quantity: 50, cost: 120, odometer: 10_000)
    add(date: "2026-11-02", quantity: 50, cost: 125, odometer: 10_500, fuel_company_id: f[:esso].id)

    get vehicles_api_v1_fuel_entries_path, params: { month: "2026-11" }
    van = json[:data].find { |c| c[:plate] == "PD1A" }
    expect(van).to include(sub: "Toyota HiAce", month_cost: "125.0", fuel_efficiency: "10.0", cost_per_km: "0.49", km: 500, entries: 2)
    expect(van[:last]).to include(date: "2026-11-02", kind_name: "Diesel", unit: "L", odometer: 10_500)
    expect(json[:data].find { |c| c[:plate] == "PD9E" }).to include(entries: 0, last: nil)

    get api_v1_vehicle_path(f[:van])
    expect(json.dig(:data, :fuel)).to include(month_cost: "125.0", fuel_efficiency: "10.0")
    get api_v1_vehicle_path(f[:managed])
    expect(json.dig(:data, :fuel)).to be_nil
  end

  it "keeps the fuel companies, and not one in use" do
    add(date: "2026-11-02", quantity: 50, cost: 125, fuel_company_id: f[:esso].id)
    get api_v1_fuel_companies_path
    expect(json[:data].first).to include(name: "Esso", kind: "fuel", entries_count: 1)
    expect(json[:data].size).to eq(9)

    put bulk_api_v1_fuel_companies_path, params: { companies: [ { name: "Shell", kind: "both" } ] }, as: :json
    expect(json.dig(:error, :message)).to eq("Esso is used by 1 entry, so it can't be deleted")

    put bulk_api_v1_fuel_companies_path, params: { companies: [ { id: f[:esso].id, name: "Esso Mobil" }, { name: "Cnergy", kind: "elec" } ] }, as: :json
    expect(json[:data].map { |c| c.slice(:name, :kind) }).to eq([ { name: "Esso Mobil", kind: "fuel" }, { name: "Cnergy", kind: "elec" } ])
  end
end
