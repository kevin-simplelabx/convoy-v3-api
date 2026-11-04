# A 6-digit one-time code for the Convoy App, sent to a mobile or email: to sign in (the first correct code creates the
# account) or to verify a mobile / email being added to a signed-in account (app_account_id set). Only an HMAC of the code
# is kept. It works once, for 10 minutes, with 5 tries; a new code replaces older ones for the same target. Until SMS and
# email go out the code is always ConvoyApp.otp_code (123456) and nothing is sent.
# == Schema Information
#
# Table name: app_sign_in_codes
# Database name: primary
#
#  id             :bigint           not null, primary key
#  attempts       :integer          default(0), not null
#  code_digest    :string           not null
#  expires_at     :datetime         not null
#  ip             :string
#  purpose        :string           default("sign_in"), not null
#  target         :string           not null
#  used_at        :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint
#
# Indexes
#
#  index_app_sign_in_codes_on_target_and_created_at  (target,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#
class AppSignInCode < ApplicationRecord
  TTL = 10.minutes
  MAX_ATTEMPTS = 5
  PER_HOUR = 5

  belongs_to :app_account, optional: true

  enum :purpose, { sign_in: "sign_in", verify: "verify" }, prefix: :for, validate: true

  scope :usable, -> { where(used_at: nil).where("expires_at > ?", Time.current).where("attempts < ?", MAX_ATTEMPTS) }

  # A new code for the target (older unused ones stop working); 422 after 5 codes an hour. Returns the record.
  def self.issue!(target, purpose:, account: nil, ip: nil)
    if where(target:, created_at: 1.hour.ago..).count >= PER_HOUR
      raise ApplicationService::Error, "Too many codes asked for. Try again in an hour"
    end

    transaction do
      where(target:, used_at: nil).update_all(used_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      create!(target:, purpose:, app_account: account, code_digest: digest(ConvoyApp.otp_code), expires_at: TTL.from_now, ip:)
    end
  end

  def self.digest(code) = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "app-code:#{code}")

  # Checks the latest usable code of the target (for this purpose / account); raises the message the screen shows.
  def self.check!(target, code, purpose:, account: nil)
    record = usable.where(target:, purpose:, app_account_id: account&.id).order(created_at: :desc).first
    raise ApplicationService::Error, "That code has expired. Send a new one" unless record
    raise ApplicationService::Error.new("That code is not right. Try again", details: { code: [ "is not right" ] }) unless record.check!(code)

    record
  end

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
