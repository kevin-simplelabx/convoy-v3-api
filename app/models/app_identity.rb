# A verified mobile number or email of a Convoy App account. Mobiles are always personal; one mobile and one personal
# email per account, and a work email per employer domain (never a personal mail provider). A value belongs to one account:
# a reissued mobile moves to whoever verifies it (AppIdentityMove). Work emails are checked again every 12 months; past
# that date the employer and school links they found are paused until verified again.
# == Schema Information
#
# Table name: app_identities
# Database name: primary
#
#  id             :bigint           not null, primary key
#  domain         :string
#  kind           :string           not null
#  tag            :string           not null
#  value          :string           not null
#  verified_at    :datetime         not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint           not null
#
# Indexes
#
#  index_app_identities_on_app_account_id    (app_account_id)
#  index_app_identities_on_domain            (domain) WHERE ((tag)::text = 'work'::text)
#  index_app_identities_on_kind_and_value    (kind,value) UNIQUE
#  index_app_identities_one_personal         (app_account_id,kind) UNIQUE WHERE ((tag)::text = 'personal'::text)
#  index_app_identities_one_work_per_domain  (app_account_id,domain) UNIQUE WHERE ((tag)::text = 'work'::text)
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#
class AppIdentity < ApplicationRecord
  REVERIFY_EVERY = 12.months
  REVERIFY_WARN = 30.days

  audited associated_with: :app_account

  belongs_to :app_account, inverse_of: :identities

  enum :kind, { mobile: "mobile", email: "email" }, validate: true
  enum :tag, { personal: "personal", work: "work" }, validate: true, prefix: false

  normalizes :value, with: ->(v) { v.to_s.strip }

  validates :value, presence: true, uniqueness: { scope: :kind }
  validates :verified_at, presence: true
  validate :value_format

  before_validation { self.domain = email? ? value.to_s.split("@").last&.downcase : nil }

  # "+6591882045" for a Singapore mobile typed as "9188 2045" / "+65 9188 2045", else the digits as typed.
  def self.normalize_mobile(value)
    digits = value.to_s.gsub(/[^\d+]/, "")
    digits = "+65#{digits}" if digits.match?(/\A[89]\d{7}\z/)
    digits
  end

  def self.valid_mobile?(value) = value.to_s.match?(/\A\+65[89]\d{7}\z/)

  def self.valid_email?(value) = value.to_s.match?(/\A[^@\s]+@[^@\s]+\.[a-z]{2,}\z/i)

  # "+65 9188 2045" / the email.
  def display = mobile? ? value.sub(/\A\+65(\d{4})(\d{4})\z/, '+65 \1 \2') : value

  # Work email: next check date, and whether its links are paused (past it) or the warning shows (30 days before).
  def reverify_due_on = work? ? (verified_at + REVERIFY_EVERY).to_date : nil

  def reverify_state(today = Date.current)
    return unless work?
    return "paused" if today >= reverify_due_on
    return "due_soon" if today >= reverify_due_on - REVERIFY_WARN

    "ok"
  end

  def links_paused?(today = Date.current) = reverify_state(today) == "paused"

  private

  def value_format
    if mobile?
      errors.add(:value, "is not an 8-digit Singapore mobile number") unless self.class.valid_mobile?(value)
    elsif !self.class.valid_email?(value)
      errors.add(:value, "is not a valid email")
    elsif work? && ConvoyApp.free_mail?(domain)
      errors.add(:value, "is a personal provider and can't be a work email")
    end
  end
end
