require "rails_helper"

# School Bus › School Finance › Collections: Convoy drafts the family bills of the coming period on its draft day (fare
# by tier and sessions, a joiner prorated, riders with no family left out), Finance issues them (INV + GST), a credit
# note carried to the next bill, late fees past due and grace, a waiver, payments with receipts, a debit note, the
# billing differences after a rider leaves, and the CSV.
RSpec.describe "School Bus finance bills" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, permissions: %w[finance finview]) }
  let!(:f) do
    within_tenant(company) do
      FinanceSetting.current.update!(gst_on: true, gst_rate: 9, gst_mode: "excl")
      school = School.create!(name: "St. Stephen's School", lat: 1.3138, lng: 103.9283)
      year = AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
      year.terms.first.update!(starts_on: "2027-01-04", ends_on: "2027-05-28")
      year.terms.second.update!(starts_on: "2027-06-28", ends_on: "2027-11-19")
      SchoolSetup.lock!(school:, year:, section: :calendar, user:)
      FareTables::Save.call(year, { payer: "parents", basis: "distance", trip: "both", cycle: "period", distribution: "equal",
                                    one_way: { type: "pct", value: 60 }, tiers: [ { max_km: 3, fare: 1680 }, { max_km: 6, fare: 1920 }, { fare: 2400 } ],
                                    small: { on: false }, express: { on: false }, cca: { on: false } }, user:)
      SchoolSetup.lock!(school:, year:, section: :fares, user:)
      Policies::Publish.call(school, Policies.default.merge(effective_on: Date.current), user:)
      mk = ->(rid, name, lat, starts = nil) { school.riders.create!(rid:, name:, lat:, lng: 103.93, postal: "460101", starts_on: starts, source: "manual") }
      riders = [ mk.("R1", "Lim Kai", 1.33), mk.("R2", "Lim Mei", 1.33), mk.("R3", "Tan Ryan", 1.36, Date.new(2027, 3, 1)), mk.("R4", "Ong Wei", 1.33) ]
      routes = %w[am pm].map do |se|
        plan = school.plans.create!(name: "#{se.upcase} Plan", session: se, effective_from: Date.new(2026, 12, 1))
        route = plan.routes.create!(number: 1, label: "#{se.upcase} 1", start_time: "07:00", end_time: "07:30", seats: 40)
        stop = route.stops.create!(position: 0, name: "Blk 101", scheduled_time: "07:00", lat: 1.33, lng: 103.93)
        riders.each { |r| SchoolRouteRider.create!(school_route: route, stop:, rid: r.rid) unless se == "pm" && r.rid == "R2" }
        route
      end
      lim = school.families.create!(code: "F001", name: "Lim Family")
      lim.guardians.create!(first_name: "Mei Ling", last_name: "Lim", relationship: "Mother", email: "meiling@mail.sg")
      tan = school.families.create!(code: "F002", name: "Tan Family")
      [ [ lim, "R1" ], [ lim, "R2" ], [ tan, "R3" ] ].each { |fam, rid| FamilyRider.create!(family: fam, school:, rid:) }
      { school:, year:, lim:, tan:, routes: }
    end
  end
  let(:school) { f[:school] }
  let(:year) { f[:year] }


  def board(**params) = get(api_v1_school_bill_runs_path(school), params: { academic_year_id: year.id, **params }).then { json[:data] }
  def at(time)
    travel_to time
    sign_in_as(user)
  end

  def bill(id) = get(api_v1_school_bill_path(id)).then { json[:data] }

  it "drafts on the draft day, issues with GST, carries a credit, charges late fees and records payments" do
    at Time.zone.local(2026, 12, 10, 9, 0)
    b = board
    expect(b).to include(payer: "family", period_index: 0, due_on: "2026-12-21", draft_on: "2026-12-14", run: nil, rows: [])
    expect(b[:periods].pluck(:label)).to eq([ "Semester 1 | billed Jan 2027", "Semester 2 | billed Jun 2027" ])
    expect(within_tenant(company) { SchoolBills::Auto.call }).to eq([])

    # On the draft day the daily job drafts: the Lims pay 2-way + AM only, Ryan joins in March, Ong Wei has no family
    at Time.zone.local(2026, 12, 14, 1, 0)
    expect(within_tenant(company) { SchoolBills::Auto.call }.size).to eq(1)
    b = board
    expect(b[:run]).to include(by: "Convoy", auto: true, unlinked: 1, label: "Semester 1 | Jan 2027")
    expect(b[:rows].map { [ it[:bill_to], it[:status], it[:amount] ] }).to contain_exactly([ "Lim Family", "draft", "1344.0" ], [ "Tan Family", "draft", anything ])
    lim = b[:rows].find { it[:bill_to] == "Lim Family" }
    expect(lim[:lines].pluck(:description)).to eq([ "Lim Kai | 0 to 3 km | 2-way", "Lim Mei | 0 to 3 km | AM only" ])
    tan = b[:rows].find { it[:bill_to] == "Tan Family" }
    expect(tan[:lines].first[:note]).to match(/\AJoins 01\/03\/2027, \d+ of \d+ school days\z/)
    expect(tan[:amount].to_d).to be_between(1, 1007)

    # Issue the Lims' bill only: INV number, 9% GST on top
    post api_v1_school_issue_bill_runs_path(school), params: { academic_year_id: year.id, period_index: 0, bill_ids: [ lim[:id] ] }, as: :json
    expect(json[:meta]).to eq(issued: 1)
    issued = bill(lim[:id])
    expect(issued).to include(number: "INV-2026-000001", subtotal: "1344.0", total: "1464.96", status: "Due", owed: "1464.96", due_on: "2026-12-21",
                              bill_to_email: "meiling@mail.sg")

    # Draft Again keeps the issued bill
    post api_v1_school_bill_runs_path(school), params: { academic_year_id: year.id, period_index: 0 }, as: :json
    expect(json[:meta]).to eq(drafted: 1)
    expect(json.dig(:data, :rows).map { [ it[:bill_to], it[:status] ] }).to eq([ [ "Tan Family", "draft" ], [ "Lim Family", "issued" ] ])

    # A credit of S$50 (+GST) carried to the Lims' next bill
    post notes_api_v1_school_bill_path(lim[:id]), params: { doc_type: "cn", description: "Bus late twice", amount: 50, reason: "Service recovery", credit_use: "carry" }, as: :json
    expect(json[:meta]).to eq(number: "CN-2026-000001")
    expect(json[:data]).to include(owed: "1464.96", credited: "0.0")

    # Past due + 7 days grace: S$20 late fee; S$10 waived; part paid; then Mark Paid pays the rest
    at Time.zone.local(2027, 1, 5, 9, 0)
    expect(bill(lim[:id])).to include(status: "Overdue", late_fee: "20.0", owed: "1484.96", days_overdue: 8)
    post waive_late_api_v1_school_bill_path(lim[:id]), params: { amount: 30, reason: "First time" }, as: :json
    expect(json.dig(:error, :message)).to eq("You can waive up to S$20.00")
    post waive_late_api_v1_school_bill_path(lim[:id]), params: { amount: 10, reason: "First time" }, as: :json
    expect(json[:data]).to include(late_fee: "10.0", owed: "1474.96")
    post payments_api_v1_school_bill_path(lim[:id]), params: { paid_on: "2027-01-05", amount: 474.96, method: "PayNow", reference: "PN123" }, as: :json
    expect(json[:meta]).to eq(receipt: "RCP-2027-000001")
    expect(json[:data]).to include(status: "Part Paid", paid: "474.96", owed: "1000.0")
    get api_v1_school_bills_path(school), params: { status: "Overdue" }
    expect(json[:data].pluck(:number)).to eq([ "INV-2026-000001" ])
    expect(json.dig(:meta, :kpis)).to include(billed: "1464.96", collected: "474.96", outstanding: "1000.0", overdue: "1000.0", credited: "10.0")
    post pay_api_v1_school_bills_path(school), params: { bill_ids: [ lim[:id] ], paid_on: "2027-01-06", method: "Bank Transfer" }, as: :json
    expect(json[:data]).to eq(receipt: "RCP-2027-000002", bills: 1, amount: "1000.0")
    expect(bill(lim[:id])).to include(status: "Paid", owed: "0.0")
    expect(bill(lim[:id])[:history].map { [ it[:kind], it[:amount] ] }).to include([ "payment", "1000.0" ], [ "payment", "474.96" ], [ "waiver", "10.0" ], [ "cn", "54.5" ])

    # Semester 2: the carried credit comes off the Lims' next bill
    post api_v1_school_bill_runs_path(school), params: { academic_year_id: year.id, period_index: 1 }, as: :json
    nxt = json.dig(:data, :rows).find { it[:bill_to] == "Lim Family" }
    post api_v1_school_issue_bill_runs_path(school), params: { academic_year_id: year.id, period_index: 1, bill_ids: [ nxt[:id] ] }, as: :json
    expect(bill(nxt[:id])).to include(number: "INV-2027-000001", subtotal: "1344.0", total: "1410.46")
    expect(bill(nxt[:id])[:lines].last).to include(description: "Credit from CN-2026-000001", amount: "-54.5", credit_note: true)

    # Lim Mei leaves the AM plan: both bills are now S$504 too much (semester 1 already has the S$50 credit); a debit note
    within_tenant(company) { SchoolRouteRider.where(rid: "R2").delete_all }
    get differences_api_v1_school_bills_path(school), params: { academic_year_id: year.id }
    expect(json[:data].map { [ it[:number], it[:was], it[:now], it[:gap] ] }).to eq([ [ "INV-2026-000001", "1294.0", "840.0", "-454.0" ],
                                                                                   [ "INV-2027-000001", "1344.0", "840.0", "-504.0" ] ])
    expect(json[:data].first[:suggest]).to include(doc_type: "cn", description: "Fare change: 1 rider now", amount: "454.0")
    post notes_api_v1_school_bill_path(nxt[:id]), params: { doc_type: "dn", description: "Extra stop", amount: 100, reason: "Second address" }, as: :json
    expect(json[:data]).to include(debited: "109.0", owed: "1519.46")
    post notes_api_v1_school_bill_path(nxt[:id]), params: { doc_type: "cn", description: "Too much", amount: 5000, reason: "x", credit_use: "reduce" }, as: :json
    expect(json.dig(:error, :message)).to eq("Only S$1519.46 is owed on this bill. Refund the rest or take it off the next bill")

    get export_api_v1_school_bills_path(school)
    expect(response.body.lines.first).to start_with("Bill No,Bill To,Code,Period,Amount")
    expect(response.body).to include("INV-2026-000001,Lim Family,F001")
  end

  it "bills the school's Managed Client when the school pays per rider" do
    within_tenant(company) { year.fare_table.update!(payer: "school") }
    at Time.zone.local(2026, 12, 14, 9, 0)
    post api_v1_school_bill_runs_path(school), params: { academic_year_id: year.id, period_index: 0 }, as: :json
    expect(json[:data]).to include(payer: "school", bill_to: { managed_client: nil, linked: false }, can_issue: false)
    expect(json.dig(:data, :rows).sole[:lines].size).to eq(4)
    post api_v1_school_issue_bill_runs_path(school), params: { academic_year_id: year.id, period_index: 0 }, as: :json
    expect(json.dig(:error, :message)).to start_with("Link this school to a Managed Client first")

    within_tenant(company) do
      client = Client.create!(name: "St. Stephen's School", kind: "company", email: "accounts@sss.edu.sg")
      school.update!(client:)
    end
    post api_v1_school_issue_bill_runs_path(school), params: { academic_year_id: year.id, period_index: 0 }, as: :json
    expect(json.dig(:data, :rows).sole).to include(status: "issued", bill_to: "St. Stephen's School")
    expect(bill(json.dig(:data, :rows).sole[:id])).to include(payer: "school", bill_to_email: "accounts@sss.edu.sg")
  end

  it "lists the documents, prints a receipt, voids it and shows a payer's statement" do
    at Time.zone.local(2026, 12, 14, 9, 0)
    lim = within_tenant(company) do
      SchoolBills::Run.call(year, 0)
      SchoolBills::Issue.call(year, 0, user:)
      SchoolBill.find_by!(family: f[:lim])
    end
    post notes_api_v1_school_bill_path(lim), params: { doc_type: "cn", description: "Bus late", amount: 10, reason: "Late twice", credit_use: "refund",
                                                       method: "PayNow", reference: "R9" }, as: :json
    post payments_api_v1_school_bill_path(lim), params: { paid_on: "2026-12-15", amount: 1000, method: "Cheque", reference: "CHQ 88" }, as: :json

    get api_v1_school_documents_path(school)
    expect(json[:data].map { [ it[:type], it[:number], it[:status] ] }).to eq([ %w[rcp RCP-2026-000001 Received], %w[inv INV-2026-000002 Due],
                                                                               [ "inv", "INV-2026-000001", "Part Paid" ], %w[cn CN-2026-000001 Refunded] ])
    expect(json[:meta][:counts]).to include(all: 4, inv: 2, cn: 1, rcp: 1)
    expect(json[:meta][:payers].pluck(:name)).to eq([ "Lim Family", "Tan Family" ])
    get api_v1_school_documents_path(school), params: { payer: "family:#{f[:tan].id}" }
    expect(json[:data].pluck(:number)).to eq([ "INV-2026-000002" ])
    rcp = within_tenant(company) { SchoolDocument.find_by!(number: "RCP-2026-000001") }
    get api_v1_school_document_path(rcp)
    expect(json[:data]).to include(title: "Official Receipt", method: "Cheque", reference: "CHQ 88", applied: [ { bill_id: lim.id, number: "INV-2026-000001", amount: "1000.0" } ])

    get api_v1_school_statement_path(school), params: { payer: "family:#{f[:lim].id}" }
    expect(json[:data][:lines].map { [ it[:details], it[:charge], it[:credit], it[:balance] ] }).to eq([ [ "INV-2026-000001 | Semester 1 | Jan 2027", "1464.96", nil, "1464.96" ],
                                                                                                    [ "RCP-2026-000001 | Cheque", nil, "1000.0", "464.96" ] ])

    post void_api_v1_school_document_path(rcp), params: { reason: "" }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter why the receipt is void")
    post void_api_v1_school_document_path(rcp), params: { reason: "Cheque bounced" }, as: :json
    expect(json[:data]).to include(status: "Void", void: hash_including(reason: "Cheque bounced"))
    expect(bill(lim.id)).to include(status: "Due", paid: "0.0", owed: "1464.96")
  end

  it "estimates a route plan's month: a year of fares over 12, two-way riders half, To Collect, operator cost" do
    at Time.zone.local(2027, 1, 5, 9, 0)
    am = f[:routes].first.plan
    within_tenant(company) { school.bus_size_rates.create!(bus_type: "MEDIUM_23", monthly: 3000) && am.routes.first.update!(bus_type: "MEDIUM_23") }
    get estimate_api_v1_plan_path(am), params: { month: "2027-01" }
    d = json[:data]
    # R1, R2, R4 on the list in January (R3 joins in March), all AM + PM in the rider data: 1,680 a year two-way, the January bill 840
    expect(d).to include(title: "Estimate for Jan 2027", paid_month: true, riders: 3, two_way: 3, revenue: "210.0", to_collect: "1260.0",
                         operator_cost: "3000.0", gross_profit: "-2790.0", margin_pct: -1328.6, unpriced: 0, basis: "distance", no_fare: 0)
    expect(d[:bands].first).to include(label: "0 to 3 km", riders: 3, two_way: 3, one_way: 0, share: 100.0, revenue: "210.0", to_collect: "1260.0")
    expect(d[:pl]).to eq(one_way: { riders: 0, amount: "0.0" }, two_way: { riders: 3, total: "420.0", half: "210.0" })
    expect(d[:notes].last).to eq("Revenue is a year of fares spread over 12 months. To Collect is what is billed in Jan 2027, when a term starts. " \
                                 "Two-way riders count half here, half in the other session")
    get estimate_api_v1_plan_path(am), params: { month: "2027-02" }
    expect(json[:data]).to include(revenue: "210.0", to_collect: "0.0")
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    get estimate_api_v1_plan_path(am)
    expect(response).to have_http_status(:forbidden)
  end
end
