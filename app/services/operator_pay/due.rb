# Operator Payments > Payment Requests: everything owed to operators and not in a batch yet.
#   run:<id>:<date>     a run on an operator's bus (3 months back to the end of this month) at its operator cost
#                       (the pay agreed on the assignment, split per run; else the trip's operator cost; else the
#                       external operator's cost per trip), or the cost Finance set. Cancelled runs only when the trip
#                       pays operators in full for cancellations. Ready once the run is done and has a cost.
#   replacement:<id>    a replacement we arranged for an operator's bus: its deduction + premium taken off.
#   item:<id>           a manual item (pay or deduct).
module OperatorPay
  class Due < ApplicationService
    Item = Struct.new(:ref, :source, :operator, :description, :details, :item_on, :amount, :ready, :why, :editable, keyword_init: true)

    def initialize(operator_id: nil, now: Time.current)
      @operator_id = operator_id
      @now = now
      @today = now.to_date
    end

    def call
      taken = OperatorPayBatchLine.joins(operator_pay_batch_operator: :operator_pay_batch)
                                  .where(operator_pay_batches: { company_id: ActsAsTenant.current_tenant.id }).pluck(:ref).to_set
      (runs + replacements + items).reject { |i| taken.include?(i.ref) }
    end

    private

    def runs
      scope = TripOccurrence.visible.where.not(operator_id: nil).between(@today.beginning_of_month << 3, @today.end_of_month)
                            .includes(:operator, :trip).chronological
      scope = scope.where(operator_id: @operator_id) if @operator_id
      list = scope.to_a
      overrides = OperatorCostOverride.where(occurrence_id: list.map(&:id)).to_h { |o| [ [ o.occurrence_id, o.occurrence_date ], o.amount ] }
      list.filter_map do |o|
        next if o.cancelled? && !o.trip&.operator_paid_full?

        cost = overrides[[ o.id, o.date ]] || o.operator_cost || o.operator&.cost_per_trip
        done = !o.cancelled? ? (o.completed? || o.ended_at || o.ends_at <= @now) : o.date < @today
        why = ("Set the cost" if cost.nil?) || ("Not run yet" unless done)
        Item.new(ref: "run:#{o.id}:#{o.date}", source: "trip", operator: o.operator, description: o.trip&.title || o.trip_label,
                 details: [ o.trip_label, Clock.hm(o.start_time), (o.cancelled? ? "cancelled, paid in full" : nil) ].compact.join(" | "),
                 item_on: o.date, amount: cost&.to_d, ready: why.nil?, why:, editable: true)
      end
    end

    def replacements
      scope = Replacement.arranged_by_us.where("COALESCE(deduction, 0) + COALESCE(premium, 0) > 0").includes(original_vehicle: :operator)
      scope.filter_map do |r|
        op = r.original_vehicle&.operator
        next unless op && (@operator_id.nil? || op.id == @operator_id)

        Item.new(ref: "replacement:#{r.id}", source: "replacement", operator: op, description: "Replacement bus we arranged",
                 details: "#{r.original_vehicle.plate} | #{r.starts_on.strftime('%-d %b')} to #{r.ends_on.strftime('%-d %b %Y')}",
                 item_on: r.starts_on, amount: -(r.deduction.to_d + r.premium.to_d), ready: true, editable: false)
      end
    end

    def items
      scope = OperatorPayItem.includes(:operator)
      scope = scope.where(operator_id: @operator_id) if @operator_id
      scope.map do |i|
        Item.new(ref: "item:#{i.id}", source: "item", operator: i.operator, description: i.description, item_on: i.item_on,
                 amount: i.amount, ready: true, editable: false)
      end
    end
  end
end
