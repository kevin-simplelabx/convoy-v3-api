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
end
