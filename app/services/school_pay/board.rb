# The Operator Payments page of a school (port of payrunVals) for a month: one row per operator with its routes, route
# pay (live until sent to Finance, then kept), the lines added or deducted, net, paid, balance and status — No Operator
# (routes with no bus), Our Buses (the company's own, nothing to pay), Paid, Part Paid, Approved, With Finance, To Check
# (the month has ended) or Open — with what the user may do (maker-checker), and the month's totals.
module SchoolPay
  class Board < ApplicationService
    def initialize(school, month, user:, today: Date.current)
      @school = school
      @month = month.beginning_of_month
      @user = user
      @today = today
    end

    def call
      cost = Cost.call(@school, @month)
      payouts = @school.school_payouts.where(month: @month)
                       .includes(:operator, :prepared_by, :sent_by, :returned_by, :approved_by, payments: :recorded_by,
                                 adjustments: %i[files created_by paired_operator])
                       .index_by(&:operator_id)
      keys = (cost[:by_operator].keys | payouts.keys | cost[:auto].keys)
      ops = Operator.where(id: keys.grep(Integer)).index_by(&:id)
      @batched = SchoolPay.batched(payouts.values)
      rights = SchoolPay.rights(@user)
      rows = keys.sort_by { [ it.is_a?(Integer) ? 0 : 1, ops[it]&.name.to_s ] }.map { row(it, ops[it], cost, payouts[it], rights) }
      payable = rows.select { it[:payable] }
      due = payable.sum(0.to_d) { it[:net] }
      paid = payable.sum(0.to_d) { it[:paid] }
      { month: @month, month_label: @month.strftime("%b %Y"), future: @month >= @today.beginning_of_month,
        month_text: (@month > @today.beginning_of_month ? "This month has not started. Amounts are a forecast" : "This month has not ended. Route pay may still change" if @month >= @today.beginning_of_month),
        rights: rights.except(:approvers), rights_text: rights_text(rights),
        kpis: { net_payable: due.round(2), paid: paid.round(2), still_to_pay: [ due - paid, 0.to_d ].max.round(2),
                operators_to_pay: payable.count { it[:status] != "Paid" } },
        kinds: SchoolPayoutAdjustment::KINDS.map { |k, s| { kind: k, sign: s } }, methods: SchoolPayoutPayment::METHODS,
        routes: cost[:rows].map { it.route.label }.uniq, rows: }
    end

    private

    def rights_text(r)
      return "No approvers set yet. Add who can prepare and approve pay runs in Finance Settings" unless r[:set_up]
      return "Maker-checker is on: the person who sends a pay run to Finance cannot approve it" if r[:maker]

      nil
    end

    def row(key, op, cost, p, rights)
      live = cost[:by_operator][key] || { routes: 0, amount: 0.to_d }
      routes = cost[:rows].select { it.key == key }
      base = p&.locked? && p.base ? p.base : live[:amount].round(2)
      auto = p&.locked? ? p.auto_lines.map(&:symbolize_keys) : (cost[:auto][key] || [])
      adjustments = p ? p.adjustments.to_a : []
      net = SchoolPay.net(base, auto, adjustments)
      batch = p && @batched[p.id]
      paid = (p ? p.paid_amount : 0.to_d) + (batch ? batch[:paid] : 0)
      bal = [ net - paid, 0.to_d ].max.round(2)
      payable = key.is_a?(Integer)
      status = status_of(key, p, paid, bal)
      mine = rights[:maker] && p&.sent_by_id == @user.id
      locked = p&.locked? || false
      st = p&.status || "draft"
      { key: key.to_s, operator: op && { id: op.id, name: op.name }, name: op&.name || (key == "own" ? "Our buses" : "Not assigned"), payable:,
        id: p&.id, routes_count: p&.locked? ? p.routes_count : live[:routes], base:, additions: lines_sum(auto, adjustments, 1),
        deductions: lines_sum(auto, adjustments, -1), net:, paid:, balance: bal, status:, tone: TONES[status], invoice_number: p&.invoice_number,
        voucher: p&.voucher_number && { number: p.voucher_number, on: p.voucher_on }, batch: batch&.except(:paid),
        routes: routes.map { route_row(it) }, lines: auto.map { auto_row(it) } + adjustments.map { adj_row(it, locked) },
        history: history(p, auto),
        can: payable ? actions(p, st, paid, locked, rights, mine, batch, net) : {},
        note: { "none" => "Assign an operator to these routes in Operator Pay before paying", "own" => "Our own buses: nothing to pay" }[key] }
    end

    TONES = { "Paid" => "success", "Part Paid" => "warning", "Approved" => "info", "With Finance" => "info", "To Check" => "warning", "Open" => "neutral",
              "No Operator" => "danger", "Our Buses" => "neutral" }.freeze

    def status_of(key, p, paid, bal)
      return "No Operator" if key == "none"
      return "Our Buses" if key == "own"
      return "Paid" if paid.positive? && bal <= 0.005
      return "Part Paid" if paid.positive?
      return "Approved" if p&.status == "approved"
      return "With Finance" if p&.status == "ready"

      @today > @month.end_of_month ? "To Check" : "Open"
    end

    def actions(p, st, paid, locked, rights, mine, batch, net)
      approver = rights[:approve] && !mine
      { edit: !locked && rights[:prepare], send: st == "draft" && paid.zero? && net.positive? && rights[:prepare], recall: st == "ready" && paid.zero? && rights[:prepare],
        send_back: st == "ready" && paid.zero? && approver, approve: st == "ready" && paid.zero? && approver,
        reopen: st == "approved" && paid.zero? && rights[:approve] && batch.nil?, pay: st == "approved" && batch.nil?,
        need_other: st == "ready" && paid.zero? && !approver }.tap { it[:pay] &&= !p.nil? }
    end

    def lines_sum(auto, adjustments, sign)
      (auto.select { it[:sign] == sign }.sum(0.to_d) { it[:amount].to_d } + adjustments.select { it.sign == sign }.sum(0.to_d, &:amount)).round(2)
    end

    def route_row(r)
      { route: r.route.label, session: r.plan.session, plan: r.plan.name, bus_type: (size = r.route.bus_size(r.vehicle)), bus_type_label: size && SchoolBus.label(size), plate: r.vehicle&.plate, price: r.price, unpriced: r.unpriced,
        days: r.days, of: r.of, break_month: r.brk, earned: r.earned.round(4), rate: r.rate, from: r.from, to: r.to, amount: r.amount, note: r.note,
        attendant: r.attendant }
    end

    def auto_row(l) = l.slice(:id, :kind, :sign, :adj_on, :route, :amount, :reason).merge(auto: true, can_remove: false)

    def adj_row(a, locked)
      { id: a.id, kind: a.kind, sign: a.sign, adj_on: a.adj_on, route: a.route_label, amount: a.amount, reason: a.reason, auto: false,
        paired_with: a.paired_operator&.name, by: a.created_by&.name, can_remove: !locked,
        files: a.files.map { (ApplicationDecorator.new(it).file_info(:file) || {}).merge(id: it.id, name: it.name.presence || it.file.file&.filename) } }
    end

    def history(p, auto)
      return [] unless p

      # Newest first by when each step was recorded: a payment's paid_on is the date typed, so its created_at orders it.
      ev = []
      ev << { at: p.returned_at, kind: "returned", text: "Sent back to Ops", by: p.returned_by&.name } if p.returned_at
      ev << { at: p.sent_at, kind: "sent", text: "Sent to Finance", by: p.sent_by&.name } if p.sent_at
      ev << { at: p.approved_at, kind: "approved", text: "Approved#{" for S$#{format('%.2f', SchoolPay.net(p.base, auto, p.adjustments.to_a))}" if p.base}", by: p.approved_by&.name } if p.approved_at
      p.payments.each do
        ev << { at: it.paid_on, kind: "paid", text: "S$#{format('%.2f', it.amount)} paid | #{it.method}#{" | #{it.reference}" if it.reference}", by: it.recorded_by&.name,
                recorded_at: it.created_at, seq: it.id }
      end
      ev.sort_by { [ (it[:recorded_at] || it[:at]).to_time, it[:seq].to_i ] }.reverse.map { it.except(:recorded_at, :seq) }
    end
  end
end
