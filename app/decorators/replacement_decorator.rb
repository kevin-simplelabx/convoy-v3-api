class ReplacementDecorator < ApplicationDecorator
  def wording = @wording ||= Replacements::Wording.new(object)
  def summary = wording.summary
  def pay_text = wording.pay_text

  # Active, Coming Up or Ended (Replacements list).
  def status_label(today = Date.current)
    return "Ended" if ends_on < today

    starts_on > today ? "Coming Up" : "Active"
  end

  # The original operator's pay for the runs covered: what is taken from them when we arrange the new bus.
  def default_deduction
    op = original_vehicle.operator_id
    return 0 if op.nil?

    Replacements::Affected.runs(object).where(operator_id: op).sum(:operator_cost)
  end
end
