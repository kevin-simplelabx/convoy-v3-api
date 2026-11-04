# Finance > Client Invoices: Ready to Invoice (by billing entity), Ad Hoc Trips, invoices and credit notes (tabs),
# Create Draft / Invoice Now, the invoice dialog (edit draft, Issue, Void, delete draft).
module Api
  module V1
    class ClientInvoicesController < BaseController
      INCLUDES = [ :client, :invoice, { lines: :runs, payments: :recorded_by, credit_notes: [], sends: :sent_by } ].freeze

      # GET /finance/invoices?tab=drafts|unpaid|paid|void|credit_notes&client_id=&q=
      def index
        authorize :finance, :index?
        list = ClientInvoice.includes(:client, :invoice, :payments, :credit_notes).order(Arel.sql("COALESCE(issued_on, created_at::date) DESC"), id: :desc)
        list = list.where(client_id: params[:client_id]) if params[:client_id].present?
        list = list.where("number ILIKE :q OR bill_to_name ILIKE :q", q: "%#{ClientInvoice.sanitize_sql_like(params[:q])}%") if params[:q].present?
        rows = list.to_a
        tabs = { "drafts" => rows.select(&:draft?), "unpaid" => rows.select { |i| i.invoice? && i.issued? && i.balance > 0.005 },
                 "paid" => rows.select { |i| i.invoice? && i.issued? && i.balance <= 0.005 }, "void" => rows.select { |i| i.invoice? && i.void? },
                 "credit_notes" => rows.select(&:credit_note?) }
        tab = tabs.key?(params[:tab]) ? params[:tab] : "drafts"
        pagy, page = pagy_array(tabs[tab])
        render json: { data: ClientInvoiceBlueprint.render_as_hash(page),
                       meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages, tab:, counts: tabs.transform_values(&:size) } }
      end

      # GET /finance/invoices/ready?month=2026-10 — Ready to Invoice, one row per billing entity.
      def ready
        authorize :finance, :index?
        entities = ClientInvoices::Billable.call(month:)
        drafts = ClientInvoice.draft.invoice.group(:client_id, :client_site_id).count
        render json: { data: entities.sort_by(&:name).map { |e| ready_row(e, drafts) }, meta: { month: month.strftime("%Y-%m") } }
      end

      # GET /finance/invoices/ad_hoc — one-off trips of the last 90 days and to come with runs not billed yet.
      def ad_hoc
        authorize :finance, :index?
        trips = Trip.kept.where(days: []).where(starts_on: (Date.current - 90)..).includes(:client).order(starts_on: :desc).limit(60)
        rows = trips.filter_map do |t|
          e = ClientInvoices::Billable.call(trip: t, client_id: t.client_id).first
          next unless e && (e.bill + e.late).any?

          { trip_id: t.id, ref: t.decorate.trip_id, title: t.title, client: { id: t.client_id, name: t.client.name }, date: t.starts_on,
            amount: e.amount, done: t.starts_on < Date.current, client_site_id: e.site&.id }
        end
        render json: { data: rows.first(12) }
      end

      # GET /finance/invoices/summary?month= — KPIs and aging.
      def summary
        authorize :finance, :index?
        render json: { data: ClientInvoices::Report.call(month: params[:month].present? ? month : Date.current) }
      end

      # GET /finance/invoices/clients — balance by billing entity.
      def clients
        authorize :finance, :index?
        render json: { data: ClientInvoices::Report.new.clients }
      end

      # GET /finance/invoices/statement?client_id=&client_site_id= — Statement of Account.
      def statement
        authorize :finance, :show?
        client = Client.kept.find(params.require(:client_id))
        site_id = params[:client_site_id].presence&.to_i
        render json: { data: ClientInvoices::Report.new.statement(client_id: client.id, client_site_id: site_id)
                               .merge(client: { id: client.id, name: client.name }, client_site_id: site_id, date: Date.current) }
      end

      # POST /finance/invoices/:id/payments { paid_on, amount, method, reference }
      def pay
        authorize :finance, :update?
        money.pay!(**params.permit(:paid_on, :amount, :method, :reference).to_h.symbolize_keys)
        render_invoice find_invoice
      end

      # POST /finance/invoices/:id/credit_note { amount, reason }
      def credit
        authorize :finance, :update?
        money.credit!(amount: params.require(:amount), reason: params[:reason])
        render_invoice find_invoice
      end

      # POST /finance/invoices/:id/send { to: [], cc: [] } — recorded only.
      def send_invoice
        authorize :finance, :update?
        money.send!(to: params[:to], cc: params[:cc])
        render_invoice find_invoice
      end

      def show
        authorize :finance, :show?
        render_invoice find_invoice
      end

      # POST /finance/invoices { client_id, client_site_id, month } (Create Draft) or { trip_id } (Invoice Now)
      def create
        authorize :finance, :create?
        trip = params[:trip_id].present? ? Trip.kept.find(params[:trip_id]) : nil
        client = trip&.client || Client.kept.find(params.require(:client_id))
        site = trip ? trip.client_site&.then { |s| s.own_billing? ? s : nil } : client.sites.find_by(id: params[:client_site_id])
        invoice = ClientInvoices::Draft.call(client:, site:, trip:, month: trip ? nil : month, user: current_user)
        render_invoice invoice, status: :created
      end

      # PATCH /finance/invoices/:id { invoice: { bill_to_name, …, manual_lines: [], remove_line_ids: [], waived_run_ids: [] } }
      def update
        authorize :finance, :update?
        render_invoice edit.update(invoice_params)
      end

      def issue
        authorize :finance, :update?
        render_invoice edit.issue!
      end

      def void
        authorize :finance, :update?
        render_invoice edit.void!
      end

      def destroy
        authorize :finance, :destroy?
        edit.destroy!
        head :no_content
      end

      private

      def find_invoice = @invoice ||= ClientInvoice.includes(INCLUDES).find(params[:id])
      def edit = ClientInvoices::Edit.new(invoice: find_invoice, user: current_user)
      def money = ClientInvoices::Money.new(invoice: find_invoice, user: current_user)

      def month
        @month ||= Date.strptime(params[:month].presence || Date.current.prev_month.strftime("%Y-%m"), "%Y-%m")
      rescue Date::Error
        raise ApplicationService::Error, "Month must look like 2026-11"
      end

      def invoice_params
        params.expect(invoice: [ *ClientInvoices::Edit::FIELDS, { remove_line_ids: [], waived_run_ids: [] },
                                 { manual_lines: [ %i[ref description details period_text quantity unit_price amount] ] },
                                 { lines: [ %i[id ref description details period_text quantity amount] ] } ])
      end

      def ready_row(e, drafts)
        { client_id: e.client.id, client_site_id: e.site&.id, name: e.name, trips: (e.bill + e.late).map(&:trip_id).uniq.size,
          runs: e.bill.size, late_cancels: e.late.size, amount: e.amount, drafts_open: drafts[e.key].to_i,
          blocked: e.blocked.map { |o, why| { date: o.date, trip_label: o.trip_label, reason: why } } }
      end

      def render_invoice(invoice, status: :ok)
        render_data ClientInvoice.includes(INCLUDES).find(invoice.id), ClientInvoiceBlueprint, view: :detail, status:
      end
    end
  end
end
