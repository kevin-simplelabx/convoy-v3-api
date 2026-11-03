require "rails_helper"

RSpec.describe "Default driver schedule" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      { bus: create(:vehicle), a: create(:driver, name: "A"), b: create(:driver, name: "B"),
        pending: create(:driver, status: :pending), managed: create(:vehicle, operator: create(:operator)) }
    end
  end

  before { sign_in_as(create(:user, :admin, company:)) }

  it "keeps a history with periods and removes only upcoming changes" do
    path = api_v1_vehicle_driver_schedules_path(data[:bus])
    post path, params: { vehicle_driver_schedule: { driver_id: data[:a].id, starts_on: Date.current - 30 } }, as: :json
    post path, params: { vehicle_driver_schedule: { driver_id: data[:b].id, starts_on: Date.current + 7 } }, as: :json

    get path
    expect(json[:data].map { |e| [ e.dig(:driver, :name), e[:ends_on] ] })
      .to eq([ [ "A", (Date.current + 6).iso8601 ], [ "B", nil ] ])

    past, upcoming = json[:data].pluck(:id)
    delete api_v1_vehicle_driver_schedule_path(data[:bus], past)
    expect(response).to have_http_status(:forbidden)
    delete api_v1_vehicle_driver_schedule_path(data[:bus], upcoming)
    expect(response).to have_http_status(:no_content)
  end

  it "takes only active drivers and own vehicles" do
    post api_v1_vehicle_driver_schedules_path(data[:bus]),
         params: { vehicle_driver_schedule: { driver_id: data[:pending].id, starts_on: Date.current } }, as: :json
    expect(response).to have_http_status(:unprocessable_content)

    post api_v1_vehicle_driver_schedules_path(data[:managed]),
         params: { vehicle_driver_schedule: { driver_id: data[:a].id, starts_on: Date.current } }, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "changes the driver from a time of day: runs before it keep the old driver" do
    travel_to Time.zone.local(2026, 11, 2, 5, 0)
    path = api_v1_vehicle_driver_schedules_path(data[:bus])
    post path, params: { vehicle_driver_schedule: { driver_id: data[:a].id, starts_on: "2026-10-01" } }, as: :json
    post path, params: { vehicle_driver_schedule: { driver_id: data[:b].id, starts_on: "2026-11-03", start_time: "6:30" } }, as: :json
    expect(json[:data]).to include(start_time: "06:30", starts_on: "2026-11-03")
    post path, params: { vehicle_driver_schedule: { driver_id: data[:b].id, starts_on: "2026-11-03", start_time: "soon" } }, as: :json
    expect(json.dig(:error, :details, :start_time)).to eq([ "must be a time like 07:30" ])

    get path
    expect(json[:data].map { [ it.dig(:driver, :name), it[:start_time], it[:ends_on], it[:ends_at] ] })
      .to eq([ [ "A", "00:00", "2026-11-03", "06:30" ], [ "B", "06:30", nil, nil ] ])

    within_tenant(company) do
      trip = create(:trip, :weekdays, starts_on: Date.new(2026, 11, 2), start_time: "06:00", end_time: "06:25", end_mode: "never")
      trip.vehicle_slots.create!(slot_no: 1, vehicle: data[:bus])
      late = create(:trip, :weekdays, starts_on: Date.new(2026, 11, 2), start_time: "07:00", end_time: "08:00", end_mode: "never")
      late.vehicle_slots.create!(slot_no: 1, vehicle: data[:bus])
      Occurrences::Sync.call(trips: [ trip, late ])
      drivers = ->(t) { TripOccurrence.where(trip: t, date: Date.new(2026, 11, 2)..Date.new(2026, 11, 4)).order(:date).map { it.driver&.name } }
      expect(drivers.(trip)).to eq(%w[A A B])
      expect(drivers.(late)).to eq(%w[A B B])
    end
  end
end
