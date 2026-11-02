require "rails_helper"

# HR > Salary Simulator: a made-up month, the sample month, shared templates.
RSpec.describe "HR salary simulator" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      van = create(:vehicle_type, name: "Van", seats: 13)
      plan = PayRatePlan.create!(name: "Flat")
      period = plan.periods.create!(name: "All Day", days: PayRatePeriod::DAYS)
      period.ranges.create!(start_time: "00:00", end_time: "23:59")
      period.rates.create!(vehicle_type: van, per_trip: 14, per_hour: 10)
      PublicHoliday.create!(date: Date.new(2026, 11, 9), name: "Deepavali")
      { van:, scheme: PayScheme.create!(name: "Basic", rate_plan: plan, basic_salary: 500, school_routes_pay: true).tap { |s| s.route_bands.create!(up_to_minutes: nil, monthly_amount: 300) } }
    end
  end

  before { sign_in_as(create(:user, company:, permissions: %w[finview])) }

  it "works out a month with a school route retainer" do
    post api_v1_pay_simulate_path, params: { scheme_id: data[:scheme].id, vehicle_type_id: data[:van].id, month: "2026-11",
                                             jobs: { "2026-11-03" => [ { type: "trip", start_time: "07:00", tv: 1 }, { type: "disposal", start_time: "17:00", end_time: "19:00" } ] },
                                             routes: [ { name: "AM1", minutes: 45, start_time: "06:30" } ] }, as: :json
    expect(response).to have_http_status(:ok), json.inspect
    expect(json[:data]).to include(total: "834.0")
    expect(json.dig(:data, :parts, 0, :rows).map { |r| r[:label] }).to include("School Route Pay")
    expect(json.dig(:data, :days, :"2026-11-09")).to include(holiday: "Deepavali", lines: [])
    expect(json.dig(:data, :days, :"2026-11-03", :lines).map { |l| l[:time] }).to eq([ "Routes", "07:00", "17:00 to 19:00" ])
  end

  it "fills a sample month and keeps templates" do
    get api_v1_pay_simulate_sample_path, params: { month: "2026-11" }
    expect(json.dig(:data, :jobs, :"2026-11-02").size).to eq(6)
    expect(json.dig(:data, :jobs, :"2026-11-09").size).to eq(2) # Deepavali Monday

    put api_v1_pay_simulator_template_path(2), params: { template: { name: "", month: "2026-11" } }, as: :json
    expect(json.dig(:error, :details, :name)).to eq([ "Name can't be blank" ])
    put api_v1_pay_simulator_template_path(2), params: { template: { name: "PH week", month: "2026-11", pay_scheme_id: data[:scheme].id,
                                                                     jobs: { "2026-11-09" => [ { type: "trip", start_time: "07:00" } ] } } }, as: :json
    get api_v1_pay_simulator_templates_path
    expect(json[:data].pluck(:slot)).to eq([ 1, 2, 3, 4, 5 ])
    expect(json.dig(:data, 1, :template)).to include(name: "PH week", month: "2026-11", days_with_jobs: 1)
  end
end
