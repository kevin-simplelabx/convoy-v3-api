# One Client Portal sign-in (Bearer token allowlist) and the client account picked for it.
# == Schema Information
#
# Table name: portal_jwts
# Database name: primary
#
#  id                :bigint           not null, primary key
#  aud               :string
#  exp               :datetime         not null
#  jti               :string           not null
#  last_used_at      :datetime
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  client_user_id    :bigint
#  portal_account_id :bigint           not null
#
# Indexes
#
#  index_portal_jwts_on_client_user_id     (client_user_id)
#  index_portal_jwts_on_exp                (exp)
#  index_portal_jwts_on_jti                (jti) UNIQUE
#  index_portal_jwts_on_portal_account_id  (portal_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_user_id => client_users.id)
#  fk_rails_...  (portal_account_id => portal_accounts.id)
#
class PortalJwt < ApplicationRecord
  belongs_to :portal_account
  belongs_to :client_user, optional: true

  scope :expired, -> { where(exp: ...Time.current) }

  def touch_used!
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 5.minutes.ago # rubocop:disable Rails/SkipsModelValidations
  end
end
