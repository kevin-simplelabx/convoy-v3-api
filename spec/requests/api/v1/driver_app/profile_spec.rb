require "rails_helper"

# Convoy Driver app › Account: the portable profile (Personal Details, Singpass locks, NRIC once, email and password),
# Driving Credentials, the companies' copy (Drivers › View Details), Career Metrics, Transport Company, My Vehicle Today.
RSpec.describe "Driver app profile" do
  let(:today) { Date.new(2026, 11, 3) }
  let(:company) { create(:company, name: "SimpleDrive", ops_phone: "+6562221100", ops_hours: "Mon–Sat 05:30–20:00", ops_email: "ops@simpledrive.sg") }
  let!(:data) do
    within_tenant(company) do
      bus = create(:vehicle, plate: "PC8812K", seats: 29, make: "Toyota", model: "Coaster")
      driver = create(:driver, name: "Ahmad", phone: "+6591234567", joined_at: Time.zone.local(2024, 10, 1))
      bus.driver_schedules.create!(starts_on: today - 30, driver:)
      company.links.create!(title: "Depot map", url: "https://simpledrive.sg/depot", note: "Where to park", position: 1)
      trip = create(:trip, title: "Google Shuttle")
      [ [ 0, "completed", 50 ], [ 1, "completed", nil ], [ 2, "scheduled", nil ] ].each do |i, status, km|
        day = today - 3 + i
        occ = TripOccurrence.create!(trip:, client: trip.client, date: day, start_time: 480, end_time: 540, starts_at: day.in_time_zone.change(hour: 8),
                                     ends_at: day.in_time_zone.change(hour: 9), kind: "ad_hoc", trip_label: "TID00000#{i}", vehicle: bus,
                                     driver:, run_key: "r#{i}", status:)
        OccurrenceTripSummary.create!(occurrence_id: occ.id, occurrence_date: occ.date, distance_km: km) if km
      end
      { driver:, bus: }
    end
  end

  before do
    travel_to today.in_time_zone.change(hour: 10)
    post code_api_v1_driver_app_session_path, params: { phone: "91234567" }, as: :json
    post api_v1_driver_app_session_path, params: { phone: "91234567", code: "123456" }, as: :json
    integration_session.bearer_token = json.dig(:data, :token)
  end

  def account = DriverAccount.last
  def kyc = ActsAsTenant.with_tenant(company) { data[:driver].reload.kyc_profile }

  it "fills Personal Details, locks what Singpass verified, adds the NRIC once and shares the copy with the company" do
    get api_v1_driver_app_profile_path
    expect(json[:data]).to include(phone: "+6591234567", phone_verified: true, id_number: nil, singpass: { verified: false, verified_at: nil, fields: [] })
    expect(json.dig(:data, :completeness)).to include(done: 1, total: 6)
    expect(json.dig(:data, :metrics)).to eq(this_company: { trips: 2, hours: 2.0, km: 50.0 }, all_time: { trips: 2, hours: 2.0, km: 50.0 })

    patch api_v1_driver_app_profile_path, params: { profile: { name: "Ahmad bin Rahman", date_of_birth: "1982-03-14", nationality: "Singaporean",
                                                               residential_status: "Singapore Citizen", id_number: "s8212345a",
                                                               address: "Blk 310 Tampines St 33 #07-114", postal_code: "520310",
                                                               photo: fixture_file_upload("photo.png", "image/png") } }
    expect(response).to have_http_status(:ok), json.inspect
    expect(json[:data]).to include(name: "Ahmad bin Rahman", id_number: "S****345A", id_label: "NRIC",
                                   full_address: "Blk 310 Tampines St 33 #07-114, Singapore 520310", photo: hash_including(:url, :thumb_url))
    expect(json.dig(:data, :completeness, :done)).to eq(4)
    expect(kyc).to have_attributes(id_number: "S8212345A", residential_status: "Singapore Citizen", date_of_birth: Date.new(1982, 3, 14),
                                   address: "Blk 310 Tampines St 33 #07-114, Singapore 520310")

    patch api_v1_driver_app_profile_path, params: { profile: { id_number: "S8299999Z" } }, as: :json
    expect(json.dig(:error, :message)).to eq("Your NRIC / FIN is verified, so it cannot be changed here")
    patch api_v1_driver_app_profile_path, params: { profile: { postal_code: "52031" } }, as: :json
    expect(json.dig(:error, :details, :postal_code)).to eq([ "Postal code must be 6 digits" ])

    account.update!(singpass_verified_at: Time.current, singpass_fields: %w[name date_of_birth])
    patch api_v1_driver_app_profile_path, params: { profile: { name: "Ahmad", date_of_birth: "1982-03-14", nationality: "Malaysian" } }, as: :json
    expect(json.dig(:error, :message)).to eq("Full Name is verified with Singpass and cannot be changed here")
    patch api_v1_driver_app_profile_path, params: { profile: { name: "Ahmad bin Rahman", nationality: "Malaysian" } }, as: :json
    expect(json[:data]).to include(nationality: "Malaysian", singpass: hash_including(verified: true, fields: %w[name date_of_birth]))
  end

  it "sets the email and password, then needs the current password to change them" do
    patch email_api_v1_driver_app_profile_path, params: { email: "Ahmad@Mail.com", password: "short" }, as: :json
    expect(json.dig(:error, :details, :password)).to eq([ "Password needs at least 8 characters" ])
    patch email_api_v1_driver_app_profile_path, params: { email: "Ahmad@Mail.com", password: "Driver123!", password_confirmation: "Driver123!" }, as: :json
    expect(json[:data]).to include(email: "ahmad@mail.com", password_set: true)
    expect(kyc.email).to eq("ahmad@mail.com")

    patch email_api_v1_driver_app_profile_path, params: { email: "new@mail.com", password: "Another123!", current_password: "wrong" }, as: :json
    expect(json.dig(:error, :message)).to eq("Your current password is not right")
    patch email_api_v1_driver_app_profile_path, params: { email: "new@mail.com", password: "Another123!", current_password: "Driver123!" }, as: :json
    expect(json.dig(:data, :email)).to eq("new@mail.com")

    post email_api_v1_driver_app_session_path, params: { email: "new@mail.com", password: "Another123!" }, as: :json
    expect(response).to have_http_status(:ok)
  end

  it "keeps Driving Credentials with expiry badges and gives the company the list" do
    post api_v1_driver_app_licences_path, params: { licence: { kind: "dl", classes: "Class 3, 4", expires_on: "2030-03-14",
                                                               card_front: fixture_file_upload("photo.png", "image/png") } }
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(name: "Driving Licence", expiry_status: "valid", card_front: hash_including(:url), card_back: nil)
    post api_v1_driver_app_licences_path, params: { licence: { kind: "dl", classes: "Class 4" } }, as: :json
    expect(json.dig(:error, :details, :kind)).to eq([ "Kind is already on your list" ])
    post api_v1_driver_app_licences_path, params: { licence: { kind: "vl", classes: "BDVL", number: "BD100000", expires_on: (today + 20).iso8601 } }, as: :json
    vl = json.dig(:data, :id)
    expect(json[:data]).to include(expiry_status: "urgent", days_left: 20)
    post api_v1_driver_app_licences_path, params: { licence: { kind: "other", name: "Class 4A", expires_on: (today - 1).iso8601 } }, as: :json
    other = json.dig(:data, :id)
    expect(json.dig(:data, :expiry_status)).to eq("expired")

    expect(kyc).to have_attributes(licence_class: "Class 3, 4", vocational_licence_number: "BD100000", vocational_licence_expires_on: today + 20)
    expect(kyc.licences.pluck("name")).to eq([ "Driving Licence", "Vocational Licence", "Class 4A" ])

    patch api_v1_driver_app_licence_path(vl), params: { licence: { expires_on: "2028-12-31" } }, as: :json
    expect(json.dig(:data, :expiry_status)).to eq("valid")
    delete api_v1_driver_app_licence_path(other)
    expect(response).to have_http_status(:no_content)
    get api_v1_driver_app_profile_path
    expect(json.dig(:data, :licences).pluck(:kind)).to eq(%w[dl vl])
    expect(json.dig(:data, :completeness, :items).find { it[:key] == "licences" }).to eq(key: "licences", done: true)

    other_account = DriverAccount.create!(phone: "+6598765432")
    foreign = other_account.licences.create!(kind: "dl")
    patch api_v1_driver_app_licence_path(foreign), params: { licence: { classes: "Class 3" } }, as: :json
    expect(response).to have_http_status(:not_found)

    sign_in_as(within_tenant(company) { create(:user, :admin, company:) })
    get details_api_v1_driver_path(data[:driver])
    expect(json.dig(:data, :kyc, :licences).pluck(:kind)).to eq(%w[dl vl])
  end

  it "keeps the company's copy as it was after the driver leaves" do
    patch api_v1_driver_app_profile_path, params: { profile: { nationality: "Singaporean" } }, as: :json
    post disconnect_api_v1_driver_app_company_path("driver-#{data[:driver].id}")
    patch api_v1_driver_app_profile_path, params: { profile: { nationality: "Malaysian" } }, as: :json
    expect(kyc.nationality).to eq("Singaporean")
  end

  it "shows Transport Company, Contact Operations, Company Links and My Vehicle Today" do
    get api_v1_driver_app_company_path
    expect(json[:data]).to include(role: "Driver", vehicles_count: 1, links: [ hash_including(title: "Depot map", url: "https://simpledrive.sg/depot") ])
    expect(json.dig(:data, :operations)).to include(phone: "+65 6222 1100", hours: "Mon–Sat 05:30–20:00", email: "ops@simpledrive.sg")
    expect(json.dig(:data, :membership)).to include(key: "driver-#{data[:driver].id}", joined_at: be_present)

    get api_v1_driver_app_vehicle_path
    expect(json.dig(:data, :current)).to include(plate: "PC8812K", name: "Toyota Coaster", seats: 29, since: (today - 30).iso8601, since_time: nil)

    get api_v1_driver_app_companies_path
    expect(json.dig(:data, 0, :trips_completed)).to eq(2)

    post disconnect_api_v1_driver_app_company_path("driver-#{data[:driver].id}")
    get api_v1_driver_app_vehicle_path
    expect(json.dig(:error, :message)).to eq("Pick a company first")
  end
end
