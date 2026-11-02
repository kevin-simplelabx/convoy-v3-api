# A coordinator's picks for booking notifications: each event kind on or off, by email too, and when they last opened
# the bell (events after it are unseen). Every kind is on until they change it.
# == Schema Information
#
# Table name: user_notification_preferences
# Database name: primary
#
#  id              :bigint           not null, primary key
#  acknowledged    :boolean          default(TRUE), not null
#  cancel_request  :boolean          default(TRUE), not null
#  client_approved :boolean          default(TRUE), not null
#  client_declined :boolean          default(TRUE), not null
#  email           :boolean          default(TRUE), not null
#  new_booking     :boolean          default(TRUE), not null
#  seen_at         :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_user_notification_preferences_on_company_id  (company_id)
#  index_user_notification_preferences_on_user_id     (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
class UserNotificationPreference < ApplicationRecord
  include TenantScoped

  belongs_to :user

  def self.for(user) = find_or_initialize_by(user:)

  def wants?(kind) = public_send(kind)
  def kinds_on = BookingEvent::KINDS.select { |k| wants?(k) }
end
