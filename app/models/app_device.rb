# The push token of a phone signed in to the Convoy App (FCM / APNs). It goes with the sign-in: signing out removes it.
# New inbox alerts are pushed to it (Push::AppAlerts) while Account › Notifications › Push is on.
# == Schema Information
#
# Table name: app_devices
# Database name: primary
#
#  id             :bigint           not null, primary key
#  platform       :string           not null
#  push_token     :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint           not null
#  app_jwt_id     :bigint           not null
#
# Indexes
#
#  index_app_devices_on_app_account_id  (app_account_id)
#  index_app_devices_on_app_jwt_id      (app_jwt_id)
#  index_app_devices_on_push_token      (push_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#  fk_rails_...  (app_jwt_id => app_jwts.id) ON DELETE => cascade
#
class AppDevice < ApplicationRecord
  belongs_to :app_account
  belongs_to :app_jwt

  enum :platform, { ios: "ios", android: "android" }, validate: true

  validates :push_token, presence: true, length: { maximum: 4096 }

  # Saves the phone's token for this sign-in: one per sign-in, and a token another sign-in has moves here. The sign-in row
  # is locked first, so registrations sent at the same moment wait for each other instead of both inserting.
  def self.register!(jwt, attrs)
    transaction do
      jwt.lock!
      where(push_token: attrs[:push_token]).where.not(app_jwt_id: jwt.id).delete_all
      where(app_jwt: jwt).first_or_initialize.update!(app_account_id: jwt.app_account_id, **attrs)
    end
  end
end
