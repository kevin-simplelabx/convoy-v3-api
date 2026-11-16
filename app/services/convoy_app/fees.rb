# Convoy App › Fees: the Family's issued School Bus bills (period bills, CCA rides, registration fees and first invoices of
# its requests) and what they come to today. Read inside each company the Family deals with (Parents.within); only the
# Billing Contact reaches them. A bill is found among the Family's own, so another Family's bill is a 404.
module ConvoyApp
  module Fees
    Row = Struct.new(:bill, :calc, :payable, keyword_init: true)

    module_function

    # The Family's issued bills in this company: its own (families copied from the household) plus the registration and
    # first invoices of its requests, which may predate the Family. Not the first invoice of a withdrawn request.
    def scope(household)
      fids = Family.where(household_id: household.id).select(:id)
      live = BusRequest.where(household_id: household.id).where.not(status: "Withdrawn")
      SchoolBill.issued.where(payer: "family", family_id: fids)
                .or(SchoolBill.issued.where(id: live.where.not(registration_bill_id: nil).select(:registration_bill_id)))
                .or(SchoolBill.issued.where(kind: "first", bus_request_id: live.select(:id)))
    end

    def load(relation)
      relation.includes(:lines, :waivers, :notes, :bus_request, :school, payments: :receipt).order(issued_on: :desc, id: :desc).to_a
             .reject { it.kind == "first" && it.bus_request&.status == "Withdrawn" }
    end

    # What each bill comes to today (Calc, with the school's late fee policy); inside the company.
    def rows(bills, today = Date.current)
      policies = SchoolBills::Calc.policies(bills.map(&:school_id).uniq, today:)
      bills.map do |b|
        Row.new(bill: b, calc: SchoolBills::Calc.call(b, policy: policies[b.school_id], today:), payable: payable?(b))
      end
    end

    # The first invoice is paid while the request is Accepted (what the School page offers); every other bill any time.
    def payable?(bill) = bill.kind != "first" || bill.bus_request&.live_status == "Accepted"

    def outstanding?(row) = row.payable && row.calc.owed > 0.005

    # Runs inside the bill's company: yields (company, bill) for this Family's bill, else 404.
    def with_bill(household, id)
      Parents.companies(household).each do |company|
        found = Parents.within(company) do
          bill = load(scope(household).where(id:)).first
          bill && [ yield(company, bill) ]
        end
        return found.first if found
      end
      raise ActiveRecord::RecordNotFound
    end

    # Every outstanding bill of the Family: [{ company:, row: }] (Page badge, Delete Family check).
    def outstanding(household)
      Parents.companies(household).flat_map do |company|
        Parents.within(company) { rows(load(scope(household))).select { outstanding?(it) }.map { |r| { company:, row: r } } }
      end
    end

    def money(value) = value.to_d.round(2)

    # One bill as a list row.
    def summary(row, company)
      b = row.bill
      last = b.payments.reject(&:voided?).last
      { id: b.id, number: b.number, kind: b.kind, period: b.period_label, school: { id: b.school_id, name: b.school.name }, company: Parents.company_json(company),
        total: b.total, owed: row.calc.owed, status: { label: row.calc.status, tone: row.calc.tone }, issued_on: b.issued_on, due_on: b.due_on,
        paid_on: (last&.paid_on if row.calc.owed <= 0.005), method: last&.method, can_pay: row.payable && row.calc.owed > 0.005 }
    end
  end
end
