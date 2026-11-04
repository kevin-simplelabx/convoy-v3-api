# A file on a booking (passenger list, itinerary).
# == Schema Information
#
# Table name: booking_attachments
# Database name: primary
#
#  id                         :bigint           not null, primary key
#  file                       :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  booking_id                 :bigint           not null
#  company_id                 :bigint           not null
#  uploaded_by_client_user_id :bigint
#  uploaded_by_id             :bigint
#
# Indexes
#
#  index_booking_attachments_on_booking_id                  (booking_id)
#  index_booking_attachments_on_company_id                  (company_id)
#  index_booking_attachments_on_uploaded_by_client_user_id  (uploaded_by_client_user_id)
#  index_booking_attachments_on_uploaded_by_id              (uploaded_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (uploaded_by_client_user_id => client_users.id)
#  fk_rails_...  (uploaded_by_id => users.id)
#
class BookingAttachment < ApplicationRecord
  include TenantScoped
  audited associated_with: :booking

  mount_uploader :file, DocumentUploader

  belongs_to :booking, inverse_of: :attachments
  belongs_to :uploaded_by, class_name: "User", optional: true
  include ActorStamp
  actor_stamp :uploaded

  validates :file, presence: true
  validate :within_limit, on: :create

  private

  def within_limit
    return if booking.nil? || booking.attachments.where.not(id: nil).count < Booking::MAX_ATTACHMENTS

    errors.add(:base, "Up to #{Booking::MAX_ATTACHMENTS} files per booking")
  end
end
