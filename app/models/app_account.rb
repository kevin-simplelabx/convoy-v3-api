# One person in the Convoy App, platform-wide (not per company): their name as everyone sees it (Show My Name As), photo,
# notification switches and every mobile and email they verified (identities; any of them signs in). Companies keep
# their own records of the person (riders' guardians, client users, bookings) and link to this account.
# delete_requested_at = Delete Account asked: removed 30 days later unless they sign in again.
# == Schema Information
#
# Table name: app_accounts
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  delete_requested_at :datetime
#  first_name          :string
#  last_name           :string
#  last_sign_in_at     :datetime
#  name_order          :string           default("first"), not null
#  notify_email        :boolean          default(TRUE), not null
#  notify_push         :boolean          default(TRUE), not null
#  notify_sms          :boolean          default(FALSE), not null
#  photo               :string
#  terms_accepted_at   :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_app_accounts_on_delete_requested_at  (delete_requested_at) WHERE (delete_requested_at IS NOT NULL)
#
class AppAccount < ApplicationRecord
  DELETE_AFTER = 30.days

  devise :jwt_authenticatable, jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  audited only: %i[first_name last_name name_order photo notify_push notify_sms notify_email terms_accepted_at delete_requested_at]

  mount_uploader :photo, ImageUploader

  has_many :identities, -> { order(:kind, :tag, :id) }, class_name: "AppIdentity", dependent: :delete_all, inverse_of: :app_account
  has_many :jwts, class_name: "AppJwt", dependent: :delete_all
  has_many :devices, class_name: "AppDevice", dependent: :delete_all

  normalizes :first_name, :last_name, with: ->(v) { v.to_s.squish.presence }

  validates :name_order, inclusion: { in: %w[first last] }
  validates :first_name, :last_name, length: { maximum: 60 }

  scope :due_for_deletion, -> { where(delete_requested_at: ...DELETE_AFTER.ago) }

  # Create Your Account done (name and terms).
  def profile_complete? = first_name.present? && last_name.present? && terms_accepted_at.present?

  # "Rachel Tan" or "Tan Mei Ling" as the person chose.
  def display_name
    parts = name_order == "last" ? [ last_name, first_name ] : [ first_name, last_name ]
    parts.compact_blank.join(" ").presence
  end

  def mobile = identities.find { it.kind == "mobile" }

  def personal_email = identities.find { it.kind == "email" && it.tag == "personal" }

  def work_emails = identities.select(&:work?)
end
