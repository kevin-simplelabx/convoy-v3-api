require "rails_helper"

# Finance > Operator Payments: requests from runs on operator buses and manual items, approve into a batch by pay date,
# bank file with payment notices, payments.
RSpec.describe "Finance operator payments" do
  let(:company) { create(:company) }
  let(:approver) { create(:user, company:, name: "Marcus Lim", permissions: %w[finance]) }
  let!(:data) do
    within_tenant(company) do
      hup = create(:operator, name: "Hup Seng", paynow_uen: "199801234D", payment_method: "paynow")
      bus = create(:vehicle, plate: "PC7475L", operator: hup)
      trip = create(:trip, title: "Factory Shuttle", operator_cancel_rule: "done")
      occ = ->(day, **attrs) do
        date = Date.new(2026, 10, day)
        TripOccurrence.create!({ trip:, date:, start_time: 480, end_time: 540, starts_at: date.in_time_zone.change(hour: 8), ends_at: date.in_time_zone.change(hour: 9),
                                 kind: "ad_hoc", trip_label: "T-#{day}", vehicle: bus, operator: hup, operator_cost: 95, run_key: "k#{day}" }.merge(attrs))
      end
      { hup:, runs: [ occ.(6), occ.(7, operator_cost: nil), occ.(8, status: "cancelled", cancelled_at: Time.current) ] }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    within_tenant(company) { FinanceApprover.create!(user: approver, can_approve: true) }
    sign_in_as(approver)
  end

  def run_ref(occ) = "run:#{occ.id}:#{occ.date}"

  it "lists requests, sets a cost, approves into a batch, makes the bank file and records payments" do
    get api_v1_finance_operator_pay_requests_path
    group = json[:data].first
    expect(group).to include(operator: { id: data[:hup].id, name: "Hup Seng" }, pays_by: { method: "PayNow UEN", to: "199801234D", warn: false },
                             to_approve: "95.0", not_ready: 1)
    expect(group[:items].map { |i| [ i[:ref], i[:ready], i[:why] ] }).to eq([ [ run_ref(data[:runs][0]), true, nil ], [ run_ref(data[:runs][1]), false, "Set the cost" ] ])

    put api_v1_finance_operator_pay_costs_path, params: { ref: run_ref(data[:runs][1]), amount: 80 }, as: :json
    post api_v1_finance_operator_pay_items_path, params: { operator_id: data[:hup].id, description: "Late arrival", item_on: "2026-10-07", amount: 20, sign: "deduct" }, as: :json
    get api_v1_finance_operator_pay_requests_path
    expect(json.dig(:data, 0, :to_approve)).to eq("155.0")
    refs = json.dig(:data, 0, :items).pluck(:ref)

    post api_v1_finance_operator_pay_approve_path, params: { refs:, pay_date: "2026-11-01" }, as: :json
    expect(json.dig(:error, :message)).to eq("Pick today or a later pay date")
    post api_v1_finance_operator_pay_approve_path, params: { refs:, pay_date: "2026-11-10" }, as: :json
    expect(response).to have_http_status(:created)
    batch = json[:data]
    expect(batch).to include(number: "PB-2026-000001", status: "scheduled", total: "155.0", open: true)

    post api_v1_finance_operator_pay_batch_bank_file_path(batch[:id]), params: { transfer_type: "FAST" }, as: :json
    expect(json[:data]).to include(status: "sent_to_bank", filename: "PB-2026-000001.csv")
    expect(json.dig(:data, :operators, 0, :notice_number)).to eq("PN-2026-000001")
    expect(json.dig(:data, :csv).lines.second).to include("Hup Seng,PAYNOW", "UEN,199801234D,155.00,PN-2026-000001")

    bo = json.dig(:data, :operators, 0, :id)
    post api_v1_finance_operator_pay_batch_payments_path(batch[:id]), params: { batch_operator_id: bo, amount: 200, method: "PayNow" }, as: :json
    expect(json.dig(:error, :message)).to eq("Amount is more than the S$155.00 left to pay")
    post api_v1_finance_operator_pay_batch_mark_paid_path(batch[:id])
    expect(json[:data]).to include(status: "paid", paid: "155.0")

    get api_v1_finance_operator_pay_requests_path
    expect(json[:data]).to eq([])

    get api_v1_finance_documents_path, params: { type: "payment_notice" }
    expect(json[:data].first).to include(type: "payment_notice", number: "PN-2026-000001", to: "Hup Seng", amount: "155.0", status: "paid")
    expect(json[:meta][:counts]).to include(payment_notice: 1)
    get api_v1_finance_payment_notice_path(json.dig(:data, 0, :id))
    expect(json[:data]).to include(number: "PN-2026-000001", pays_by: { method: "PayNow UEN", to: "199801234D" }, left: "0.0")
    expect(json.dig(:data, :lines).size).to eq(3)
  end

  it "lets only approvers approve" do
    sign_in_as(create(:user, company:, permissions: %w[finance]))
    post api_v1_finance_operator_pay_approve_path, params: { refs: [ run_ref(data[:runs][0]) ], pay_date: "2026-11-10" }, as: :json
    expect(json.dig(:error, :message)).to eq("Only approvers in Finance Settings can approve requests, set pay dates and record payments")
  end
end
