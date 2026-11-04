# The push token of a phone signed in to the Convoy App (FCM / APNs). It goes with the sign-in: signing out removes it.
# Nothing is pushed yet (no provider); alerts are kept in the app's inbox.
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
end
