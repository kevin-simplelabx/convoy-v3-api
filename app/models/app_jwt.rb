# One Convoy App sign-in (Bearer token allowlist): the phone it is on. A person may be signed in on several phones.
# == Schema Information
#
# Table name: app_jwts
# Database name: primary
#
#  id             :bigint           not null, primary key
#  aud            :string
#  exp            :datetime         not null
#  jti            :string           not null
#  last_used_at   :datetime
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint           not null
#
# Indexes
#
#  index_app_jwts_on_app_account_id  (app_account_id)
#  index_app_jwts_on_exp             (exp)
#  index_app_jwts_on_jti             (jti) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#
class AppJwt < ApplicationRecord
  belongs_to :app_account
  has_many :devices, class_name: "AppDevice", dependent: :delete_all

  scope :expired, -> { where(exp: ...Time.current) }

  def touch_used!
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 5.minutes.ago # rubocop:disable Rails/SkipsModelValidations
  end
end
