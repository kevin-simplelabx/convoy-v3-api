# One Convoy Driver app sign-in (Bearer token allowlist): the phone it is on, and the company membership picked for it
# with that company's app session (what Ops Control reads as "signed in to the Driver app").
# == Schema Information
#
# Table name: driver_jwts
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  aud                   :string
#  exp                   :datetime         not null
#  jti                   :string           not null
#  last_used_at          :datetime
#  name                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  driver_account_id     :bigint           not null
#  driver_app_session_id :bigint
#  driver_id             :bigint
#  operator_driver_id    :bigint
#
# Indexes
#
#  index_driver_jwts_on_driver_account_id   (driver_account_id)
#  index_driver_jwts_on_driver_id           (driver_id)
#  index_driver_jwts_on_exp                 (exp)
#  index_driver_jwts_on_jti                 (jti) UNIQUE
#  index_driver_jwts_on_operator_driver_id  (operator_driver_id)
#
# Foreign Keys
#
#  fk_rails_...  (driver_account_id => driver_accounts.id)
#  fk_rails_...  (driver_app_session_id => driver_app_sessions.id) ON DELETE => nullify
#  fk_rails_...  (driver_id => drivers.id) ON DELETE => nullify
#  fk_rails_...  (operator_driver_id => operator_drivers.id) ON DELETE => nullify
#
class DriverJwt < ApplicationRecord
  belongs_to :driver_account
  belongs_to :driver, optional: true
  belongs_to :operator_driver, optional: true
  belongs_to :driver_app_session, optional: true

  scope :expired, -> { where(exp: ...Time.current) }

  # The picked membership (in any company), or nil.
  def membership = ActsAsTenant.without_tenant { driver || operator_driver }

  # Its key ("driver-4"), read from the ids so no company is needed.
  def membership_key
    if driver_id then "driver-#{driver_id}"
    elsif operator_driver_id then "operator_driver-#{operator_driver_id}"
    end
  end

  def touch_used!
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 5.minutes.ago # rubocop:disable Rails/SkipsModelValidations
  end
end
