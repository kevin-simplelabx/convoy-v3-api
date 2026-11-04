# Client Portal › Invoices (billing roles; read only — paying, statements and PDFs are not built): invoices for trips and
# bookings (issued, not void; with what is paid, credited and still to pay) and School Bus bills sent to the client as a
# school (SchoolBills::Calc: credits, debit notes, payments, late fee). Site roles: only their sites' own billing and their
# sites' schools. KPIs Outstanding / Overdue / Invoices; filter all | not_paid | trips | school_bus; search.
module Portal
  class Invoices < ApplicationService
    LIMIT = 200
    TRIP_STATUS = { "paid" => "Paid", "overdue" => "Overdue", "partly_paid" => "Part Paid", "issued" => "Due" }.freeze

    def initialize(client_user:, filter: nil, q: nil, today: Date.current)
      @user = client_user
      @client = client_user.client
      @filter = filter.presence || "all"
      @q = q.to_s.strip.downcase
      @today = today
    end

    def call
      rows = (trip_invoices + school_bills).sort_by { [ it[:issued_on] || Date.new(1900), it[:number].to_s ] }.reverse
      kpis = { outstanding: sum(rows.select { it[:balance].positive? }), overdue: sum(rows.select { it[:status] == "Overdue" }), invoices: rows.size }
      rows = rows.select { keep?(it) }
      { kpis:, has_school_bus: rows.any? { it[:kind] == "school_bus" } || school_ids.any?, rows: rows.first(LIMIT) }
    end

    private

    def trip_invoices
      scope = ClientInvoice.where(client: @client, kind: "invoice", status: "issued").includes(:client_site, :payments, :credit_notes)
      @user.limit_to_sites(scope).map do |inv|
        { kind: "trips", id: inv.id, number: inv.number, for: inv.bill_to_name, site: inv.client_site&.name, period: inv.period_label,
          issued_on: inv.issued_on, due_on: inv.due_on, total: inv.total.to_d, paid: (inv.paid + inv.credited).to_d, balance: inv.balance.to_d,
          late_fee: 0.to_d, status: TRIP_STATUS.fetch(inv.display_status(@today), "Due") }
      end
    end

    def school_bills
      return [] if school_ids.empty?

      policies = SchoolBills::Calc.policies(school_ids, today: @today)
      SchoolBill.issued.where(client: @client, payer: "school", school_id: school_ids)
                .includes(:school, :lines, :payments, :waivers, :notes).map do |b|
        c = SchoolBills::Calc.call(b, policy: policies[b.school_id], today: @today)
        { kind: "school_bus", id: b.id, number: b.number, for: b.to_name, site: site_names[b.school_id] || b.school.name, period: b.period_label,
          issued_on: b.issued_on, due_on: b.due_on, total: (c.net + c.late).to_d, paid: c.paid.to_d, balance: c.owed.to_d, late_fee: c.late.to_d,
          status: c.status }
      end
    end

    # The client's own school (everyone) and its sites' schools (people covering the site).
    def school_ids
      @school_ids ||= ([ @client.school&.id ] + @user.limit_to_sites(@client.sites.where.not(school_id: nil), :id).pluck(:school_id)).compact.uniq
    end

    def site_names = @site_names ||= @client.sites.where(school_id: school_ids).to_h { [ it.school_id, it.name ] }

    def keep?(row)
      return false if @q.present? && [ row[:number], row[:site], row[:for], row[:period] ].compact.none? { it.downcase.include?(@q) }

      case @filter
      when "not_paid" then row[:balance].positive?
      when "trips" then row[:kind] == "trips"
      when "school_bus" then row[:kind] == "school_bus"
      else true
      end
    end

    def sum(rows) = { amount: rows.sum(0.to_d) { it[:balance] }, count: rows.size }
  end
end
