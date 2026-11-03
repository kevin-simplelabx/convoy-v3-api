# A 6-digit one-time code for signing in to the Convoy Driver app, by mobile number (the account may not exist yet:
# the first correct code creates it). Only an HMAC of the code is kept. It works once, for 10 minutes, with 5 tries; a
# new code replaces the older ones. Until SMS is set up the code is always DriverApp.otp_code (123456) and is not sent.
# == Schema Information
#
# Table name: driver_sign_in_codes
# Database name: primary
#
#  id          :bigint           not null, primary key
#  attempts    :integer          default(0), not null
#  code_digest :string           not null
#  expires_at  :datetime         not null
#  ip          :string
#  phone       :string           not null
#  used_at     :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_driver_sign_in_codes_on_phone_and_created_at  (phone,created_at)
#
class DriverSignInCode < ApplicationRecord
  TTL = 10.minutes
  MAX_ATTEMPTS = 5

  scope :usable, -> { where(used_at: nil).where("expires_at > ?", Time.current).where("attempts < ?", MAX_ATTEMPTS) }

  # A new code for the mobile (older unused codes stop working). Returns [record, plain code].
  def self.issue!(phone, ip: nil)
    code = DriverApp.otp_code
    transaction do
      where(phone:, used_at: nil).update_all(used_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      [ create!(phone:, code_digest: digest(code), expires_at: TTL.from_now, ip:), code ]
    end
  end

  def self.digest(code) = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "driver-code:#{code}")

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
