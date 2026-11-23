# == Schema Information
#
# Table name: driver_devices
# Database name: primary
#
#  id                :bigint           not null, primary key
#  platform          :string           not null
#  push_token        :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  driver_account_id :bigint           not null
#  driver_jwt_id     :bigint           not null
#
# Indexes
#
#  index_driver_devices_on_driver_account_id  (driver_account_id)
#  index_driver_devices_on_driver_jwt_id      (driver_jwt_id) UNIQUE
#  index_driver_devices_on_push_token         (push_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (driver_account_id => driver_accounts.id) ON DELETE => cascade
#  fk_rails_...  (driver_jwt_id => driver_jwts.id) ON DELETE => cascade
#
# The push token of the phone a Convoy Driver app sign-in is on (FCM). It goes with the sign-in: signing out, or signing in
# on another phone, removes it. Push::DriverNotifications sends the bell lines of every company the account works for.
class DriverDevice < ApplicationRecord
  belongs_to :driver_account
  belongs_to :driver_jwt

  enum :platform, { ios: "ios", android: "android" }, validate: true

  validates :push_token, presence: true, length: { maximum: 4096 }
end
