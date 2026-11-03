# School Bus Payment & Refund Policy: the starting point of a new version (Convoy OS defaults).
module Policies
  REMINDERS = [
    { timing: "before", days: 7, email_subject: "Bus fare due [Due Date] for [Child Name]",
      email_body: "Dear [Parent Name],\n\nThe bus fare of [Amount] for [Child Name] for [Period] is due on [Due Date].\n\nPay online: [Pay Link]\n\nThank you,\n[School] Transport",
      whatsapp_body: "Hi [Parent Name], [Child Name]'s bus fare of [Amount] for [Period] is due on [Due Date]. Pay here: [Pay Link]",
      app_title: "Bus fare due [Due Date]", app_body: "[Amount] for [Child Name], [Period]" },
    { timing: "on", days: 0, email_subject: "Bus fare due today for [Child Name]",
      email_body: "Dear [Parent Name],\n\nThe bus fare of [Amount] for [Child Name] for [Period] is due today.\n\nPay online: [Pay Link]\n\nThank you,\n[School] Transport",
      whatsapp_body: "Hi [Parent Name], [Child Name]'s bus fare of [Amount] is due today. Pay here: [Pay Link]",
      app_title: "Bus fare due today", app_body: "[Amount] for [Child Name], [Period]" },
    { timing: "after", days: 3, email_subject: "Overdue: bus fare for [Child Name]",
      email_body: "Dear [Parent Name],\n\nThe bus fare of [Amount] for [Child Name] for [Period] was due on [Due Date] and has not been received. A late charge of [Late Charge] applies after the grace period.\n\nPay online: [Pay Link]\n\nThank you,\n[School] Transport",
      whatsapp_body: "Hi [Parent Name], [Child Name]'s bus fare of [Amount] was due on [Due Date]. A late charge of [Late Charge] applies after the grace period. Pay here: [Pay Link]",
      app_title: "Bus fare overdue", app_body: "[Amount] for [Child Name] was due [Due Date]" }
  ].map { it.merge(email: true, whatsapp: true, app: true) }.freeze
  DEFAULTS = {
    due_rule: "before", due_days_before: 14, due_day: 1, late_type: "flat", late_flat: 20, late_pct: 1, late_cap: nil, late_grace_days: 7,
    late_flag_days: 30, withdrawal_notice: 1, withdrawal_unit: "months", refund_basis: "days", refund_method: "credit", refund_within_days: 30,
    withdrawal_fee: nil, address_notice_days: 14, address_start: "any", address_max_days: 90, deposit_amount: 200, deposit_return: "offset",
    registration_fee: 50, ack_required: true, ack_reaccept: true,
    ack_text: "I have read and agree to the Payment & Refund Policy, including the payment due dates, late charges and withdrawal notice."
  }.freeze
  FIELDS = DEFAULTS.keys.freeze
  REMINDER_FIELDS = %i[timing days email whatsapp app email_subject email_body whatsapp_body app_title app_body].freeze

  module_function

  def present(v)
    v.slice(*FIELDS).symbolize_keys.merge(reminders: v.reminders.map { it.slice(*REMINDER_FIELDS).symbolize_keys })
  end

  def default = DEFAULTS.merge(reminders: REMINDERS)
end
