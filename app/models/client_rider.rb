# A person who rides a Managed Client's staff shuttle with the Convoy App. The row is an invitation, made when a verified
# work email on the client's domain matched (ConvoyApp::Links::Match); the person answers Accept / Not Me in the app and
# the office can remove the link. Never linked without the person's tap.
# == Schema Information
#
# Table name: client_riders
# Database name: primary
#
#  id             :bigint           not null, primary key
#  matched_email  :string           not null
#  responded_at   :datetime
#  status         :string           default("invited"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint           not null
#  client_id      :bigint           not null
#  company_id     :bigint           not null
#  removed_by_id  :bigint
#
# Indexes
#
#  index_client_riders_on_app_account_id                (app_account_id)
#  index_client_riders_on_client_id                     (client_id)
#  index_client_riders_on_client_id_and_app_account_id  (client_id,app_account_id) UNIQUE
#  index_client_riders_on_company_id                    (company_id)
#  index_client_riders_on_removed_by_id                 (removed_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (removed_by_id => users.id) ON DELETE => nullify
#
class ClientRider < ApplicationRecord
  include TenantScoped
  audited associated_with: :client

  belongs_to :client
  belongs_to :app_account
  belongs_to :removed_by, class_name: "User", optional: true

  enum :status, { invited: "invited", accepted: "accepted", declined: "declined", removed: "removed" }, validate: true

  normalizes :matched_email, with: ->(v) { v.to_s.strip.downcase }

  validates :matched_email, presence: true # one row per (client, account): the unique index (ConvoyApp::Links::Match relies on it)

  # The links a person can still act on or see: waiting for them, or accepted.
  scope :open_links, -> { where(status: %w[invited accepted]) }
end
