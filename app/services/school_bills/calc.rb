# What an issued School Bus bill comes to today: credit notes taken off it and other waivers lower it, debit notes raise
# it, payments pay it, and once it is past its due date plus the policy's grace days with money still owed, the late fee
# of the Payment & Refund Policy in use (flat, or a percentage of what is owed for every 30 days, up to the cap) less any
# late fee waived. Status Paid, Part Paid, Overdue, Due, or Credited when credits cover the whole bill.
module SchoolBills
  class Calc
    TONES = { "Paid" => "success", "Part Paid" => "warning", "Overdue" => "danger", "Due" => "info", "Credited" => "neutral" }.freeze

    Result = Struct.new(:bill, :paid, :credited, :late_waived, :debited, :net, :late, :late_raw, :owed, :overdue, :days_overdue, :status,
                        keyword_init: true) do
      def tone = TONES[status]
      # Shown under Overdue: past due and grace, including part-paid bills.
      def overdue? = overdue
    end

    # bill with lines / payments / waivers / notes loaded; policy = the school's policy in use today (nil = no late fee).
    def self.call(bill, policy:, today: Date.current)
      live = bill.notes.reject(&:voided?)
      credit = live.select { it.credit_note? && it.credit_use == "reduce" }.sum(0.to_d, &:total)
      debit = live.select(&:debit_note?).sum(0.to_d, &:total)
      paid = bill.payments.reject(&:voided?).sum(0.to_d, &:amount)
      waived = bill.waivers.reject { it.kind == "late" }.sum(0.to_d, &:amount)
      waived_late = bill.waivers.select { it.kind == "late" }.sum(0.to_d, &:amount)

      net = [ bill.total + debit - credit - waived, 0.to_d ].max
      grace_end = bill.due_on && (bill.due_on + (policy&.late_grace_days || 0))
      base = [ net - paid, 0.to_d ].max
      over = base > 0.005 && grace_end.present? && today > grace_end
      days = over ? (today - grace_end).to_i : 0
      raw = over ? late_fee(policy, base, days) : 0.to_d
      late = [ raw - waived_late, 0.to_d ].max
      owed = [ net + late - paid, 0.to_d ].max.round(2)
      status = if net <= 0.005 && bill.total.positive? then "Credited"
      elsif owed <= 0.005 then "Paid"
      elsif paid.positive? then "Part Paid"
      elsif over then "Overdue"
      else "Due"
      end
      Result.new(bill:, paid:, credited: waived + credit, late_waived: waived_late, debited: debit, net:, late:, late_raw: raw, owed:, overdue: over,
                 days_overdue: days, status:)
    end

    def self.late_fee(policy, base, days)
      return 0.to_d unless policy

      fee = case policy.late_type
      when "pct" then base * (policy.late_pct || 0) / 100 * [ (days / 30.0).ceil, 1 ].max
      when "none" then 0
      else policy.late_flat || 0
      end
      fee = [ fee, policy.late_cap ].min if policy.late_cap.to_d.positive?
      fee.to_d.round(2)
    end

    # Policies in use today by school id, for working out many bills at once.
    def self.policies(school_ids, today: Date.current)
      SchoolPolicyVersion.where(school_id: school_ids, effective_on: ..today).order(:effective_on, :version).index_by(&:school_id)
    end
  end
end
