# == Schema Information
#
# Table name: allowlisted_jwts
# Database name: primary
#
#  id           :bigint           not null, primary key
#  aud          :string
#  exp          :datetime         not null
#  jti          :string           not null
#  last_used_at :datetime
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint
#  user_id      :bigint           not null
#
# Indexes
#
#  index_allowlisted_jwts_on_company_id  (company_id)
#  index_allowlisted_jwts_on_exp         (exp)
#  index_allowlisted_jwts_on_jti         (jti) UNIQUE
#  index_allowlisted_jwts_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
# One sign-in (device / app) of a user: the Bearer token (JWT) is valid while its jti is here and exp is ahead.
# Signing out deletes the row; a Convoy Admin's picked company lives on it (company_id).
class AllowlistedJwt < ApplicationRecord
  belongs_to :user
  belongs_to :company, optional: true

  scope :expired, -> { where(exp: ...Time.current) }

  # last_used_at for the device list, written at most every few minutes.
  def touch_used!
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 5.minutes.ago
  end
end
