# "Can't Accept" on changes the transport company made to a booking (Convoy App): what does not work and a message.
# The booking stays as it is until the company sends another option; Convoy OS sees the replies on the booking.
# == Schema Information
#
# Table name: booking_change_replies
# Database name: primary
#
#  id                        :bigint           not null, primary key
#  message                   :text
#  reason                    :string           not null
#  replied_by_name           :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  booking_id                :bigint           not null
#  company_id                :bigint           not null
#  replied_by_app_account_id :bigint
#  replied_by_client_user_id :bigint
#
# Indexes
#
#  index_booking_change_replies_on_booking_id                 (booking_id)
#  index_booking_change_replies_on_company_id                 (company_id)
#  index_booking_change_replies_on_replied_by_app_account_id  (replied_by_app_account_id)
#  index_booking_change_replies_on_replied_by_client_user_id  (replied_by_client_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (replied_by_app_account_id => app_accounts.id) ON DELETE => nullify
#  fk_rails_...  (replied_by_client_user_id => client_users.id)
#
class BookingChangeReply < ApplicationRecord
  include TenantScoped
  audited associated_with: :booking

  REASONS = [ "The new time does not work", "We need the buses we asked for", "The price is more than approved", "Something else" ].freeze

  belongs_to :booking
  belongs_to :replied_by_client_user, class_name: "ClientUser", optional: true
  belongs_to :replied_by_app_account, class_name: "AppAccount", optional: true

  validates :reason, inclusion: { in: REASONS, message: "Pick what does not work" }
  validates :replied_by_name, presence: true
end
