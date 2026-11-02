require "rails_helper"

# HR > Pay Schemes: save the whole scheme with its bands and tiers, the default, lock and delete rules.
RSpec.describe "HR pay schemes" do
  let(:company) { create(:company) }
  let!(:plan) { within_tenant(company) { PayRatePlan.create!(name: "Standard") } }

  before { sign_in_as(create(:user, company:, permissions: %w[finance])) }

  def save(id: nil, lock: false, **attrs)
    body = { scheme: { name: "Basic + Trips", scheme_type: "basic_plus_trips", pay_rate_plan_id: plan.id }.merge(attrs), lock: }
    id ? patch(api_v1_pay_scheme_path(id), params: body, as: :json) : post(api_v1_pay_schemes_path, params: body, as: :json)
  end

  it "saves a scheme with bands and tiers, and keeps one default" do
    save(pay_rate_plan_id: nil)
    expect(json.dig(:error, :details, :rate_plan)).to eq([ "Rate plan must be picked" ])

    save(basic_salary: 500, basic_covers_daily_trips: true, basic_covered_daily_trips: 1, has_guarantee: true, guaranteed_amount: 2200,
         on_top_ph: true, shift_working_days: %w[mon sat xx], shift_start_time: "07:30",
         route_bands: [ { up_to_minutes: "", monthly_amount: 350 }, { up_to_minutes: 40, monthly_amount: 200 } ],
         volume_tiers: [ { from_trip: 7, to_trip: 10, boost_type: "flat", boost_value: 2 }, { from_trip: 11, boost_type: "percentage", boost_value: 10 } ],
         weekly_tiers: [ { target_trips: 20, pay_as: "lump_sum", amount: 50 } ], monthly_tiers: [ { target_trips: 100, pay_as: "per_trip", amount: 1 } ])
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(is_default: true, type_label: "Basic + Trips", basic_salary: "500.0", shift_working_days: %w[mon sat],
                                   shift_start_time: "07:30", rate_plan: { id: plan.id, name: "Standard" },
                                   route_bands: [ { up_to_minutes: 40, monthly_amount: "200.0" }, { up_to_minutes: nil, monthly_amount: "350.0" } ],
                                   weekly_tiers: [ { target_trips: 20, pay_as: "lump_sum", amount: "50.0" } ])
    expect(json.dig(:data, :volume_tiers).last).to include(from_trip: 11, to_trip: nil, boost_type: "percentage")
    first = json.dig(:data, :id)

    save(name: "Monthly", scheme_type: "monthly_with_minimum", is_default: true)
    second = json.dig(:data, :id)
    get api_v1_pay_schemes_path
    expect(json[:data].to_h { |s| [ s[:id], s[:is_default] ] }).to eq(first => false, second => true)

    delete api_v1_pay_scheme_path(second)
    expect(json.dig(:error, :message)).to eq("Make another scheme the default first")
    delete api_v1_pay_scheme_path(first)
    expect(response).to have_http_status(:no_content)
    delete api_v1_pay_scheme_path(second)
    expect(json.dig(:error, :message)).to eq("Keep at least one pay scheme")

    delete api_v1_pay_rate_plan_path(plan)
    expect(json.dig(:error, :message)).to eq("Used by Monthly. Pick another rate plan there first")
  end

  it "refuses to save a locked scheme" do
    save(lock: true)
    save(id: json.dig(:data, :id), basic_salary: 1)
    expect(json.dig(:error, :message)).to eq("Basic + Trips is locked. Ask an Admin to unlock it")
  end
end
