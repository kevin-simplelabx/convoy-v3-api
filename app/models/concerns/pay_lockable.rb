# HR records announced to drivers (rate plans, pay schemes, bonuses) can be locked: a locked one can't be changed or
# deleted until an Admin unlocks it. Saves, locks and unlocks are written to the audit log (HR > Audit Log) with a
# sentence in `comment`; creates and deletes are audited automatically.
module PayLockable
  extend ActiveSupport::Concern

  included do
    audited on: %i[create destroy]
    belongs_to :locked_by, class_name: "User", optional: true
  end

  def locked? = locked_at.present?

  def lock!(user)
    update!(locked_at: Time.current, locked_by: user)
    log_audit!("Locked")
  end

  def unlock!
    update!(locked_at: nil, locked_by: nil)
    log_audit!("Unlocked")
  end

  def ensure_unlocked!(admin:)
    return unless locked?

    raise ApplicationService::Error, "#{name} is locked. #{admin ? 'Unlock it to make changes' : 'Ask an Admin to unlock it'}"
  end

  # One audit row for an update, with what changed in words.
  def log_audit!(comment)
    audits.create!(action: "update", comment:, audited_changes: {})
  end
end
