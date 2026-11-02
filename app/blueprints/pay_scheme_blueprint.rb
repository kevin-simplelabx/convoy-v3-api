class PaySchemeBlueprint < ApplicationBlueprint
  fields :name, :description, :is_default, :scheme_type, :type_label, :pay_rate_plan_id, :locked_at

  field(:locked) { |s| s.locked? }
  field(:locked_by) { |s| s.locked_by && { id: s.locked_by.id, name: s.locked_by.shown_name } }

  view :detail do
    fields(*(PaySchemes::Save::FIELDS - %i[name description is_default scheme_type pay_rate_plan_id shift_start_time shift_end_time]),
           :shift_working_days)
    field(:shift_start_time) { |s| s.shift_start_time_hm }
    field(:shift_end_time) { |s| s.shift_end_time_hm }
    field(:rate_plan) { |s| s.rate_plan && { id: s.rate_plan.id, name: s.rate_plan.name } }
    field(:route_bands) { |s| s.route_bands.map { |b| { up_to_minutes: b.up_to_minutes, monthly_amount: b.monthly_amount } } }
    field(:volume_tiers) { |s| s.volume_tiers.map { |t| t.slice(:from_trip, :to_trip, :boost_type, :boost_value) } }
    field(:weekly_tiers) { |s| s.weekly_tiers.map { |t| t.slice(:target_trips, :pay_as, :amount) } }
    field(:monthly_tiers) { |s| s.monthly_tiers.map { |t| t.slice(:target_trips, :pay_as, :amount) } }
  end
end
