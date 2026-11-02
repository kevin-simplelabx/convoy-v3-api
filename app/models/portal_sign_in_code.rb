# A 6-digit one-time code emailed to a Client Portal person: first sign-in (set a password) or a forgotten password.
# Only an HMAC of the code is kept. It works once, for 15 minutes, with 5 tries; a new code replaces the older ones.
# == Schema Information
#
# Table name: portal_sign_in_codes
# Database name: primary
#
#  id                :bigint           not null, primary key
#  attempts          :integer          default(0), not null
#  code_digest       :string           not null
#  expires_at        :datetime         not null
#  ip                :string
#  purpose           :string           not null
#  used_at           :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  portal_account_id :bigint           not null
#
# Indexes
#
#  index_portal_sign_in_codes_on_portal_account_id_and_created_at  (portal_account_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (portal_account_id => portal_accounts.id)
#
class PortalSignInCode < ApplicationRecord
  TTL = 15.minutes
  MAX_ATTEMPTS = 5

  belongs_to :portal_account

  enum :purpose, { first: "first", reset: "reset" }, prefix: :for, scopes: false, validate: true

  scope :usable, -> { where(used_at: nil).where("expires_at > ?", Time.current).where("attempts < ?", MAX_ATTEMPTS) }

  # A new code for the account (older unused codes stop working). Returns [record, plain code].
  def self.issue!(account, purpose:, ip: nil)
    code = format("%06d", SecureRandom.random_number(1_000_000))
    transaction do
      account.sign_in_codes.where(used_at: nil).update_all(used_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      [ account.sign_in_codes.create!(purpose:, code_digest: digest(code), expires_at: TTL.from_now, ip:), code ]
    end
  end

  def self.digest(code) = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "portal-code:#{code}")

  # True when the code matches (and marks it used); counts the try otherwise.
  def check!(code)
    if ActiveSupport::SecurityUtils.secure_compare(code_digest, self.class.digest(code.to_s.strip))
      update!(used_at: Time.current)
      true
    else
      increment!(:attempts) # rubocop:disable Rails/SkipsModelValidations
      false
    end
  end
end
