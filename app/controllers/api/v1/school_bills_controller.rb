# School Bus › School Finance › Collections: the Family Bills card (draft, issue, settings), the school's bills worked out
# for today (filter, search, totals, CSV), one bill with its history, and money on bills: payments with a receipt (one
# bill or many), late fees waived, credit and debit notes; billing differences against today's riders and fares.
module Api
  module V1
    class SchoolBillsController < BaseController
      NO_LOCKED_YEAR = "Lock the Bus Fares for a year first"

      # GET /schools/:school_id/bills?academic_year_id=&period_index=&status=&q=&page=&limit=
      def index
        authorize :finance, :index?
        school = find_school
        year = params[:academic_year_id].present? ? school.academic_years.find(params[:academic_year_id]) : nil
        out = SchoolBills::Collections.call(school, year:, period_index: params[:period_index], status: params[:status], q: params[:q])
        pagy, rows = pagy_array(out[:rows])
        render json: { data: rows.map { SchoolBills::Present.row(it) },
                       meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages, counts: out[:counts], kpis: out[:kpis],
                               methods: SchoolBills::RecordPayment::METHODS } }
      end

      # GET /schools/:school_id/bills/export?… (same filters) — CSV of the bills shown.
      def export
        authorize :finance, :index?
        school = find_school
        year = params[:academic_year_id].present? ? school.academic_years.find(params[:academic_year_id]) : nil
        rows = SchoolBills::Collections.call(school, year:, period_index: params[:period_index], status: params[:status], q: params[:q])[:rows]
        send_data csv(rows), filename: "Collections #{Date.current.iso8601}.csv", type: "text/csv"
      end

      # GET /schools/:school_id/bills/differences?academic_year_id=
      def differences
        authorize :finance, :index?
        render json: { data: SchoolBills::Differences.call(find_year(find_school)) }
      end

      # GET /schools/:school_id/bill_runs?academic_year_id=&period_index=&q= — the Family Bills card.
      def runs
        authorize :finance, :index?
        year = find_year(find_school, required: false)
        return render json: { data: { on: false, error: NO_LOCKED_YEAR } } unless year

        render json: { data: SchoolBills::Board.call(year, index: params[:period_index], q: params[:q]) }
      end

      # POST /schools/:school_id/bill_runs { academic_year_id, period_index } — Draft Now / Draft Again.
      def draft
        authorize :finance, :create?
        year = find_year(find_school)
        run = SchoolBills::Run.call(year, params.require(:period_index), user: current_user)
        drafts = SchoolBill.drafts.where(school: year.school, academic_year: year, kind: "period", period_index: run.period_index).count
        render json: { data: SchoolBills::Board.call(year, index: run.period_index), meta: { drafted: drafts } }, status: :created
      end

      # POST /schools/:school_id/bill_runs/issue { academic_year_id, period_index, bill_ids: [] (none = every draft) }
      def issue
        authorize :finance, :create?
        year = find_year(find_school)
        ids = params[:bill_ids].presence && Array(params[:bill_ids])
        bills = SchoolBills::Issue.call(year, params.require(:period_index), bill_ids: ids, user: current_user)
        render json: { data: SchoolBills::Board.call(year, index: params[:period_index]), meta: { issued: bills.size } }
      end

      # PATCH /school_bills/settings { draft_days, start_rule: prorate|full|half }
      def settings
        authorize :finance, :update?
        days = params.require(:draft_days).to_i
        rule = params.require(:start_rule).to_s
        raise ApplicationService::Error, "Enter the days before the due date" unless days.positive?
        raise ApplicationService::Error, "Pick how a child who starts mid-period is charged" unless SchoolBills::Draft::RULES.include?(rule)

        s = FinanceSetting.current
        s.update!(school_bill_draft_days: days, school_bill_start_rule: rule)
        render json: { data: { draft_days: s.school_bill_draft_days, start_rule: s.school_bill_start_rule } }
      end

      # GET /school_bills/:id
      def show
        authorize :finance, :show?
        render json: { data: SchoolBills::Present.detail(calc(find)) }
      end

      # POST /school_bills/:id/payments { paid_on, amount, method, reference }
      def pay
        authorize :finance, :create?
        bill = find
        receipt = SchoolBills::RecordPayment.call(bill.school, [ [ bill, params.require(:amount).to_d ] ], paid_on: day(:paid_on), method: params[:method],
                                                                                                          reference: params[:reference], user: current_user)
        render json: { data: SchoolBills::Present.detail(calc(find)), meta: { receipt: receipt.number } }, status: :created
      end

      # POST /schools/:school_id/bills/pay { bill_ids: [], paid_on, method, reference } — Mark Paid: each pays what it owes.
      def pay_many
        authorize :finance, :create?
        school = find_school
        bills = SchoolBill.issued.where(school:, id: Array(params.require(:bill_ids))).includes(:lines, :payments, :waivers, :notes, :family).to_a
        policy = school.policy_versions.in_use_on(Date.current)
        list = bills.map { [ it, SchoolBills::Calc.call(it, policy:).owed ] }.select { |_, owed| owed > 0.005 }
        receipt = SchoolBills::RecordPayment.call(school, list, paid_on: day(:paid_on), method: params[:method], reference: params[:reference], user: current_user)
        render json: { data: { receipt: receipt.number, bills: list.size, amount: receipt.total } }, status: :created
      end

      # POST /school_bills/:id/waive_late { amount, reason }
      def waive_late
        authorize :finance, :update?
        bill = find
        c = calc(bill)
        amount = params.require(:amount).to_d
        raise ApplicationService::Error, "Enter the amount to waive" unless amount.positive?
        raise ApplicationService::Error, "Enter a reason for the waiver" if params[:reason].to_s.strip.empty?
        raise ApplicationService::Error, "You can waive up to S$#{format('%.2f', c.late)}" if amount > c.late + 0.005

        bill.waivers.create!(kind: "late", amount: amount.round(2), reason: params[:reason].to_s.strip, created_by: current_user)
        render json: { data: SchoolBills::Present.detail(calc(find)) }
      end

      # POST /school_bills/:id/notes { doc_type: cn|dn, description, amount, reason, credit_use: reduce|refund|carry, issued_on, method, reference }
      def add_note
        authorize :finance, :create?
        note = SchoolBills::AddNote.call(find, params.permit(:doc_type, :description, :amount, :reason, :credit_use, :issued_on, :method, :reference),
                                         user: current_user)
        render json: { data: SchoolBills::Present.detail(calc(find)), meta: { number: note.number } }, status: :created
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def find
        SchoolBill.where(school: policy_scope(School)).includes(:school, :family, :issued_by, :lines, payments: %i[receipt recorded_by],
                                                                waivers: :created_by, notes: :created_by).find(params[:id])
      end

      def calc(bill) = SchoolBills::Calc.call(bill, policy: bill.school.policy_versions.in_use_on(Date.current))

      # The year asked for, else the one with locked fares covering today, else the latest with locked fares.
      def find_year(school, required: true)
        return school.academic_years.find(params[:academic_year_id]) if params[:academic_year_id].present?

        locked = school.academic_years.includes(:setup_locks, :fare_table).select { it.fare_table&.locked? }
        year = locked.find { (it.starts_on..it.ends_on).cover?(Date.current) } || locked.max_by(&:starts_on)
        raise ApplicationService::Error, NO_LOCKED_YEAR if year.nil? && required

        year
      end

      def day(key)
        params[key].present? ? Date.parse(params[key].to_s) : nil
      rescue Date::Error
        nil
      end

      def csv(rows)
        require "csv"
        CSV.generate do |out|
          out << [ "Bill No", "Bill To", "Code", "Period", "Amount", "GST", "Late Fee", "Credited", "Debited", "Paid", "Owed", "Due", "Status" ]
          rows.each do |c|
            b = c.bill
            out << [ b.number, b.to_name, b.bill_to_code, b.period_label, b.total, b.gst_amount, c.late, c.credited, c.debited, c.paid, c.owed, b.due_on, c.status ]
          end
        end
      end
    end
  end
end
