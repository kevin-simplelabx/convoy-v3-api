# One driving action sent by the Convoy Driver app (start, arrive, leave, skip, attendance, count, edit route, complete,
# force end, skip trip), kept once by the app's client_id: the same action sent again (after being offline, or a retry)
# is answered without doing it twice. `at` = when it happened on the phone; payload = what was sent (audit).
# == Schema Information
#
# Table name: driver_app_actions
# Database name: primary
#
#  id                :bigint           not null, primary key
#  at                :datetime         not null
#  kind              :string           not null
#  occurrence_date   :date             not null
#  payload           :jsonb            not null
#  created_at        :datetime         not null
#  client_id         :uuid             not null
#  company_id        :bigint           not null
#  driver_account_id :bigint           not null
#  occurrence_id     :bigint           not null
#
# Indexes
#
#  index_driver_app_actions_on_driver_account_id_and_client_id    (driver_account_id,client_id) UNIQUE
#  index_driver_app_actions_on_occurrence_id_and_occurrence_date  (occurrence_id,occurrence_date)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (driver_account_id => driver_accounts.id)
#
class DriverAppAction < ApplicationRecord
  include TenantScoped

  KINDS = %w[start arrive leave skip_stop attendance count route complete force_end skip
             disposal_start disposal_run_start disposal_run_end disposal_extend disposal_end].freeze

  belongs_to :driver_account
  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date]

  validates :kind, inclusion: { in: KINDS }
  validates :client_id, presence: true, uniqueness: { scope: :driver_account_id }
end
