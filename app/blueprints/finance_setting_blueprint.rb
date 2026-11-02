class FinanceSettingBlueprint < Blueprinter::Base
  fields(*Finance::SaveSettings::FIELDS, :locked_at)

  field(:locked) { |s| s.locked? }
  field(:locked_by) { |s| s.locked_by && { id: s.locked_by.id, name: s.locked_by.shown_name } }
  field(:approvers) do |s|
    s.approvers.map { |a| { user_id: a.user_id, name: a.user.shown_name, email: a.user.email, active: a.user.kept? && a.user.active?, can_prepare: a.can_prepare, can_approve: a.can_approve } }
  end
  field(:active_users) { |_s, o| o[:active_users] }
  # "Maker-checker is on, but only 1 active user is left, so no pay run can be approved. Switch to One Person"
  field(:maker_checker_warning) { |s, o| s.approval_maker? && o[:active_users].to_i < 2 }
  field(:doc_types) { FinanceSetting::DOC_TYPES }
end
