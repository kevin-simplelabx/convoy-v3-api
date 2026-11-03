require "rails_helper"

# School Bus › School Finance › Operator Payments: route pay per operator for a month (school days, a bus moving to
# another operator mid-month, a replacement we arranged), lines Ops adds (a file, a covered route paired with the other
# operator), Send to Finance, maker-checker approval, a payment with its Payment Voucher, Recall and Reopen.
RSpec.describe "School Bus finance payouts" do
  let(:company) { create(:company) }
  let(:ops) { create(:user, company:, permissions: %w[finance finview]) }
  let(:checker) { create(:user, company:, permissions: %w[finance finview]) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      a = create(:operator, name: "Alpha Bus")
      b = create(:operator, name: "Beta Coaches")
      va = create(:vehicle, plate: "PA1001A", operator: a)
      vb = create(:vehicle, plate: "PB2002B", operator: b)
      school.bus_size_rates.create!(bus_type: "MEDIUM_23", monthly: 4200)
      plan = school.plans.create!(name: "AM Plan", session: "am", effective_from: Date.new(2026, 11, 1))
      am1 = plan.routes.create!(number: 1, label: "AM 1", start_time: "07:00", end_time: "07:30", bus_type: "MEDIUM_23")
      am2 = plan.routes.create!(number: 2, label: "AM 2", start_time: "07:00", end_time: "07:30", bus_type: "MEDIUM_23")
      am1.vehicle_changes.create!(vehicle: va, effective_from: Date.new(2026, 11, 1))
      am2.vehicle_changes.create!(vehicle: vb, effective_from: Date.new(2026, 11, 1))
      am2.vehicle_changes.create!(vehicle: va, effective_from: Date.new(2026, 11, 16))
      am1.replacements.create!(vehicle: vb, starts_on: Date.new(2026, 11, 18), ends_on: Date.new(2026, 11, 19), arranged_by: "us", daily_rate: 150,
                               reason: "Aircon broke")
      { school:, a:, b: }
    end
  end
  let(:school) { f[:school] }

  def at(time, user = ops)
    travel_to time
    sign_in_as(user)
  end

  def board = get(api_v1_school_payouts_path(school), params: { month: "2026-11" }).then { json[:data] }
  def row(data, name) = data[:rows].find { it[:name] == name }
  def path(name, op = f[:a]) = public_send(:"#{name}_api_v1_school_payout_path", school, op.id)

  it "works out route pay per operator, takes lines, goes through maker-checker and is paid with a voucher" do
    at Time.zone.local(2026, 12, 2, 9, 0)
    d = board
    a = row(d, "Alpha Bus")
    expect(a).to include(status: "To Check", routes_count: 2, base: "6400.0", deductions: "300.0", net: "6100.0", payable: true)
    expect(a[:routes].map { [ it[:route], it[:days], it[:of], it[:amount], it[:note] ] }).to eq([ [ "AM 1", 21, 21, "4200.0", nil ],
                                                                                                [ "AM 2", 11, 21, "2200.0", "Took over from Beta Coaches on 16/11/2026" ] ])
    expect(a[:lines].sole).to include(kind: "Replacement bus we arranged", amount: "300.0", auto: true, reason: "PB2002B (Beta Coaches), 2 days at S$150.00/day. Aircon broke")
    b = row(d, "Beta Coaches")
    expect(b).to include(base: "2000.0", additions: "300.0", net: "2300.0")
    expect(d[:kpis]).to eq(net_payable: "8400.0", paid: "0.0", still_to_pay: "8400.0", operators_to_pay: 2)
    expect(d[:rights]).to include(prepare: true, approve: false, set_up: false)

    # A taxi claim with its receipt, and Beta covering a route for Alpha (added to Beta, deducted from Alpha)
    post path(:lines), params: { month: "2026-11", kind: "Taxi claim", adj_on: "2026-11-20", route: "AM 1", amount: 45, reason: "Bus no-show",
                                 files: [ fixture_file_upload("sample.pdf", "application/pdf") ] }
    expect(response).to have_http_status(:created)
    post path(:lines, f[:b]), params: { month: "2026-11", kind: "Covered another route", adj_on: "2026-11-25", route: "AM 2", amount: 100,
                                        reason: "Alpha short of drivers", paired_operator_id: f[:a].id }
    a = row(json[:data], "Alpha Bus")
    expect(a[:lines].map { [ it[:kind], it[:sign], it[:amount] ] }).to include([ "Taxi claim", -1, "45.0" ], [ "Route covered by Beta Coaches", -1, "100.0" ])
    expect(a[:lines].find { it[:kind] == "Taxi claim" }[:files].sole).to include(name: "sample.pdf", url: start_with("/api/v1/downloads/"))
    expect(a).to include(net: "5955.0")
    expect(row(json[:data], "Beta Coaches")).to include(net: "2400.0")
    patch api_v1_school_payout_path(school, f[:a].id), params: { month: "2026-11", invoice_number: "ALP-1125" }, as: :json
    expect(row(json[:data], "Alpha Bus")[:invoice_number]).to eq("ALP-1125")

    # Send to Finance: no approver yet; then maker-checker stops the sender approving their own
    post path(:send_to_finance), params: { month: "2026-11" }, as: :json
    expect(row(json[:data], "Alpha Bus")).to include(status: "With Finance", can: hash_including(edit: false, recall: true, approve: false, need_other: true))
    post path(:approve), params: { month: "2026-11" }, as: :json
    expect(json.dig(:error, :message)).to eq("Add approvers in Finance Settings first")
    within_tenant(company) do
      FinanceSetting.current.update!(approval: "maker")
      FinanceApprover.create!(company:, user: ops, can_prepare: true, can_approve: true)
      FinanceApprover.create!(company:, user: checker, can_prepare: true, can_approve: true)
    end
    post path(:approve), params: { month: "2026-11" }, as: :json
    expect(json.dig(:error, :message)).to eq("Maker-checker is on. Another approver must check what you sent")
    post path(:lines), params: { month: "2026-11", kind: "Damage", adj_on: "2026-11-26", amount: 10, reason: "x" }
    expect(json.dig(:error, :message)).to eq("This pay run is with Finance or approved. Recall or reopen it first")

    at Time.zone.local(2026, 12, 3, 9, 0), checker
    post path(:approve), params: { month: "2026-11" }, as: :json
    a = row(json[:data], "Alpha Bus")
    expect(a).to include(status: "Approved", base: "6400.0", net: "5955.0", can: hash_including(pay: true, reopen: true))
    expect(a[:history].map { it[:text] }).to eq([ "Approved for S$6400.00", "Sent to Finance" ])
    post path(:payments), params: { month: "2026-11", paid_on: "2026-12-03", amount: 6000, method: "Bank Transfer" }, as: :json
    expect(json.dig(:error, :message)).to eq("Amount is more than the S$5955.00 left to pay")
    post path(:payments), params: { month: "2026-11", paid_on: "2026-12-03", amount: 5000, method: "Bank Transfer", reference: "FAST 1" }, as: :json
    a = row(json[:data], "Alpha Bus")
    expect(a).to include(status: "Part Paid", paid: "5000.0", balance: "955.0", voucher: { number: "PV-2026-000001", on: "2026-12-03" })
    post path(:reopen), params: { month: "2026-11" }, as: :json
    expect(json.dig(:error, :message)).to eq("Only an approved pay run with no payment can be reopened")

    get api_v1_school_payout_voucher_path(a[:id])
    expect(json[:data]).to include(number: "PV-2026-000001", invoice_number: "ALP-1125", net: "5955.0", pay_to: hash_including(name: "Alpha Bus"))
    expect(json[:data][:lines].map { it[:details] }).to eq([ "Route pay, 2 routes", "Replacement bus we arranged | AM 1 | PB2002B (Beta Coaches), 2 days at S$150.00/day. Aircon broke",
                                                             "Taxi claim | AM 1 | Bus no-show", "Route covered by Beta Coaches | AM 2 | Alpha short of drivers" ])

    # Beta: sent by Ops, recalled, sent again and sent back by the checker
    at Time.zone.local(2026, 12, 3, 10, 0)
    post path(:send_to_finance, f[:b]), params: { month: "2026-11" }, as: :json
    post path(:recall, f[:b]), params: { month: "2026-11" }, as: :json
    expect(row(json[:data], "Beta Coaches")).to include(status: "To Check", can: hash_including(edit: true, send: true))
    post path(:send_to_finance, f[:b]), params: { month: "2026-11" }, as: :json
    at Time.zone.local(2026, 12, 3, 11, 0), checker
    post path(:send_back, f[:b]), params: { month: "2026-11" }, as: :json
    b = row(json[:data], "Beta Coaches")
    expect(b).to include(status: "To Check", base: "2000.0")
    expect(b[:history].first).to include(text: "Sent back to Ops", by: checker.name)

    # Approved pay runs reach Finance › Operator Payments; once batched they are paid there
    due = within_tenant(company) { OperatorPay::Due.call.select { it.source == "school" } }
    expect(due.map { [ it.operator.name, it.amount, it.ready, it.why ] }).to contain_exactly([ "Alpha Bus", 955, true, nil ],
                                                                                            [ "Beta Coaches", nil, false, "Not sent to Finance" ])
    within_tenant(company) { OperatorPay::Batches.new(user: checker).approve!(refs: [ "school_payout:#{a[:id]}" ], pay_date: Date.new(2026, 12, 10)) }
    a = row(board, "Alpha Bus")
    expect(a).to include(batch: hash_including(pay_date: "2026-12-10"), paid: "5000.0", can: hash_including(pay: false, reopen: false))

    get api_v1_finance_school_collections_path
    expect(json[:meta][:schools].pluck(:name)).to eq([ "St. Stephen's School" ])
    get api_v1_finance_documents_path, params: { type: "payment_voucher" }
    expect(json[:data].sole).to include(number: "PV-2026-000001", to: "Alpha Bus", school: "St. Stephen's School", amount: "5000.0")
  end
end
