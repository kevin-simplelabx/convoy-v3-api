require "rails_helper"

# School Bus › School Finance › Operator Payments: Remove a line (net back, the paired deduction too, refused once
# with Finance) and Reopen an approved pay run (back to To Check with live route pay; refused once paid or batched).
RSpec.describe "School Bus finance payout steps" do
  let(:company) { create(:company) }
  let(:ops) { create(:user, company:, permissions: %w[finance finview]) }
  let(:viewer) { create(:user, company:, permissions: %w[finview]) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      a = create(:operator, name: "Alpha Bus")
      b = create(:operator, name: "Beta Coaches")
      school.bus_size_rates.create!(bus_type: "MEDIUM_23", monthly: 4200)
      plan = school.plans.create!(name: "AM Plan", session: "am", effective_from: Date.new(2026, 11, 1))
      { a: 1, b: 2 }.each do |key, n|
        route = plan.routes.create!(number: n, label: "AM #{n}", start_time: "07:00", end_time: "07:30", bus_type: "MEDIUM_23")
        route.vehicle_changes.create!(vehicle: create(:vehicle, plate: "P#{n}00#{n}A", operator: key == :a ? a : b), effective_from: Date.new(2026, 11, 1))
      end
      { school:, a:, b: }
    end
  end
  let(:school) { f[:school] }

  before do
    travel_to Time.zone.local(2026, 12, 2, 9, 0)
    sign_in_as(ops)
  end

  def board = get(api_v1_school_payouts_path(school), params: { month: "2026-11" }).then { json[:data] }
  def row(name, data = board) = data[:rows].find { it[:name] == name }
  def path(name, op = f[:a]) = public_send(:"#{name}_api_v1_school_payout_path", school, op.id)
  def line_path(id, op = f[:a]) = line_api_v1_school_payout_path(school, op.id, id, month: "2026-11")
  def step(name, op = f[:a]) = post(path(name, op), params: { month: "2026-11" }, as: :json)
  def totals(r) = r.slice(:status, :base, :additions, :deductions, :net)

  def add_line(op = f[:a], **attrs)
    post path(:lines, op), params: { month: "2026-11", kind: "Taxi claim", adj_on: "2026-11-20", route: "AM 1", amount: 45.5, reason: "Bus no-show" }.merge(attrs)
    expect(response).to have_http_status(:created), json.inspect
    row(op.name, json[:data])[:lines].reject { it[:auto] }.last[:id]
  end

  def approvers!
    within_tenant(company) { FinanceApprover.create!(company:, user: ops, can_prepare: true, can_approve: true) }
  end

  describe "remove_line" do
    it "removes a line and works the net out again" do
      expect(totals(row("Alpha Bus"))).to eq(status: "To Check", base: "4200.0", additions: "0.0", deductions: "0.0", net: "4200.0")
      id = add_line
      expect(totals(row("Alpha Bus"))).to include(deductions: "45.5", net: "4154.5")

      delete line_path(id)
      expect(response).to have_http_status(:ok)
      expect(totals(row("Alpha Bus", json[:data]))).to eq(status: "To Check", base: "4200.0", additions: "0.0", deductions: "0.0", net: "4200.0")
      expect(row("Alpha Bus", json[:data])[:lines]).to be_empty
      expect(within_tenant(company) { SchoolPayoutAdjustment.exists?(id) }).to be(false)
    end

    it "removes the matching deduction of a covered route with it" do
      id = add_line(f[:b], kind: "Covered another route", route: "AM 1", amount: 100, reason: "Alpha short of drivers", paired_operator_id: f[:a].id)
      d = board
      expect(totals(row("Alpha Bus", d))).to include(deductions: "100.0", net: "4100.0")
      expect(totals(row("Beta Coaches", d))).to include(additions: "100.0", net: "4300.0")

      delete line_path(id, f[:b])
      expect(response).to have_http_status(:ok)
      expect(totals(row("Beta Coaches", json[:data]))).to include(additions: "0.0", net: "4200.0")
      expect(totals(row("Alpha Bus", json[:data]))).to include(deductions: "0.0", net: "4200.0")
    end

    it "removes both sides from the deduction's side too" do
      add_line(f[:b], kind: "Covered another route", route: "AM 1", amount: 100, reason: "Alpha short of drivers", paired_operator_id: f[:a].id)
      deduction = row("Alpha Bus")[:lines].reject { it[:auto] }.sole[:id]

      delete line_path(deduction, f[:a])
      expect(response).to have_http_status(:ok)
      expect(totals(row("Beta Coaches", json[:data]))).to include(additions: "0.0", net: "4200.0")
      expect(totals(row("Alpha Bus", json[:data]))).to include(deductions: "0.0", net: "4200.0")
    end

    it "is refused while the other operator's matching line is with Finance, and nothing changes" do
      id = add_line(f[:b], kind: "Covered another route", route: "AM 1", amount: 100, reason: "Alpha short of drivers", paired_operator_id: f[:a].id)
      step(:send_to_finance, f[:a])
      expect(response).to have_http_status(:ok), json.inspect

      delete line_path(id, f[:b])
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Alpha Bus is already with Finance or approved. Recall or reopen it first to remove the matching line")
      expect(totals(row("Beta Coaches"))).to include(additions: "100.0", net: "4300.0")
      expect(totals(row("Alpha Bus"))).to include(status: "With Finance", deductions: "100.0")

      step(:recall, f[:a])
      delete line_path(id, f[:b])
      expect(response).to have_http_status(:ok)
      expect(totals(row("Alpha Bus", json[:data]))).to include(deductions: "0.0")
    end

    it "is refused once the pay run is with Finance, and works again after Recall" do
      id = add_line
      step(:send_to_finance)
      expect(totals(row("Alpha Bus", json[:data]))).to eq(status: "With Finance", base: "4200.0", additions: "0.0", deductions: "45.5", net: "4154.5")

      delete line_path(id)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("This pay run is with Finance or approved. Recall or reopen it first")
      expect(totals(row("Alpha Bus"))).to include(net: "4154.5")

      step(:recall)
      delete line_path(id)
      expect(totals(row("Alpha Bus", json[:data]))).to eq(status: "To Check", base: "4200.0", additions: "0.0", deductions: "0.0", net: "4200.0")
    end

    it "needs Finance, finds only the operator's own lines and keeps other companies out" do
      id = add_line
      delete line_path(id, f[:b])
      expect(response).to have_http_status(:not_found)

      sign_in_as(viewer)
      delete line_path(id)
      expect(response).to have_http_status(:forbidden)

      sign_in_as(create(:user, company: create(:company), permissions: %w[finance finview]))
      delete line_path(id)
      expect(response).to have_http_status(:not_found)
      expect(within_tenant(company) { SchoolPayoutAdjustment.exists?(id) }).to be(true)
    end
  end

  describe "reopen" do
    before { approvers! }

    it "takes an approved pay run with no payment back to To Check" do
      add_line
      step(:send_to_finance)
      step(:approve)
      a = row("Alpha Bus", json[:data])
      expect(totals(a)).to eq(status: "Approved", base: "4200.0", additions: "0.0", deductions: "45.5", net: "4154.5")
      expect(a[:history].map { it[:text] }).to eq([ "Approved for S$4154.50", "Sent to Finance" ])

      step(:reopen)
      expect(response).to have_http_status(:ok)
      a = row("Alpha Bus", json[:data])
      expect(totals(a)).to eq(status: "To Check", base: "4200.0", additions: "0.0", deductions: "45.5", net: "4154.5")
      expect(a[:history]).to eq([])
      expect(a[:can]).to include(edit: true, send: true, reopen: false)
      payout = within_tenant(company) { SchoolPayout.find_by!(operator: f[:a]) }
      expect(payout.slice(:status, :base, :approved_by_id, :sent_by_id)).to eq("status" => "draft", "base" => nil, "approved_by_id" => nil, "sent_by_id" => nil)
      expect(payout.audits.last.audited_changes["status"]).to eq(%w[approved draft])
    end

    it "is refused for an open pay run, one with a payment, one in a batch, and by a preparer who cannot approve" do
      step(:reopen)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Only an approved pay run with no payment can be reopened")

      step(:send_to_finance)
      step(:approve)
      within_tenant(company) { OperatorPay::Batches.new(user: ops).approve!(refs: [ "school_payout:#{SchoolPayout.find_by!(operator: f[:a]).id}" ], pay_date: Date.new(2026, 12, 10)) }
      step(:reopen)
      expect(json.dig(:error, :message)).to eq("This pay run is in an Operator Payments batch")

      step(:send_to_finance, f[:b])
      step(:approve, f[:b])
      post path(:payments, f[:b]), params: { month: "2026-11", paid_on: "2026-12-02", amount: 1000, method: "Bank Transfer" }, as: :json
      step(:reopen, f[:b])
      expect(json.dig(:error, :message)).to eq("Only an approved pay run with no payment can be reopened")
      expect(row("Beta Coaches")).to include(status: "Part Paid", net: "4200.0", paid: "1000.0", balance: "3200.0")

      preparer = create(:user, company:, permissions: %w[finance finview])
      within_tenant(company) { FinanceApprover.create!(company:, user: preparer, can_prepare: true, can_approve: false) }
      sign_in_as(preparer)
      step(:reopen)
      expect(json.dig(:error, :message)).to eq("Only an approver can reopen a pay run")
    end

    it "needs Finance and keeps other companies out" do
      step(:send_to_finance)
      step(:approve)

      sign_in_as(viewer)
      step(:reopen)
      expect(response).to have_http_status(:forbidden)

      sign_in_as(create(:user, company: create(:company), permissions: %w[finance finview]))
      step(:reopen)
      expect(response).to have_http_status(:not_found)
      expect(within_tenant(company) { SchoolPayout.find_by!(operator: f[:a]).status }).to eq("approved")
    end
  end
end
