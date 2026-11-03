# An alert Ops Control raised on a run (driver not logged in, trip not started, running late, not at the first pick-up,
# late arrival, no GPS) at a severity: 1 = Warning (At Risk), 2 = Action. Open until the problem clears; acknowledging
# stops the alarm and escalation but keeps the trip flagged. Written only by OpsControl::Sync and Acknowledge.
# == Schema Information
#
# Table name: ops_alerts
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  acknowledged_at    :timestamptz
#  cleared_at         :timestamptz
#  escalated_at       :timestamptz
#  kind               :string           not null
#  message            :text             not null
#  occurrence_date    :date             not null
#  raised_at          :timestamptz      not null
#  severity           :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  acknowledged_by_id :bigint
#  company_id         :bigint           not null
#  occurrence_id      :bigint           not null
#
# Indexes
#
#  index_ops_alerts_on_company_id_and_raised_at  (company_id,raised_at)
#  index_ops_alerts_on_company_open              (company_id) WHERE (cleared_at IS NULL)
#  index_ops_alerts_open                         (occurrence_id,occurrence_date,kind,severity) UNIQUE WHERE (cleared_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (acknowledged_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#
class OpsAlert < ApplicationRecord
  include TenantScoped

  KINDS = %w[login start eta miss late gps].freeze
  SEVERITIES = { 1 => "warning", 2 => "action" }.freeze

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :ops_alerts
  belongs_to :acknowledged_by, class_name: "User", optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :severity, inclusion: { in: SEVERITIES.keys }

  scope :open, -> { where(cleared_at: nil) }
  scope :unacknowledged, -> { where(acknowledged_at: nil) }

  def action? = severity == 2

  # Open / Acknowledged / Escalated / Cleared, as in the Alert Log.
  def log_status
    return "cleared" if cleared_at
    return "acknowledged" if acknowledged_at

    escalated_at ? "escalated" : "open"
  end
end
