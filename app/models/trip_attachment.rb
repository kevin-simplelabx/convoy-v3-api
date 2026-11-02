# == Schema Information
#
# Table name: trip_attachments
# Database name: primary
#
#  id             :bigint           not null, primary key
#  file           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  trip_id        :bigint           not null
#  uploaded_by_id :bigint
#
# Indexes
#
#  index_trip_attachments_on_company_id      (company_id)
#  index_trip_attachments_on_trip_id         (trip_id)
#  index_trip_attachments_on_uploaded_by_id  (uploaded_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (uploaded_by_id => users.id)
#
# A file kept with a trip (itinerary, guest list, permit, PO): up to 10 per trip, shown in the trip form and drawer.
class TripAttachment < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  mount_uploader :file, DocumentUploader

  belongs_to :trip, inverse_of: :attachments
  belongs_to :uploaded_by, class_name: "User", optional: true

  validates :file, presence: true
  validate :within_limit, on: :create

  private

  def within_limit
    return if trip.nil? || trip.attachments.where.not(id: nil).count < Trip::MAX_ATTACHMENTS

    errors.add(:base, "Up to #{Trip::MAX_ATTACHMENTS} files per trip")
  end
end
