require "rails_helper"

# School Bus › Year Setup › Payment & Refund Policy (versions by effective date, checks, a scheduled version replaced on
# publish) and Payment Methods (fees, the company's or the school's own account).
RSpec.describe "School Bus policy and payment methods" do
  let(:company) { create(:company) }
  let!(:school) { within_tenant(company) { School.create!(name: "St. Stephen's School") } }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[finance]))
  end

  it "publishes policy versions from a date and replaces one that has not started" do
    get api_v1_school_policy_path(school)
    draft = json.dig(:data, :draft)
    expect(draft).to include(due_rule: "before", due_days_before: 14, late_flat: 20, deposit_amount: 200, registration_fee: 50, effective_on: "2026-11-02")
    expect(draft[:reminders].map { |r| [ r[:timing], r[:days] ] }).to eq([ [ "before", 7 ], [ "on", 0 ], [ "after", 3 ] ])

    post api_v1_school_policy_path(school), params: draft.merge(effective_on: "2026-11-01"), as: :json
    expect(json.dig(:error, :message)).to eq("The effective date cannot be in the past")
    post api_v1_school_policy_path(school), params: draft.merge(due_rule: "day", due_day: 30), as: :json
    expect(json.dig(:error, :message)).to eq("Pick a due day from 1 to 28")
    bad = draft[:reminders].map(&:dup).tap { |r| r[2][:whatsapp_body] = "" }
    post api_v1_school_policy_path(school), params: draft.merge(reminders: bad), as: :json
    expect(json.dig(:error, :message)).to eq("3 days after due: pick a channel and fill in each message")

    post api_v1_school_policy_path(school), params: draft, as: :json
    expect(response).to have_http_status(:created)
    expect(json.dig(:data, :versions)).to match([ hash_including(version: 1, effective_on: "2026-11-02", state: "in_use") ])

    post api_v1_school_policy_path(school), params: draft.merge(effective_on: "2027-01-01", late_type: "pct", late_pct: 1.5), as: :json
    post api_v1_school_policy_path(school), params: draft.merge(effective_on: "2027-02-01", late_type: "none"), as: :json
    d = json[:data]
    expect(d[:versions].map { |v| [ v[:version], v[:effective_on], v[:state] ] }).to eq([ [ 2, "2027-02-01", "scheduled" ], [ 1, "2026-11-02", "in_use" ] ])
    expect(d[:draft]).to include(late_type: "none", effective_on: "2027-02-01")
  end

  it "saves payment methods against the company's or the school's own account" do
    get api_v1_school_payment_methods_path(school)
    expect(json[:data]).to include(saved: false, account_bank: nil, own_account: false)
    expect(json.dig(:data, :paynow)).to include(on: true, fee_kind: "none")

    put api_v1_school_payment_methods_path(school), params: { bank: { on: false }, paynow: { on: false }, card: { on: false } }, as: :json
    expect(json.dig(:error, :message)).to eq("Turn on at least one way to pay")
    put api_v1_school_payment_methods_path(school), params: { paynow: { on: true }, card: { on: true, fee_kind: "pct", fee: 12 } }, as: :json
    expect(json.dig(:error, :message)).to eq("The admin fee for Card looks too high: use a percentage up to 10")
    put api_v1_school_payment_methods_path(school), params: { paynow: { on: true } }, as: :json
    expect(json.dig(:error, :message)).to start_with("PayNow needs the company's PayNow UEN")

    put api_v1_school_payment_methods_path(school), params: { paynow: { on: true }, card: { on: true, fee_kind: "pct", fee: 3 }, own_account: true, paynow_id: "t08gb1234a" }, as: :json
    expect(json[:data]).to include(saved: true, own_account: true, paynow_id: "T08GB1234A")
    expect(json.dig(:data, :card)).to include(on: true, fee_kind: "pct", fee: "3.0")
    expect(json.dig(:data, :bank)).to include(on: false)
  end

  it "needs the finance permission to publish" do
    sign_in_as(create(:user, company:, permissions: %w[schools]))
    post api_v1_school_policy_path(school), params: { effective_on: "2026-11-02" }, as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
