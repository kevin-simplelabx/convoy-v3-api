class PayBonusBlueprint < ApplicationBlueprint
  fields :name, :description, :plan_type, :type_label, :frequency, :starts_on, :last_period_on, :ends_on, :locked_at

  field(:status) { |b| b.status }
  field(:locked) { |b| b.locked? }
  field(:locked_by) { |b| b.locked_by && { id: b.locked_by.id, name: b.locked_by.shown_name } }

  view :detail do
    fields(*(PayBonuses::Save::FIELDS - %i[name description plan_type frequency starts_on last_period_on]))
    field(:scheme_ids) { |b| b.all_schemes? ? [] : b.bonus_schemes.map(&:pay_scheme_id) }
    field(:eligible_driver_ids) { |b| b.eligible_driver_ids }
    field(:signed_up_driver_ids) { |b| b.signed_up_driver_ids }
    field(:tiers) { |b| b.tiers.map { |t| t.slice(:target_trips, :metric_min, :metric_max, :pay_as, :amount, :points) } }
    field(:payments) { |b| b.payments.map { |p| p.slice(:percentage, :months_after) } }
    field(:excluded_periods) { |b| b.excluded_periods.map { |p| p.slice(:name, :starts_on, :ends_on) } }
  end
end
