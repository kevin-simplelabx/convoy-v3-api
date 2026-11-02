require "rails_helper"

# HR > Drivers: the scheme and vehicle type in force today, dated assignments that never overlap, rate warnings.
RSpec.describe "HR drivers" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      van = create(:vehicle_type, name: "Van", seats: 13)
      coach = create(:vehicle_type, name: "Coach", seats: 45)
      plan = PayRatePlan.create!(name: "Standard")
      period = plan.periods.create!(name: "All Day", days: PayRatePeriod::DAYS)
      period.ranges.create!(start_time: "00:00", end_time: "23:59")
      period.rates.create!(vehicle_type: van, per_trip: 14, per_hour: 10)
      basic = PayScheme.create!(name: "Basic + Trips", rate_plan: plan, is_default: true)
      monthly = PayScheme.create!(name: "Monthly", rate_plan: plan, scheme_type: "monthly_with_minimum")
      eric = create(:driver, name: "Eric Pang")
      bus = create(:vehicle, plate: "PD1234A", seats: 13)
      bus.driver_schedules.create!(driver: eric, starts_on: Date.new(2026, 10, 1))
      { van:, coach:, basic:, monthly:, eric: }
    end
  end
  let(:eric) { data[:eric] }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[finance]))
  end

  def assign(kind, **attrs) = post(assignments_api_v1_pay_driver_path(eric, kind:), params: { assignment: attrs }, as: :json)

  it "pays on the default scheme and the bus type until assigned" do
    get api_v1_pay_drivers_path
    expect(json[:data].first).to include(name: "Eric Pang", vehicle: hash_including(plate: "PD1234A"),
                                         vehicle_type: { id: data[:van].id, name: "Van" },
                                         scheme_today: { id: data[:basic].id, name: "Basic + Trips" }, warning: nil)
  end

  it "keeps assignments from overlapping and checks dates" do
    assign("schemes", pay_scheme_id: data[:monthly].id, starts_on: "2026-09-01")
    expect(json.dig(:error, :details, :starts_on)).to eq([ "Starts on can go back up to 1 month, to 2 Oct 2026" ])

    assign("schemes", pay_scheme_id: data[:monthly].id, starts_on: "2026-10-15")
    assign("schemes", pay_scheme_id: data[:basic].id, starts_on: "2026-12-01")
    expect(json.dig(:data, :pay_schemes).map { |a| a.slice(:starts_on, :ends_on, :tag) })
      .to eq([ { starts_on: "2026-10-15", ends_on: "2026-11-30", tag: "current" }, { starts_on: "2026-12-01", ends_on: nil, tag: "upcoming" } ])
    expect(json[:data]).to include(scheme_today: { id: data[:monthly].id, name: "Monthly" })

    id = json.dig(:data, :pay_schemes, 0, :id)
    patch assignment_api_v1_pay_driver_path(eric, kind: "schemes", assignment_id: id), params: { assignment: { ends_on: "2026-10-01" } }, as: :json
    expect(json.dig(:error, :details, :ends_on)).to eq([ "Ends on is before the start date" ])

    assign("vehicle_types", vehicle_type_id: data[:coach].id, starts_on: "2026-11-02")
    expect(json[:data]).to include(vehicle_type: { id: data[:coach].id, name: "Coach" },
                                   warning: "Rate plan Standard of Monthly has no rates for Coach, so these jobs are paid S$0")
    expect(json.dig(:data, :vehicle_types, 0, :warning)).to start_with("Rate plan Standard")

    delete assignment_api_v1_pay_driver_path(eric, kind: "vehicle_types", assignment_id: json.dig(:data, :vehicle_types, 0, :id))
    expect(json.dig(:data, :vehicle_types)).to eq([])
  end
end
