require "rails_helper"

RSpec.describe "School Runs" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      cal = create(:calendar, kind: :school)
      { client: create(:client, name: "Eastern Coaches", kind: :transport_company), type: create(:vehicle_type, seats: 13),
        bus: create(:vehicle, plate: "PD3318K"), cal:,
        other: create(:trip, kind: :school_run, session: :am, title: "Other Run").tap { |t| t.stops.first.students.create!(name: "Tan Wei") } }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 6, 0)
    sign_in_as(create(:user, company:))
  end

  def school_run(**attrs)
    { kind: "school_run", session: "am", client_id: f[:client].id, starts_on: "2026-11-02", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      calendar_id: f[:cal].id, price: 2100, price_basis: "month",
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ], vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:bus].id } ],
      stops_attributes: [
        { position: 0, name: "Blk 443A Bedok", use: "pu", scheduled_time: "06:40", students_attributes: [ { name: "Lim Jia Hui", class_name: "P3", phone: "9123 4567" } ] },
        { position: 1, name: "Blk 120 Bedok", use: "pu", scheduled_time: "06:55", students_attributes: [ { name: "Ali Hassan", class_name: "P5" }, { name: "Chen Yu", class_name: "P1" } ] },
        { position: 2, name: "Red Swastika School", use: "do" }
      ] }.merge(attrs)
  end

  it "works out the times and passengers, estimating the school arrival when not given" do
    post api_v1_trips_path, params: { trip: school_run }, as: :json
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(start_time: "06:40", end_time: "07:05", pax: 3, school_time_estimated: true)
    expect(json.dig(:data, :stops, 1, :students).pluck(:name)).to eq([ "Ali Hassan", "Chen Yu" ])
  end

  it "moves the morning run on a Late Arrival day only" do
    within_tenant(company) { f[:cal].days.create!(kind: :late, starts_on: "2026-11-04", usual_time: "07:30", new_time: "09:00") }
    post api_v1_trips_path, params: { trip: school_run }, as: :json
    get api_v1_occurrences_path, params: { trip_id: json.dig(:data, :id), from: "2026-11-03", to: "2026-11-04" }
    expect(json[:data].pluck(:start_time)).to eq(%w[06:40 08:10])
  end

  it "bills the next 12 months with unpaid months and No School days taken off" do
    within_tenant(company) { f[:cal].days.create!(kind: :ns, starts_on: "2026-11-11", ends_on: "2026-11-13") }
    post api_v1_trips_path, params: { trip: school_run(paid_months_mode: "part", unpaid_months: [ 12 ], unpaid_month_share: 50, charge_no_school_days: false) }, as: :json
    get api_v1_trip_school_run_bill_path(json.dig(:data, :id))
    nov, dec = json[:data].first(2)
    # November: 18 run days, 3 No School days lost -> 2100 x 18/21 = 1800; December paid at half
    expect(nov).to include(month: "2026-11", runs: 18, no_school_days: 3, amount: "1800.0")
    expect(dec).to include(month: "2026-12", share: 0.5, amount: "1050.0")
  end

  describe "Import Route List" do
    let(:list) do
      { is_route_list: true, label: "AM 13", session: "am", school: "Red Swastika School", school_address: "350 Bedok North Ave 3 469719",
        start_date: "2026-11-09", arrive_by: "07:20", leave_by: "", notes: "Attendant alights at Blk 120",
        rows: [
          { name: "Lim Jia Hui", class_name: "P3", address: "Blk 443A Bedok North", postal: "461443", time: "06.40", point: "Blk 443A Shelter", parent_name: "Mdm Lim", phone: "91234567", phone2: "", note: "" },
          { name: "Goh Mei", class_name: "P2", address: "Blk 443B Bedok North", postal: "462443", time: "06:40", point: "Blk 443A shelter", parent_name: "", phone: "", phone2: "", note: "" },
          { name: "Tan Wei", class_name: "P4", address: "Blk 120 Bedok", postal: "460120", time: "06:35", point: "", parent_name: "", phone: "98765432", phone2: "", note: "Sits in front" }
        ] }
    end

    def read_list(reply)
      fake_claude.reply = reply
      perform_enqueued_jobs { post api_v1_document_reads_path, params: { kind: "route_list", file: fixture_file_upload("route.csv", "text/csv") } }
      json.dig(:data, :id)
    end

    it "groups rows into stops, flags what to check and gives trip params" do
      post api_v1_route_list_review_path, params: { document_read_id: read_list(list) }, as: :json
      d = json[:data]
      expect(d[:stops].map { |s| [ s[:name], s[:time], s[:rows].pluck(:name) ] }).to eq([
        [ "Blk 443A Bedok North", "06:40", [ "Lim Jia Hui", "Goh Mei" ] ], [ "Blk 120 Bedok", "06:35", [ "Tan Wei" ] ]
      ])
      expect(d[:stops].last[:rows].first[:flags]).to eq([ "Earlier than the row above", "Also on Other Run" ])
      expect(d[:stops].first[:rows].last[:flags]).to eq([ "No parent phone" ])
      expect(d[:flagged]).to eq(2)

      attrs = d[:trip_attributes]
      expect(attrs).to include(title: "Red Swastika School AM 13", session: "am", starts_on: "2026-11-09", days: [ 1, 2, 3, 4, 5 ])
      expect(attrs[:stops_attributes].pluck(:name, :use, :scheduled_time)).to eq([
        [ "Blk 443A Bedok North", "pu", "06:40" ], [ "Blk 120 Bedok", "pu", "06:35" ], [ "Red Swastika School", "do", "07:20" ]
      ])

      post api_v1_route_list_review_path, params: { document_read_id: read_list(list), joins: [ false, false, false ] }, as: :json
      expect(json.dig(:data, :stops).size).to eq(3)
    end

    it "joins postal codes on one Saved Pick-up Point and takes its name" do
      post api_v1_pickup_points_path, params: { pickup_point: { name: "Bedok Court Gate", postal_codes: "461443, 462443", note: "Main gate" } }, as: :json
      expect(response).to have_http_status(:created)
      rows = list[:rows].map { |r| r.merge(point: "") }
      post api_v1_route_list_review_path, params: { document_read_id: read_list(list.merge(rows:)) }, as: :json
      expect(json.dig(:data, :stops, 0)).to include(name: "Bedok Court Gate", driver_note: "Main gate")
    end

    it "applies a new list from a date: changes shown, earlier list kept, students keep their key" do
      post api_v1_trips_path, params: { trip: school_run }, as: :json
      trip_id = json.dig(:data, :id)
      key = json.dig(:data, :stops, 0, :students, 0, :key)

      read_id = read_list(list)
      post api_v1_route_list_review_path, params: { document_read_id: read_id, trip_id: }, as: :json
      expect(json.dig(:data, :changes)).to include(added: [ "Goh Mei", "Tan Wei" ], removed: [ "Ali Hassan", "Chen Yu" ])

      post api_v1_trip_route_list_path(trip_id), params: { document_read_id: read_id, apply_from: "2026-11-09" }, as: :json
      expect(response).to have_http_status(:ok), json.inspect
      expect(json.dig(:data, :stops, 0, :students).find { |s| s[:name] == "Lim Jia Hui" }[:key]).to eq(key)
      expect(json.dig(:data, :route_list_name)).to eq("route.csv")

      get api_v1_trip_route_list_versions_path(trip_id)
      expect(json[:data].first).to include(valid_until: "2026-11-08", students: 3)

      get api_v1_occurrences_path, params: { trip_id:, date: "2026-11-06" }
      get passengers_api_v1_occurrence_path(json.dig(:data, 0, :id))
      expect(json.dig(:data, :stops).flat_map { |s| s[:students].pluck(:name) }).to eq([ "Lim Jia Hui", "Ali Hassan", "Chen Yu" ])
    end
  end

  it "marks students boarded, alighted and absent on the Passenger List" do
    post api_v1_trips_path, params: { trip: school_run }, as: :json
    get api_v1_occurrences_path, params: { trip_id: json.dig(:data, :id), date: "2026-11-03" }
    occ = json.dig(:data, 0, :id)
    get passengers_api_v1_occurrence_path(occ)
    lim, ali = json.dig(:data, :stops).flat_map { |s| s[:students] }.first(2)

    patch mark_passenger_api_v1_occurrence_path(occ, key: lim[:key]), params: { mark: "boarded" }, as: :json
    patch mark_passenger_api_v1_occurrence_path(occ, key: lim[:key]), params: { mark: "alighted" }, as: :json
    patch mark_passenger_api_v1_occurrence_path(occ, key: ali[:key]), params: { mark: "absent" }, as: :json
    statuses = json.dig(:data, :stops).flat_map { |s| s[:students] }.to_h { |s| [ s[:name], s[:status] ] }
    expect(statuses).to eq("Lim Jia Hui" => "alighted", "Ali Hassan" => "absent", "Chen Yu" => "not_marked")

    patch mark_passenger_api_v1_occurrence_path(occ, key: ali[:key]), params: { mark: "clear" }, as: :json
    expect(json.dig(:data, :stops, 1, :students, 0, :status)).to eq("not_marked")
  end

  it "clears student data 7 years after the run ended" do
    old = within_tenant(company) do
      t = create(:trip, kind: :school_run, session: :am, days: [ 1 ], end_mode: :date, starts_on: Date.new(2018, 1, 1), ends_on: Date.new(2019, 6, 30))
      t.stops.first.students.create!(name: "Kept Too Long")
      t
    end
    within_tenant(company) { SchoolRuns::Purge.call }
    expect(old.reload.students_purged_at).to be_present
    expect(TripStopStudent.unscoped.where(name: "Kept Too Long")).to be_empty
    expect(TripStopStudent.unscoped.where(name: "Tan Wei")).to exist
  end
end
