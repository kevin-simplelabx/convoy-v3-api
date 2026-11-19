require "rails_helper"

# Finance > Operator Payments > Batches: Download Again (the bank file CSV), only once the bank file was made.
RSpec.describe "Finance operator bank file download" do
  let(:company) { create(:company) }
  let(:approver) { create(:user, company:, permissions: %w[finance]) }
  let(:batch_id) do
    within_tenant(company) do
      FinanceApprover.create!(user: approver, can_approve: true)
      hup = create(:operator, name: "Hup Seng", paynow_uen: "199801234D", payment_method: "paynow", email: "pay@hupseng.sg")
      OperatorPayItem.create!(operator: hup, description: "Extra trips", item_on: Date.new(2026, 10, 7), amount: 155.5, created_by: approver)
      OperatorPay::Batches.new(user: approver).approve!(refs: [ "item:#{OperatorPayItem.last.id}" ], pay_date: Date.new(2026, 11, 10)).id
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    batch_id
    sign_in_as(approver)
  end

  def download = get(api_v1_finance_operator_pay_batch_bank_file_csv_path(batch_id))

  it "is refused before the bank file is made, then gives the same CSV as when it was made" do
    download
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Make the bank file first")

    post api_v1_finance_operator_pay_batch_bank_file_path(batch_id), params: { transfer_type: "FAST" }, as: :json
    made = json.dig(:data, :csv)

    download
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Content-Disposition"]).to include('attachment; filename="PB-2026-000001.csv"')
    expect(response.body).to eq(made)
    expect(response.body.lines.size).to eq(2)
    expect(response.body.lines.second.chomp).to eq("2026-11-10,Hup Seng,PayNow,,,,,,UEN,199801234D,155.50,PN-2026-000001,pay@hupseng.sg")
  end

  it "needs Finance access and keeps other companies out" do
    sign_in_as(create(:user, company:, permissions: %w[vehicles]))
    download
    expect(response).to have_http_status(:forbidden)

    sign_in_as(create(:user, company: create(:company), permissions: %w[finance]))
    download
    expect(response).to have_http_status(:not_found)
  end
end
