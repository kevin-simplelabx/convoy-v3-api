# An email a notification would send (recorded only until mail is set up: sent_at stays empty).
# == Schema Information
#
# Table name: notification_emails
# Database name: primary
#
#  id               :bigint           not null, primary key
#  body             :text
#  sent_at          :datetime
#  subject          :string           not null
#  to               :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  booking_event_id :bigint
#  company_id       :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_notification_emails_on_booking_event_id  (booking_event_id)
#  index_notification_emails_on_company_id        (company_id)
#  index_notification_emails_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_event_id => booking_events.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
class NotificationEmail < ApplicationRecord
  include TenantScoped

  belongs_to :user
  belongs_to :booking_event, optional: true

  validates :to, :subject, presence: true
end
