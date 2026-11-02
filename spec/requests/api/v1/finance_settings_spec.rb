require "rails_helper"

# Finance > Finance Settings: GST, approvers and maker-checker, prefixes, lock; document numbers.
RSpec.describe "Finance settings" do
  let(:company) { create(:company) }
  let(:finset) { create(:user, company:, name: "Marcus Lim", permissions: %w[finance finset]) }
  let!(:other) { create(:user, company:, name: "Rachel Tan") }

  before { sign_in_as(finset) }

  def save(lock: false, **attrs) = patch(api_v1_finance_settings_path, params: { settings: attrs, lock: }, as: :json)

  it "saves GST, approvers and prefixes with the prototype's checks" do
    get api_v1_finance_settings_path
    expect(json[:data]).to include(gst_on: false, gst_rate: "9.0", approval: "single", prefix_inv: "INV", prefix_pb: "PB", locked: false)

    save(gst_on: true, gst_rate: 0)
    expect(json.dig(:error, :message)).to eq("Enter a GST rate between 0 and 100")
    save(prefix_cn: "inv")
    expect(json.dig(:error, :message)).to eq("Each document type needs its own prefix")
    save(gst_on: true)
    expect(json.dig(:error, :message)).to eq("Add at least one approver for operator pay runs")

    save(approval: "maker", approvers: [ { user_id: finset.id, can_approve: true } ])
    expect(json.dig(:error, :message)).to eq("Maker-checker needs at least two people: add a second approver or a preparer")
    save(gst_on: true, gst_reg_no: "M90012345A", approval: "maker", prefix_inv: "sd-inv!",
         approvers: [ { user_id: finset.id, can_approve: true }, { user_id: other.id, can_prepare: true, can_approve: false } ])
    expect(response).to have_http_status(:ok), json.inspect
    expect(json[:data]).to include(gst_on: true, approval: "maker", prefix_inv: "SDINV", maker_checker_warning: false)
    expect(json.dig(:data, :approvers).pluck(:name)).to contain_exactly("Marcus Lim", "Rachel Tan")

    expect(within_tenant(company) { [ Finance::Numbering.next!("inv", date: Date.new(2026, 11, 2)), Finance::Numbering.next!("inv", date: Date.new(2026, 12, 1)) ] })
      .to eq(%w[SDINV-2026-000001 SDINV-2026-000002])
    expect(FinanceSetting.split(100, on: true, rate: 9, mode: "incl")).to eq(sub: BigDecimal("91.74"), gst: BigDecimal("8.26"), total: 100)
  end

  it "locks, and only an Admin unlocks" do
    save(approvers: [ { user_id: finset.id, can_approve: true } ], lock: true)
    expect(json[:data]).to include(locked: true, locked_by: { id: finset.id, name: "Marcus Lim" })
    save(gst_on: true)
    expect(json.dig(:error, :message)).to eq("Finance Settings are locked. Unlock to change them")
    post unlock_api_v1_finance_settings_path
    expect(response).to have_http_status(:forbidden)

    sign_in_as(create(:user, :admin, company:))
    post unlock_api_v1_finance_settings_path
    expect(json[:data]).to include(locked: false)
  end

  it "needs the finset permission" do
    sign_in_as(create(:user, company:, permissions: %w[finance]))
    get api_v1_finance_settings_path
    expect(response).to have_http_status(:forbidden)
  end
end
