require "rails_helper"

# School Bus › school › Rider Data and Riders: check a file, import a list (bad rows skipped, homes placed by OneMap in
# the background), the list in use on a date with manual riders, counts, search, Add Rider and the CSV export.
RSpec.describe "School Bus riders" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:school) { within_tenant(company) { School.create!(name: "St. Stephen's School", short_name: "SSS", postal: "455789") } }

  def upload(text, name = "riders.csv")
    file = Tempfile.new([ "riders", File.extname(name) ])
    file.write(text)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv", original_filename: name)
  end

  let(:csv) do
    <<~CSV
      Student ID,Name,Grade/Class,Home Address,Postal,AM,PM,CCA,Start Date,End Date,Parent,Contact
      S-1,Tan Wei Ling,P3,Blk 101 Bedok North,460101,Y,Y,Mon;Wed,,,Tan Ah Kow,91234567
      S-2,Lim Jia Hui,P5,Blk 216 Bedok North,460216,Y,N,,02/01/2026,20/11/2026,,
      S-3,,P1,Somewhere,460300,Y,Y,,,,,
      S-4,Goh Kai,P2,Blk 9 Joo Chiat,4271,Y,Y,Funday,,,,
      S-1,Tan Again,P3,Blk 1,460101,Y,Y,,,,,
      S-5,Ng Mei,P4,Blk 77 Nowhere,469999,N,Y,,,,,
    CSV
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    fake_one_map.add("460101", 1.3301, 103.9301, "101 Bedok North Ave 4")
    fake_one_map.add("460216", 1.3302, 103.9302, "216 Bedok North St 1")
    sign_in_as(create(:user, company:, permissions: %w[schools]))
  end

  it "checks a file, imports the readable rows and places homes in the background" do
    post preview_api_v1_school_rider_datasets_path(school), params: { file: upload(csv) }
    expect(json[:data]).to include(riders: 3, problems: 3)
    expect(json.dig(:data, :errors).map { |e| e[:line] }).to eq([ 4, 5, 6 ])
    expect(json.dig(:data, :errors, 1, :message)).to eq("Goh Kai: CCA days must be days like Mon;Wed") # 4271 → 004271, as the prototype pads

    perform_enqueued_jobs do
      post api_v1_school_rider_datasets_path(school), params: { file: upload(csv), effective_from: "2026-10-01" }
    end
    expect(response).to have_http_status(:created)
    expect(json[:meta]).to include(skipped_count: 3)

    get api_v1_school_rider_datasets_path(school)
    expect(json[:data].first).to include(file_name: "riders.csv", riders_count: 3, checked_count: 3, unlocated_count: 1, status: "ready", state: "in_use")
    expect(json.dig(:data, 0, :file, :url)).to be_present

    get api_v1_school_riders_path(school)
    expect(json[:meta][:counts]).to eq(all: 3, am: 2, pm: 2, cca: 1, unlocated: 1)
    tan = json[:data].find { |r| r[:rid] == "S-1" }
    expect(tan).to include(name: "Tan Wei Ling", cca_days: [ 1, 3 ], lat: 1.3301, located: true, source: "csv")
    lim = json[:data].find { |r| r[:rid] == "S-2" }
    expect(lim).to include(pm: false, starts_on: "2026-01-02", ends_on: "2026-11-20")

    get api_v1_school_riders_path(school), params: { filter: "unlocated" }
    expect(json[:data].map { |r| r[:rid] }).to eq(%w[S-5])
    get api_v1_school_riders_path(school), params: { q: "bedok", date: "2026-11-25" }
    expect(json[:data].map { |r| r[:rid] }).to eq(%w[S-1])
  end

  it "uses the list in effect on the date; a later list is scheduled, then replaces it" do
    perform_enqueued_jobs do
      post api_v1_school_rider_datasets_path(school), params: { file: upload(csv), effective_from: "2026-10-01" }
      post api_v1_school_rider_datasets_path(school), params: { file: upload("Name,Address,Postal\nNew Kid,Blk 1,460101\n", "jan.csv"), effective_from: "2027-01-02" }
    end
    get api_v1_school_rider_datasets_path(school)
    expect(json[:data].map { |d| d[:state] }).to eq(%w[in_use scheduled])

    get api_v1_school_rider_events_path(school), params: { date: "2026-11-02" } # the Plan For calendar
    ev = json[:data].map { it.values_at(:date, :kind, :rid) }
    expect(ev).to include([ "2026-10-01", "list", nil ], [ "2026-11-20", "leave", "S-2" ], [ "2027-01-02", "list", nil ],
                          [ "2027-01-02", "join", "S-0002" ], [ "2027-01-02", "leave", "S-1" ])
    expect(json[:data].find { it[:kind] == "list" }).to include(name: "riders.csv")
    expect(json[:meta]).to eq(date: "2026-11-02", soon: 1) # S-2 leaves on 20 Nov
    get api_v1_school_rider_datasets_path(school), params: { date: "2027-01-05" }
    expect(json[:data].map { |d| d[:state] }).to eq(%w[replaced in_use])
    get api_v1_school_riders_path(school), params: { date: "2027-01-05" }
    expect(json[:data].map { |r| r[:name] }).to eq([ "New Kid" ])
    expect(json.dig(:meta, :dataset, :file_name)).to eq("jan.csv")

    id = json.dig(:meta, :dataset, :id)
    delete api_v1_school_rider_dataset_path(school, id)
    get api_v1_school_riders_path(school), params: { date: "2027-01-05" }
    expect(json[:data].map { |r| r[:rid] }).to contain_exactly("S-1", "S-5") # S-2 ended on 20 Nov
  end

  it "adds a rider by hand and exports the riders as CSV" do
    post api_v1_school_riders_path(school), params: { rider: { first_name: "Wei", last_name: "Tan", name_order: "last", postal: "460216", am: true, pm: false, cca_days: "Tue" } }
    expect(response).to have_http_status(:created)
    expect(json[:data]).to include(rid: "M-0001", name: "Tan Wei", address: "216 Bedok North St 1", located: true, source: "manual", cca_days: [ 2 ])

    post api_v1_school_riders_path(school), params: { rider: { first_name: "Ann", postal: "469999", am: false, pm: false } }
    expect(json.dig(:error, :message)).to include("Pick at least one of AM, PM or CCA")
    post api_v1_school_riders_path(school), params: { rider: { first_name: "Ann", postal: "469999", starts_on: "2026-11-01" } }
    expect(json[:data]).to include(rid: "M-0002", located: false)

    get export_api_v1_school_riders_path(school)
    expect(response.media_type).to eq("text/csv")
    lines = response.body.lines
    expect(lines.first.strip).to start_with("student_id,student_name")
    expect(lines.size).to eq(3)
  end

  it "needs the schools permission to change riders" do
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    post api_v1_school_riders_path(school), params: { rider: { first_name: "Ann", postal: "460101" } }
    expect(response).to have_http_status(:forbidden)
    get api_v1_school_riders_path(school)
    expect(response).to have_http_status(:ok)
  end
end
